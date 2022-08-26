#!/usr/bin/env bash

export LC_ALL=C

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"/../.. || exit

DOCKER_IMAGE=${DOCKER_IMAGE:-e4coin/e4coind-develop}
DOCKER_TAG=${DOCKER_TAG:-latest}
DOCKER_RELATIVE_PATH=contrib/containers/deploy

BASE_BUILD_DIR=${BASE_BUILD_DIR:-.}


if [ -d $DOCKER_RELATIVE_PATH/bin ]; then
    rm $DOCKER_RELATIVE_PATH/bin/*
fi

mkdir $DOCKER_RELATIVE_PATH/bin
cp "$BASE_BUILD_DIR"/src/e4coind    $DOCKER_RELATIVE_PATH/bin/
cp "$BASE_BUILD_DIR"/src/e4coin-cli $DOCKER_RELATIVE_PATH/bin/
cp "$BASE_BUILD_DIR"/src/e4coin-tx  $DOCKER_RELATIVE_PATH/bin/
strip $DOCKER_RELATIVE_PATH/bin/e4coind
strip $DOCKER_RELATIVE_PATH/bin/e4coin-cli
strip $DOCKER_RELATIVE_PATH/bin/e4coin-tx

docker build --pull -t "$DOCKER_IMAGE":"$DOCKER_TAG" -f $DOCKER_RELATIVE_PATH/Dockerfile docker
