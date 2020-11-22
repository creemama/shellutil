#!/bin/sh

IFS=$(printf '\n\t')
set -o errexit -o nounset
if [ -n "${BASH_VERSION:-}" ]; then
	# shellcheck disable=SC2039
	set -o pipefail
fi
# set -o xtrace

apk_get_alpine_version() {
	grep VERSION_ID </etc/os-release |
		sed -E 's/VERSION_ID=|(\.[0-9]+$)//g'
}

apk_guarantee_edgecommunity() {
	if [ -f /etc/apk/repositories ] && ! grep '@edgecommunity http://nl.alpinelinux.org/alpine/edge/community' /etc/apk/repositories >/dev/null 2>&1; then
		printf '%s' '@edgecommunity http://nl.alpinelinux.org/alpine/edge/community' >>/etc/apk/repositories
	fi
}

# shellcheck disable=SC2120
apk_update_node_image_version() {
	# shellcheck disable=SC2039
	local file
	if [ -n "${1:-}" ]; then
		file="${1}"
	else
		file='./dev.sh'
	fi

	# shellcheck disable=SC2039
	local sed_pattern
	if [ -n "${2:-}" ]; then
		sed_pattern="${2}"
	else
		sed_pattern="s#(^node_image='creemama/node-no-yarn:)[^']+'#\\\\1%s-alpine%s'#"
	fi

	# shellcheck disable=SC2039
	local major_node_version
	major_node_version="$(get_major_node_version)"

	# shellcheck disable=SC2039
	local alpine_version
	alpine_version="$(apk_get_alpine_version)"

	# shellcheck disable=SC2059
	sed -E -i"" \
		"$(printf "${sed_pattern}" "${major_node_version}" "${alpine_version}")" \
		"${file}"
}

apk_update_package_version() {
	apk_guarantee_edgecommunity

	# shellcheck disable=SC2039
	local package
	package="${1}"

	# shellcheck disable=SC2039
	local file
	file="${2:-./dev.sh}"

	# shellcheck disable=SC2039
	local package_version
	package_version="$(
		apk --no-cache --update search "${package}" |
			grep -E "${package}-[0-9]" |
			head -n 1 |
			sed -E "s/${package}-([0-9]+\.[0-9]+)\..*/\1/"
	)"

	sed -E -i"" \
		"s/${package}(@edgecommunity)?~=[0-9.]+/${package}\\1~=${package_version}/" \
		"${file}"
}

get_major_node_version() {
	node --version | tr -d 'v'
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

local_tput() {
	if ! is_tty; then
		return 0
	fi
	if test_command_exists tput; then
		# $@ is unquoted.
		# shellcheck disable=SC2068
		tput $@
	fi
}

npm_update_package_version() {
	# shellcheck disable=SC2039
	local package
	package="${1}"

	# shellcheck disable=SC2039
	local file
	file="${2:-./dev.sh}"

	# shellcheck disable=SC2039
	local package_version
	package_version="$(npm show "${package}" version)"

	sed -E -i"" \
		"s/(${package}@)[0-9.]+/\\1${package_version}/" \
		"${file}"
}

tbold() {
	local_tput bold
}

tcyan() {
	local_tput setaf 6
}

tgray() {
	local_tput setaf 7
}

tgreen() {
	local_tput setaf 2
}

tred() {
	local_tput setaf 1
}

treset() {
	local_tput sgr0
}

tyellow() {
	local_tput setaf 3
}

test_command_exists() {
	command -v "${1}" >/dev/null 2>&1
}
