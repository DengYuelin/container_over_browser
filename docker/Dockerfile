# syntax=docker/dockerfile:1.6

# Copyright (c) 2023, Haoguang Yang. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Caddy requires GoLang
#FROM golang:alpine AS golang_build
#WORKDIR /src
#RUN --mount=type=cache,target=/root/go \
#    go mod init build && \
    # build Easy-noVNC -- this repo is archived and no longer updates.
    # go get github.com/geek1011/easy-novnc@v1.1.0 && \
    # go build -o /usr/local/bin/easy-novnc github.com/geek1011/easy-novnc && rm -rf ./* && \
    # build Caddy
#    printf "module caddy\n\
#    require github.com/caddyserver/caddy/v2 v2.7.4\n\
#    require github.com/mholt/caddy-webdav master\n" > go.mod && \
#    printf "package main\n\
#    import caddycmd \"github.com/caddyserver/caddy/v2/cmd\"\n\
#    import _ \"github.com/caddyserver/caddy/v2/modules/standard\"\n\
#    import _ \"github.com/mholt/caddy-webdav\"\n\
#    func main() { caddycmd.Main() }\n" > caddy.go && \
#    go mod tidy && go build -o /usr/local/bin/caddy . && cd / && rm -rf /src

FROM caddy:latest AS caddy

FROM gitpod/openvscode-server:latest AS openvscode-server

# this is the base OS image
FROM ros:noetic-ros-core-focal AS ros_noetic_desktop_full

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y ros-noetic-desktop-full && \
    apt-get install -y python3-rosdep python3-rosinstall python3-rosinstall-generator \
        python3-wstool build-essential python3-rosdep && \
    rosdep init

FROM ros:humble-ros-core-jammy AS ros2_humble_desktop

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y ros-${ROS_DISTRO}-desktop

FROM ros2_humble_desktop AS mfet442
# FROM ros_noetic_desktop_full AS mfet442

SHELL ["/bin/bash", "-c"]

# enable NVIDIA graphics
ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics

# install essential maintenance and development software
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC \
    apt-get install -y --no-install-recommends sudo tzdata && \
    apt-get install -y --no-install-recommends \
    lsb-release gnupg2 ca-certificates bash-completion supervisor openvpn bridge-utils vim nano git gzip wget curl\
    menu openbox tigervnc-standalone-server lxterminal libegl1 libxext6 mesa-utils vulkan-tools

# install docker cli tools
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt/lists \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli docker-buildx-plugin docker-compose-plugin

# copy over the built noVNC and caddy servers
# COPY --from=golang_build /usr/local/bin/easy-novnc /usr/local/bin/    # switched to the native version below.
ADD --keep-git-dir=false https://github.com/novnc/noVNC.git#master /opt/noVNC
ADD --keep-git-dir=false https://github.com/novnc/websockify.git#master /opt/noVNC/utils/websockify
COPY --from=caddy /usr/bin/caddy /usr/local/bin/

# disable sudo user password and copy over ADE configs
RUN echo 'ALL ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
COPY ./docker/ade_env.sh /etc/profile.d/ade_env.sh
COPY ./docker/ade_entrypoint /ade_entrypoint

# copy over config files for browser remote access
COPY ./docker/openbox_menu.xml /etc/xdg/openbox/menu.xml
COPY ./docker/supervisord.conf /etc/
COPY ./docker/Caddyfile /etc/
COPY ./docker/apt_01norecommends /etc/apt/apt.conf.d/01norecommends

# enable NVIDIA GPU access for rendering inside contianers
COPY ./docker/vulkan_nvidia_icd.json /etc/vulkan/icd.d/nvidia_icd.json
COPY ./docker/egl_10_nvidia.json /usr/share/glvnd/egl_vendor.d/10_nvidia.json

# OpenVSCode-Server
COPY --from=openvscode-server /home/.openvscode-server /opt/openvscode-server
ENV OPENVSCODE_SERVER_ROOT="/opt/openvscode-server"

# wrap up
ENTRYPOINT ["/ade_entrypoint"]
CMD ["/bin/sh", "-c", "trap 'exit 147' TERM; tail -f /dev/null & while wait ${!}; [ $? -ge 128 ]; do true; done"]
