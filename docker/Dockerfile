# syntax=docker/dockerfile:1.2

# noVNC server bundle and Caddy requires GoLang
FROM golang:bullseye AS golang_build
WORKDIR /src
RUN --mount=type=cache,target=/root/go \
    # build Easy-noVNC
    go mod init build && \
    go get github.com/geek1011/easy-novnc@v1.1.0 && \
    go build -o /usr/local/bin/easy-novnc github.com/geek1011/easy-novnc && rm -rf ./* && \
    # build Caddy
    printf "module caddy\n\
    require github.com/caddyserver/caddy/v2 v2.6.4\n\
    require github.com/mholt/caddy-webdav master\n" > go.mod && \
    printf "package main\n\
    import caddycmd \"github.com/caddyserver/caddy/v2/cmd\"\n\
    import _ \"github.com/caddyserver/caddy/v2/modules/standard\"\n\
    import _ \"github.com/mholt/caddy-webdav\"\n\
    func main() { caddycmd.Main() }\n" > caddy.go && \
    go mod tidy && go build -o /usr/local/bin/caddy . && rm -rf ./*

# this is the base OS image
FROM ubuntu:focal AS container_over_browser_base

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
    lxterminal mesa-utils vulkan-tools openvpn bridge-utils vim nano
    # net-tools iputils-ping

# copy over the built noVNC and caddy servers
COPY --from=golang_build /usr/local/bin/caddy /usr/local/bin/
COPY --from=golang_build /usr/local/bin/easy-novnc /usr/local/bin/

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

# wrap up
ENTRYPOINT ["/ade_entrypoint"]

CMD ["/bin/sh", "-c", "trap 'exit 147' TERM; tail -f /dev/null & while wait ${!}; [ $? -ge 128 ]; do true; done"]
