#!/usr/bin/env bash
################################################################################
# Copyright 2024, Fraunhofer Institute for Secure Information Technology SIT.  #
# All rights reserved.                                                         #
# ---------------------------------------------------------------------------- #
# Build container image.                                                       #
# ---------------------------------------------------------------------------- #
# Author:        Michael Eckel <michael.eckel@sit.fraunhofer.de>               #
# Date Modified: 2024-04-23T17:10:09+00:00                                     #
# Date Created:  2024-04-23T17:10:09+00:00                                     #
################################################################################

## exit on error, unset variable as error, and prevent errors in pipelines
#set -euo pipefail


# ---------------------------------------------------------------------------- #
# --- GLOBAL CONSTANTS ------------------------------------------------------- #
# ---------------------------------------------------------------------------- #

readonly CONTAINER_IMAGE_ENV_FILE='./docker/docker-image.config'
readonly CONTAINER_USER_DEFAULT='bob'


# ---------------------------------------------------------------------------- #
# --- GLOBAL VARIABLES ------------------------------------------------------- #
# ---------------------------------------------------------------------------- #

export DOCKER_BUILDKIT=1


# ---------------------------------------------------------------------------- #
# --- MAIN ------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #

## change directory to the one this script is placed in
cd "$(dirname "${0}")"

## go up one directory
cd ../

# ---------------------------------------------------------------------------- #

## main function
main() {
	## load config
	set -a  # automatically export all variables
	source "${CONTAINER_IMAGE_ENV_FILE}"
	set +a

	## sanity checks
	for cfg_opt in \
		'CONTAINER_IMAGE_VENDOR' \
		'CONTAINER_IMAGE_NAME' \
		'CONTAINER_IMAGE_VERSION'
	do
		cfg_opt_val="$(eval "echo \${${cfg_opt}}")"
		if [ -z "${cfg_opt_val}" ]; then
			log_warning "Please set the '${cfg_opt}' option in file" \
				"'${CONTAINER_IMAGE_ENV_FILE}'."
			exit 1
		fi
	done

	## construct container image name
	local -r container_image_fullname="`#
		`${CONTAINER_IMAGE_VENDOR}/`#
		`${CONTAINER_IMAGE_NAME}`#
		`:${CONTAINER_IMAGE_VERSION}"

	## set variables
	local -r container_user="$([ -n "${CONTAINER_USER}" ] \
			&& echo "${CONTAINER_USER}" || echo "${CONTAINER_USER_DEFAULT}")"
	local -r container_uid="$(id -u)"
	local -r container_gid="$(id -g)"

	## build container image
	docker build \
		-t "${container_image_fullname}" \
		--build-arg "user=${container_user}" \
		--build-arg "uid=${container_uid}" \
		--build-arg "gid=${container_gid}" \
		.
}


# ---------------------------------------------------------------------------- #
# --- FUNCTIONS -------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #

# --- app-specific functions ------------------------------------------------- #


# --- basic functions -------------------------------------------------------- #

log_info() {
	echo '[INFO]  ' "${*}"
}

log_warning() {
	echo '[WARN]  ' "${*}" >&2
}

log_error() {
	echo '[ERROR] ' "${*}" >&2
}

verify_runtime_dependencies() {
	while read cmd; do
		## filter empty and commented lines
		if [ -z "${cmd}" ] || [[ "${cmd}" =~ ^\# ]]; then
			continue
		fi

		## check if command exists
		if [ ! -n "$(command -v "${cmd}")" ]; then
			echo "Required command '${cmd}' not found or not executable!" >&2
			exit 2
		fi
	done < <(echo "${cmd_reqs}")
}


# ---------------------------------------------------------------------------- #
# --- DEPENDENCIES ----------------------------------------------------------- #
# ---------------------------------------------------------------------------- #

## verify_dependencies (list all required commands here; #comments are allowed)
read -r -d '' cmd_reqs <<- EOM
## basic tools
dirname

## app-specific tools
docker
id
EOM


# ---------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #

## call main function
verify_runtime_dependencies
main "$@"

