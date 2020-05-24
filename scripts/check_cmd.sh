#!/bin/sh

echo 🔎 Checking necessary programs, tools, commands ...

DIR=$(dirname $0)
. $DIR/utils/semver.sh
. $DIR/utils/uname.sh
. $DIR/utils/cmd_exists.sh

missing=
old=

## general
### iterate through a tuple: https://stackoverflow.com/questions/9713104/loop-over-tuples-in-bash
OLDIFS=$IFS
IFS='@'
for cmd_ver in \
	zsh@4.3.11 emacs@26.1 alacritty@0.4.0 code@1.45.0 \
	cargo@0.4.0 go@1.11; do
	set -- $cmd_ver
	printf '%s' "Checking for $1 (at least $2) ... "
	check_version $1 $2
	retval=$?
	case $retval in
	0)
		stat="ok"
		;;
	1)
		stat="missing"
		;;
	2)
		stat="too old"
		;;
	4)
		stat="broken?"
		;;
	*)
		stat="unable to check"
		;;
	esac
	echo $stat

	if [ $retval -eq 2 ]; then
		old="$1 (>=$2); $old"
	elif [ $retval -ne 0 ]; then
		missing="$1 (>=$2); $missing"
	fi
done
IFS=$OLDIFS # reset IFS

os_specific_cmds=
get_os
retval=$?
case $retval in
0) os_specific_cmds="xclip" ;;
1) os_specific_cmds="pbcopy" ;;
*) ;;
esac
for cmd in $os_specific_cmds; do
	printf '%s' "Checking for $cmd ... "
	if ! cmd_exists $cmd; then
		echo "missing"
		missing="$cmd; $missing"
	else
		echo "ok"
	fi
done

## Report Result
echo
if [ x"$missing" != x ]; then
	echo "❓ Missing tools: $missing"
	return 1
fi
if [ x"$old" != x ]; then
	echo "⬆️ Update required: $old"
	return 1
fi
if [ x"$missing" = x -a x"$old" = x ]; then
	echo "✔️ All tools ready!"
	return 0
fi