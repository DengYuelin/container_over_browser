#!/bin/bash

export DOCKER_BUILDKIT=1

docker build -t container_over_browser_base:latest -f ./docker/Dockerfile .

# the following command creates a docker network that is using the host DHCP on the host gateway.
# docker network create -d macvlan --subnet=128.46.157.0/24 --gateway=128.46.157.1 -o parent=enp3s0 pub_net
