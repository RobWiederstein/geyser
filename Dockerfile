### Start from the official rocker/shiny image
FROM rocker/shiny:4.2.2

# Install system dependencies if needed (uncomment lines below)
# RUN apt-get update && \
#     apt-get install -y --no-install-recommends libssl-dev libxml2-dev && \
#     rm -rf /var/lib/apt/lists/*

# Copy the app directory (expecting local ./geyser/ contains app.R)
COPY geyser/ /srv/shiny-server/geyser/
WORKDIR /srv/shiny-server/geyser

# Restore R package dependencies with renv
# (assumes you ran renv::snapshot() locally and shipped renv.lock)
RUN R -e "install.packages('renv', repos='https://cloud.r-project.org')" && \
    R -e "renv::restore()"

# Ensure Shiny Server user owns the app
RUN chown -R shiny:shiny /srv/shiny-server/geyser

# Expose default Shiny port
EXPOSE 3838

# Launch Shiny Server
CMD ["/usr/bin/shiny-server"]

