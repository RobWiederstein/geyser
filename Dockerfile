# Use the rocker/shiny image as the base.
# It includes R and Shiny Server, providing a complete environment.
FROM rocker/shiny:4.4.0

# 1. Install system-level dependencies required by your R packages.
#    This includes libraries for common R packages (e.g., xml, curl, png, jpeg).
#    '--no-install-recommends' keeps the image smaller.
#    'rm -rf /var/lib/apt/lists/*' cleans up apt cache to further reduce image size.
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

# 2. Install the renv R package globally.
#    This is needed to restore the project-specific R library.
RUN R -e "install.packages('renv', repos = 'https://cloud.r-project.org/')"

# 3. Clean up default Shiny Server example applications.
#    This ensures your app is the only one served at its intended path.
RUN rm -rf /srv/shiny-server/*

# 4. Create the main serving directory for the app and set its permissions.
#    Shiny Server looks for apps in /srv/shiny-server/ subdirectories.
#    Ensure the 'geyser' folder is owned by 'shiny' user for proper access.
RUN mkdir -p /srv/shiny-server/geyser && \
    chown -R shiny:shiny /srv/shiny-server/geyser

# 5. Set the working directory to the app's final location within the container.
#    Subsequent COPY commands will use this as their destination.
WORKDIR /srv/shiny-server/geyser

# 6. Copy core application files and renv setup from the local build context.
#    '.Rprofile', 'renv.lock', and 'app.R' are copied directly into WORKDIR.
#    The 'renv/' directory (including 'activate.R') is copied into ./renv/.
#    --chown ensures files are owned by the 'shiny' user for permissions.
COPY --chown=shiny:shiny .Rprofile renv.lock app.R ./
COPY --chown=shiny:shiny renv/ ./renv/

# 7. Restore the renv project library.
#    This installs all R package dependencies specified in renv.lock
#    into the project's isolated library, run as the 'shiny' user.
RUN sudo -u shiny Rscript -e "renv::restore(prompt = FALSE)"

# 8. Expose the default Shiny Server port.
#    This informs Docker that the container listens on port 3838.
EXPOSE 3838

# The base rocker/shiny image already includes the correct CMD
# to launch the Shiny Server. No need to specify it again.