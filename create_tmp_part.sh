#!/bin/bash

log() {
	ds=`date +'%Y-%m-%d %H:%M:%S'`
	echo -e "$ds ${2:-ERROR}: $1" | fold -w70 -s | sed '2~1s/^/  /'
}

getopt --test > /dev/null
if [[ $? -ne 4 ]]; then
    log "Please install getopt"
    exit 1
fi

TMP_PART=/opt/tmppart/parts
TMP_MNT=/opt/tmppart/mntpoints

SHORT=vs:n:
LONG=verbose,size:,name:
FORCE=false
[ ! -d $TMP_PART ] && mkdir -p $TMP_PART 
[ ! -d $TMP_MNT ] && mkdir -p $TMP_MNT
 
# -temporarily store output to be able to check for errors
# -activate advanced mode getopt quoting e.g. via “--options”
# -pass arguments only via   -- "$@"   to separate them correctly
PARSED=`getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@"`
if [[ $? -ne 0 ]]; then
    # e.g. $? == 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
# use eval with "$PARSED" to properly handle the quoting
eval set -- "$PARSED"
# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -v|--verbose)
            set -x
            shift
            ;;
        -s|--size)
            tp_size="$2"
            shift 2
            ;;
        -n|--name)
            tp_name="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Check parameter"
            exit 3
            ;;
    esac
done

# From Robert Siemer's answer [StackOverflow Answer](http://stackoverflow.com/a/29754866).

[[ $tp_name"x" -ne "x" ]] && log "Specify a name" && exit
tp_size=${tp_size:-4G}

touch $TMP_PART/$tp_name
truncate -s $tp_size $TMP_PART/$tp_name
mke2fs -q -t ext4 -F $TMP_PART/$tp_name
mkdir -p $TMP_MNT/$tp_name
mount $TMP_PART/$tp_name $TMP_MNT/$tp_name
