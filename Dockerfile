# ==> Stage 1: Build the R environment and restore packages <==
# Use a specific version of the rocker/r-ver image for reproducibility
FROM rocker/r-ver:4.3.3 AS builder

# Install system dependencies required by common R packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
       libssl-dev \
       libxml2-dev \
       libcurl4-openssl-dev \
       libgit2-dev && \
    rm -rf /var/lib/apt/lists/*

# Install the renv package itself
RUN R -e "install.packages('renv', repos = 'https://cloud.r-project.org/')"

# Set up the application directory
WORKDIR /app

# Copy the renv lockfile. This step is cached by Docker.
# The build will only re-run from here if renv.lock changes.
COPY geyser/renv.lock .

# Restore the R packages from the lockfile.
# The `renv.consent = TRUE` option prevents interactive prompts during the build.
RUN R -e "options(renv.consent = TRUE); renv::restore()"


# ==> Stage 2: Create the final Shiny Server image <==
# Use the rocker/shiny image, which has Shiny Server pre-installed
FROM rocker/shiny:4.3.3

# Copy the restored R package library from the builder stage
COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# Copy the application source code into the directory Shiny Server uses
COPY geyser /srv/shiny-server/geyser

# --- THIS IS THE FIX ---
# Change the ownership of the app directory to the shiny user
# This gives the server permission to write to the renv library
RUN chown -R shiny:shiny /srv/shiny-server/geyser

# Expose the default Shiny Server port
EXPOSE 3838

# The base rocker/shiny image already includes the correct CMD
# to launch the server, so you don't need to specify it again.
