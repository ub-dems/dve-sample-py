##### Copyright 2019 The TensorFlow Authors.


```python
#@title Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
```

# TensorFlow 2 quickstart for beginners

<table class="tfo-notebook-buttons" align="left">
  <td>
    <a target="_blank" href="https://www.tensorflow.org/tutorials/quickstart/beginner"><img src="https://www.tensorflow.org/images/tf_logo_32px.png" />View on TensorFlow.org</a>
  </td>
  <td>
    <a target="_blank" href="https://colab.research.google.com/github/tensorflow/docs/blob/master/site/en/tutorials/quickstart/beginner.ipynb"><img src="https://www.tensorflow.org/images/colab_logo_32px.png" />Run in Google Colab</a>
  </td>
  <td>
    <a target="_blank" href="https://github.com/tensorflow/docs/blob/master/site/en/tutorials/quickstart/beginner.ipynb"><img src="https://www.tensorflow.org/images/GitHub-Mark-32px.png" />View source on GitHub</a>
  </td>
  <td>
    <a href="https://storage.googleapis.com/tensorflow_docs/docs/site/en/tutorials/quickstart/beginner.ipynb"><img src="https://www.tensorflow.org/images/download_logo_32px.png" />Download notebook</a>
  </td>
</table>

This short introduction uses [Keras](https://www.tensorflow.org/guide/keras/overview) to:

1. Load a prebuilt dataset.
1. Build a neural network machine learning model that classifies images.
2. Train this neural network.
3. Evaluate the accuracy of the model.

This tutorial is a [Google Colaboratory](https://colab.research.google.com/notebooks/welcome.ipynb) notebook. Python programs are run directly in the browser—a great way to learn and use TensorFlow. To follow this tutorial, run the notebook in Google Colab by clicking the button at the top of this page.

1. In Colab, connect to a Python runtime: At the top-right of the menu bar, select *CONNECT*.
2. To run all the code in the notebook, select **Runtime** > **Run all**. To run the code cells one at a time, hover over each cell and select the **Run cell** icon.

![Run cell icon](images/beginner/run_cell_icon.png)

## Set up TensorFlow

Import TensorFlow into your program to get started:

@see: https://macjim.medium.com/loading-alternative-cudnn-library-versions-in-tensorflow-90c7472e361a


```python
import os
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "0"  # DEBUG, INFO, WARNING, ERROR: 0 ~ 3
```


```python
!nvidia-smi -L
```

    GPU 0: Tesla V100-PCIE-16GB (UUID: GPU-a2db1942-76d6-3572-10f1-3d0b0e1fbd72)



```python
import tensorflow as tf

print("TensorFlow version:", tf.__version__)
print(tf.config.list_physical_devices('GPU'))

```

    2025-03-28 17:19:22.918192: E external/local_xla/xla/stream_executor/cuda/cuda_fft.cc:467] Unable to register cuFFT factory: Attempting to register factory for plugin cuFFT when one has already been registered
    WARNING: All log messages before absl::InitializeLog() is called are written to STDERR
    E0000 00:00:1743178762.938922  134527 cuda_dnn.cc:8579] Unable to register cuDNN factory: Attempting to register factory for plugin cuDNN when one has already been registered
    E0000 00:00:1743178762.945425  134527 cuda_blas.cc:1407] Unable to register cuBLAS factory: Attempting to register factory for plugin cuBLAS when one has already been registered
    W0000 00:00:1743178762.962523  134527 computation_placer.cc:177] computation placer already registered. Please check linkage and avoid linking the same target more than once.
    W0000 00:00:1743178762.962557  134527 computation_placer.cc:177] computation placer already registered. Please check linkage and avoid linking the same target more than once.
    W0000 00:00:1743178762.962560  134527 computation_placer.cc:177] computation placer already registered. Please check linkage and avoid linking the same target more than once.
    W0000 00:00:1743178762.962562  134527 computation_placer.cc:177] computation placer already registered. Please check linkage and avoid linking the same target more than once.
    2025-03-28 17:19:22.968294: I tensorflow/core/platform/cpu_feature_guard.cc:210] This TensorFlow binary is optimized to use available CPU instructions in performance-critical operations.
    To enable the following instructions: AVX2 FMA, in other operations, rebuild TensorFlow with the appropriate compiler flags.


    TensorFlow version: 2.19.0
    [PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]



```python
print(tf.reduce_sum(tf.random.normal([1000, 1000])))
```

    tf.Tensor(-839.56964, shape=(), dtype=float32)


    I0000 00:00:1743178767.073278  134527 gpu_device.cc:2019] Created device /job:localhost/replica:0/task:0/device:GPU:0 with 14784 MB memory:  -> device: 0, name: Tesla V100-PCIE-16GB, pci bus id: 0001:00:00.0, compute capability: 7.0



```python
try:
    with tf.device('/GPU:0'):  # Specify GPU device
        a = tf.constant([1.0, 2.0, 3.0, 4.0])
        b = tf.constant([2.0, 2.0, 2.0, 2.0])
        c = a + b
        print("Result of GPU operation:", c.numpy())
except RuntimeError as e:
    print("Error using GPU:", e)
```

    Result of GPU operation: [3. 4. 5. 6.]


If you are following along in your own development environment, rather than [Colab](https://colab.research.google.com/github/tensorflow/docs/blob/master/site/en/tutorials/quickstart/beginner.ipynb), see the [install guide](https://www.tensorflow.org/install) for setting up TensorFlow for development.

Note: Make sure you have upgraded to the latest `pip` to install the TensorFlow 2 package if you are using your own development environment. See the [install guide](https://www.tensorflow.org/install) for details.

## Load a dataset

Load and prepare the MNIST dataset. The pixel values of the images range from 0 through 255. Scale these values to a range of 0 to 1 by dividing the values by `255.0`. This also converts the sample data from integers to floating-point numbers:


```python
mnist = tf.keras.datasets.mnist

(x_train, y_train), (x_test, y_test) = mnist.load_data()
x_train, x_test = x_train / 255.0, x_test / 255.0
```

## Build a machine learning model

Build a `tf.keras.Sequential` model:


```python
model = tf.keras.models.Sequential([
  tf.keras.layers.Flatten(input_shape=(28, 28)),
  tf.keras.layers.Dense(128, activation='relu'),
  tf.keras.layers.Dropout(0.2),
  tf.keras.layers.Dense(10)
])
```

    /home/gp21012/.cache/pypoetry/virtualenvs/dve-sample-r-x2RGOxK1-py3.12/lib/python3.12/site-packages/keras/src/layers/reshaping/flatten.py:37: UserWarning: Do not pass an `input_shape`/`input_dim` argument to a layer. When using Sequential models, prefer using an `Input(shape)` object as the first layer in the model instead.
      super().__init__(**kwargs)


[`Sequential`](https://www.tensorflow.org/guide/keras/sequential_model) is useful for stacking layers where each layer has one input [tensor](https://www.tensorflow.org/guide/tensor) and one output tensor. Layers are functions with a known mathematical structure that can be reused and have trainable variables. Most TensorFlow models are composed of layers. This model uses the [`Flatten`](https://www.tensorflow.org/api_docs/python/tf/keras/layers/Flatten), [`Dense`](https://www.tensorflow.org/api_docs/python/tf/keras/layers/Dense), and [`Dropout`](https://www.tensorflow.org/api_docs/python/tf/keras/layers/Dropout) layers.

For each example, the model returns a vector of [logits](https://developers.google.com/machine-learning/glossary#logits) or [log-odds](https://developers.google.com/machine-learning/glossary#log-odds) scores, one for each class.


```python
predictions = model(x_train[:1]).numpy()
predictions
```




    array([[-0.550547  , -0.1624318 ,  0.08318366,  0.41945243, -0.00209579,
            -1.1499236 ,  0.0712679 , -0.04941237,  0.39848927,  0.5140858 ]],
          dtype=float32)



The `tf.nn.softmax` function converts these logits to *probabilities* for each class: 


```python
tf.nn.softmax(predictions).numpy()
```




    array([[0.05472739, 0.0806791 , 0.1031408 , 0.14436774, 0.09470963,
            0.03005376, 0.10191909, 0.09033265, 0.14137284, 0.15869707]],
          dtype=float32)



Note: It is possible to bake the `tf.nn.softmax` function into the activation function for the last layer of the network. While this can make the model output more directly interpretable, this approach is discouraged as it's impossible to provide an exact and numerically stable loss calculation for all models when using a softmax output. 

Define a loss function for training using `losses.SparseCategoricalCrossentropy`:


```python
loss_fn = tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True)
```

The loss function takes a vector of ground truth values and a vector of logits and returns a scalar loss for each example. This loss is equal to the negative log probability of the true class: The loss is zero if the model is sure of the correct class.

This untrained model gives probabilities close to random (1/10 for each class), so the initial loss should be close to `-tf.math.log(1/10) ~= 2.3`.


```python
loss_fn(y_train[:1], predictions).numpy()
```




    np.float32(3.5047674)



Before you start training, configure and compile the model using Keras `Model.compile`. Set the [`optimizer`](https://www.tensorflow.org/api_docs/python/tf/keras/optimizers) class to `adam`, set the `loss` to the `loss_fn` function you defined earlier, and specify a metric to be evaluated for the model by setting the `metrics` parameter to `accuracy`.


```python
model.compile(optimizer='adam',
              loss=loss_fn,
              metrics=['accuracy'])
```

## Train and evaluate your model

Use the `Model.fit` method to adjust your model parameters and minimize the loss: 


```python
model.fit(x_train, y_train, epochs=5)
```

    Epoch 1/5


    WARNING: All log messages before absl::InitializeLog() is called are written to STDERR
    I0000 00:00:1743178769.941890  134620 service.cc:152] XLA service 0x71a868003e60 initialized for platform CUDA (this does not guarantee that XLA will be used). Devices:
    I0000 00:00:1743178769.941915  134620 service.cc:160]   StreamExecutor device (0): Tesla V100-PCIE-16GB, Compute Capability 7.0
    2025-03-28 17:19:29.965598: I tensorflow/compiler/mlir/tensorflow/utils/dump_mlir_util.cc:269] disabling MLIR crash reproducer, set env var `MLIR_CRASH_REPRODUCER_DIRECTORY` to enable.
    I0000 00:00:1743178770.067161  134620 cuda_dnn.cc:529] Loaded cuDNN version 90300


    [1m   1/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m52:34[0m 2s/step - accuracy: 0.1250 - loss: 2.4616

    [1m  25/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.3302 - loss: 2.0245  

    [1m  53/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.4595 - loss: 1.7215

    [1m  82/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.5312 - loss: 1.5221

    I0000 00:00:1743178770.867686  134620 device_compiler.h:188] Compiled cluster using XLA!  This line is logged at most once for the lifetime of the process.


    [1m 109/1875[0m [32m━[0m[37m━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.5766 - loss: 1.3902

    [1m 138/1875[0m [32m━[0m[37m━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.6124 - loss: 1.2829

    [1m 164/1875[0m [32m━[0m[37m━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.6368 - loss: 1.2066

    [1m 192/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.6579 - loss: 1.1396

    [1m 220/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.6754 - loss: 1.0839

    [1m 248/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.6902 - loss: 1.0362

    [1m 276/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7028 - loss: 0.9949

    [1m 304/1875[0m [32m━━━[0m[37m━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7139 - loss: 0.9588

    [1m 332/1875[0m [32m━━━[0m[37m━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7235 - loss: 0.9270

    [1m 360/1875[0m [32m━━━[0m[37m━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7320 - loss: 0.8988

    [1m 388/1875[0m [32m━━━━[0m[37m━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7396 - loss: 0.8736

    [1m 416/1875[0m [32m━━━━[0m[37m━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7465 - loss: 0.8506

    [1m 444/1875[0m [32m━━━━[0m[37m━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7528 - loss: 0.8296

    [1m 471/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7584 - loss: 0.8110

    [1m 499/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7637 - loss: 0.7932

    [1m 527/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7686 - loss: 0.7768

    [1m 555/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7732 - loss: 0.7616

    [1m 583/1875[0m [32m━━━━━━[0m[37m━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7774 - loss: 0.7474

    [1m 608/1875[0m [32m━━━━━━[0m[37m━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7810 - loss: 0.7354

    [1m 637/1875[0m [32m━━━━━━[0m[37m━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7849 - loss: 0.7223

    [1m 665/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7885 - loss: 0.7105

    [1m 694/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7920 - loss: 0.6989

    [1m 721/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7951 - loss: 0.6886

    [1m 749/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.7981 - loss: 0.6785

    [1m 777/1875[0m [32m━━━━━━━━[0m[37m━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.8010 - loss: 0.6689

    [1m 805/1875[0m [32m━━━━━━━━[0m[37m━━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8037 - loss: 0.6598

    [1m 834/1875[0m [32m━━━━━━━━[0m[37m━━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8064 - loss: 0.6508

    [1m 862/1875[0m [32m━━━━━━━━━[0m[37m━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8089 - loss: 0.6426

    [1m 889/1875[0m [32m━━━━━━━━━[0m[37m━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8112 - loss: 0.6350

    [1m 917/1875[0m [32m━━━━━━━━━[0m[37m━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8134 - loss: 0.6275

    [1m 945/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8156 - loss: 0.6203

    [1m 973/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8176 - loss: 0.6134

    [1m1001/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8196 - loss: 0.6068

    [1m1029/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8215 - loss: 0.6004

    [1m1058/1875[0m [32m━━━━━━━━━━━[0m[37m━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8234 - loss: 0.5940

    [1m1083/1875[0m [32m━━━━━━━━━━━[0m[37m━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8250 - loss: 0.5887

    [1m1110/1875[0m [32m━━━━━━━━━━━[0m[37m━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8267 - loss: 0.5831

    [1m1138/1875[0m [32m━━━━━━━━━━━━[0m[37m━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8284 - loss: 0.5776

    [1m1165/1875[0m [32m━━━━━━━━━━━━[0m[37m━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8299 - loss: 0.5723

    [1m1193/1875[0m [32m━━━━━━━━━━━━[0m[37m━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8315 - loss: 0.5671

    [1m1221/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8330 - loss: 0.5620

    [1m1250/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8346 - loss: 0.5569

    [1m1278/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8360 - loss: 0.5522

    [1m1306/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.8374 - loss: 0.5476

    [1m1334/1875[0m [32m━━━━━━━━━━━━━━[0m[37m━━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.8387 - loss: 0.5431

    [1m1362/1875[0m [32m━━━━━━━━━━━━━━[0m[37m━━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.8400 - loss: 0.5388

    [1m1390/1875[0m [32m━━━━━━━━━━━━━━[0m[37m━━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.8413 - loss: 0.5345

    [1m1418/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.8425 - loss: 0.5304

    [1m1439/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.8435 - loss: 0.5274

    [1m1467/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.8446 - loss: 0.5234

    [1m1495/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.8458 - loss: 0.5196

    [1m1521/1875[0m [32m━━━━━━━━━━━━━━━━[0m[37m━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.8468 - loss: 0.5161

    [1m1548/1875[0m [32m━━━━━━━━━━━━━━━━[0m[37m━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.8479 - loss: 0.5126

    [1m1575/1875[0m [32m━━━━━━━━━━━━━━━━[0m[37m━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.8489 - loss: 0.5092

    [1m1601/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.8499 - loss: 0.5060

    [1m1629/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.8509 - loss: 0.5026

    [1m1658/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.8520 - loss: 0.4991

    [1m1686/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.8529 - loss: 0.4959

    [1m1713/1875[0m [32m━━━━━━━━━━━━━━━━━━[0m[37m━━[0m [1m0s[0m 2ms/step - accuracy: 0.8539 - loss: 0.4928

    [1m1741/1875[0m [32m━━━━━━━━━━━━━━━━━━[0m[37m━━[0m [1m0s[0m 2ms/step - accuracy: 0.8548 - loss: 0.4897

    [1m1769/1875[0m [32m━━━━━━━━━━━━━━━━━━[0m[37m━━[0m [1m0s[0m 2ms/step - accuracy: 0.8557 - loss: 0.4867

    [1m1797/1875[0m [32m━━━━━━━━━━━━━━━━━━━[0m[37m━[0m [1m0s[0m 2ms/step - accuracy: 0.8566 - loss: 0.4837

    [1m1826/1875[0m [32m━━━━━━━━━━━━━━━━━━━[0m[37m━[0m [1m0s[0m 2ms/step - accuracy: 0.8575 - loss: 0.4807

    [1m1854/1875[0m [32m━━━━━━━━━━━━━━━━━━━[0m[37m━[0m [1m0s[0m 2ms/step - accuracy: 0.8583 - loss: 0.4779

    [1m1875/1875[0m [32m━━━━━━━━━━━━━━━━━━━━[0m[37m[0m [1m5s[0m 2ms/step - accuracy: 0.8590 - loss: 0.4757


    Epoch 2/5


    [1m   1/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m36s[0m 19ms/step - accuracy: 0.9375 - loss: 0.2238

    [1m  29/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9524 - loss: 0.1481  

    [1m  57/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9563 - loss: 0.1420

    [1m  85/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9582 - loss: 0.1392

    [1m 113/1875[0m [32m━[0m[37m━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9598 - loss: 0.1365

    [1m 141/1875[0m [32m━[0m[37m━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9603 - loss: 0.1364

    [1m 167/1875[0m [32m━[0m[37m━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9603 - loss: 0.1370

    [1m 195/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9600 - loss: 0.1383

    [1m 223/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9596 - loss: 0.1399

    [1m 252/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9592 - loss: 0.1415

    [1m 281/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9588 - loss: 0.1428

    [1m 310/1875[0m [32m━━━[0m[37m━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9586 - loss: 0.1438

    [1m 339/1875[0m [32m━━━[0m[37m━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9584 - loss: 0.1446

    [1m 367/1875[0m [32m━━━[0m[37m━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9583 - loss: 0.1451

    [1m 395/1875[0m [32m━━━━[0m[37m━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9582 - loss: 0.1455

    [1m 423/1875[0m [32m━━━━[0m[37m━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9581 - loss: 0.1460

    [1m 451/1875[0m [32m━━━━[0m[37m━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9580 - loss: 0.1465

    [1m 478/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9579 - loss: 0.1468

    [1m 505/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9578 - loss: 0.1471

    [1m 533/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9577 - loss: 0.1474

    [1m 561/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9577 - loss: 0.1475

    [1m 590/1875[0m [32m━━━━━━[0m[37m━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9576 - loss: 0.1477

    [1m 618/1875[0m [32m━━━━━━[0m[37m━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9576 - loss: 0.1478

    [1m 646/1875[0m [32m━━━━━━[0m[37m━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9576 - loss: 0.1478

    [1m 673/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9576 - loss: 0.1479

    [1m 700/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9576 - loss: 0.1479

    [1m 729/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9575 - loss: 0.1479

    [1m 757/1875[0m [32m━━━━━━━━[0m[37m━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9575 - loss: 0.1479

    [1m 785/1875[0m [32m━━━━━━━━[0m[37m━━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9575 - loss: 0.1480

    [1m 813/1875[0m [32m━━━━━━━━[0m[37m━━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1480

    [1m 841/1875[0m [32m━━━━━━━━[0m[37m━━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1480

    [1m 866/1875[0m [32m━━━━━━━━━[0m[37m━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1479

    [1m 882/1875[0m [32m━━━━━━━━━[0m[37m━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1479

    [1m 906/1875[0m [32m━━━━━━━━━[0m[37m━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1479

    [1m 933/1875[0m [32m━━━━━━━━━[0m[37m━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1478

    [1m 959/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1478

    [1m 987/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1478

    [1m1015/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1477

    [1m1043/1875[0m [32m━━━━━━━━━━━[0m[37m━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1477

    [1m1070/1875[0m [32m━━━━━━━━━━━[0m[37m━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1476

    [1m1098/1875[0m [32m━━━━━━━━━━━[0m[37m━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9573 - loss: 0.1476

    [1m1125/1875[0m [32m━━━━━━━━━━━━[0m[37m━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1475

    [1m1152/1875[0m [32m━━━━━━━━━━━━[0m[37m━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1474

    [1m1179/1875[0m [32m━━━━━━━━━━━━[0m[37m━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1473

    [1m1204/1875[0m [32m━━━━━━━━━━━━[0m[37m━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1472

    [1m1231/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1472

    [1m1258/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1471

    [1m1286/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1470

    [1m1314/1875[0m [32m━━━━━━━━━━━━━━[0m[37m━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1469

    [1m1343/1875[0m [32m━━━━━━━━━━━━━━[0m[37m━━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1468

    [1m1371/1875[0m [32m━━━━━━━━━━━━━━[0m[37m━━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1467

    [1m1397/1875[0m [32m━━━━━━━━━━━━━━[0m[37m━━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1467

    [1m1425/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1466

    [1m1452/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1465

    [1m1478/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1464

    [1m1505/1875[0m [32m━━━━━━━━━━━━━━━━[0m[37m━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9574 - loss: 0.1463

    [1m1532/1875[0m [32m━━━━━━━━━━━━━━━━[0m[37m━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9575 - loss: 0.1462

    [1m1558/1875[0m [32m━━━━━━━━━━━━━━━━[0m[37m━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9575 - loss: 0.1461

    [1m1584/1875[0m [32m━━━━━━━━━━━━━━━━[0m[37m━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9575 - loss: 0.1460

    [1m1607/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9575 - loss: 0.1460

    [1m1632/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9575 - loss: 0.1459

    [1m1659/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9575 - loss: 0.1458

    [1m1686/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9575 - loss: 0.1457

    [1m1713/1875[0m [32m━━━━━━━━━━━━━━━━━━[0m[37m━━[0m [1m0s[0m 2ms/step - accuracy: 0.9575 - loss: 0.1456

    [1m1742/1875[0m [32m━━━━━━━━━━━━━━━━━━[0m[37m━━[0m [1m0s[0m 2ms/step - accuracy: 0.9575 - loss: 0.1455

    [1m1770/1875[0m [32m━━━━━━━━━━━━━━━━━━[0m[37m━━[0m [1m0s[0m 2ms/step - accuracy: 0.9575 - loss: 0.1454

    [1m1798/1875[0m [32m━━━━━━━━━━━━━━━━━━━[0m[37m━[0m [1m0s[0m 2ms/step - accuracy: 0.9575 - loss: 0.1454

    [1m1825/1875[0m [32m━━━━━━━━━━━━━━━━━━━[0m[37m━[0m [1m0s[0m 2ms/step - accuracy: 0.9575 - loss: 0.1453

    [1m1853/1875[0m [32m━━━━━━━━━━━━━━━━━━━[0m[37m━[0m [1m0s[0m 2ms/step - accuracy: 0.9576 - loss: 0.1452

    [1m1875/1875[0m [32m━━━━━━━━━━━━━━━━━━━━[0m[37m[0m [1m4s[0m 2ms/step - accuracy: 0.9576 - loss: 0.1451


    Epoch 3/5


    [1m   1/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m37s[0m 20ms/step - accuracy: 0.9688 - loss: 0.1000

    [1m  27/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9738 - loss: 0.0885  

    [1m  55/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9747 - loss: 0.0848

    [1m  77/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9743 - loss: 0.0861

    [1m 103/1875[0m [32m━[0m[37m━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9743 - loss: 0.0864

    [1m 130/1875[0m [32m━[0m[37m━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9740 - loss: 0.0873

    [1m 157/1875[0m [32m━[0m[37m━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9737 - loss: 0.0882

    [1m 184/1875[0m [32m━[0m[37m━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9735 - loss: 0.0889

    [1m 213/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9733 - loss: 0.0895

    [1m 241/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9730 - loss: 0.0900

    [1m 270/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9726 - loss: 0.0908

    [1m 297/1875[0m [32m━━━[0m[37m━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9723 - loss: 0.0915

    [1m 325/1875[0m [32m━━━[0m[37m━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9720 - loss: 0.0923

    [1m 352/1875[0m [32m━━━[0m[37m━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9717 - loss: 0.0928

    [1m 379/1875[0m [32m━━━━[0m[37m━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9715 - loss: 0.0934

    [1m 408/1875[0m [32m━━━━[0m[37m━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9713 - loss: 0.0940

    [1m 437/1875[0m [32m━━━━[0m[37m━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9711 - loss: 0.0946

    [1m 466/1875[0m [32m━━━━[0m[37m━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9709 - loss: 0.0951

    [1m 494/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9707 - loss: 0.0956

    [1m 522/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9706 - loss: 0.0960

    [1m 550/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9705 - loss: 0.0963

    [1m 578/1875[0m [32m━━━━━━[0m[37m━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9704 - loss: 0.0967

    [1m 606/1875[0m [32m━━━━━━[0m[37m━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9703 - loss: 0.0970

    [1m 632/1875[0m [32m━━━━━━[0m[37m━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9702 - loss: 0.0973

    [1m 661/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9701 - loss: 0.0976

    [1m 689/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9700 - loss: 0.0979

    [1m 717/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9699 - loss: 0.0981

    [1m 745/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9698 - loss: 0.0984

    [1m 774/1875[0m [32m━━━━━━━━[0m[37m━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9698 - loss: 0.0986

    [1m 802/1875[0m [32m━━━━━━━━[0m[37m━━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9697 - loss: 0.0988

    [1m 831/1875[0m [32m━━━━━━━━[0m[37m━━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9697 - loss: 0.0990

    [1m 860/1875[0m [32m━━━━━━━━━[0m[37m━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9696 - loss: 0.0992

    [1m 888/1875[0m [32m━━━━━━━━━[0m[37m━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9696 - loss: 0.0994

    [1m 917/1875[0m [32m━━━━━━━━━[0m[37m━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9695 - loss: 0.0997

    [1m 946/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9695 - loss: 0.0999

    [1m 974/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9695 - loss: 0.1001

    [1m1003/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9694 - loss: 0.1003

    [1m1031/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9694 - loss: 0.1005

    [1m1059/1875[0m [32m━━━━━━━━━━━[0m[37m━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9694 - loss: 0.1006

    [1m1088/1875[0m [32m━━━━━━━━━━━[0m[37m━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9693 - loss: 0.1008

    [1m1116/1875[0m [32m━━━━━━━━━━━[0m[37m━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9693 - loss: 0.1010

    [1m1144/1875[0m [32m━━━━━━━━━━━━[0m[37m━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9693 - loss: 0.1011

    [1m1172/1875[0m [32m━━━━━━━━━━━━[0m[37m━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9692 - loss: 0.1013

    [1m1200/1875[0m [32m━━━━━━━━━━━━[0m[37m━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9692 - loss: 0.1014

    [1m1229/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9692 - loss: 0.1016

    [1m1257/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9692 - loss: 0.1017

    [1m1283/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9692 - loss: 0.1018

    [1m1309/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9691 - loss: 0.1019

    [1m1336/1875[0m [32m━━━━━━━━━━━━━━[0m[37m━━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9691 - loss: 0.1020

    [1m1364/1875[0m [32m━━━━━━━━━━━━━━[0m[37m━━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9691 - loss: 0.1021

    [1m1390/1875[0m [32m━━━━━━━━━━━━━━[0m[37m━━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9691 - loss: 0.1022

    [1m1418/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9691 - loss: 0.1023

    [1m1446/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9691 - loss: 0.1023

    [1m1475/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9691 - loss: 0.1024

    [1m1503/1875[0m [32m━━━━━━━━━━━━━━━━[0m[37m━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9690 - loss: 0.1025

    [1m1532/1875[0m [32m━━━━━━━━━━━━━━━━[0m[37m━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9690 - loss: 0.1025

    [1m1560/1875[0m [32m━━━━━━━━━━━━━━━━[0m[37m━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9690 - loss: 0.1026

    [1m1588/1875[0m [32m━━━━━━━━━━━━━━━━[0m[37m━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9690 - loss: 0.1026

    [1m1615/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9690 - loss: 0.1027

    [1m1643/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9690 - loss: 0.1027

    [1m1670/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9690 - loss: 0.1027

    [1m1697/1875[0m [32m━━━━━━━━━━━━━━━━━━[0m[37m━━[0m [1m0s[0m 2ms/step - accuracy: 0.9690 - loss: 0.1028

    [1m1725/1875[0m [32m━━━━━━━━━━━━━━━━━━[0m[37m━━[0m [1m0s[0m 2ms/step - accuracy: 0.9690 - loss: 0.1028

    [1m1750/1875[0m [32m━━━━━━━━━━━━━━━━━━[0m[37m━━[0m [1m0s[0m 2ms/step - accuracy: 0.9690 - loss: 0.1028

    [1m1776/1875[0m [32m━━━━━━━━━━━━━━━━━━[0m[37m━━[0m [1m0s[0m 2ms/step - accuracy: 0.9690 - loss: 0.1028

    [1m1799/1875[0m [32m━━━━━━━━━━━━━━━━━━━[0m[37m━[0m [1m0s[0m 2ms/step - accuracy: 0.9690 - loss: 0.1029

    [1m1827/1875[0m [32m━━━━━━━━━━━━━━━━━━━[0m[37m━[0m [1m0s[0m 2ms/step - accuracy: 0.9690 - loss: 0.1029

    [1m1854/1875[0m [32m━━━━━━━━━━━━━━━━━━━[0m[37m━[0m [1m0s[0m 2ms/step - accuracy: 0.9690 - loss: 0.1029

    [1m1875/1875[0m [32m━━━━━━━━━━━━━━━━━━━━[0m[37m[0m [1m3s[0m 2ms/step - accuracy: 0.9690 - loss: 0.1029


    Epoch 4/5


    [1m   1/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m36s[0m 20ms/step - accuracy: 1.0000 - loss: 0.0469

    [1m  30/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9802 - loss: 0.0698  

    [1m  59/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9786 - loss: 0.0764

    [1m  87/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9771 - loss: 0.0809

    [1m 115/1875[0m [32m━[0m[37m━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9760 - loss: 0.0839

    [1m 144/1875[0m [32m━[0m[37m━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9754 - loss: 0.0856

    [1m 172/1875[0m [32m━[0m[37m━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9751 - loss: 0.0865

    [1m 201/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9750 - loss: 0.0869

    [1m 229/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9749 - loss: 0.0867

    [1m 257/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9750 - loss: 0.0864

    [1m 285/1875[0m [32m━━━[0m[37m━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9750 - loss: 0.0860

    [1m 313/1875[0m [32m━━━[0m[37m━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9750 - loss: 0.0858

    [1m 339/1875[0m [32m━━━[0m[37m━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9750 - loss: 0.0858

    [1m 366/1875[0m [32m━━━[0m[37m━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9749 - loss: 0.0857

    [1m 392/1875[0m [32m━━━━[0m[37m━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9749 - loss: 0.0855

    [1m 420/1875[0m [32m━━━━[0m[37m━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9748 - loss: 0.0853

    [1m 449/1875[0m [32m━━━━[0m[37m━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9748 - loss: 0.0852

    [1m 476/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9748 - loss: 0.0850

    [1m 500/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9747 - loss: 0.0849

    [1m 528/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9747 - loss: 0.0847

    [1m 556/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9747 - loss: 0.0846

    [1m 583/1875[0m [32m━━━━━━[0m[37m━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9746 - loss: 0.0846

    [1m 611/1875[0m [32m━━━━━━[0m[37m━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9746 - loss: 0.0845

    [1m 639/1875[0m [32m━━━━━━[0m[37m━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9746 - loss: 0.0845

    [1m 667/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9746 - loss: 0.0845

    [1m 694/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9745 - loss: 0.0845

    [1m 716/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9745 - loss: 0.0845

    [1m 744/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9745 - loss: 0.0845

    [1m 773/1875[0m [32m━━━━━━━━[0m[37m━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9745 - loss: 0.0846

    [1m 802/1875[0m [32m━━━━━━━━[0m[37m━━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9745 - loss: 0.0846

    [1m 830/1875[0m [32m━━━━━━━━[0m[37m━━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9744 - loss: 0.0846

    [1m 858/1875[0m [32m━━━━━━━━━[0m[37m━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9744 - loss: 0.0846

    [1m 886/1875[0m [32m━━━━━━━━━[0m[37m━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9744 - loss: 0.0847

    [1m 912/1875[0m [32m━━━━━━━━━[0m[37m━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9744 - loss: 0.0847

    [1m 938/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9744 - loss: 0.0847

    [1m 962/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9743 - loss: 0.0847

    [1m 987/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9743 - loss: 0.0847

    [1m1015/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9743 - loss: 0.0847

    [1m1044/1875[0m [32m━━━━━━━━━━━[0m[37m━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9743 - loss: 0.0848

    [1m1073/1875[0m [32m━━━━━━━━━━━[0m[37m━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9743 - loss: 0.0848

    [1m1101/1875[0m [32m━━━━━━━━━━━[0m[37m━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9742 - loss: 0.0848

    [1m1129/1875[0m [32m━━━━━━━━━━━━[0m[37m━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9742 - loss: 0.0849

    [1m1155/1875[0m [32m━━━━━━━━━━━━[0m[37m━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9742 - loss: 0.0850

    [1m1183/1875[0m [32m━━━━━━━━━━━━[0m[37m━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9742 - loss: 0.0850

    [1m1212/1875[0m [32m━━━━━━━━━━━━[0m[37m━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9741 - loss: 0.0851

    [1m1240/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9741 - loss: 0.0851

    [1m1268/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9741 - loss: 0.0852

    [1m1295/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9741 - loss: 0.0852

    [1m1323/1875[0m [32m━━━━━━━━━━━━━━[0m[37m━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9741 - loss: 0.0853

    [1m1351/1875[0m [32m━━━━━━━━━━━━━━[0m[37m━━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9740 - loss: 0.0853

    [1m1379/1875[0m [32m━━━━━━━━━━━━━━[0m[37m━━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9740 - loss: 0.0854

    [1m1407/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9740 - loss: 0.0854

    [1m1435/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9740 - loss: 0.0854

    [1m1463/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9740 - loss: 0.0855

    [1m1490/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9740 - loss: 0.0855

    [1m1518/1875[0m [32m━━━━━━━━━━━━━━━━[0m[37m━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9740 - loss: 0.0855

    [1m1546/1875[0m [32m━━━━━━━━━━━━━━━━[0m[37m━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9739 - loss: 0.0855

    [1m1574/1875[0m [32m━━━━━━━━━━━━━━━━[0m[37m━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9739 - loss: 0.0856

    [1m1602/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9739 - loss: 0.0856

    [1m1629/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9739 - loss: 0.0856

    [1m1657/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9739 - loss: 0.0856

    [1m1685/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9739 - loss: 0.0856

    [1m1712/1875[0m [32m━━━━━━━━━━━━━━━━━━[0m[37m━━[0m [1m0s[0m 2ms/step - accuracy: 0.9739 - loss: 0.0856

    [1m1739/1875[0m [32m━━━━━━━━━━━━━━━━━━[0m[37m━━[0m [1m0s[0m 2ms/step - accuracy: 0.9739 - loss: 0.0856

    [1m1767/1875[0m [32m━━━━━━━━━━━━━━━━━━[0m[37m━━[0m [1m0s[0m 2ms/step - accuracy: 0.9739 - loss: 0.0857

    [1m1791/1875[0m [32m━━━━━━━━━━━━━━━━━━━[0m[37m━[0m [1m0s[0m 2ms/step - accuracy: 0.9739 - loss: 0.0857

    [1m1820/1875[0m [32m━━━━━━━━━━━━━━━━━━━[0m[37m━[0m [1m0s[0m 2ms/step - accuracy: 0.9739 - loss: 0.0857

    [1m1848/1875[0m [32m━━━━━━━━━━━━━━━━━━━[0m[37m━[0m [1m0s[0m 2ms/step - accuracy: 0.9739 - loss: 0.0857

    [1m1875/1875[0m [32m━━━━━━━━━━━━━━━━━━━━[0m[37m[0m [1m3s[0m 2ms/step - accuracy: 0.9739 - loss: 0.0857


    Epoch 5/5


    [1m   1/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m35s[0m 19ms/step - accuracy: 1.0000 - loss: 0.0078

    [1m  30/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9763 - loss: 0.0728  

    [1m  58/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9755 - loss: 0.0777

    [1m  85/1875[0m [37m━━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9763 - loss: 0.0764

    [1m 112/1875[0m [32m━[0m[37m━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9772 - loss: 0.0745

    [1m 140/1875[0m [32m━[0m[37m━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9776 - loss: 0.0729

    [1m 168/1875[0m [32m━[0m[37m━━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9777 - loss: 0.0723

    [1m 196/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9778 - loss: 0.0720

    [1m 224/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m3s[0m 2ms/step - accuracy: 0.9777 - loss: 0.0718

    [1m 252/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9777 - loss: 0.0716

    [1m 279/1875[0m [32m━━[0m[37m━━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9777 - loss: 0.0714

    [1m 307/1875[0m [32m━━━[0m[37m━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9777 - loss: 0.0714

    [1m 335/1875[0m [32m━━━[0m[37m━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9776 - loss: 0.0714

    [1m 363/1875[0m [32m━━━[0m[37m━━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9776 - loss: 0.0714

    [1m 391/1875[0m [32m━━━━[0m[37m━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0714

    [1m 420/1875[0m [32m━━━━[0m[37m━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0715

    [1m 448/1875[0m [32m━━━━[0m[37m━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9774 - loss: 0.0714

    [1m 467/1875[0m [32m━━━━[0m[37m━━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9774 - loss: 0.0714

    [1m 492/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9774 - loss: 0.0714

    [1m 520/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9774 - loss: 0.0714

    [1m 549/1875[0m [32m━━━━━[0m[37m━━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9774 - loss: 0.0714

    [1m 577/1875[0m [32m━━━━━━[0m[37m━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9774 - loss: 0.0713

    [1m 606/1875[0m [32m━━━━━━[0m[37m━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0712

    [1m 635/1875[0m [32m━━━━━━[0m[37m━━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0712

    [1m 662/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0712

    [1m 690/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0712

    [1m 719/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0712

    [1m 748/1875[0m [32m━━━━━━━[0m[37m━━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0713

    [1m 770/1875[0m [32m━━━━━━━━[0m[37m━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0713

    [1m 795/1875[0m [32m━━━━━━━━[0m[37m━━━━━━━━━━━━[0m [1m2s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0713

    [1m 823/1875[0m [32m━━━━━━━━[0m[37m━━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0713

    [1m 850/1875[0m [32m━━━━━━━━━[0m[37m━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0714

    [1m 878/1875[0m [32m━━━━━━━━━[0m[37m━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0714

    [1m 906/1875[0m [32m━━━━━━━━━[0m[37m━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0714

    [1m 932/1875[0m [32m━━━━━━━━━[0m[37m━━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0714

    [1m 960/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0714

    [1m 989/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0714

    [1m1008/1875[0m [32m━━━━━━━━━━[0m[37m━━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0715

    [1m1034/1875[0m [32m━━━━━━━━━━━[0m[37m━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0715

    [1m1060/1875[0m [32m━━━━━━━━━━━[0m[37m━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0715

    [1m1088/1875[0m [32m━━━━━━━━━━━[0m[37m━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1115/1875[0m [32m━━━━━━━━━━━[0m[37m━━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1142/1875[0m [32m━━━━━━━━━━━━[0m[37m━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1168/1875[0m [32m━━━━━━━━━━━━[0m[37m━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1196/1875[0m [32m━━━━━━━━━━━━[0m[37m━━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1222/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1250/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1275/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1303/1875[0m [32m━━━━━━━━━━━━━[0m[37m━━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1331/1875[0m [32m━━━━━━━━━━━━━━[0m[37m━━━━━━[0m [1m1s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1359/1875[0m [32m━━━━━━━━━━━━━━[0m[37m━━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1387/1875[0m [32m━━━━━━━━━━━━━━[0m[37m━━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1416/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1443/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1471/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1498/1875[0m [32m━━━━━━━━━━━━━━━[0m[37m━━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1526/1875[0m [32m━━━━━━━━━━━━━━━━[0m[37m━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0715

    [1m1553/1875[0m [32m━━━━━━━━━━━━━━━━[0m[37m━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0715

    [1m1581/1875[0m [32m━━━━━━━━━━━━━━━━[0m[37m━━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0715

    [1m1608/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0715

    [1m1635/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0715

    [1m1662/1875[0m [32m━━━━━━━━━━━━━━━━━[0m[37m━━━[0m [1m0s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1691/1875[0m [32m━━━━━━━━━━━━━━━━━━[0m[37m━━[0m [1m0s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1718/1875[0m [32m━━━━━━━━━━━━━━━━━━[0m[37m━━[0m [1m0s[0m 2ms/step - accuracy: 0.9775 - loss: 0.0716

    [1m1746/1875[0m [32m━━━━━━━━━━━━━━━━━━[0m[37m━━[0m [1m0s[0m 2ms/step - accuracy: 0.9774 - loss: 0.0716

    [1m1774/1875[0m [32m━━━━━━━━━━━━━━━━━━[0m[37m━━[0m [1m0s[0m 2ms/step - accuracy: 0.9774 - loss: 0.0716

    [1m1802/1875[0m [32m━━━━━━━━━━━━━━━━━━━[0m[37m━[0m [1m0s[0m 2ms/step - accuracy: 0.9774 - loss: 0.0717

    [1m1830/1875[0m [32m━━━━━━━━━━━━━━━━━━━[0m[37m━[0m [1m0s[0m 2ms/step - accuracy: 0.9774 - loss: 0.0717

    [1m1858/1875[0m [32m━━━━━━━━━━━━━━━━━━━[0m[37m━[0m [1m0s[0m 2ms/step - accuracy: 0.9774 - loss: 0.0717

    [1m1875/1875[0m [32m━━━━━━━━━━━━━━━━━━━━[0m[37m[0m [1m4s[0m 2ms/step - accuracy: 0.9774 - loss: 0.0717





    <keras.src.callbacks.history.History at 0x71a9cc6435c0>



The `Model.evaluate` method checks the model's performance, usually on a [validation set](https://developers.google.com/machine-learning/glossary#validation-set) or [test set](https://developers.google.com/machine-learning/glossary#test-set).


```python
model.evaluate(x_test,  y_test, verbose=2)
```

    313/313 - 1s - 4ms/step - accuracy: 0.9774 - loss: 0.0723





    [0.07225997000932693, 0.977400004863739]



The image classifier is now trained to ~98% accuracy on this dataset. To learn more, read the [TensorFlow tutorials](https://www.tensorflow.org/tutorials/).

If you want your model to return a probability, you can wrap the trained model, and attach the softmax to it:


```python
probability_model = tf.keras.Sequential([
  model,
  tf.keras.layers.Softmax()
])
```


```python
probability_model(x_test[:5])
```




    <tf.Tensor: shape=(5, 10), dtype=float32, numpy=
    array([[5.77128496e-08, 5.93177396e-10, 3.21330390e-06, 4.99261478e-05,
            4.03187336e-12, 1.12208284e-07, 3.06617443e-13, 9.99942422e-01,
            1.08525782e-07, 4.19782646e-06],
           [1.28008949e-07, 9.61238984e-05, 9.99878407e-01, 2.50921621e-05,
            4.13008024e-16, 6.35557882e-08, 1.46080339e-08, 5.68010638e-14,
            1.60652522e-08, 6.17234535e-14],
           [9.24555877e-07, 9.99303102e-01, 2.47018004e-04, 1.23792252e-05,
            5.08015228e-06, 4.29081229e-06, 2.99778330e-05, 2.67712370e-04,
            1.28828760e-04, 6.90679656e-07],
           [9.99637961e-01, 1.09688676e-08, 3.29386821e-04, 3.32580299e-07,
            4.02763911e-09, 2.40158124e-06, 7.92188857e-08, 2.17121578e-05,
            6.20480822e-09, 8.12751387e-06],
           [1.34152418e-04, 2.64359237e-08, 3.19784112e-06, 9.03420755e-07,
            9.85753119e-01, 4.18467389e-05, 6.62735101e-06, 2.72629876e-03,
            6.13348448e-06, 1.13276979e-02]], dtype=float32)>



## Conclusion

Congratulations! You have trained a machine learning model using a prebuilt dataset using the [Keras](https://www.tensorflow.org/guide/keras/overview) API.

For more examples of using Keras, check out the [tutorials](https://www.tensorflow.org/tutorials/keras/). To learn more about building models with Keras, read the [guides](https://www.tensorflow.org/guide/keras). If you want learn more about loading and preparing data, see the tutorials on [image data loading](https://www.tensorflow.org/tutorials/load_data/images) or [CSV data loading](https://www.tensorflow.org/tutorials/load_data/csv).

