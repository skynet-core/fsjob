#!/bin/sh

trap "exit 1" SIGINT SIGTERM

# WATCH_TARGET
if [ -z $WATCH_TARGET ]; then
    WATCH_TARGET="$(pwd)"
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

JOBS=$(find "$JOBS_FOLDER" -type f -executable -iname "*.job" | sort -z)

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
    name=$(inotifywait -r -e $WAIT_EVENTS $WATCH_TARGET 2>/dev/null | cut -d ' ' -f3)
    debug "INFO: got event on $name"

    for job in $(find "$JOBS_FOLDER" -type f -iname "*.job" | sort -z); do
        debug "INFO: process $job"
        param="$WATCH_TARGET/$name"
        if [ ! -d "$WATCH_TARGET" ]; then
            param="$WATCH_TARGET"
        fi
        if [ -x "$job" ]; then
            debug "INFO: starting job $job with param $param"
            "$job" "$param"
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
