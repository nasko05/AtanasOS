#!/bin/sh
./build_docker.sh
docker run --rm -it -v "$(pwd)":/root/env atanas-os