---
title: "Deploying DSpace REST: Best Practices and Lessons Learned"
subtitle: "A comprehensive guide for setting up and configuring DSpace REST for production"
author: "Ouail Derghal"
date: 2023-04-15
lastmod: 2023-04-22
featuredImage: /posts/deploy-dspace-rest/thumbnail.png
tags: [ "DSpace", "Spring", "Java", "Debian" ]
draft: false
---

# Summary

The article discusses how to deploy a DSpace REST instance and configure a Debian server with all necessary
dependencies. It outlines the requirements for the server and the dependencies needed to get DSpace REST up and running.
The article discusses how to set up a Debian server, install required packages, including Java JDK, Apache Maven, Apache
Ant, PostgreSQL, Apache Solr, and Apache Tomcat. It further guides readers on how to configure each of these
dependencies on a Debian server.

## Introduction

DSpace is an open-source digital repository software system that is used to capture, store, index, preserve, and share
digital research materials, including articles, books, conference proceedings, images, and data sets. It was initially
developed jointly by the Massachusetts Institute of Technology (MIT) and Hewlett-Packard (HP) Labs and is now managed
and maintained by a community of developers and users worldwide.

In this article, we'll go through how to deploy a DSpace REST instance and configure a Debian server with all necessary
dependencies. In order to proceed with the steps outlined in this guide, you will need to have SSH access to your Debian
server, and it is recommended that you have configured the SSH server and linked your key to the authorized keys.

## Setting up Debian server

The first step is to SSH into your Debian server. For the purposes of this guide, we will assume that your server has a
publicly accessible IP address and a registered domain name. Use the commands bellow to connect to your Debian
instance :

```shell
ssh root@api.dspace.org
```

Version `7.x` of DSpace REST, which is the most current stable release and offers significant changes and enhancements
over earlier versions, will be the main emphasis of this article. It requires certain prerequisites in order to work
properly. The dependencies are listed below:

- Java JDK 11 or 17 (OpenJDK or Oracle JDK)
- Apache Maven 3.3.x or above
- Apache Ant 1.10.x or later
- Relational Database (PostgreSQL or Oracle)
- Apache Solr 8.x
- Apache Tomcat 9

The version specifications used in this article are listed in the table below:

| Requirement   | Version | Download                                                     |
|---------------|---------|--------------------------------------------------------------|
| Java JDK      | 11.0.18 | Debian repos                                                 |
| Apache Maven  | 5.10.0  | Debian repos                                                 |
| Apache Ant    | 1.10.9  | Debian repos                                                 |
| PostgreSQL    | 13.9    | Debian repos                                                 |
| Apache Solr   | 8.11.2  | [Solr download page](https://solr.apache.org/downloads.html) |
| Apache Tomcat | 9.0.43  | Debian repos                                                 |

### Java JDK

The DSpace REST application is written in Java and built on top of the [Spring](https://spring.io/) framework. The first
required dependency to run a DSpace instance is `JDK 11/17` , which is needed to compile and execute Java code. Debian
11 includes JDK 11 in its default repositories. To install it, you can run
the following command:

```shell
sudo apt install -y default-{jdk,jre}
```

Run the command `javac --version` to check the JDK version that was installed.

### Apache Maven

Apache Maven is a build automation and software project management tool used primarily for Java projects. DSpace REST
relies on Apache Maven to manage Java project dependencies and build the software package. You can install Apache Maven
on Debian-based systems using the `apt` package manager, as it is available in the Debian repositories.

```shell
apt install -y maven
```

If you have installed Apache Maven successfully, it should now be available on your system via the `mvn` command. To
verify the installation, run the command `mvn --version` and check if the output shows a version number matching the one
listed in the requirements table.

### Apache Ant

Apache Ant is a build automation tool that enables the automation of the software projects building, testing, and
deployment process. In this article, we will utilize Ant to build the DSpace artifact (WAR package) and deploy it to the
server. Execute the following commands to install Ant and check the version that was acquired:

```shell
sudo apt install -y ant
ant -version
```

### PostgreSQL database

DSpace REST supports two popular relational databases: Oracle and PostgreSQL. Both databases offer robust features and
are widely used by many organizations. For the purposes of this article, we will be using PostgreSQL, a free and
open-source alternative with a strong reputation for reliability and performance.

To get started, you'll need to install PostgreSQL on your server:

```shell
sudo apt install -y libpq-dev postgresql postgresql-contrib
```

Next, you need to enable PostrgreSQL service :

```shell
sudo systemctl enable --now postgresql
```

Following that, you need to create a new database and user in PostgreSQL, and give that user the necessary privileges to
interact with the database:

{{< admonition type=note title="Note" open=true >}}
Don't forget to switch to `postgres` user before running the commands below.
{{< /admonition >}}

```shell
createuser --username=postgres --no-superuser --pwprompt dspace # you will be prompted for password
createdb --username=postgres --owner=dspace --encoding=UNICODE dspace
psql --username=postgres dspace -c "CREATE EXTENSION pgcrypto;"
```

The last command enables `pgcrypto` extension that provides cryptographic functions for secure data storage.

### Apache Solr

Apache Solr is a powerful, open-source search platform that provides advanced full-text search and data analytics
capabilities. It enables real-time indexing and data storage for the DSpace REST application. While Solr is not
available on Debian repos, it can be easily downloaded from the official website. Follow the simple steps to download,
install and configure Solr on your Debian instance:

Download extract and install Solr:

```shell
wget -c https://downloads.apache.org/lucene/solr/8.11.2/solr-8.11.2.zip -P /tmp 
unzip solr-8.11.2.zip -d /tmp
sudo bash /tmp/solr-8.11.2/bin/install_solr_service.sh /tmp/solr-8.11.2.zip
```

After installation, Solr is located in the /opt directory and the service should be running. You can verify the service
status by using the following `systemd` command:

```shell
sudo systemctl status solr
```

### Apache Tomcat

Apache Tomcat is a widely used open-source web server and servlet container that provides a robust platform for serving
Java applications. It is commonly referred to as a servlet engine since it executes Java servlets. In our case, we will
be using Tomcat to deploy the DSpace REST application on the server. Tomcat typically runs on port `:8080`, and the
application will be accessible on that port. To serve the application over HTTPS, we will be using a `reverse proxy`
which will be discussed further in this article.

Tomcat is also available on Debian repositories and can be installed via `apt` command:

```shell
sudo apt install -y tomcat9 # install tomcat9
sudo systemctl enable --now tomcat9 # enable service on startup
```

We will discuss the configuration of Tomcat for DSpace REST later. The configuration files can be found in
the `/etc/tomcat9`directory.

## Installing DSpace REST

In this section, we will be discussing the steps involved in building and deploying DSpace REST. We'll assume that
you're already logged into your Debian server as `root` via SSH and that you installed all necessary prerequisites by
following the instructions in the previous section.

{{< admonition type=note title="Note" open=true >}}
For the purpose of this tutorial, we are using [DSpace CRIS](https://wiki.lyrasis.org/display/DSPACECRIS). It is a
module of the DSpace platform that extends the functionality of DSpace to manage and showcase research information.
{{< /admonition >}}

### Downloading DSpace REST

First of all, you need to download the DSpace REST application either from
their [releases page](https://github.com/4Science/DSpace/releases) or by running the command below:

```shell
wget -c https://github.com/4Science/DSpace/archive/refs/tags/dspace-cris-2022.03.00.zip -P /opt
unzip /opt/dspace-cris-2022.03.00.zip -d /opt 
mv /opt/DSpace-dspace-cris-2022.03.00/ $DSPACE_SOURCE
```

{{< admonition type=tip title="Tip" open=true >}}
You can use shell variables to define the directories required for installing DSpace:

```shell
DSPACE_SOURCE=/opt/dspace-source
DSPACE_INSTALL=/dspace
SOLR_DIR=/opt/solr
```

{{< /admonition >}}

### Creating configuration file

To proceed, the next step is to create a configuration file for the DSpace application. The easiest way to do this is by
copying the `EXAMPLE` configuration file to the DSpace configuration directory. You can accomplish this by running the
following command in your shell:

```shell
cp $DSPACE_SOURCE/dspace/config/local.cfg.EXAMPLE $DSPACE_SOURCE/dspace/config/local.cfg
```

Once you have successfully copied the EXAMPLE configuration file to the appropriate directory, you need to set the
necessary configuration variables. These variables are specific to your installation and should be customized
accordingly (database credentials, server URL and user interface URL)

```cfg
# Server configuration
dspace.dir = /dspace
dspace.server.url = https://api-dspace.organization.edu
dspace.ui.url = https://dspace.organization.edu

# Database credentials
db.url = jdbc:postgresql://localhost:5432/dspace
db.username = dspace
db.password = dspace
```

### Building installation package

To build and install the DSpace package, you can use the `maven` and `ant` tools. You must first
build DSpace and install its project dependencies (commands have to be run with root privileges):

```shell
cd $DSPACE_SOURCE
mvn package
```

Afterwards, you can install DSpace by running the following commands:

```shell
cd $DSPACE_SOURCE/dspace/target/dspace-installer
ant fresh_install
```

DSpace will be installed under `dspace.dir` directory specified in `local.cfg` config file. You now have access to
the `dspace` binary, which will assist you in managing your DSpace instance. It is located
under `$DSPACE_INSTALL/bin/`.

### Initializing the database

By default, DSpace application initializes the database on the first startup. Although, you can initiate database
migrating by using the DSpace binary helper:

```shell
$DSPACE_INSTALL/bin/dspace database migrate
```

To check if your database has been fully initialized, you can run `$DSPACE_INSTALL/bin/dspace database info`.

### Deploying `server` web application

Once you've built and installed DSpace, a `server` package will be created in the `webapps` directory located within the
DSpace installation path. This package contains the main web application that needs to be deployed to the Tomcat server.
In this section, we will configure Tomcat to host the DSpace application on the server's root, using port `:8080`.

To begin with, you have to change your working directory to Tomcat configuration directory and create a `Catalina`
configuration file. You need to tell Tomcat where to find DSpace web application:

Firstly, you will need to change your working directory to the Tomcat configuration folder. After that, you create
a `Catalina` configuration file. This file will inform Tomcat where to locate the DSpace web application:

```shell
cd /etc/tomcat
vi ./Catalina/localhost/ROOT.xml
```

Within the `Context` tag of the `ROOT.xml` file, you must specify the path to the DSpace web application:

```xml
<?xml version='1.0'?>
<Context docBase="/dspace/webapps/server"/>
```

he DSpace application can be accessed at `http://localhost:8080`. Later in this article, we will use `Nginx` as a
reverse proxy to expose the application over HTTPS using a domain name.

### Deploying Solr cores

The DSpace installation automatically creates a set of four pre-configured Solr cores that are initially empty. You need
to deploy the cores to Solr config directory and restart the service:

```shell
cp -R $DSPACE_INSTALL/solr/* $SOLR_DIR/server/solr/configsets
chown -R solr:solr $SOLR_DIR/server/solr/configsets

# Restart Solr service
$SOLR_DIR/bin/solr restart
```

{{< admonition type=note title="Note" open=true >}}
You can specify Solr server URL by changing `solr.server` variable in `local.cfg` file. To check the status of Solr, you
have to access Solr Web Interface served on http://localhost:8983/solr/.
{{< /admonition >}}

## Setting up production environment

In this section, we'll be configuring Nginx as a reverse proxy to serve the DSpace REST application. Additionally, we'll
be setting up SSL certificates and configuring the server firewall to enhance security.

### Installing and configuring Nginx

Nginx server will be listening on port `80` over HTTPS and redirects incoming requests to Tomcat server. To install
Nginx, you can use `apt package manager:

```shell
sudo apt install -y nginx
sudo systemctl enable nginx --now
```

Once you've completed the previous step, the next task is to generate a configuration file for the Nginx reverse proxy.
Before you can do this, you may need to delete the default Nginx configuration file.

```shell
rm /etc/nginx/sites-enables/default
vi /etc/nginx/sites-available/api-dspace
```

Bellow is the configuration file for Nginx reverse proxy running on port `:80`:

```nginx
server {
  listen 80;
  server_name api-dspace.organization.edu;

  location / {
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Forwarded-Host $host;
    proxy_pass http://localhost:8080;
  }
}
```

Now you have to enable `api-dspace` configuration:

```shell
sudo ln -s /etc/nginx/sites-available/api-dspace /etc/nginx/sites-enabled/
sudo nginx -s reload # restart Nginx
```

DSpace API should be accessible on port `:80`, to check if Nginx server is working you can
visit http://api-dspace.organization.edu.

### Setting up SSL certificates

For the sake of simplicity in this tutorial, we will be using free SSL certificates provided by `LetsEncrypt` and the
`certbot` script to set up a reverse proxy over HTTPS. To proceed, you need to install the following packages:

```shell
sudo apt install -y certbot python3-certbot-nginx
```

To generate SSL certificates and apply them to the Nginx configuration file, run the following command:

```console
sudo certbot --nginx -d api-dspace.organization.edu
```

The configuration file should resemble the following:

{{< admonition type=tip title="Tip" open=true >}}
It is recommended that you redirect traffic from port `:80` to port `:443`. You can do this by specifying a `rewrite`
action on port `:80` of Nginx server.
{{< /admonition >}}

```nginx
server {
  listen 80;
  server_name api-dspace.organization.edu;
  rewrite ^ https://api-dspace.organization.edu;
}

server {
  listen 443 ssl;
  server_name api-dspace.organization.edu;

  ssl_certificate /etc/letsencrypt/live/api-dspace.organization.edu/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/api-dspace.organization.edu/privkey.pem;
  include /etc/letsencrypt/options-ssl-nginx.conf;
  ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

  location / {
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Forwarded-Host $host;
    proxy_pass http://localhost:8080;
  }
}
```

{{< admonition type=success title="Congratulations" open=true >}}
Access to the DSpace API is now available over HTTPS for improved security.
{{< /admonition >}}
