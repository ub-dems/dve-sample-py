# ---
# jupyter:
#   jupytext:
#     formats: ipynb,py:percent
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.19.5
#   kernelspec:
#     display_name: Python 3 (ipykernel)
#     language: python
#     name: python3
# ---

# %% [markdown] id="rX8mhOLljYeM"
# ##### Copyright 2019 The TensorFlow Authors.

# %% cellView="form" id="BZSlp3DAjdYf"
# @title Licensed under the Apache License, Version 2.0 (the "License");
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

# %% [markdown] id="3wF5wszaj97Y"
# # TensorFlow 2 quickstart for beginners

# %% [markdown] id="DUNzJc4jTj6G"
# <table class="tfo-notebook-buttons" align="left">
#   <td>
#     <a target="_blank" href="https://www.tensorflow.org/tutorials/quickstart/beginner"><img src="https://www.tensorflow.org/images/tf_logo_32px.png" />View on TensorFlow.org</a>
#   </td>
#   <td>
#     <a target="_blank" href="https://colab.research.google.com/github/tensorflow/docs/blob/master/site/en/tutorials/quickstart/beginner.ipynb"><img src="https://www.tensorflow.org/images/colab_logo_32px.png" />Run in Google Colab</a>
#   </td>
#   <td>
#     <a target="_blank" href="https://github.com/tensorflow/docs/blob/master/site/en/tutorials/quickstart/beginner.ipynb"><img src="https://www.tensorflow.org/images/GitHub-Mark-32px.png" />View source on GitHub</a>
#   </td>
#   <td>
#     <a href="https://storage.googleapis.com/tensorflow_docs/docs/site/en/tutorials/quickstart/beginner.ipynb"><img src="https://www.tensorflow.org/images/download_logo_32px.png" />Download notebook</a>
#   </td>
# </table>

# %% [markdown] id="04QgGZc9bF5D"
# This short introduction uses [Keras](https://www.tensorflow.org/guide/keras/overview) to:
#
# 1. Load a prebuilt dataset.
# 1. Build a neural network machine learning model that classifies images.
# 2. Train this neural network.
# 3. Evaluate the accuracy of the model.

# %% [markdown] id="hiH7AC-NTniF"
# This tutorial is a [Google Colaboratory](https://colab.research.google.com/notebooks/welcome.ipynb) notebook. Python programs are run directly in the browser—a great way to learn and use TensorFlow. To follow this tutorial, run the notebook in Google Colab by clicking the button at the top of this page.
#
# 1. In Colab, connect to a Python runtime: At the top-right of the menu bar, select *CONNECT*.
# 2. To run all the code in the notebook, select **Runtime** > **Run all**. To run the code cells one at a time, hover over each cell and select the **Run cell** icon.
#
# ![Run cell icon](images/beginner/run_cell_icon.png)

# %% [markdown] id="nnrWf3PCEzXL"
# ## Set up TensorFlow
#
# Import TensorFlow into your program to get started:

# %% [markdown]
# @see: https://macjim.medium.com/loading-alternative-cudnn-library-versions-in-tensorflow-90c7472e361a

# %%
import os

os.environ["TF_CPP_MIN_LOG_LEVEL"] = "0"  # DEBUG, INFO, WARNING, ERROR: 0 ~ 3

# %%
# !nvidia-smi -L

# %% id="0trJmd6DjqBZ"
import tensorflow as tf

print("TensorFlow version:", tf.__version__)
print(tf.config.list_physical_devices("GPU"))

# %%
print(tf.reduce_sum(tf.random.normal([1000, 1000])))

# %%
try:
    with tf.device("/GPU:0"):  # Specify GPU device
        a = tf.constant([1.0, 2.0, 3.0, 4.0])
        b = tf.constant([2.0, 2.0, 2.0, 2.0])
        c = a + b
        print("Result of GPU operation:", c.numpy())
except RuntimeError as e:
    print("Error using GPU:", e)

# %% [markdown] id="7NAbSZiaoJ4z"
# If you are following along in your own development environment, rather than [Colab](https://colab.research.google.com/github/tensorflow/docs/blob/master/site/en/tutorials/quickstart/beginner.ipynb), see the [install guide](https://www.tensorflow.org/install) for setting up TensorFlow for development.
#
# Note: Make sure you have upgraded to the latest `pip` to install the TensorFlow 2 package if you are using your own development environment. See the [install guide](https://www.tensorflow.org/install) for details.
#
# ## Load a dataset
#
# Load and prepare the MNIST dataset. The pixel values of the images range from 0 through 255. Scale these values to a range of 0 to 1 by dividing the values by `255.0`. This also converts the sample data from integers to floating-point numbers:

# %% id="7FP5258xjs-v"
mnist = tf.keras.datasets.mnist

(x_train, y_train), (x_test, y_test) = mnist.load_data()
x_train, x_test = x_train / 255.0, x_test / 255.0

# %% [markdown] id="BPZ68wASog_I"
# ## Build a machine learning model
#
# Build a `tf.keras.Sequential` model:

# %% id="h3IKyzTCDNGo"
model = tf.keras.models.Sequential(
    [
        tf.keras.layers.Flatten(input_shape=(28, 28)),
        tf.keras.layers.Dense(128, activation="relu"),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(10),
    ]
)

# %% [markdown] id="l2hiez2eIUz8"
# [`Sequential`](https://www.tensorflow.org/guide/keras/sequential_model) is useful for stacking layers where each layer has one input [tensor](https://www.tensorflow.org/guide/tensor) and one output tensor. Layers are functions with a known mathematical structure that can be reused and have trainable variables. Most TensorFlow models are composed of layers. This model uses the [`Flatten`](https://www.tensorflow.org/api_docs/python/tf/keras/layers/Flatten), [`Dense`](https://www.tensorflow.org/api_docs/python/tf/keras/layers/Dense), and [`Dropout`](https://www.tensorflow.org/api_docs/python/tf/keras/layers/Dropout) layers.
#
# For each example, the model returns a vector of [logits](https://developers.google.com/machine-learning/glossary#logits) or [log-odds](https://developers.google.com/machine-learning/glossary#log-odds) scores, one for each class.

# %% id="OeOrNdnkEEcR"
predictions = model(x_train[:1]).numpy()
predictions

# %% [markdown] id="tgjhDQGcIniO"
# The `tf.nn.softmax` function converts these logits to *probabilities* for each class:

# %% id="zWSRnQ0WI5eq"
tf.nn.softmax(predictions).numpy()

# %% [markdown] id="he5u_okAYS4a"
# Note: It is possible to bake the `tf.nn.softmax` function into the activation function for the last layer of the network. While this can make the model output more directly interpretable, this approach is discouraged as it's impossible to provide an exact and numerically stable loss calculation for all models when using a softmax output.

# %% [markdown] id="hQyugpgRIyrA"
# Define a loss function for training using `losses.SparseCategoricalCrossentropy`:

# %% id="RSkzdv8MD0tT"
loss_fn = tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True)

# %% [markdown] id="SfR4MsSDU880"
# The loss function takes a vector of ground truth values and a vector of logits and returns a scalar loss for each example. This loss is equal to the negative log probability of the true class: The loss is zero if the model is sure of the correct class.
#
# This untrained model gives probabilities close to random (1/10 for each class), so the initial loss should be close to `-tf.math.log(1/10) ~= 2.3`.

# %% id="NJWqEVrrJ7ZB"
loss_fn(y_train[:1], predictions).numpy()

# %% [markdown] id="ada44eb947d4"
# Before you start training, configure and compile the model using Keras `Model.compile`. Set the [`optimizer`](https://www.tensorflow.org/api_docs/python/tf/keras/optimizers) class to `adam`, set the `loss` to the `loss_fn` function you defined earlier, and specify a metric to be evaluated for the model by setting the `metrics` parameter to `accuracy`.

# %% id="9foNKHzTD2Vo"
model.compile(optimizer="adam", loss=loss_fn, metrics=["accuracy"])

# %% [markdown] id="ix4mEL65on-w"
# ## Train and evaluate your model
#
# Use the `Model.fit` method to adjust your model parameters and minimize the loss:

# %% id="y7suUbJXVLqP"
model.fit(x_train, y_train, epochs=5)

# %% [markdown] id="4mDAAPFqVVgn"
# The `Model.evaluate` method checks the model's performance, usually on a [validation set](https://developers.google.com/machine-learning/glossary#validation-set) or [test set](https://developers.google.com/machine-learning/glossary#test-set).

# %% id="F7dTAzgHDUh7"
model.evaluate(x_test, y_test, verbose=2)

# %% [markdown] id="T4JfEh7kvx6m"
# The image classifier is now trained to ~98% accuracy on this dataset. To learn more, read the [TensorFlow tutorials](https://www.tensorflow.org/tutorials/).

# %% [markdown] id="Aj8NrlzlJqDG"
# If you want your model to return a probability, you can wrap the trained model, and attach the softmax to it:

# %% id="rYb6DrEH0GMv"
probability_model = tf.keras.Sequential([model, tf.keras.layers.Softmax()])

# %% id="cnqOZtUp1YR_"
probability_model(x_test[:5])

# %% [markdown] id="-47O6_GLdRuT"
# ## Conclusion
#
# Congratulations! You have trained a machine learning model using a prebuilt dataset using the [Keras](https://www.tensorflow.org/guide/keras/overview) API.
#
# For more examples of using Keras, check out the [tutorials](https://www.tensorflow.org/tutorials/keras/). To learn more about building models with Keras, read the [guides](https://www.tensorflow.org/guide/keras). If you want learn more about loading and preparing data, see the tutorials on [image data loading](https://www.tensorflow.org/tutorials/load_data/images) or [CSV data loading](https://www.tensorflow.org/tutorials/load_data/csv).
#
