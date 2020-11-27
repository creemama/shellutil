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
	command_help='all - Run format and update.
docker - Develop inside a Docker container.
docker-all - Run the all command using a Docker container.
docker-format - Run format using a Docker container.
docker-update - Run update using a Docker container.
format - Run shfmt, prettier, and shellcheck.
git - Run git.
gitk - Run gitk.
update - Check and update project dependencies.'
	# shellcheck disable=SC2039
	local commands
	commands="$(main_extract_commands "$command_help")"
	# shellcheck disable=SC2086
	if [ -z "${1:-}" ]; then
		main_exit_with_no_command_error "$command_help"
	elif [ "$1" = "$(arg 0 $commands)" ]; then
		./format.sh format
		update
	elif [ "$1" = "$(arg 1 $commands)" ]; then
		shift
		./format.sh docker "$@"
	elif [ "$1" = "$(arg 2 $commands)" ]; then
		./format.sh docker -c "./dev.sh all"
	elif [ "$1" = "$(arg 3 $commands)" ]; then
		./format.sh docker-format
	elif [ "$1" = "$(arg 4 $commands)" ]; then
		run_docker_update
	elif [ "$1" = "$(arg 5 $commands)" ]; then
		./format.sh format
	elif [ "$1" = "$(arg 6 $commands)" ]; then
		shift
		./git.sh git "$@"
	elif [ "$1" = "$(arg 7 $commands)" ]; then
		shift
		./git.sh gitk "$@"
	elif [ "$1" = "$(arg 8 $commands)" ]; then
		update
	else
		main_exit_with_invalid_command_error "$1" "$command_help"
	fi
}

run_docker_update() {
	docker pull creemama/node-no-yarn:lts-alpine
	docker run -it --rm \
		--volume "$(pwd)":/tmp \
		--workdir /tmp \
		creemama/node-no-yarn:lts-alpine \
		sh -c './dev.sh update'
}

update() {
	apk_update_node_image_version format.sh
	apk_update_package_version shellcheck format.sh
	apk_update_package_version shfmt format.sh
	npm_update_package_version prettier format.sh

	apk_update_node_image_version git.sh
	apk_update_package_version git git.sh
	apk_update_package_version git-gitk git.sh
	apk_update_package_version gnupg git.sh
	apk_update_package_version openssh git.sh
	apk_update_package_version terminus-font git.sh
}

main "$@"
