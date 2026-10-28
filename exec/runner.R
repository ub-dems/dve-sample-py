#!/usr/bin/env Rscript
##{{{
# runner.R: R main script
# ====================================
#
#  R main script invoked by runner.sh via Rscript
#
#  "./exec/runner.sh help" for arguments and available environment
#
#}}} \\\    

rm(list=ls())
devtools::load_all(".") 

require(dvesimpler)


library(yaml)
library(magrittr, warn.conflicts = FALSE)

#{{{ [ LOGS ] /////////////////////////////////////////////////////////////////

library(logging)

runner_logs <- function(job_desc){ log_init("runner.log", args=job_desc$job_conf$args) }



#{{{ [ CONF ] /////////////////////////////////////////////////////////////////

# ---(scripts)------------------------------------------------

E_PROJECT_SCRIPTS <- c(
  "dummy/target/pipeline-runner.R",
  "dummy/dummy-runner.R",
  "dummy/dummy-reader.R"
)

E_DEFAULT_SCRIPT <- E_PROJECT_SCRIPTS[2]

#{{{ [ JOB ] /////////////////////////////////////////////////////////////////


# ---(globals)---------------------------------------------

E_RUNNER_JOB <- NULL


# ---(desc)------------------------------------------------

runner_conf <- function(script = E_DEFAULT_SCRIPT,args = commandArgs(trailingOnly=TRUE)) {
  result <- list(
    script = script,
    args = args,
    source = exe_path(script)
  )
  class(result) <- "runner_conf"
  return (result)
}

print.runner_conf <- function(x) {
  cat("# runner_conf:","\n")
  s <- as.yaml(x)
  cat(x, "\n")

}

runner_job <- function(job_conf, store_fun = function(x) { E_RUNNER_JOB <<- x; return (x)}) {
  result <- list(
      
      job_conf = job_conf,
      store_fun = store_fun,
      
      info = paste0("job:", job_conf$script, "(", job_conf$args, ")"),
      
      #source_rev <- try(system("git rev-parse HEAD", intern = TRUE)) 
      
      started = FALSE,
      completed = FALSE,
      failed = NA,
      
      start = function(.self, job_conf) {
        start_time <- Sys.time()
        return (.self$set(.self,list(
          job_conf = job_conf,
          start_time = start_time,
          started = TRUE
        )))
      },
      
      complete = function(.self, job_time) {
        end_time <- Sys.time()
        elapsed <- end_time - .self$start_time
        return (.self$set(.self,list(
          job_time = job_time,
          end_time = end_time,
          elapsed = elapsed,
          failed = FALSE,
          completed = TRUE,
          rc = 0
        )))
      },
      
      fail = function(.self, ex) {
        end_time <- Sys.time()
        elapsed <- end_time - .self$start_time
        return (.self$set(.self,list(
          ex = ex,
          end_time = end_time,
          elapsed = elapsed,
          failed = TRUE,
          rc = 0
        )))
      },
      
      restore_logs = function(.self) {
        log_init("runner.log", args=job_desc$job_conf$args)
        return (.self)
      },
      
      set = function(.self, val) {
        return (store_fun(modifyList(.self, val)))
      },
      
      init_time = Sys.time()
      
  )
  class(result) <- "runner_job"
  store_fun(result)
  return (result)
}

print.runner_job <- function(x) {
  cat("# runner_job:","\n")
  s <- as.yaml(x)
  cat(x, "\n")
  
}


init_job <- function() {
  job_conf <- runner_conf()
  job_desc <- runner_job(job_conf)
  return (job_desc)
}

#}}} \\\

#{{{ [ MAIN ] /////////////////////////////////////////////////////////////////

# ---(call)------------------------------------------------

runner_call <- function(job_desc) {

  job_time <- NA

  result = tryCatch({
    
    job_conf <- job_desc$job_conf
    
    job_desc %<>% job_desc$start(job_conf)
    
    #job_desc <- job_desc$start(job_desc, job_conf)
    
    script <- job_conf$script
    args <- job_conf$args
    source <- job_conf$source
    
#   job_time <<- time(system("date"))
    job_time <<- time(source(source))
    
    job_desc %<>% job_desc$complete(job_time)
    
    (job_desc)

  }, warning = function(we) {
    logwarn("#? RUN: ({we}) -- %s", job_desc$info)
  }, error = function(ex) {
    print(ex)
    logerror("#! RUN: ({ex}) -- %s", job_desc$info)
    job_desc %<>% job_desc$fail(ex)
    return (job_desc)
  }, finally = {
    # job_desc %<>% job_desc$complete(job_time)
    job_desc %<>% job_desc$restore_logs()
    logdebug("#. RUN: (ended) -- %s", job_desc$info)
  })
  return (result)
  
}

# ---(exit)------------------------------------------------

runner_exit <- function(job_desc) {
  
  if (job_desc$failed) {
    
    logerror("#> RUN: FAIL -- %s", job_desc$ex)
    
    stop(job_desc$ex)
  }
  
  return (job_desc$rc)
}

# ---(main)------------------------------------------------

runner_main <- function() {

  job_desc <- init_job()
  
  runner_logs(job_desc)
  
  loginfo("#> RUN: enter -- %s", job_desc$info)
  
  job_desc <- runner_call(job_desc)

  loginfo("#< RUN: exit (rc:%d, time:%.3f sec.) -- %s", job_desc$rc, job_desc$elapsed, job_desc$info)
  
  if (!interactive()) {
    print(sprintf("### RC=%d",job_desc$rc))
    
    #quit(status=job_desc$rc)
  }

  return (runner_exit(job_desc))
}

runner_main()


#}}} \\\
