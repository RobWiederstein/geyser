# ==> Stage 1: Install packages into a temporary renv library <==
FROM rocker/r-ver:4.3.3 AS builder

# Install system dependencies required by your R packages
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

# Install renv itself
RUN R -e "install.packages('renv', repos = 'https://cloud.r-project.org/')"

# Set the working directory
WORKDIR /build

# Copy the lockfile and restore packages into the private renv library
COPY geyser/renv.lock .
RUN R -e "options(renv.consent = TRUE); renv::restore()"


# ==> Stage 2: Create the final image <==
FROM rocker/shiny:4.3.3

# --- THE BRUTE FORCE FIX ---
# Copy the packages restored by renv in Stage 1 directly into the
# main, system-wide R library where shiny-server is guaranteed to find them.
COPY --from=builder /build/renv/library/R-4.3/x86_64-pc-linux-gnu/* /usr/local/lib/R/site-library/

# Copy the application files into the server directory
COPY geyser /srv/shiny-server/geyser

# No 'chown' or special config needed, as packages are now global.

# Expose the default Shiny Server port
EXPOSE 3838

# The base rocker/shiny image already includes the correct CMD
# to launch the server, so you don't need to specify it again.
