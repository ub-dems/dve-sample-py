#!/usr/bin/env python

##
# TensorFlow GPU test
# @see: https://www.tensorflow.org/guide/gpu

# from project root, run with:
# poetry run python exec/dummy-keras.py [options | --help]

import argparse
import os
import sys
from collections import namedtuple

# from tensorflow import keras
import keras as keras
import numpy as np
import tensorflow as tf
from keras import layers, utils
from keras.datasets import mnist

ARGS = None

TF_ENV = {
    # "CUDA_VISIBLE_DEVICES": "-1",
    # "TF_CPP_MIN_LOG_LEVEL": "1",
    # "TF_USE_CUDNN": "false",
}


def dump_env(args):
    if args.verbose > 1:
        for name, value in sorted(os.environ.items()):
            print("{0}: {1}".format(name, value))


def setenv_default(name, value):
    # if os.environ.get(name):
    #    return
    prev = os.environ.get(name, "<*undef*>")
    os.environ[name] = value
    print(f'{name}="{value}" # was: "{prev}"')


def setenv_all(args, envs):
    print("#setenv: {{{")
    print(f"#setenv: envs: {envs}")
    for name, value in envs.items():
        setenv_default(name, value)
    print("#setenv: }}}")


def load_environ(args):
    pass


def config_environ(args):
    print("### > {{{ //config")
    # if args.cudnn:
    #     TF_ENV["TF_USE_CUDNN"] = "true"

    if args.cpu:
        TF_ENV["CUDA_VISIBLE_DEVICES"] = "-1"

    if args.debug:
        TF_ENV["TF_CPP_MIN_LOG_LEVEL"] = "2"

    setenv_all(args, TF_ENV)
    print("### < }}} //config")


def show_environ(args):
    print("### > {{{ //status")
    dump_env(args)
    gpus = tf.config.list_physical_devices("GPU")
    print("Num GPUs Available: ", len(gpus))
    print("GPUs: ", gpus)
    print("### < }}} //status")


def debug_enable(args):
    if args.verbose > 0:
        tf.debugging.set_log_device_placement(True)


def setup_environ(args):
    config_environ(args)
    load_environ(args)
    show_environ(args)
    debug_enable(args)


def run_mult():
    print("### {{{ //tf.matmult")
    # Create some tensors
    a = tf.constant([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
    b = tf.constant([[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]])
    c = tf.matmul(a, b)
    print(c)
    print("### }}} //tf.matmult")


mist_conf = {
    "num_classes": 10,
    "input_shape": (28, 28, 1),
    "batch_size": 128,
    "epochs": 15,
}

MistData = namedtuple("MistData", ["x_train", "y_train", "x_test", "y_test"])


def load_mist():
    print("### > {{{ //mist.load:")

    num_classes = mist_conf["num_classes"]

    # Load the data and split it between train and test sets
    (x_train, y_train), (x_test, y_test) = mnist.load_data()

    # Scale images to the [0, 1] range
    x_train = x_train.astype("float32") / 255
    x_test = x_test.astype("float32") / 255
    # Make sure images have shape (28, 28, 1)
    x_train = np.expand_dims(x_train, -1)
    x_test = np.expand_dims(x_test, -1)
    print("x_train shape:", x_train.shape)
    print(x_train.shape[0], "train samples")
    print(x_test.shape[0], "test samples")

    # convert class vectors to binary class matrices
    y_train = utils.to_categorical(y_train, num_classes)
    y_test = utils.to_categorical(y_test, num_classes)

    data = MistData(x_train, y_train, x_test, y_test)

    print("### < }}} //mist.load")

    return data


def define_mist():
    print("### > {{{ //mist.define")
    # model
    num_classes = mist_conf["num_classes"]
    input_shape = mist_conf["input_shape"]

    model = keras.Sequential(
        [
            keras.Input(shape=input_shape),
            layers.Conv2D(32, kernel_size=(3, 3), activation="relu"),
            layers.MaxPooling2D(pool_size=(2, 2)),
            layers.Conv2D(64, kernel_size=(3, 3), activation="relu"),
            layers.MaxPooling2D(pool_size=(2, 2)),
            layers.Flatten(),
            layers.Dropout(0.5),
            layers.Dense(num_classes, activation="softmax"),
        ]
    )
    model.compile(
        loss="categorical_crossentropy", optimizer="adam", metrics=["accuracy"]
    )
    model.summary()
    print("### < }}} //mist.define")
    return model


def train_mist(model, data):
    print("### > {{{ //mist.train")
    batch_size = mist_conf["batch_size"]
    epochs = mist_conf["epochs"]
    x_train, y_train = data.x_train, data.y_train

    model.fit(
        x_train, y_train, batch_size=batch_size, epochs=epochs, validation_split=0.1
    )
    print("### < }}} //mist.train")
    return model


def eval_mist(model, data):
    print("### > {{{ //mist.eval")
    # evaluate
    x_test, y_test = data.x_test, data.y_test

    score = model.evaluate(x_test, y_test, verbose=0)
    print("Test loss:", score[0])
    print("Test accuracy:", score[1])
    print("### < }}} //mist.eval")
    return score


def save_mist(model, data, score):
    pass


def run_mist():
    print("### > {{{ //mist.RUN")
    data = load_mist()
    model = define_mist()
    model = train_mist(model, data)
    score = eval_mist(model, data)
    save_mist(model, data, score)
    print("### < }}} //mist.RUN")


def run():
    run_mult()
    run_mist()


def parse_args(argv=sys.argv[1:]):
    global ARGS
    parser = argparse.ArgumentParser(
        prog="dummy-keras.py",
        description="GPT test with tensorflow and keras",
        epilog="Runs mist ML sample from https://www.tensorflow.org/guide/gpu",
    )
    # parser.add_argument("--cudnn", action=argparse.BooleanOptionalAction)
    parser.add_argument("--verbose", "-v", action="count", default=0)
    parser.add_argument("--debug", "-d", action="store_true", default=False)
    parser.add_argument("--cpu", action="store_true", default=False)
    parser.add_argument(
        "-c",
        "--num_classes",
        type=int,
        default=mist_conf["num_classes"],
        dest="num_classes",
    )
    parser.add_argument(
        "-e", "--epochs", type=int, default=mist_conf["epochs"], dest="epochs"
    )
    parser.add_argument(
        "-b",
        "--batch_size",
        type=int,
        default=mist_conf["batch_size"],
        dest="batch_size",
    )

    args = parser.parse_args(argv)
    mist_conf["num_classes"] = args.num_classes
    mist_conf["epochs"] = args.epochs
    mist_conf["batch_size"] = args.batch_size
    ARGS = args
    return args


def main(argv=sys.argv[1:]):
    print(argv)
    args = parse_args(argv)
    setup_environ(args)
    run()
    return 0


if __name__ == "__main__":
    if "-n" not in sys.argv:
        sys.exit(main(sys.argv[1:]))
