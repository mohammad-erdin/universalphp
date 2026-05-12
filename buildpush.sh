bash scripts/build.sh --php 8.4 --os alpine --platform=linux/amd64
bash scripts/build.sh --php 8.5 --os alpine --platform=linux/amd64

bash scripts/build.sh --php 8.4 --os trixie --platform=linux/amd64
bash scripts/build.sh --php 8.5 --os trixie --platform=linux/amd64

docker push ghcr.io/mohammad-erdin/docker-php:8.4-frankenphp-alpine
docker push ghcr.io/mohammad-erdin/docker-php:8.5-frankenphp-alpine

docker push ghcr.io/mohammad-erdin/docker-php:8.4-frankenphp-trixie
docker push ghcr.io/mohammad-erdin/docker-php:8.5-frankenphp-trixie