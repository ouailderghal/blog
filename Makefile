IMAGE_NAME = klakegg/hugo
IMAGE_TAG = latest
IMAGE = $(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: build
build:
	docker run --rm --interactive --tty --volume ".:/src" $(IMAGE)

.PHONY: server
server:
	docker run --rm --interactive --tty --volume ".:/src" --publish "1313:1313" $(IMAGE) server

