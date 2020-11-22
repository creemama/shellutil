#!/bin/sh

script_dir="$(
	cd "$(dirname "${0}")"
	pwd -P
)"
# shellcheck source=shellutil.sh
. "${script_dir}/shellutil.sh"
cd "${script_dir}"
# set -o xtrace

apk_shellcheck='shellcheck~=0.7'
apk_shfmt='shfmt@edgecommunity~=3.2'
node_image='creemama/node-no-yarn:14.15.1-alpine3.11'
npm_prettier='prettier@2.2.0'

apk_update() {
	# shellcheck disable=SC2119
	apk_update_node_image_version
	apk_update_package_version shellcheck
	apk_update_package_version shfmt
	npm_update_package_version prettier
}

docker_run() {
	# shellcheck disable=SC2068
	docker run -it --rm \
		--volume "$(pwd):/tmp" \
		--workdir /tmp \
		"${node_image}" \
		sh ${@}
}

docker_update() {
	docker pull creemama/node-no-yarn:lts-alpine
	docker run -it --rm \
		--volume "$(pwd):/tmp" \
		--workdir /tmp \
		'creemama/node-no-yarn:lts-alpine' \
		sh -c './dev.sh update'
}

format() {
	apk_guarantee_edgecommunity
	if ! test_command_exists shellcheck; then
		apk add "${apk_shellcheck}"
	fi
	if ! test_command_exists shfmt; then
		apk add "${apk_shfmt}"
	fi
	if ! test_command_exists prettier; then
		npm install --global "${npm_prettier}"
	fi
	shfmt -w ./*.sh
	prettier --write .
	shellcheck ./*.sh
}

main() {
	if [ "${1:-}" = "docker" ]; then
		docker_run -c 'sh'
	elif [ "${1:-}" = "docker-format" ]; then
		docker_run -c './dev.sh format'
	elif [ "${1:-}" = "docker-update" ]; then
		docker_update
	elif [ "${1:-}" = "format" ]; then
		format
	elif [ "${1:-}" = "update" ]; then
		apk_update
	else
		print_help
	fi
}

print_help() {
	cat <<EOF

  $(tbold)./dev.sh$(treset) <command>

  $(tgray)Commands:
    $(tgray)- Execute
    $(tcyan)$ ./dev.sh docker

    $(tgray)- Execute
    $(tcyan)$ ./dev.sh docker-format

    $(tgray)- Execute
    $(tcyan)$ ./dev.sh docker-update

    $(tgray)- Format shell scripts and Markdown files.
    $(tcyan)$ ./dev.sh format

    $(tgray)- Check for a newer version of node:lts-alpine and
      updates this project if so.
    $(tcyan)$ ./dev.sh update
$(treset)

EOF
}

main "$@"
