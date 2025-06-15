# =========================================================================
# Multi-Stage Dockerfile for a Shiny App with renv
# =========================================================================

#--------------------------------------------------------------------------
# Stage 1: The "Builder"
#
# Purpose: Install all system and R package dependencies in a temporary
# environment. We use a base R image here because we don't need Shiny
# Server just to install packages.
#--------------------------------------------------------------------------
FROM rocker/r-ver:4.4.0 AS builder

# 1a. Install system-level dependencies required for R package compilation.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libssl-dev \
        libxml2-dev \
        libcurl4-openssl-dev \
        libgit2-dev \
        libsodium-dev \
        libfontconfig1-dev \
        libharfbuzz-dev \
        libfribidi-dev \
        libfreetype6-dev \
        libpng-dev \
        libtiff5-dev \
        libjpeg-dev && \
    rm -rf /var/lib/apt/lists/*

# 1b. Copy only the renv setup files and restore the R library.
WORKDIR /build
COPY renv.lock .Rprofile ./
COPY renv/ ./renv/
RUN R -e "install.packages('renv', repos = 'https://cloud.r-project.org/')"
RUN R -e "renv::restore()"


#--------------------------------------------------------------------------
# Stage 2: The "Final Image"
#
# Purpose: Create the lean, final image that will run in production.
# We start fresh from the official rocker/shiny image, which is
# optimized for running apps, not building them.
#--------------------------------------------------------------------------
FROM rocker/shiny:4.4.0

# 2a. Install only the essential RUNTIME system dependencies.
# Note: For many packages, the runtime library (e.g., libcurl4) is
# different and smaller than the development library (e.g., libcurl4-openssl-dev).
# For simplicity here, we install the same list, but this could be further optimized.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libssl-dev \
        libxml2-dev \
        libcurl4-openssl-dev \
        libgit2-dev \
        libsodium-dev \
        libfontconfig1-dev \
        libharfbuzz-dev \
        libfribidi-dev \
        libfreetype6-dev \
        libpng-dev \
        libtiff5-dev \
        libjpeg-dev && \
    rm -rf /var/lib/apt/lists/*

# 2b. THE MAGIC: Copy the fully installed R packages from the "builder" stage.
# We are copying the entire library from our temporary builder image into the
# final image. We don't need to run renv::restore() again!
COPY --from=builder /build/renv/library /usr/local/lib/R/site-library

# 2c. Set up the Shiny Server environment as before.
RUN rm -rf /srv/shiny-server/* && \
    mkdir -p /srv/shiny-server/geyser && \
    chown -R shiny:shiny /srv/shiny-server/geyser
WORKDIR /srv/shiny-server/geyser

# 2d. Copy ONLY the application code into the final image.
# We don't need to copy renv.lock, .Rprofile, etc., because the
# packages are already installed.
COPY --chown=shiny:shiny app.R ./

# 2e. Expose the port. The CMD is inherited from the base image.
EXPOSE 3838
