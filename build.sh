#!/bin/sh

IMAGE_NAME="mattirantakomi/redir-nginx"
IMAGE_TAG=$(date +%Y-%m-%d_%s)

docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest .
docker push ${IMAGE_NAME}:${IMAGE_TAG}
docker push ${IMAGE_NAME}:latest
