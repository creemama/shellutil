# shellutil.sh

> POSIX-compliant shell scripting utility functions

Include `shellutil.sh` as a
[submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) of your Git
repo by executing the following:

```
$ git submodule add https://github.com/creemama/shellutil
```

Use the [dot operator](https://ss64.com/bash/source.html) to include
`shellutil.sh` in one of your scripts:

```
#!/bin/sh

script_dir="$(
	cd "$(dirname "${0}")"
	pwd -P
)"
cd "${script_dir}"
if [ ! -f shellutil/shellutil.sh ]; then
	git submodule update --init
fi
# shellcheck source=shellutil/shellutil.sh
. shellutil/shellutil.sh
# set -o xtrace

printf '%s%s%s' "$(tbold)" 'Hello world!' "$(treset)"
```

## Available Utility Functions

- `is_integer`
- `is_tty`
- `tbold`
- `tcyan`
- `tgray`
- `tgreen`
- `tred`
- `treset`
- `tyellow`
- `test_command_exists`
