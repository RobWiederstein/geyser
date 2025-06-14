# Use the rocker/shiny image directly as our one and only stage
FROM rocker/shiny:4.3.3

# Install system dependencies that your R packages might need
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
       libssl-dev \
       libxml2-dev \
       libcurl4-openssl-dev \
       libgit2-dev && \
    rm -rf /var/lib/apt/lists/*

# Install renv itself
RUN R -e "install.packages('renv', repos = 'https://cloud.r-project.org/')"

# Create and set the final working directory for the app
WORKDIR /srv/shiny-server/geyser

# Copy the renv lockfile. Caching this layer speeds up future builds.
COPY geyser/renv.lock .

# Restore the R packages from the lockfile. This creates the private renv library.
RUN R -e "options(renv.consent = TRUE); renv::restore()"

# --- THE NEW DEFINITIVE FIX ---
# Modify the site-wide R environment file to force all R sessions to use
# our renv library. This is more robust than an ENV var that might get dropped.
RUN echo "R_LIBS_USER=/srv/shiny-server/geyser/renv/library/R-4.3/x86_64-pc-linux-gnu" >> "$(R RHOME)/etc/Renviron.site"

# Now copy the rest of your application files into the WORKDIR
COPY geyser/ .

# Fix permissions for the shiny user on the app directory.
RUN chown -R shiny:shiny /srv/shiny-server/geyser

# Expose the default Shiny Server port
EXPOSE 3838

# The base rocker/shiny image already includes the correct CMD
# to launch the server, so you don't need to specify it again.
