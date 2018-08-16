#!/bin/bash
#
# Management script for Singularity containers
#

BUILD_DIR=./build

# Exit on error
set -e

if [ "$#" -lt 2 ]; then
    echo "Usage: `basename $0` [build|shell|clean|deploy] [tool1] [tool2] .. [tooln]"
    echo "       You can combine multiple commands with a plus, e.g. clean+build+deploy"
    exit 1
fi

COMMANDS=$1
CMDARR=(${COMMANDS//+/ })
shift 1 # remove command parameter from args

for COMMAND in "${CMDARR[@]}"
do
    echo "Executing $COMMAND command on these targets: $@"

    if [ "$COMMAND" == "build" ]; then

        mkdir -p $BUILD_DIR

        echo "Will build these images: $@"

        for ALIGNER in "$@"
        do
            ALIGNER=${ALIGNER%/}
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

        ALIGNER=${1%/}
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

        echo "Will deploy these images: $@"

        for ALIGNER in "$@"
        do
            ALIGNER=${ALIGNER%/}
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

     elif [ "$COMMAND" == "push" ]; then

        LOCAL_REGISTRY=`grep int.janelia.org ~/.sregistry`
        if [ -z "$LOCAL_REGISTRY" ]; then
            echo "Before using this script, ensure that your ~/.sregistry file points to a local repository in the int.janelia.org domain"
            exit 1
        fi

        echo "Will push these images: $@"

        for ALIGNER in "$@"
        do
            ALIGNER=${ALIGNER%/}
            VERSION=`grep VERSION $ALIGNER/Singularity | sed "s/VERSION //"`
            FILENAME=${ALIGNER}-${VERSION}.img
            IMGFILE=$BUILD_DIR/$FILENAME

            if [ ! -f $IMGFILE ]; then
                echo "Container $IMGFILE not found. You must first build the container with build.sh"
            else
                echo "Pushing $FILENAME to remote repository"
                echo "sregistry push --name jacs-tools/$ALIGNER --tag $VERSION $IMGFILE"
                sregistry push --name jacs-tools/$ALIGNER --tag $VERSION $IMGFILE
            fi

        done

    elif [ "$COMMAND" == "clean" ]; then

        echo "Will clean these images: $@"

        for ALIGNER in "$@"
        do
            ALIGNER=${ALIGNER%/}
            # I hope ALIGNER doesn't have any spaces in it!
            rm -f $BUILD_DIR/${ALIGNER}*
        done

    else
        echo "Unknown command: $COMMAND"
        exit 1
    fi

done
