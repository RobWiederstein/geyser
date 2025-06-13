FROM rocker/shiny:4.2.2

# Install system dependencies required by common R packages (SSL, XML, CURL, Git)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
       libssl-dev \
       libxml2-dev \
       libcurl4-openssl-dev \
       libgit2-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy renv lockfile first to leverage Docker cache for dependencies
COPY geyser/renv.lock /srv/shiny-server/geyser/renv.lock
WORKDIR /srv/shiny-server/geyser

# Install renv and jsonlite, then restore R package dependencies
RUN R -e "install.packages(c('renv','jsonlite'), repos='https://cloud.r-project.org')" && \
    R -e "renv::restore(prompt = FALSE)"

# Copy the rest of the application code (app.R, .Rprofile, etc.)
COPY geyser/ /srv/shiny-server/geyser/

# Ensure the Shiny Server 'shiny' user owns the app directory
RUN chown -R shiny:shiny /srv/shiny-server/geyser

# Expose Shiny Server (default port)
EXPOSE 3838

# Switch to the non-root 'shiny' user for security
USER shiny

# Launch Shiny Server
CMD ["/usr/bin/shiny-server"]

