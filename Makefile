# Name of the Docker image
IMAGE_NAME = hybrid-node
# Tag for the image
IMAGE_TAG = latest
# Container name
CONTAINER_NAME = hybrid-node

# Default target: build the image
.PHONY: all
all: build

# Build the Docker image
.PHONY: build
build:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

# Run the Docker container
.PHONY: run
run:
	docker run --rm --privileged -p 10250:10250 --network host -v /var/run/docker.sock:/var/run/docker.sock --name $(CONTAINER_NAME) -d $(IMAGE_NAME):$(IMAGE_TAG) 
	docker exec -it $(CONTAINER_NAME) /bin/bash

# Stop the running container
.PHONY: stop
stop:
	docker stop $(CONTAINER_NAME) || true
	docker rm $(CONTAINER_NAME) || true

# Clean up dangling images and stopped containers
.PHONY: clean
clean:
	docker system prune -f

# Display available Makefile commands
.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make build      - Build the Docker image"
	@echo "  make run        - Run the Docker container"
	@echo "  make stop       - Stop and remove the container"
	@echo "  make clean      - Clean up dangling images and stopped containers"
	@echo "  make help       - Display this help message"