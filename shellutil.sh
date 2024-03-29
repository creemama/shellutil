#!/bin/sh

IFS=$(printf '\n\t')
set -o errexit -o nounset
if [ -n "${BASH_VERSION:-}" ]; then
	# shellcheck disable=SC3040
	set -o pipefail
fi
# set -o xtrace

arg() {
	print_arg_n "$@"
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

print_arg_n() {
	local n
	n="$1"
	local i
	i=0
	shift
	for arg in "$@"; do
		if [ "$n" = "$i" ]; then
			printf '%s\n' "$arg"
			return
		fi
		i=$((i + 1))
	done
}

run_tput() {
	if ! is_tty; then
		return 0
	fi
	if test_command_exists tput; then
		tput "$@"
	fi
}

string_starts_with() {
	printf %s "${1:-}" | grep -q "^${2:-}"
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
	command -v "$1" >/dev/null 2>&1
}
