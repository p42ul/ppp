# This first stage builds the frontend code
FROM archlinux/base as builder

# Install prerequisites
# (Ruby and Git are needed for elm-github-install)
RUN pacman -Sy --noconfirm nodejs npm ruby git
RUN npm install elm@elm0.18.0
RUN gem install elm_install --no-document -v 1.6.1 

# Add binaries to our path
ENV PATH="$PATH:/node_modules/elm/bin"
# Dirty hack to make command substitution work in Docker.
# You still need to use "source /ruby_path" for every command that runs a ruby binary
RUN echo "export PATH=\$PATH:$(ruby -e 'print Gem.user_dir')/bin" > /ruby_path

# Create a directory for our Elm source code,
# Move into that directory, and copy our source into it.
WORKDIR /elm-src
COPY ./audience ./audience
COPY ./performer ./performer

# Build that code!
RUN cd performer && \
    elm-make --yes ./src/Performer.elm --output build/Performer.js
RUN cd audience && \
    source /ruby_path && \
    elm-install && \
    elm-make --yes ./src/Audience.elm --output build/index.html

# This second stage serves the frontend code
FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf

# Move our build artifacts and includes into our webroot (/plexus)
COPY --from=builder /elm-src/performer/build /plexus/performer
COPY --from=builder /elm-src/performer/include /plexus/performer
COPY --from=builder /elm-src/audience/build /plexus/audience
COPY ./htpasswd /secret/htpasswd

EXPOSE 443
