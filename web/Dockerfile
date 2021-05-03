# ARG statements are scattered throughout the Dockerfile because
# of this issue: https://github.com/moby/moby/issues/34129
# All of these arguments must be specified at build time.
# elm_config: relative path to Elm build-time configuration options
# nginx_config: relative path to our NGINX config file
# htpasswd: relative path to our password file that NGINX uses for auth
################################################################################
# Stage 1: Build the frontend code                                             #
################################################################################

FROM archlinux:base as builder

# Install prerequisites
# (Ruby and Git are needed for elm-github-install)
# (OpenSSL is needed to install Elm)
RUN pacman -Sy --noconfirm yarn ruby git openssl glibc
RUN yarn global add elm@0.18.0 elm-github-install

# Create a directory for our Elm source code,
# Move into that directory, and copy our source into it.
WORKDIR /elm-src
COPY ./audience ./audience
COPY ./performer ./performer
# Copy additional Elm config.
# elm_config is the full path to the config file you want to use.
ARG elm_config="set-me-at-build-time"
COPY ${elm_config} ./audience/src/Config.elm
COPY ${elm_config} ./performer/src/Config.elm

# Build that code!
RUN cd performer && \
    elm-make --yes ./src/Performer.elm --output build/Performer.js
RUN cd audience && \
    elm-install && \
    elm-make --yes ./src/Audience.elm --output build/index.html

################################################################################
# Stage 2: Serve the frontend code                                             #
################################################################################

FROM nginx:alpine

ARG nginx_config="set-me-at-build-time"
ARG htpasswd="set-me-at-build-time"

COPY ${nginx_config} /etc/nginx/nginx.conf

# Move our build artifacts and includes into our webroot (/plexus)
COPY --from=builder /elm-src/performer/build /plexus/performer
COPY --from=builder /elm-src/performer/include /plexus/performer
COPY --from=builder /elm-src/audience/build /plexus/audience
COPY ${htpasswd} /secret/htpasswd

EXPOSE 443
