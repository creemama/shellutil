#!/bin/sh

script_dir="$(
	cd "$(dirname "$0")"
	pwd -P
)"
# shellcheck source=mainutil.sh
. "$script_dir"/mainutil.sh
# shellcheck source=shellutil.sh
. "$script_dir"/shellutil.sh
# set -o xtrace

apk_git=git~=2.24
apk_git_gitk=git-gitk~=2.24
apk_gnupg=gnupg~=2.2
apk_openssh=openssh~=8.1
apk_terminus_font=terminus-font~=4.48
node_image=creemama/node-no-yarn:14.15.1-alpine3.11

main() {
	# shellcheck disable=SC2039
	local command_help
	command_help='docker - Develop inside a Docker container.
docker-git - Run git using a Docker container.
docker-gitk - Run gitk using a Docker container.
git - Run git.
gitk - Run gitk.'
	# shellcheck disable=SC2039
	local commands
	commands="$(main_extract_commands "$command_help")"
	# shellcheck disable=SC2086
	if [ -z "${1:-}" ]; then
		main_exit_with_no_command_error "$command_help"
	elif [ "$1" = "$(arg 0 $commands)" ]; then
		shift
		run_docker "$@"
	elif string_starts_with "$1" docker-; then
		run_docker_command "$@"
	elif [ "$1" = "$(arg 3 $commands)" ]; then
		shift
		run_git "$@"
	elif [ "$1" = "$(arg 4 $commands)" ]; then
		shift
		run_gitk "$@"
	else
		main_exit_with_invalid_command_error "$1" "$command_help"
	fi
}

run_docker() {
	# IP, DISPLAY, and /tmp/.X11-unix are for gitk.
	# https://stackoverflow.com/questions/37523980/running-gui-apps-on-docker-container-with-a-macbookpro-host
	# https://fredrikaverpil.github.io/2016/07/31/docker-for-mac-and-gui-applications/
	# https://forums.docker.com/t/how-to-run-gui-apps-in-containiers-in-osx-docker-for-mac/17797/6
	export IP
	IP="$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}')"
	xhost + "${IP}"
	docker run \
		--env DISPLAY="${IP}":0 \
		-it \
		--rm \
		--volume /tmp/.X11-unix:/tmp/.X11-unix \
		--volume ~/.gnupg:/root/.gnupg \
		--volume ~/.ssh:/root/.ssh:ro \
		--volume "$(pwd -P):$(pwd -P)" \
		--workdir "$(pwd -P)" \
		"$node_image" \
		sh "$@"
}

run_docker_command() {
	# shellcheck disable=SC2039
	local command
	command="$(printf %s "${1:-}" | sed -E 's/^docker-//')"
	shift
	run_docker -c "$script_dir/git.sh $command $(array_to_string "$@")"
}

run_git() {
	if ! test_command_exists git; then
		apk add "$apk_git" "$apk_gnupg" "$apk_openssh"
	fi
	if [ -z "${GPG_TTY:-}" ]; then
		export GPG_TTY
		GPG_TTY="$(tty)"
	fi
	git "$@"
}

run_gitk() {
	if ! test_command_exists gitk; then
		apk add "$apk_git_gitk" "$apk_terminus_font"
	fi
	gitk "$@"
}

main "$@"
