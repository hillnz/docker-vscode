# TODO ditch stages once there are ARM builds https://github.com/gitpod-io/openvscode-server/issues/36

FROM node:14-buster AS build

# renovate: datasource=docker depName=gitpod/openvscode-server
ARG VSCODE_VERSION=1.61.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        xvfb x11vnc fluxbox dbus-x11 x11-utils x11-xserver-utils xdg-utils \
        fbautostart xterm eterm gnome-terminal gnome-keyring seahorse nautilus \
        libx11-dev libxkbfile-dev libsecret-1-dev libnotify4 libnss3 libxss1 \
        libasound2 libgbm1 xfonts-base xfonts-terminus fonts-noto fonts-wqy-microhei \
        fonts-droid-fallback vim-tiny nano libgconf2-dev libgtk-3-dev twm

RUN git clone https://github.com/gitpod-io/openvscode-server && \
    cd openvscode-server && \
    git checkout openvscode-server-v${VSCODE_VERSION} && \
    yarn && yarn gulp server-min

FROM ubuntu:rolling

ARG USERNAME=openvscode-server
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apt update && \
    apt install -y git wget sudo && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /home/

COPY --from=build /server-pkg /home/openvscode-server

# Creating the user and usergroup
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USERNAME -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

RUN chmod g+rw /home && \
    mkdir -p /home/workspace && \
    chown -R $USERNAME:$USERNAME /home/workspace && \
    chown -R $USERNAME:$USERNAME /home/openvscode-server;

USER $USERNAME

WORKDIR /home/workspace/

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV HOME=/home/workspace
ENV EDITOR=code
ENV VISUAL=code
ENV GIT_EDITOR="code --wait"
ENV OPENVSCODE_SERVER_ROOT=/home/openvscode-server

EXPOSE 3000

ENTRYPOINT ${OPENVSCODE_SERVER_ROOT}/server.sh

# Customisation starts here
USER root

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
	curl \
	docker \
	docker-compose \
	git \
	tldr \
	zsh

USER openvscode-server
