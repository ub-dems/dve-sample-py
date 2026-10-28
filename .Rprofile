# ==============================================================================
# Consolidated Project .Rprofile
# ==============================================================================

local({

  # 1. Configure Posit Public Package Manager (P3M / RSPM)
  # ----------------------------------------------------------------------------
  # Sets the default repository to Posit's CDN for pre-compiled binaries on 
  # Linux, macOS, and Windows.
  options(
    repos = c(CRAN = "https://packagemanager.posit.co/cran/latest")
  )

  # 2. Configure renv Behavior
  # ----------------------------------------------------------------------------
  options(
    # Enable automatic transformation of P3M URLs to Linux binary paths
    renv.config.ppm.enabled = TRUE,

    # Fallback default to explicit snapshotting (DESCRIPTION-based)
    renv.config.snapshot.type = "explicit",

    # Prevent interactive prompts during automated scripts / CI runs
    renv.config.consent = TRUE
  )

  # 3. Bootstrap / Activate renv Project Environment
  # ----------------------------------------------------------------------------
  activate_script <- file.path("renv", "activate.R")
  
  if (file.exists(activate_script)) {
    source(activate_script)
  } else if (interactive()) {
    message("* 'renv/activate.R' not found. Run `renv::init()` to initialize this project.")
  }

})
