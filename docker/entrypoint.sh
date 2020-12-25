#!/bin/sh

trap "exit 1" INT TERM

# WATCH_TARGET
if [ -z $WATCH_TARGET ]; then
    if [ -z "$1" ]; then
        WATCH_TARGET="$(pwd)"
    else
        WATCH_TARGET="$1"
    fi
fi

if [ -d "$WATCH_TARGET" ]; then
    WATCH_TARGET=$(
        cd $WATCH_TARGET
        pwd
    )
else
    dir_name=$(dirname $WATCH_TARGET)
    file_name="${WATCH_TARGET##*/}"
    full_path=$(
        cd $dir_name
        pwd
    )
    WATCH_TARGET="$full_name/$file_name"
fi

if [ -z $WAIT_EVENTS ]; then
    WAIT_EVENTS="create"
fi

if [ -z $JOBS_FOLDER ]; then
    JOBS_FOLDER="/etc/fsjob"
fi

if [ -z "$FOREVER" ]; then
    FOREVER=0
fi

if [ -z "$DEBUG" ]; then
    DEBUG=0
fi

if [ -z "$INCL_PATTERN" ]; then
    INCL_PATTERN='.*'
fi

no_err() {
    "$@" 2>/dev/null
}

no_out() {
    "$@" 1>/dev/null
}

silent() {
    no_out "no_err" "$@"
}

debug() {
    if [ $DEBUG -ne 0 ]; then
        echo "INFO: $@" 1>&2
    fi
}

JOBS=$(find "$JOBS_FOLDER" -type f -executable -iname "*.job" | sort)

cat <<EOF
PARAMS:
    WATCH TARGET: $WATCH_TARGET
    WAIT EVENTS: $WAIT_EVENTS
    JOBS FOLDER: $JOBS_FOLDER
    FOREVER: $FOREVER
    DEBUG: $DEBUG
    INITIAL JOBS: $JOBS
EOF

debug "wait for $WAIT_EVENTS on $WATCH_TARGET"
# break loop
monitor="-r"
if [ $FOREVER -ne 0 ]; then
    monitor="-r -m"
fi

inotifywait $monitor -e $WAIT_EVENTS $WATCH_TARGET --format '%w%f' 2>/dev/null | while read name; do
    if silent expr match "$name" "$INCL_PATTERN"; then
        if [ -n "$EXCL_PATTERN" ]; then
            if silent expr match "$name" "$EXCL_PATTERN"; then
                debug "skip $name: due exclude pattern $EXCL_PATTERN match"
                continue
            fi
        fi
        debug "got event on $name"
        for job in $(find "$JOBS_FOLDER" -type f -iname "*.job" | sort); do
            debug "process $job"
            if [ -x "$job" ]; then
                debug "starting job $job with param $name"
                "$job" "$name"
                if ! "$job" "$name"; then
                    echo "ERROR: $job failed"
                    exit $?
                fi
            else
                debug "can't execute $job"
            fi
        done
    else
        debug "skip $name: due include pattern $INCL_PATTERN dismatch"
    fi
done
