#!/bin/sh

script_dir="$(
	cd "$(dirname "${0}")"
	pwd -P
)"
# shellcheck source=shellutil.sh
. "${script_dir}/shellutil.sh"
# set -o xtrace

apk_shellcheck=shellcheck~=0.7
apk_shfmt=shfmt@edgecommunity~=3.2
node_image=creemama/node-no-yarn:14.15.1-alpine3.11
npm_prettier=prettier@2.2.0

apk_guarantee_edgecommunity() {
	if [ -f /etc/apk/repositories ] && ! grep '@edgecommunity http://nl.alpinelinux.org/alpine/edge/community' /etc/apk/repositories >/dev/null 2>&1; then
		printf %s '@edgecommunity http://nl.alpinelinux.org/alpine/edge/community' >>/etc/apk/repositories
	fi
}

format() {
	run_shfmt
	run_prettier
	run_shellcheck
}

main() {
	if [ "${1:-}" = docker ]; then
		run_docker -c sh
	elif [ "${1:-}" = docker-format ]; then
		run_docker -c "${script_dir}/format.sh format"
	elif [ "${1:-}" = docker-prettier ]; then
		run_docker -c "${script_dir}/format.sh prettier"
	elif [ "${1:-}" = docker-shfmt ]; then
		run_docker -c "${script_dir}/format.sh shfmt"
	elif [ "${1:-}" = docker-shellcheck ]; then
		run_docker -c "${script_dir}/format.sh shellcheck"
	elif [ "${1:-}" = format ]; then
		format
	elif [ "${1:-}" = prettier ]; then
		run_prettier
	elif [ "${1:-}" = shfmt ]; then
		run_shfmt
	elif [ "${1:-}" = shellcheck ]; then
		run_shellcheck
	elif [ -n "${1:-}" ]; then
		printf '%s%s is not a recognized command.\n%s' "$(tred)" "${1}" "$(treset)"
		exit 1
	else
		printf '%sEnter a command.\n%s' "$(tred)" "$(treset)"
		exit 1
	fi
}

run_docker() {
	# shellcheck disable=SC2068
	docker run -it --rm \
		--volume "$(pwd -P):$(pwd -P)" \
		--workdir "$(pwd -P)" \
		"${node_image}" \
		sh ${@}
}

run_prettier() {
	if ! test_command_exists prettier; then
		npm install --global "${npm_prettier}"
	fi
	prettier --write .
}

run_shellcheck() {
	if ! test_command_exists shellcheck; then
		apk add "${apk_shellcheck}"
	fi
	shellcheck --external-sources ./*.sh
}

run_shfmt() {
	if ! test_command_exists shfmt; then
		apk_guarantee_edgecommunity
		apk add "${apk_shfmt}"
	fi
	shfmt -w ./*.sh
}

main "$@"
