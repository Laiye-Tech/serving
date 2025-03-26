#!/bin/bash
set -x

echo "必须使用外网"

export TF_SERVING_VERSION=$(git branch --show-current)
export ENCRYPT_FILE_URL=${ENCRYPT_FILE_URL:-https://www.laiye.com/libcryptfile.so}

# build tensorflow-devel-gpu image
docker buildx build --file=./tensorflow_serving/tools/docker/Dockerfile.devel -t tensorflow/serving:${TF_SERVING_VERSION}-devel . --load
docker buildx build --file=./tensorflow_serving/tools/docker/Dockerfile.devel-gpu -t tensorflow/serving:${TF_SERVING_VERSION}-devel-gpu . --load

# build tensorflow image
docker buildx build --file=./tensorflow_serving/tools/docker/Dockerfile.gpu --build-arg TF_SERVING_VERSION=${TF_SERVING_VERSION} --build-args ENCRYPT_FILE_URL=${ENCRYPT_FILE_URL} -t tensorflow/serving:${TF_SERVING_VERSION}-gpu . --load
docker buildx build --file=./tensorflow_serving/tools/docker/Dockerfile --build-arg TF_SERVING_VERSION=${TF_SERVING_VERSION} --build-args ENCRYPT_FILE_URL=${ENCRYPT_FILE_URL} -t tensorflow/serving:${TF_SERVING_VERSION} . --load
