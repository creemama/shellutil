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
	run_shfmt "${@+"${@}"}"
	run_prettier "${@+"${@}"}"
	run_shellcheck "${@+"${@}"}"
}

main() {
	if [ "${1:-}" = docker ]; then
		shift
		run_docker "${@+"${@}"}"
	elif [ "${1:-}" = docker-format ]; then
		shift
		run_docker -c "${script_dir}/format.sh format $(array_to_string "${@+"${@}"}")"
	elif [ "${1:-}" = docker-prettier ]; then
		shift
		run_docker -c "${script_dir}/format.sh prettier $(array_to_string "${@+"${@}"}")"
	elif [ "${1:-}" = docker-shfmt ]; then
		shift
		run_docker -c "${script_dir}/format.sh shfmt $(array_to_string "${@+"${@}"}")"
	elif [ "${1:-}" = docker-shellcheck ]; then
		shift
		run_docker -c "${script_dir}/format.sh shellcheck $(array_to_string "${@+"${@}"}")"
	elif [ "${1:-}" = format ]; then
		shift
		format "${@+"${@}"}"
	elif [ "${1:-}" = prettier ]; then
		shift
		run_prettier "${@+"${@}"}"
	elif [ "${1:-}" = shfmt ]; then
		shift
		run_shfmt "${@+"${@}"}"
	elif [ "${1:-}" = shellcheck ]; then
		shift
		run_shellcheck "${@+"${@}"}"
	elif [ -n "${1:-}" ]; then
		printf '%s%s is not a recognized command.\n%s' "$(tred)" "${1}" "$(treset)"
		exit 1
	else
		printf '%sEnter a command.\n%s' "$(tred)" "$(treset)"
		exit 1
	fi
}

run_docker() {
	docker run -it --rm \
		--volume "$(pwd -P):$(pwd -P)" \
		--workdir "$(pwd -P)" \
		"${node_image}" \
		sh "${@+"${@}"}"
}

run_prettier() {
	if [ -f node_modules/.bin/prettier ]; then
		# shellcheck disable=SC2068
		./node_modules/.bin/prettier --write ${@:-.}
	else
		if ! test_command_exists prettier; then
			npm install --global "${npm_prettier}"
		fi
		# shellcheck disable=SC2068
		prettier --write ${@:-.}
	fi
}

run_shellcheck() {
	if [ -n "${2:-}" ]; then
		for arg in "$@"; do
			run_shellcheck "${arg}"
		done
		return
	fi
	# shellcheck disable=SC2039
	local files
	if [ -n "${1:-}" ]; then
		if [ -d "${1}" ]; then
			(
				cd "${1}"
				run_shellcheck
			)
			return
		else
			files="${1}"
		fi
	else
		files='./*.sh'
	fi
	if ! test_command_exists shellcheck; then
		apk add "${apk_shellcheck}"
	fi
	# shellcheck disable=SC2086
	shellcheck --external-sources ${files}
}

run_shfmt() {
	if [ -n "${2:-}" ]; then
		for arg in "$@"; do
			run_shfmt "${arg}"
		done
		return
	fi
	# shellcheck disable=SC2039
	local files
	if [ -n "${1:-}" ]; then
		if [ -d "${1}" ]; then
			(
				cd "${1}"
				run_shfmt
			)
			return
		else
			files="${1}"
		fi
	else
		files='./*.sh'
	fi
	if ! test_command_exists shfmt; then
		apk_guarantee_edgecommunity
		apk add "${apk_shfmt}"
	fi
	# shellcheck disable=SC2086
	shfmt -w ${files}
}

main "$@"
