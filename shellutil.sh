#!/bin/sh

IFS=$(printf '\n\t')
set -o errexit -o nounset
if [ -n "${BASH_VERSION:-}" ]; then
	# shellcheck disable=SC2039
	set -o pipefail
fi
# set -o xtrace

array_to_string() {
	if [ -n "${1:-}" ]; then
		# shellcheck disable=SC2039
		local command=''
		for arg in "${@}"; do
			command="$(printf %s "${command}") '${arg}'"
		done
		printf %s "${command}"
	fi
}

# https://unix.stackexchange.com/a/598047
is_integer() {
	case "${1#[+-]}" in
	*[!0123456789]*) return 1 ;;
	'') return 1 ;;
	*) return 0 ;;
	esac
}

is_tty() {
	# "No value for $TERM and no -T specified"
	# https://askubuntu.com/questions/591937/no-value-for-term-and-no-t-specified
	tty -s >/dev/null 2>&1
}

run_tput() {
	if ! is_tty; then
		return 0
	fi
	if ! test_command_exists tput && test_command_exists apk; then
		# ncurses has tput in Alpine Linux. Let's not care about the version of
		# ncurses.
		apk add ncurses >/dev/null 2>&1 || true
	fi
	if test_command_exists tput; then
		# $@ is unquoted.
		# shellcheck disable=SC2068
		tput $@
	fi
}

tbold() {
	run_tput bold
}

tcyan() {
	run_tput setaf 6
}

tgray() {
	run_tput setaf 7
}

tgreen() {
	run_tput setaf 2
}

tred() {
	run_tput setaf 1
}

treset() {
	run_tput sgr0
}

tyellow() {
	run_tput setaf 3
}

test_command_exists() {
	command -v "${1}" >/dev/null 2>&1
}
