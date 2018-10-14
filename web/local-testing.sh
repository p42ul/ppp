# Script to build and run a local test version of the frontend.

docker build -t frontend-dev \
    --build-arg nginx_config=./conf/nginx-dev.conf \
    --build-arg elm_config=./conf/ConfigDev.elm \
    --build-arg htpasswd=./conf/htpasswd-prod \
    .

echo "Running frontend-dev container with ports 80:80 exposed..."
docker run --rm -it -p 80:80 frontend-dev