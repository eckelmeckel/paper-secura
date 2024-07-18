################################################################################
# Copyright 2024, Fraunhofer Institute for Secure Information Technology SIT.  #
# All rights reserved.                                                         #
# ---------------------------------------------------------------------------- #
# Dockerfile.                                                                  #
# ---------------------------------------------------------------------------- #
# Author:        Michael Eckel <michael.eckel@sit.fraunhofer.de>               #
# Date Modified: 2024-04-18T12:33:13+00:00                                     #
# Date Created:  2024-07-03T12:33:13+00:00                                     #
# ---------------------------------------------------------------------------- #
# Hint: Check your Dockerfile at https://www.fromlatest.io/                    #
################################################################################


## -----------------------------------------------------------------------------
## --- preamble ----------------------------------------------------------------
## -----------------------------------------------------------------------------

## --- global arguments --------------------------------------------------------


## --- set base image(s) -------------------------------------------------------

FROM ubuntu:22.04 AS base

## --- metadata ----------------------------------------------------------------

LABEL org.opencontainers.image.authors="michael.eckel@sit.fraunhofer.de"

## --- image specific arguments ------------------------------------------------

## user and group
ARG user='bob'
ARG uid=1000
ARG gid=1000


## -----------------------------------------------------------------------------
## --- pre-work for interactive environment ------------------------------------
## -----------------------------------------------------------------------------

## Bash command completion
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    bash-completion \
    && rm -rf /var/lib/apt/lists/*


## -----------------------------------------------------------------------------
## --- install dependencies ----------------------------------------------------
## -----------------------------------------------------------------------------

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    python3 \
    python3-requests \
    && rm -rf /var/lib/apt/lists/*


## -----------------------------------------------------------------------------
## --- setup user --------------------------------------------------------------
## -----------------------------------------------------------------------------

## install sudo and gosu
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    gosu \
    sudo \
    && rm -rf /var/lib/apt/lists/*

## create non-root user and grant sudo permission
RUN export user="${user}" uid="${uid}" gid="${gid}" \
    && addgroup --gid "${gid}" "${user}" \
    && adduser --home /home/"${user}" --uid "${uid}" --gid "${gid}" \
    --disabled-password --gecos '' "${user}" \
    && mkdir -vp /etc/sudoers.d/ \
    && echo "${user}     ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/"${user}" \
    && chmod 0440 /etc/sudoers.d/"${user}" \
    && chown "${uid}:${gid}" -R /home/"${user}"


## -----------------------------------------------------------------------------
## --- configuration -----------------------------------------------------------
## -----------------------------------------------------------------------------

## configure Bash
COPY "./docker/dist/home/user/.bashrc" "/home/${user}/.bashrc"
COPY "./docker/dist/home/user/.bash_aliases" "/home/${user}/.bash_aliases"
COPY "./docker/dist/home/user/.bash_history" "/home/${user}/.bash_history"

## Docker entrypoint
COPY "./docker/dist/usr/local/bin/docker-entrypoint.sh" "/usr/local/bin/"
## keep backwards compatibility
RUN ln -s '/usr/local/bin/docker-entrypoint.sh' /

## set environment variables
USER "${uid}:${gid}"
ENV HOME=/home/"${user}"
WORKDIR /home/"${user}/poc-ima-vuln"


## -----------------------------------------------------------------------------
## --- postamble ---------------------------------------------------------------
## -----------------------------------------------------------------------------

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/bin/bash"]
