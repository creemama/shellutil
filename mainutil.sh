#!/bin/sh

main_exit_with_no_command_error() {
	# $1 is command_help.
	printf '%s%sEnter a command:\n%s%s%s\n%s' \
		"$(tbold)" \
		"$(tred)" \
		"$(treset)" \
		"$(tcyan)" \
		"$1" \
		"$(treset)"
	exit 1
}

main_extract_commands() {
	# $1 is command_help.
	printf %s "$1" | sed -E 's/([^ ]+) - .*/\1/g'
}

main_exit_with_invalid_command_error() {
	# $1 is command.
	# $2 is command_help.
	printf '%s%s%s is not a recognized command. Enter a command:\n%s%s%s\n%s' \
		"$(tbold)" \
		"$(tred)" \
		"$1" \
		"$(treset)" \
		"$(tcyan)" \
		"$2" \
		"$(treset)"
	exit 1
}
