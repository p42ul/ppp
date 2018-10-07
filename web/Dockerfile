# ARG statements are scattered throughout the Dockerfile because
# of this issue: https://github.com/moby/moby/issues/34129
################################################################################
# Stage 1: Build the frontend code                                             #
################################################################################

FROM archlinux/base as builder

# Install prerequisites
# (Ruby and Git are needed for elm-github-install)
# (OpenSSL is needed to install Elm)
RUN pacman -Sy --noconfirm yarn ruby git openssl
RUN yarn global add elm@0.18.0 elm-github-install

# Create a directory for our Elm source code,
# Move into that directory, and copy our source into it.
WORKDIR /elm-src
COPY ./audience ./audience
COPY ./performer ./performer
# Copy additional Elm config
ARG elm_config="./conf/Config.elm"
COPY ${elm_config} ./audience/src
COPY ${elm_config} ./performer/src

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

ARG nginx_config="./conf/nginx.conf"
ARG htpasswd="./conf/htpasswd"

COPY ${nginx_config} /etc/nginx/nginx.conf

# Move our build artifacts and includes into our webroot (/plexus)
COPY --from=builder /elm-src/performer/build /plexus/performer
COPY --from=builder /elm-src/performer/include /plexus/performer
COPY --from=builder /elm-src/audience/build /plexus/audience
COPY ${htpasswd} /secret/htpasswd

EXPOSE 443
