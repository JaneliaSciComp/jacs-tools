#!/bin/bash
#
# Management script for Singularity containers
#

DIR=$(cd "$(dirname "$0")"; pwd)
BUILD_DIR=$DIR/build
TEST_BUILD_DIR=$BUILD_DIR/test

# Exit on error
set -e

if [ "$#" -lt 2 ]; then
    echo "Usage: `basename $0` [build|shell|clean|test|deploy|push] [tool_1] [tool_2] .. [tool_n]"
    echo "       You can combine multiple commands with a plus sign, e.g. clean+build+deploy"
    echo
    echo "Commands:"
    echo "  build - Builds the given container into a Singularity image"
    echo "  shell - Runs an interactive shell on the given container"
    echo "  clean - Removes the built container and any temporary files"
    echo "  test - Runs integration tests (if any) on the given container"
    echo "  deploy - Copies the given container into the deployment area given by the \$JACS_SINGULARITY_DIR environment variable"
    #echo "  push - Pushes the given container to Janelia's Singularity container repository"
    echo 
    echo "Examples:"
    echo "  Build all the JRC2018 aligners, run the integration tests, and deploy them if all the tests succeed:"
    echo "  ./`basename $0` clean+build+test+deploy aligner*2018*"
    echo
    exit 1
fi

# Load the customized enviroment
. $DIR/env.sh

COMMANDS=$1
CMDARR=(${COMMANDS//+/ })
shift 1 # remove command parameter from args

for COMMAND in "${CMDARR[@]}"
do
    echo "Executing $COMMAND command on these targets: $@"

    if [[ "$COMMAND" == "build" ]]; then

        mkdir -p $BUILD_DIR

        echo "Will build these images: $@"

        for ALIGNER in "$@"
        do
            ALIGNER=${ALIGNER%/}
            VERSION=`grep VERSION $ALIGNER/Singularity | sed "s/VERSION //" | head -n 1`
            FILENAME=${ALIGNER}-${VERSION}.img
            sudo rm -f /tmp/$FILENAME && true
            echo "---------------------------------------------------------------------------------"
            echo " Building image for $ALIGNER"
            echo "---------------------------------------------------------------------------------"
            pushd $ALIGNER
            if [[ -e ./setup.sh ]]; then
                echo "Running setup.sh"
                bash ./setup.sh
            fi
            sudo singularity build /tmp/$FILENAME Singularity
            if [[ -e ./cleanup.sh ]]; then
                echo "Running cleanup.sh"
                bash ./cleanup.sh
            fi
            popd
            FINAL=$BUILD_DIR/$FILENAME
            cp /tmp/$FILENAME $FINAL
            sudo rm -f /tmp/$FILENAME
            echo "Created container $FINAL"
            rm -rf $TEST_BUILD_DIR/$ALIGNER
            echo "Purged test results for $ALIGNER"
        done

    elif [[ "$COMMAND" == "shell" ]]; then

        ALIGNER=${1%/}
        VERSION=`grep VERSION $ALIGNER/Singularity | sed "s/VERSION //" | head -n 1`
        FILENAME=${ALIGNER}-${VERSION}.img
        IMGFILE=$BUILD_DIR/$FILENAME

        if [ ! -f $IMGFILE ]; then
            echo "Container $IMGFILE not found. You must first build the aligner container with build.sh"
            exit 1
        fi

        singularity shell $IMGFILE

    elif [[ "$COMMAND" == "deploy" ]]; then

        if [ -z "$JACS_SINGULARITY_DIR" ]; then
            echo "Set the JACS_SINGULARITY_DIR environment variable to the directory where containers will be deployed"
            exit 1
        fi

        echo "Will deploy these images: $@"

        for ALIGNER in "$@"
        do
            ALIGNER=${ALIGNER%/}
            VERSION=`grep VERSION $ALIGNER/Singularity | sed "s/VERSION //" | head -n 1`
            FILENAME=${ALIGNER}-${VERSION}.img
            IMGFILE=$BUILD_DIR/$FILENAME

            if [ ! -f $IMGFILE ]; then
                echo "Container $IMGFILE not found. You must first build the aligner container with build.sh"
            else
                echo "Copying $FILENAME to $JACS_SINGULARITY_DIR"
                cp $IMGFILE $JACS_SINGULARITY_DIR
            fi

        done

     elif [[ "$COMMAND" == "push_is_unsupported" ]]; then

        LOCAL_REGISTRY=`grep int.janelia.org ~/.sregistry`
        if [ -z "$LOCAL_REGISTRY" ]; then
            echo "Before using this script, ensure that your ~/.sregistry file points to a local repository in the int.janelia.org domain"
            exit 1
        fi

        echo "Will push these images: $@"

        for ALIGNER in "$@"
        do
            ALIGNER=${ALIGNER%/}
            VERSION=`grep VERSION $ALIGNER/Singularity | sed "s/VERSION //" | head -n 1`
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

    elif [[ "$COMMAND" == "clean" ]]; then

        echo "Cleaning test output"
        rm -rf $TEST_BUILD_DIR

        echo "Cleaning images: $@"
        for ALIGNER in "$@"
        do
            ALIGNER=${ALIGNER%/}
            # I hope ALIGNER doesn't have any spaces in it!
            rm -f $BUILD_DIR/${ALIGNER}*
        done

    elif [[ "$COMMAND" == "test" || "$COMMAND" == "cleantest" ]]; then

        echo "Will test these images: $@"

        for ALIGNER in "$@"
        do
            ALIGNER=${ALIGNER%/}
            VERSION=`grep VERSION $ALIGNER/Singularity | sed "s/VERSION //" | head -n 1`
            FILENAME=${ALIGNER}-${VERSION}.img
            IMGFILE=$BUILD_DIR/$FILENAME

            for TEST_DIR in $ALIGNER/tests/*/
            do
                if [[ -d "$TEST_DIR" ]]; then
                    TEST_NAME=`basename $TEST_DIR`
                    TEST_SCRIPT=$TEST_DIR/test.sh
                    if [[ -e "$TEST_SCRIPT" ]]; then
                        TMPDIR=$TEST_BUILD_DIR/$ALIGNER/$TEST_NAME

                        if [[ "$COMMAND" == "cleantest" ]]; then
                            echo "Cleaning previous test results"
                            rm -rf $TMPDIR
                        fi

                        if [[ -e $TMPDIR/passed ]]; then
                            echo "Test '$TEST_NAME' already passed for this build. Use 'cleantest' to run it again."
                        else
                            if [[ -e $TMPDIR ]]; then
                                echo "Test '$TEST_NAME' has existing results which will be reused. Use 'cleantest' to start from scratch."
                            fi
                            echo "---------------------------------------------------------"
                            echo "Running $ALIGNER test '$TEST_NAME'"
                            echo "  Test script: $TEST_SCRIPT"
                            echo "  Working directory: $TMPDIR"
                            echo "---------------------------------------------------------"
                            mkdir -p $TMPDIR
                            set +e # disable exit on error, so that we can catch and deal with errors here
                            set -x
                            bash $TEST_SCRIPT $DIR $IMGFILE $TMPDIR
                            TEST_CODE=$?
                            set +x
                            set -e
                            if [[ "$TEST_CODE" -ne 0 ]]; then
                                echo "Test FAILED with exit code $TEST_CODE"
                                echo "See output in $TMPDIR for more details."
                                exit 1
                            else
                                touch $TMPDIR/passed
                                echo "Test passed"
                            fi
                        fi
                    else 
                        echo "Test $TEST_NAME has no test.sh script"
                    fi
                fi
            done

        done

    else
        echo "Unknown command: $COMMAND"
        exit 1
    fi

done
