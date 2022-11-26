#!/bin/sh

script_dir="$(
	cd "$(dirname "$0")"
	pwd -P
)"
cd "$script_dir"
# shellcheck source=mainutil.sh
. mainutil.sh
# shellcheck source=shellutil.sh
. shellutil.sh
# shellcheck source=updateutil.sh
. updateutil.sh
# set -o xtrace

main() {
	# shellcheck disable=SC2039
	local command_help
	command_help='docker - Develop inside a Docker container.
docker-format - Run format using a Docker container.
docker-update - Run update using a Docker container.
format - Run shfmt, prettier, and shellcheck.
git - Run git.
update - Check and update project dependencies.'
	# shellcheck disable=SC2039
	local commands
	commands="$(main_extract_commands "$command_help")"
	# shellcheck disable=SC2086
	if [ -z "${1:-}" ]; then
		main_exit_with_no_command_error "$command_help"
	elif [ "$1" = "$(arg 0 $commands)" ]; then
		shift
		./git.sh docker "$@"
	elif [ "$1" = "$(arg 1 $commands)" ]; then
		./format.sh docker-format
	elif [ "$1" = "$(arg 2 $commands)" ]; then
		run_docker_update
	elif [ "$1" = "$(arg 3 $commands)" ]; then
		./format.sh format
	elif [ "$1" = "$(arg 4 $commands)" ]; then
		shift
		./git.sh git "$@"
	elif [ "$1" = "$(arg 5 $commands)" ]; then
		update
	else
		main_exit_with_invalid_command_error "$1" "$command_help"
	fi
}

run_docker_update() {
	docker pull creemama/node-dev:lts-alpine
	docker run -it --rm \
		--volume "$(pwd)":/tmp \
		--workdir /tmp \
		creemama/node-dev:lts-alpine \
		sh -c './dev.sh update'
}

update() {
	apk_update_node_image_version format.sh
	apk_update_node_image_version git.sh
	# As a submodule, git status might not work in a Docker container mounted to this
	# script_dir.
	printf '%s%s\nRun git status.\n%s' "$(tbold)" "$(tyellow)" "$(treset)"
}

main "$@"
