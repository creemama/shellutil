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

node_image=creemama/shellutil-dev:18.13.0-alpine3.17

format() {
	run_shfmt "$@"
	run_prettier "$@"
	run_shellcheck "$@"
}

main() {
	local command_help
	command_help='docker - Develop inside a Docker container.
format - (or docker-format) Run shfmt, prettier, and shellcheck.
prettier - (or docker-prettier) Run prettier.
shell-format - (or docker-shell-format) Run shfmt and shellcheck.
shfmt - (or docker-shellcheck) Run shfmt.
shellcheck - (or docker-shellcheck) Run shellcheck.'
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
	elif [ "$1" = "$(arg 1 $commands)" ]; then
		shift
		format "$@"
	elif [ "$1" = "$(arg 2 $commands)" ]; then
		shift
		run_prettier "$@"
	elif [ "$1" = "$(arg 3 $commands)" ]; then
		shift
		shell_format "$@"
	elif [ "$1" = "$(arg 4 $commands)" ]; then
		shift
		run_shfmt "$@"
	elif [ "$1" = "$(arg 5 $commands)" ]; then
		shift
		run_shellcheck "$@"
	else
		main_exit_with_invalid_command_error "$1" "$command_help"
	fi
}

run_docker() {
	docker run -it --rm \
		--volume "$(pwd -P):$(pwd -P)" \
		--workdir "$(pwd -P)" \
		"$node_image" \
		sh "$@"
}

run_docker_command() {
	local command
	command="$(printf %s "${1:-}" | sed -E 's/^docker-//')"
	shift
	run_docker -c "$script_dir/format.sh $command $*"
}

run_prettier() {
	if [ -f node_modules/.bin/prettier ]; then
		./node_modules/.bin/prettier --write "${@:-.}"
	else
		prettier --write "${@:-.}"
	fi
}

run_shellcheck() {
	if [ -n "${2:-}" ]; then
		for arg in "$@"; do
			run_shellcheck "$arg"
		done
		return
	fi
	local files
	if [ -n "${1:-}" ]; then
		if [ -d "$1" ]; then
			(
				cd "$1"
				run_shellcheck
			)
			return
		else
			files="$1"
		fi
	else
		files='./*.sh'
	fi
	# shellcheck disable=SC2086
	shellcheck -e SC3043 --external-sources $files
}

run_shfmt() {
	if [ -n "${2:-}" ]; then
		for arg in "$@"; do
			run_shfmt "$arg"
		done
		return
	fi
	local files
	if [ -n "${1:-}" ]; then
		if [ -d "$1" ]; then
			(
				cd "$1"
				run_shfmt
			)
			return
		else
			files="$1"
		fi
	else
		files='./*.sh'
	fi
	# shellcheck disable=SC2086
	shfmt -w $files
}

shell_format() {
	run_shfmt "$@"
	run_shellcheck "$@"
}

main "$@"
