#!/bin/sh

trap "exit 1" SIGINT SIGTERM

# WATCH_TARGET
if [ -z $WATCH_TARGET ]; then
    WATCH_TARGET="$(pwd)"
elif [ -d "$WATCH_TARGET" ]; then
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

if [ -z "$FOREWER" ]; then
    FOREWER=0
fi

if [ -z "$DEBUG" ]; then
    DEBUG=0
fi

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
    FOREWER: $FOREWER
    DEBUG: $DEBUG
    INITIAL JOBS: $JOBS
EOF

while true; do
    debug "INFO: wait for $WAIT_EVENTS on $WATCH_TARGET"
    name=$(inotifywait -r -e $WAIT_EVENTS $WATCH_TARGET --format '%w/%f' 2>/dev/null)
    debug "INFO: got event on $name"

    for job in $(find "$JOBS_FOLDER" -type f -iname "*.job" | sort); do
        debug "INFO: process $job"
        if [ -x "$job" ]; then
            debug "INFO: starting job $job with param $param"
            "$job" "$name"
        else
            debug "INFO: can't execute $job"
        fi
        if [ $? -ne 0 ]; then
            echo "ERROR: $job failed"
            exit $?
        fi
    done
    # break loop
    if [ $FOREWER -eq 0 ]; then
        break
    fi
done
