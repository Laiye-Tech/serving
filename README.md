# TensorFlow Serving

[![Ubuntu Build Status](https://storage.googleapis.com/tensorflow-serving-kokoro-build-badges-bucket/ubuntu.svg)](https://storage.googleapis.com/tensorflow-serving-kokoro-build-badges-bucket/ubuntu.html)
[![Ubuntu Build Status at TF HEAD](https://storage.googleapis.com/tensorflow-serving-kokoro-build-badges-bucket/ubuntu-tf-head.svg)](https://storage.googleapis.com/tensorflow-serving-kokoro-build-badges-bucket/ubuntu-tf-head.html)
![Docker CPU Nightly Build Status](https://storage.googleapis.com/tensorflow-serving-kokoro-build-badges-bucket/docker-cpu-nightly.svg)
![Docker GPU Nightly Build Status](https://storage.googleapis.com/tensorflow-serving-kokoro-build-badges-bucket/docker-gpu-nightly.svg)

## Difference from origin repo

This forked repo use forked TensorFlow repo `https://github.com/Laiye-Tech/tensorflow` which modified `ReadBinaryProto` function for load a encrypted saved model(a pb file). so the saved model should be ecnrypted by our [ecnrypt tool](https://github.com/Laiye-Tech/cryptpb).

## Architecture of encrypted model

![](./images/TensorFlow模型.jpg)

### Build from sources

There are some differences from TensorFlow build document. 

**CPU**
```sh
docker build --build-arg \
    -t snowcrumble/tensorflow-serving-devel:v2.2.0-crypt \
    -f tensorflow_serving/tools/docker/Dockerfile.devel .

docker push snowcrumble/tensorflow-serving-devel:v2.2.0-crypt

docker build --build-arg \
    TF_SERVING_BUILD_IMAGE=snowcrumble/tensorflow-serving-devel:v2.2.0-crypt \
    -t snowcrumble/tensorflow-serving:v2.2.0-crypt \
    -f tensorflow_serving/tools/docker/Dockerfile .
```

**GPU**
```sh
docker build -t snowcrumble/tensorflow-serving-devel-gpu:v2.2.0-crypt-nolm \
    -f tensorflow_serving/tools/docker/Dockerfile.devel-gpu .

docker push snowcrumble/tensorflow-serving-devel-gpu:v2.2.0-crypt-nolm

docker build --build-arg \
    TF_SERVING_BUILD_IMAGE=snowcrumble/tensorflow-serving-devel-gpu:v2.2.0-crypt-nolm \
    -t snowcrumble/tensorflow-serving-gpu:v2.2.0-crypt-nolm \
    -f tensorflow_serving/tools/docker/Dockerfile.gpu .
```

### Run

Make sure saved_model.pb is encrypted by our [crypt tool](https://git.laiye.com/lijingfeng/cryptpb#run)

```sh
export MODEL_DIR=$PWD/tensorflow_serving/servables/tensorflow/testdata/saved_model_half_plus_two_cpu/
export MODEL_NAME=half_plus_two
docker run -t --rm -p 8501:8501 -p 8500:8500 \
    -v "$MODEL_DIR:/models/$MODEL_NAME" \
    -e MODEL_NAME=$MODEL_NAME \
    -e TF_CPP_MIN_VLOG_LEVEL=2 \
    -e LM_CLIENT_SERVICE_ID="100001" \
    -e LM_CLIENT_LICENSE_MANAGER_ADDR="localhost:19080" \
    snowcrumble/tensorflow-serving:v2.2.0-crypt-nolm &

# 多模型
docker run -t --rm -p 8501:8501 -p 8500:8500 \
    --entrypoint /usr/bin/tensorflow_model_server \
    -v "$PWD:/models" \
    -e TF_CPP_MIN_VLOG_LEVEL=2 \
    -e LM_CLIENT_SERVICE_ID="100001" \
    -e LM_CLIENT_LICENSE_MANAGER_ADDR="localhost:19080" \
    snowcrumble/tensorflow-serving --port=8500 --rest_api_port=8501 \
    --model_config_file="/models/config"
```

*Below is original doc.*

----
TensorFlow Serving is a flexible, high-performance serving system for
machine learning models, designed for production environments. It deals with
the *inference* aspect of machine learning, taking models after *training* and
managing their lifetimes, providing clients with versioned access via
a high-performance, reference-counted lookup table.
TensorFlow Serving provides out-of-the-box integration with TensorFlow models,
but can be easily extended to serve other types of models and data.

To note a few features:

-   Can serve multiple models, or multiple versions of the same model
    simultaneously
-   Exposes both gRPC as well as HTTP inference endpoints
-   Allows deployment of new model versions without changing any client code
-   Supports canarying new versions and A/B testing experimental models
-   Adds minimal latency to inference time due to efficient, low-overhead
    implementation
-   Features a scheduler that groups individual inference requests into batches
    for joint execution on GPU, with configurable latency controls
-   Supports many *servables*: Tensorflow models, embeddings, vocabularies,
    feature transformations and even non-Tensorflow-based machine learning
    models

## Serve a Tensorflow model in 60 seconds
```bash
# Download the TensorFlow Serving Docker image and repo
docker pull tensorflow/serving

git clone https://github.com/tensorflow/serving
# Location of demo models
TESTDATA="$(pwd)/serving/tensorflow_serving/servables/tensorflow/testdata"

# Start TensorFlow Serving container and open the REST API port
docker run -t --rm -p 8501:8501 \
    -v "$TESTDATA/saved_model_half_plus_two_cpu:/models/half_plus_two" \
    -e MODEL_NAME=half_plus_two \
    tensorflow/serving &

# Query the model using the predict API
curl -d '{"instances": [1.0, 2.0, 5.0]}' \
    -X POST http://localhost:8501/v1/models/half_plus_two:predict

# Returns => { "predictions": [2.5, 3.0, 4.5] }
```

## End-to-End Training & Serving Tutorial

Refer to the official Tensorflow documentations site for [a complete tutorial to train and serve a Tensorflow Model](https://www.tensorflow.org/tfx/tutorials/serving/rest_simple).


## Documentation

### Set up

The easiest and most straight-forward way of using TensorFlow Serving is with
Docker images. We highly recommend this route unless you have specific needs
that are not addressed by running in a container.

*   [Install Tensorflow Serving using Docker](tensorflow_serving/g3doc/docker.md)
    *(Recommended)*
*   [Install Tensorflow Serving without Docker](tensorflow_serving/g3doc/setup.md)
    *(Not Recommended)*
*   [Build Tensorflow Serving from Source with Docker](tensorflow_serving/g3doc/building_with_docker.md)
*   [Deploy Tensorflow Serving on Kubernetes](tensorflow_serving/g3doc/serving_kubernetes.md)

### Use

#### Export your Tensorflow model

In order to serve a Tensorflow model, simply export a SavedModel from your
Tensorflow program.
[SavedModel](https://github.com/tensorflow/tensorflow/blob/master/tensorflow/python/saved_model/README.md)
is a language-neutral, recoverable, hermetic serialization format that enables
higher-level systems and tools to produce, consume, and transform TensorFlow
models.

Please refer to [Tensorflow documentation](https://www.tensorflow.org/guide/saved_model#save_and_restore_models)
for detailed instructions on how to export SavedModels.

#### Configure and Use Tensorflow Serving

* [Follow a tutorial on Serving Tensorflow models](tensorflow_serving/g3doc/serving_basic.md)
* [Configure Tensorflow Serving to make it fit your serving use case](tensorflow_serving/g3doc/serving_config.md)
* Read the [Performance Guide](tensorflow_serving/g3doc/performance.md)
and learn how to [use TensorBoard to profile and optimize inference requests](tensorflow_serving/g3doc/tensorboard.md)
* Read the [REST API Guide](tensorflow_serving/g3doc/api_rest.md)
or [gRPC API definition](https://github.com/tensorflow/serving/tree/master/tensorflow_serving/apis)
* [Use SavedModel Warmup if initial inference requests are slow due to lazy initialization of graph](tensorflow_serving/g3doc/saved_model_warmup.md)
* [If encountering issues regarding model signatures, please read the SignatureDef documentation](tensorflow_serving/g3doc/signature_defs.md)
* If using a model with custom ops, [learn how to serve models with custom ops](tensorflow_serving/g3doc/custom_op.md)

### Extend

Tensorflow Serving's architecture is highly modular. You can use some parts
individually (e.g. batch scheduling) and/or extend it to serve new use cases.

* [Ensure you are familiar with building Tensorflow Serving](tensorflow_serving/g3doc/building_with_docker.md)
* [Learn about Tensorflow Serving's architecture](tensorflow_serving/g3doc/architecture.md)
* [Explore the Tensorflow Serving C++ API reference](https://www.tensorflow.org/tfx/serving/api_docs/cc/)
* [Create a new type of Servable](tensorflow_serving/g3doc/custom_servable.md)
* [Create a custom Source of Servable versions](tensorflow_serving/g3doc/custom_source.md)

## Contribute


**If you'd like to contribute to TensorFlow Serving, be sure to review the
[contribution guidelines](CONTRIBUTING.md).**


## For more information

Please refer to the official [TensorFlow website](http://tensorflow.org) for
more information.
