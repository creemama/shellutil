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
	local file
	file="${1:-dev.sh}"

	local sed_pattern
	sed_pattern="${2:-s#(creemama/(node-no-yarn|shellutil-dev):).*#\\\\1%s-alpine%s#}"

	local major_node_version
	major_node_version="$(get_major_node_version)"

	local alpine_version
	alpine_version="$(apk_get_alpine_version)"

	# shellcheck disable=SC2059
	sed -E -i'' \
		"$(printf "$sed_pattern" "$major_node_version" "$alpine_version")" \
		"$file"
}

apk_update_package_version() {
	local package
	package="$1"

	local file
	file="${2:-dev.sh}"

	local package_version
	# "s/$package-([0-9]+[a-z]?)-.*/\1/" matches the following:
	# less-530-r0
	# tzdata-2019a-r0
	local packages
	packages="$(apk --no-cache --update search "$package" | sort)"
	package_version="$(
		printf %s "$packages" |
			grep -E "^$package-[0-9]" |
			head -n 1 |
			sed -E "s/$package-([0-9]+\.[0-9]+).*/\1/" |
			sed -E "s/$package-([0-9]+[a-z]?)-.*/\1/"
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
		"s/$package~=[0-9a-z.-]+/$package\\1~=$package_version/" \
		"$file"
}

get_major_node_version() {
	node --version | tr -d v
}

npm_update_package_version() {
	local package
	package="$1"

	local file
	file="${2:-dev.sh}"

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

pip_update_package_version() {
	if ! test_command_exists pip3; then
		printf '%s%spip3 does not exist.\n%s' "$(tbold)" "$(tred)" "$(treset)"
		exit 1
	fi

	local package
	package="$1"

	local file
	file="${2:-dev.sh}"

	local package_version
	# https://www.python.org/dev/peps/pep-0440/
	package_version="$(pip3 install "$package"==random 2>&1 |
		grep -E "\(from versions: " |
		sed -E 's/.*\(from versions: (.*)\)/\1/' |
		sed -E 's/\S+(a|b|rc|post|dev)\S+//g' |
		tr -d , |
		sed -E 's/.+\s(\S+)\s*/\1/')"

	printf '\n%s%sChecking %s %s...%s\n' \
		"$(tbold)" \
		"$(tcyan)" \
		"$package" \
		"$package_version" \
		"$(treset)"

	sed -E -i'' \
		"s/$package==[0-9.]+/$package==$package_version/" \
		"$file"
}
