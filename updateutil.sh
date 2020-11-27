#!/bin/sh

apk_get_alpine_version() {
	grep VERSION_ID </etc/os-release | sed -E 's/VERSION_ID=|(\.[0-9]+$)//g'
}

apk_guarantee_edgecommunity() {
	if [ -f /etc/apk/repositories ] && ! grep '@edgecommunity http://nl.alpinelinux.org/alpine/edge/community' /etc/apk/repositories >/dev/null 2>&1; then
		printf %s '@edgecommunity http://nl.alpinelinux.org/alpine/edge/community' >>/etc/apk/repositories
	fi
}

apk_update_node_image_version() {
	# shellcheck disable=SC2039
	local file
	file="${1:-dev.sh}"

	# shellcheck disable=SC2039
	local sed_pattern
	sed_pattern="${2:-s#(^node_image=creemama/node-no-yarn:).*#\\\\1%s-alpine%s#}"

	# shellcheck disable=SC2039
	local major_node_version
	major_node_version="$(get_major_node_version)"

	# shellcheck disable=SC2039
	local alpine_version
	alpine_version="$(apk_get_alpine_version)"

	# shellcheck disable=SC2059
	sed -E -i'' \
		"$(printf "$sed_pattern" "$major_node_version" "$alpine_version")" \
		"$file"
}

apk_update_package_version() {
	# shellcheck disable=SC2039
	local package
	package="$1"

	# shellcheck disable=SC2039
	local file
	file="${2:-dev.sh}"

	# shellcheck disable=SC2039
	local package_version
	# "s/$package-([0-9]+)[a-z]?-.*/\1/" matches the following:
	# less-530-r0
	# tzdata-2019a-r0
	# shellcheck disable=SC2039
	local packages
	packages="$(apk --no-cache --update search "$package")"
	package_version="$(
		printf %s "$packages" |
			grep -E "^$package-[0-9]" |
			head -n 1 |
			sed -E "s/$package-([0-9]+\.[0-9]+).*/\1/" |
			sed -E "s/$package-([0-9]+)[a-z]?-.*/\1/"
	)"

	printf '\n%s%sChecking %s...%s\n%s\n%s%s...%s%s\n' \
		"$(tbold)" \
		"$(tcyan)" \
		"$package" \
		"$(treset)" \
		"$packages" \
		"$(tbold)" \
		"$(tcyan)" \
		"$package_version" \
		"$(treset)"

	sed -E -i'' \
		"s/$package(@edgecommunity)?~=[0-9.]+/$package\\1~=$package_version/" \
		"$file"
}

get_major_node_version() {
	node --version | tr -d v
}

npm_update_package_version() {
	# shellcheck disable=SC2039
	local package
	package="$1"

	# shellcheck disable=SC2039
	local file
	file="${2:-dev.sh}"

	# shellcheck disable=SC2039
	local package_version
	package_version="$(npm show "$package" version)"

	printf '\n%s%sChecking %s@%s...%s\n' \
		"$(tbold)" \
		"$(tcyan)" \
		"$package" \
		"$package_version" \
		"$(treset)"

	# The package might have / in the name like @babel/cli, so let's use # as the sed
	# expression separator.
	sed -E -i'' \
		"s#($package@)[0-9.]+#\\1$package_version#" \
		"$file"
}
