# syntax=docker/dockerfile:1.6

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

FROM caddy:alpine AS caddy

FROM gitpod/openvscode-server:latest AS openvscode-server

# this is the base OS image
FROM ubuntu:jammy AS container_over_browser_base

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
    lsb-release gnupg2 ca-certificates openbox menu tigervnc-standalone-server supervisor \
    lxterminal mesa-utils vulkan-tools openvpn bridge-utils vim nano gzip wget

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
COPY ./docker/nvidia_icd.json /etc/vulkan/icd.d/nvidia_icd.json
ENV VK_ICD_FILENAMES /etc/vulkan/icd.d/nvidia_icd.json

# OpenVSCode-Server
COPY --from=openvscode-server /home/.openvscode-server /opt/openvscode-server
ENV OPENVSCODE_SERVER_ROOT="/opt/openvscode-server"
RUN \
    # Direct download links to external .vsix not available on https://open-vsx.org/
    urls=(\
        https://github.com/lharri73/DBC-Language-Syntax/releases/latest/download/dbc-2.0.0.vsix \
        https://github.com/microsoft/vscode-cpptools/releases/latest/download/cpptools-linux.vsix \
    )\
    # Create a tmp dir for downloading
    && tdir=/tmp/exts && mkdir -p "${tdir}" && cd "${tdir}" \
    # Download via wget from $urls array.
    && wget "${urls[@]}" && \
    ms_marketplace_urls=(\
        https://marketplace.visualstudio.com/_apis/public/gallery/publishers/nonanonno/vsextensions/vscode-ros2/0.1.5/vspackage \
        https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-iot/vsextensions/vscode-ros/0.9.5/vspackage \
    )\
    && for ms_raw in "${ms_marketplace_urls[@]}"; do \
        wget ${ms_raw}; \
        mv vspackage vspackage.gz; \
        gunzip vspackage.gz; \
        pkg_name=$(echo ${ms_raw} | cut -d '/' -f 10); \
        mv vspackage ${pkg_name}.vsix; \
    done && \
    # List the extensions in this array
    exts=(\
        # From https://open-vsx.org/ registry directly
        cschlosser.doxdocgen \
        eamodio.gitlens \
        jeff-hykin.better-cpp-syntax \
        ms-python.isort \
        ms-python.python \
        njpwerner.autodocstring \
        RandomFractalsInc.geo-data-viewer \
        redhat.vscode-xml \
        redhat.vscode-yaml \
        shd101wyy.markdown-preview-enhanced \
        Gruntfuggly.todo-tree \
        twxs.cmake \
        muhammad-sammy.csharp \
        # From filesystem, .vsix that we downloaded (using bash wildcard '*')
        "${tdir}"/* \
    )\
    # Install the $exts
    && for ext in "${exts[@]}"; do ${OPENVSCODE_SERVER_ROOT}/bin/openvscode-server --extensions-dir /opt/openvscode-server/extensions/ --install-extension "${ext}"; done \
    && rm -rf "${tdir}" && chmod g+w /opt/openvscode-server/extensions/

# wrap up
ENTRYPOINT ["/ade_entrypoint"]
CMD ["/bin/sh", "-c", "trap 'exit 147' TERM; tail -f /dev/null & while wait ${!}; [ $? -ge 128 ]; do true; done"]
