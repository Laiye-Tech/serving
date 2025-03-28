# TensorFlow Serving

[README](README.md) | [中文文档](README_zh.md)

## Overview

As we all know, the machine learning model is the most important "intellectual property" of every AI company, and `TensorFlow Serving` encodes the model in the `Protobuffer` file and loads the model directly at runtime. This is likely to cause the model to leak and cause the company Incalculable loss. This forked repo provide a way to protect the safety of model files, it uses forked TensorFlow repo [https://github.com/Laiye-Tech/tensorflow](https://github.com/Laiye-Tech/tensorflow) which modified `ReadBinaryProto` function for loading an encrypted saved model(a pb file). So the saved model should be ecnrypted by our [ecnrypt tool](https://github.com/Laiye-Tech/cryptpb).

## Architecture of encrypted model

![](./images/TensorFlow模型.jpg)

Our encryption tool and `TensorFlow`'s decryption module (`loader.cc`) share the secret key which is hard-coded in the code. After the model training is completed, the encryption tool is used to encrypt the model into a ciphertext model. `TF-serving` requires the model that reads the ciphertext be decrypted before using it.

## Build from sources

### Prepare

For security reasons, do not use the default secret key. You can modify the shared secret key in these two locations: [cryptfile.cc#L119](https://github.com/Laiye-Tech/cryptpb/blob/main/cryptfile/cryptfile.cc#L119) and [env.cc#L62](https://github.com/Laiye-Tech/tensorflow/blob/master/tensorflow/core/platform/env.cc#L62). We currently use the `AES` encryption algorithm, you can modify its key and iv.

> Note: The key and iv in these two places need to be consistent

### Build

Same as the official build method. However, official build cloning online code when building specified a commit hash, but we modify secret key in local, so we are using local building as described below.

---

**Local building**

You can also modify [WORKSPACE#L18](https://github.com/Laiye-Tech/serving/blob/master/WORKSPACE#L18) to use local_repository rule of bazel.

1. Copy tensorflow source code which has modified secret key into serving dir to enclosed by docker build context

```bash
cp -r ../tensorflow ./tensorflow
```

2. modity Dockerfiles and bazel files below to using local repo

- tensorflow_serving/tools/docker/Dockerfile.devel
- tensorflow_serving/tools/docker/Dockerfile.devel-gpu
- WORKSPACE
- tensorflow_serving/workspace.bzl (possible, fix some checksum errors when building)

There is a example [patch](./local_build.patch) to apply local build

---

**CPU**

```sh
docker build  \
    -t tensorflow-serving-devel \
    -f tensorflow_serving/tools/docker/Dockerfile.devel .

docker build --build-arg \
    TF_SERVING_BUILD_IMAGE=tensorflow-serving-devel \
    -t tensorflow-serving \
    -f tensorflow_serving/tools/docker/Dockerfile .
```

**GPU**

```sh
docker build \
    -t tensorflow-serving-devel-gpu \
    -f tensorflow_serving/tools/docker/Dockerfile.devel-gpu .

docker build --build-arg \
    TF_SERVING_BUILD_IMAGE=tensorflow-serving-devel-gpu \
    -t tensorflow-serving-gpu \
    -f tensorflow_serving/tools/docker/Dockerfile.gpu .
```

### Run

Make sure saved_model.pb is encrypted by our [crypt tool](https://github.com/Laiye-Tech/cryptpb#run)

```sh
# Location of demo models
export MODEL_DIR=$PWD/tensorflow_serving/servables/tensorflow/testdata/saved_model_half_plus_two_cpu/
export MODEL_NAME=half_plus_two

# Start TensorFlow Serving container and open the REST API port
docker run -t --rm -p 8501:8501 -p 8500:8500 \
    -v "$MODEL_DIR:/models/$MODEL_NAME" \
    -e MODEL_NAME=$MODEL_NAME \
    tensorflow-serving &

# Query the model using the predict API
curl -d '{"instances": [1.0, 2.0, 5.0]}' \
    -X POST http://localhost:8501/v1/models/half_plus_two:predict

# Returns => { "predictions": [2.5, 3.0, 4.5] }
```

### Upgrade

We create a new branch then rebase to offical tag. Use this branch to build upgraded tensorflow serving. For example, upgrade to 2.18.0:

```bash
# 1. upgrade tensorflow
git clone https://github.com/Laiye-Tech/tensorflow
cd tensorflow
git branch b2.18.0
git remote add tf https://github.com/tensorflow/tensorflow
git fetch tf refs/tags/v2.18.0:refs/tags/v2.4.0
git checkout -b tf2.18.0 tags/v2.4.0
git checkout b2.18.0
# suggest not rebase fix it
git rebase tf2.18.0
# resolve possibility conflicts
git push --set-upstream origin b2.18.0

# 2. upgrade tensorflow serving
git clone https://github.com/Laiye-Tech/serving
cd tensorflow
git branch b2.18.0
git remote add tf https://github.com/tensorflow/serving
git fetch tf
git checkout -b tf2.18.0 tags/2.4.0
git checkout b2.18.0
git rebase tf2.18.0
# resolve possibility conflicts
git push --set-upstream origin b2.18.0


export ENCRYPT_FILE_URL=your compile file(/opt/lib/libcryptfile.so)
bash local_build.sh

# then modify the shared secret key as described in section ### Prepare and build it in section ### Build.
```