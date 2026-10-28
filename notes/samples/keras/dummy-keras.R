#!/usr/bin/env Rscript

##
# TensorFlow GPU test
# @see: https://www.tensorflow.org/guide/gpu

# from project root, run with:
#
# poetry run Rscript exec/dummy-keras.R [--args (options | --help)]
#

install_venv <- function() {
  INSTALL_POETRY_ENV <- FALSE
  if (INSTALL_POETRY_ENV) {
    system("poetry env info")
    system("poetry env use $(which python)")
    system("poetry install")
    reticulate::py_discover_config()
  }
}
install_auto <- function() {
  INSTALL_KERAS <- FALSE
  if (INSTALL_KERAS) {
    keras::install_keras()
  }
}
install_deps <- function() {
  install_venv()
  install_auto()
}


library(reticulate)

library(argparse)

def_args <- function() {
  args <- list(
    verbose= FALSE,
    debug= FALSE,
    cpu= FALSE,
    num_classes= 10,
    batch_size= 128,
    epochs=15
  )
  return (args)
}

dump_env <- function(args = def_args()) {
  if (args$verbose > 1) {
    print("### > {{{ //environ")
    environ <- Sys.getenv()
    print(environ)
    print("### < }}} //environ")
  }
}

setenv_default <- function(name, value, args = def_args()) {
    prev = Sys.getenv(name, "<*undef*>")
    do.call(Sys.setenv, as.list(setNames(value, name)))
    cat(sprintf("%s=%s // was: %s", name, value, prev))
}

setenv_all <- function(env, args = def_args()) {
  for (name in ls(env)) {
    value <- env[[name]]
    setenv_default(name, value, args)
  }
}

load_environ <- function(args = def_args()) {
  print("### > {{{ //library")

  library(tensorflow)
  library(keras)
  
  py_tf <<- import("tensorflow", as="tf")
  
  print("### < }}} //library")
}

config_environ <- function(args = def_args()) {
  print("### > {{{ //config")

  TF_ENV <- new.env()

  if (args$cpu) {
    TF_ENV$CUDA_VISIBLE_DEVICES <- "-1"
  }

  if (args$debug) {
        TF_ENV$TF_CPP_MIN_LOG_LEVEL <- "2"
  }

  setenv_all(TF_ENV, args)

  print("### < }}} //config")
}

show_environ <- function(args = def_args()) {
  print("### > {{{ //status")
  reticulate::py_config()
  
  gpus <- py_tf$config$list_physical_devices('GPU')
  print("GPUs: ")
  print(gpus)
  print("### < }}} //status")
}

debug_enable <- function(args = def_args()) {
  if (args$verbose > 0) {
        py_tf$debugging$set_log_device_placement(TRUE)
  }
  
}

setup_environ <- function(args = def_args()) {
    config_environ(args)
    load_environ(args)
    show_environ(args)
    debug_enable(args)
}

run_mult <- function(args = def_args()) {
    print("### {{{ //tf.matmult")
    a = py_tf$constant(array(c(1.0, 2.0, 3.0, 4.0, 5.0, 6.0), dim=c(3,2)))
    b = py_tf$constant(array(c(1.0, 2.0, 3.0, 4.0, 5.0, 6.0), dim=c(2,3)))
    c = py_tf$matmul(a, b)
    print(c)
    print("### }}} //tf.matmult")
}


# from: https://cran.r-project.org/web/packages/keras/vignettes/index.html

load_mist <- function(args = def_args()) {
  print("### > {{{ //mist.load")

  num_classes = args$num_classes

  mnist <- dataset_mnist()
  x_train <- mnist$train$x
  y_train <- mnist$train$y
  x_test <- mnist$test$x
  y_test <- mnist$test$y


  # reshape
  x_train <- array_reshape(x_train, c(nrow(x_train), 784))
  x_test <- array_reshape(x_test, c(nrow(x_test), 784))
  # rescale
  x_train <- x_train / 255
  x_test <- x_test / 255

  y_train <- to_categorical(y_train, num_classes)
  y_test <- to_categorical(y_test, num_classes)

  data <- new.env()
  data$x_train <- x_train
  data$y_train <- y_train
  data$x_test <- x_test
  data$y_test <- y_test

  print("### < }}} //mist.load")
  
  return (data)
  
}


define_mist <- function(args = def_args()) {
  print("### > {{{ //mist.define")

  num_classes = args$num_classes
  
  model <- keras_model_sequential() 
  model %>% 
    layer_dense(units = 256, activation = 'relu', input_shape = c(784)) %>% 
    layer_dropout(rate = 0.4) %>% 
    layer_dense(units = 128, activation = 'relu') %>%
    layer_dropout(rate = 0.3) %>%
    layer_dense(units = num_classes, activation = 'softmax')

  summary(model)

  model %>% compile(
    loss = 'categorical_crossentropy',
    optimizer = optimizer_rmsprop(),
    metrics = c('accuracy')
  )
  
  print("### < }}} //mist.define")
  return (model)
    

  
}


train_mist <- function(model, data, args = def_args()) {
  print("### > {{{ //mist.train")
  
  batch_size = args$batch_size
  epochs = args$epochs
  
  x_train <- data$x_train
  y_train <- data$y_train
  
  history <- model %>% fit(
    x_train, y_train, 
    epochs = epochs, batch_size = batch_size, 
    validation_split = 0.2
  )

  print("### < }}} //mist.train")
  return (model)

  
}



eval_mist <- function(model, data, args = def_args()) {
  print("### > {{{ //mist.eval")

  x_test <- data$x_test
  y_test <- data$y_test
  
  score <- model %>% evaluate(x_test, y_test)

  summary(score)

  # model %>% predict_classes(x_test)

  model %>% predict(x_test) %>% k_argmax()
  model %>% predict(x_test) %>% `>`(0.5) %>% k_cast("int32")

  print("### < }}} //mist.eval")

  return (score)
  
}


save_mist <- function(model, data, score, args = def_args()) {
  #
}


run_mist <- function(args = def_args()) {
  print("### > {{{ //mist.RUN")
  data <- load_mist(args)
  model <- define_mist(args)
  model <- train_mist(model, data, args)
  score <- eval_mist(model, data, args)
  save_mist(model, data, score, args)
  print("### < }}} //mist.RUN")
}


run <- function(args = def_args()) {
  run_mult(args)
  run_mist(args)
}

parse_args <- function(argv = c()) {
  defaults <- def_args()

  parser = argparse::ArgumentParser(
    description="GPT test with tensorflow and keras from https://www.tensorflow.org/guide/gpu"
  )
  parser$add_argument("--verbose", "-v", action="count", default=defaults$verbose, help="verbose level")
  parser$add_argument("--debug", action="store_true", default=defaults$debug, help="debug mode")
  parser$add_argument("--cpu", action="store_true", default=defaults$cpu, help="ignore GPU, CPU only")
  
  parser$add_argument(
    "-c",
    "--num_classes",
    type="integer",
    default=defaults$num_classes,
    dest="num_classes",
    help="MIST number of target classes"
  )
  parser$add_argument(
    "-e",
    "--epochs",
    type="integer",
    default=defaults$epochs,
    dest="epochs",
    help="MIST epochs"
  )
  parser$add_argument(
    "-b",
    "--batch_size",
    type="integer",
    default=defaults$batch_size,
    dest="batch_size",
    help="MIST batch size"
  )

  args <- parser$parse_args(argv)
  
  return (args)
}


main <- function(argv = c()) {
  args <- parse_args(argv)
  setup_environ(args)
  run(args)
  
  return (0)
}


# main( c("-vv"))
# main( c("-v"))
# main( c("--cpu", "-v"))
# main( c("--cpu"))
#main()

main(argv = commandArgs(trailingOnly=TRUE))
