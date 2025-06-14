# Use the rocker/shiny image directly as our one and only stage
FROM rocker/shiny:4.3.3

# 1. Install system dependencies required by your R packages.
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

# 2. Install renv itself
RUN R -e "install.packages('renv', repos = 'https://cloud.r-project.org/')"

# 3. Create and set the final working directory for the app
WORKDIR /srv/shiny-server/geyser

# 4. Copy renv files first to leverage Docker caching.
COPY geyser/renv.lock .
COPY geyser/.Rprofile .
COPY geyser/renv/activate.R renv/activate.R

# 5. Restore the renv project library.
RUN R -e "options(renv.consent = TRUE); renv::restore()"

# 6. Now copy the rest of your application files
COPY geyser/ .

# 7. Copy our custom shiny-server.conf into the image, overwriting the default.
# This is the new, robust way to configure the server.
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf

# 8. Set correct ownership for the shiny user.
# The :HOME_USER: directive in our config will now resolve to 'shiny'.
RUN chown -R shiny:shiny /srv/shiny-server/geyser

# 9. Expose the default Shiny Server port
EXPOSE 3838

# The base rocker/shiny image already includes the correct CMD
# to launch the server, so you don't need to specify it again.
