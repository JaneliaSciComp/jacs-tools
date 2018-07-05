#!/bin/bash

if [ "$#" -lt 2 ]; then
    echo "Usage: `basename $0` [build|shell|clean|deploy] [tool1] [tool2] .. [tooln]"
    exit 1
fi

COMMAND=$1
BUILD_DIR=./build

if [ "$COMMAND" == "build" ]; then

    mkdir -p $BUILD_DIR

    shift 1 # remove command parameter from args
    echo "Will build these images: $@"

    for ALIGNER in "$@"
    do
        VERSION=`grep VERSION $ALIGNER/Singularity | sed "s/VERSION //"`
        FILENAME=${ALIGNER}-${VERSION}.img
        sudo rm /tmp/$FILENAME && true
        echo "---------------------------------------------------------------------------------"
        echo " Building image for $ALIGNER"
        echo "---------------------------------------------------------------------------------"
        pushd $ALIGNER
        sudo singularity build /tmp/$FILENAME Singularity
        popd
        FINAL=$BUILD_DIR/$FILENAME
        cp /tmp/$FILENAME $FINAL
        sudo rm /tmp/$FILENAME
        echo "Created container $FINAL"
    done

elif [ "$COMMAND" == "shell" ]; then

    ALIGNER=$2
    VERSION=`grep VERSION $ALIGNER/Singularity | sed "s/VERSION //"`
    FILENAME=${ALIGNER}-${VERSION}.img
    IMGFILE=$BUILD_DIR/$FILENAME

    if [ ! -f $IMGFILE ]; then
        echo "Container $IMGFILE not found. You must first build the aligner container with build.sh"
        exit 1
    fi

    singularity shell $IMGFILE

elif [ "$COMMAND" == "deploy" ]; then

    if [ -z "$JACS_SINGULARITY_DIR" ]; then
        echo "Set the JACS_SINGULARITY_DIR environment variable to the directory where containers will be deployed"
        exit 1
    fi

    shift 1 # remove command parameter from args
    echo "Will deploy these images: $@"

    for ALIGNER in "$@"
    do
        VERSION=`grep VERSION $ALIGNER/Singularity | sed "s/VERSION //"`
        FILENAME=${ALIGNER}-${VERSION}.img
        IMGFILE=$BUILD_DIR/$FILENAME

        if [ ! -f $IMGFILE ]; then
            echo "Container $IMGFILE not found. You must first build the aligner container with build.sh"
        else
            echo "Copying $FILENAME to $JACS_SINGULARITY_DIR"
            cp $IMGFILE $JACS_SINGULARITY_DIR
        fi

    done

elif [ "$COMMAND" == "clean" ]; then

    shift 1 # remove command parameter from args
    echo "Will clean these images: $@"

    for ALIGNER in "$@"
    do
        # I hope ALIGNER doesn't have any spaces in it!
        rm -f $BUILD_DIR/${ALIGNER}*
    done

else
    echo "Unknown command: $COMMAND"
    exit 1
fi

