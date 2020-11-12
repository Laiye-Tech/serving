# TensorFlow Serving

[README](README.md) | [中文文档](README_zh.md)

## 与官方repo的区别

此 repo 提供一种保护模型文件安全性的方法，它依赖我们 fork 的 TensorFlow repo: [https://github.com/Laiye-Tech/tensorflow](https://github.com/Laiye-Tech/tensorflow)，我们修改了TensorFlow代码中的`ReadBinaryProto`方法用来读取加密过的`SavedModel`(Protobuffer文件)，该文件是用我们的[加密工具](https://github.com/Laiye-Tech/cryptpb)加密过的。

## 模型加密架构

![](./images/TensorFlow模型.jpg)

我们的加密工具和 `TensorFlow` 解密模块(`loader.cc`)共享秘钥，秘钥是硬编码在代码中的，在模型训练完成后用加密工具将模型加密为密文模型，`TF-serving` 需要读取密文的模型解密后使用。

### 从源码构建

跟官方的构建方式一样

**CPU**
```sh
docker build --build-arg \
    -t tensorflow-serving-devel \
    -f tensorflow_serving/tools/docker/Dockerfile.devel .

docker build --build-arg \
    TF_SERVING_BUILD_IMAGE=tensorflow-serving-devel \
    -t tensorflow-serving \
    -f tensorflow_serving/tools/docker/Dockerfile .
```

**GPU**
```sh
docker build -t tensorflow-serving-devel-gpu \
    -f tensorflow_serving/tools/docker/Dockerfile.devel-gpu .

docker build --build-arg \
    TF_SERVING_BUILD_IMAGE=tensorflow-serving-devel-gpu \
    -t tensorflow-serving-gpu \
    -f tensorflow_serving/tools/docker/Dockerfile.gpu .
```

### 运行

确保 `saved_model.pb` 是用我们的 [加密工具](https://github.com/Laiye-Tech/cryptpb#run) 加密过的。

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

