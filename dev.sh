#!/bin/sh

script_dir="$(
	cd "$(dirname "$0")"
	pwd -P
)"
cd "$script_dir"
# shellcheck source=shellutil.sh
. shellutil.sh
# shellcheck source=update.sh
. update.sh
# set -o xtrace

main() {
	if [ -z "${1:-}" ]; then
		printf '%sEnter a command.\n%s' "$(tred)" "$(treset)"
		exit 1
	elif [ "$1" = docker ]; then
		./format.sh docker
	elif [ "$1" = docker-format ]; then
		./format.sh docker-format
	elif [ "$1" = docker-update ]; then
		run_docker_update
	elif [ "$1" = format ]; then
		./format.sh format
	elif [ "$1" = update ]; then
		update
	else
		printf '%s%s is not a recognized command.\n%s' "$(tred)" "$1" "$(treset)"
		exit 1
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
}

main "$@"
