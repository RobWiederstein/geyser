# Dockerfile for Geyser Shiny App
#
# Diagnosis:
# The application failed during initialization due to missing jsonlite.
# This Dockerfile installs renv, restores dependencies, installs jsonlite,
# and copies the app code from geyser/.

FROM rocker/shiny:4.2.2

# Install system dependencies required by common R packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
       libssl-dev \
       libxml2-dev \
       libcurl4-openssl-dev \
       libgit2-dev && \
    rm -rf /var/lib/apt/lists/*

# Set working directory for the Shiny app
WORKDIR /srv/shiny-server/geyser

# Copy renv lockfile and project files
COPY geyser/renv.lock ./renv.lock

# Install renv and restore locked R package dependencies
RUN R -e "install.packages('renv', repos='https://cloud.r-project.org')" && \
    R -e "renv::restore(prompt = FALSE)"

# Ensure jsonlite is available for Shiny runtime
RUN R -e "install.packages('jsonlite', repos='https://cloud.r-project.org')"

# Copy the rest of the application code
COPY geyser/ ./

# Ensure Shiny Server user owns the app directory
RUN chown -R shiny:shiny /srv/shiny-server/geyser

# Expose Shiny Server port
EXPOSE 3838

# Switch to non-root user
USER shiny

# Launch Shiny Server
CMD ["/usr/bin/shiny-server"]

