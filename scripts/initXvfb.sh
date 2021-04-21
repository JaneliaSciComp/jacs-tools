#!/bin/bash
#
# Tries ports incrementally, starting with the given argument, and when it finds a free port runs an Xvfb instance in the background.
#
# Evaluate with `source` before starting GUI operations in your script.
#
# At the end of this script, the following state will be set:
#   XVFB_PORT: the port that Xvfb is actually running on
#   XVFB_PID: the pid of the Xvfb instance
#   a function called cleanXvfb to kill Xvfb and clean up Xvfb resources
#   a trap on EXIT signal to call cleanXvfb
#

NUMPARAMS=$#
if [ $NUMPARAMS -lt 1 ]
then
    echo " "
    echo " USAGE: sh $0 [starting port]"
    echo " "
    exit
fi

DISPLAY_PORT=$1
echo "Finding a port for Xvfb, starting at $DISPLAY_PORT..."
PORT=$DISPLAY_PORT
COUNTER=0
RETRIES=10

# Clean up Xvfb on any exit
function cleanXvfb {
    kill $MYPID
    rm -f /tmp/.X${PORT}-lock
    rm -f /tmp/.X11-unix/X${PORT}
    echo "Cleaned up Xvfb"
}
trap cleanXvfb EXIT

while [ "$COUNTER" -lt "$RETRIES" ]; do
    
    while (test -f "/tmp/.X${PORT}-lock") || (test -f "/tmp/.X11-unix/X${PORT}") || (netstat -atwn | grep "^.*:${PORT}.*:\*\s*LISTEN\s*$")
        do PORT=$(( ${PORT} + 1 ))
    done
    echo "Found the first free port: $PORT"

    # Run Xvfb (virtual framebuffer) on the chosen port
    /usr/bin/Xvfb :${PORT} -screen 0 1280x1024x24 -fp /usr/share/X11/fonts/misc > Xvfb.${PORT}.log 2>&1 &
    echo "Started Xvfb on port $PORT"

    # Save the PID so that we can kill it when we're done
    MYPID=$!
    export DISPLAY=":${PORT}.0"
    
    # Wait some time and check to make sure Xvfb is actually running, and retry if not. 
    sleep 3
    if kill -0 $MYPID >/dev/null 2>&1; then
        echo "Xvfb is running as $MYPID"
        break
    else
        echo "Xvfb died immediately, trying again..."
        cleanXvfb
        PORT=$(( ${PORT} + 1 ))
    fi
    COUNTER="$(( $COUNTER + 1 ))"

done

export XVFB_PORT=$PORT
export XVFB_PID=$MYPID

