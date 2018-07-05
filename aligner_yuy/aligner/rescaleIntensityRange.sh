#!/bin/bash
#
# rescale image's intensity range pipeline, version 1.0, 2013/4/25
#

################################################################################
#
# The pipeline is developed for rescaling the intensity range of TAR to SUB.
#
################################################################################

##################
# Basic Funcs
##################

DIR=$(cd "$(dirname "$0")"; pwd)
. $DIR/common.sh

##################
# Inputs
##################

CONFIGFILE=""
TOOLDIR=""
WORKDIR=""
SUB=""
TAR=""
OUTPUT_FILE=""

while getopts "c:k:w:s:i:o:h" opt
do case "$opt" in
    c) CONFIGFILE="$OPTARG";;
    k) TOOLDIR="$OPTARG";;
    w) WORKDIR="$OPTARG";;
    s) SUB="$OPTARG";;
    i) TAR="$OPTARG";;
    o) OUTPUT_FILE="$OPTARG";;
    h) echo "Usage: $0 [-c configuration_file] [-k toolkits_dir] [-w work_dir] [-s input_sub] [-i input_tar] [-o output_file]" >&2
        exit 1;;
    esac
done
shift $((OPTIND-1))

# tools
Vaa3D=`readItemFromConf $CONFIGFILE "Vaa3D"`
Vaa3D=${TOOLDIR}"/"${Vaa3D}

# debug inputs
message "Inputs..."
echo "WORKDIR: $WORKDIR"
echo "SUB: $SUB"
echo "TAR: $TAR"
message "Tools..."
echo "Vaa3D: $Vaa3D"
echo ""

OUTPUT=${WORKDIR}

if [ ! -d $OUTPUT ]; then 
mkdir $OUTPUT
fi

ensureRawFile "$Vaa3D" "$OUTPUT" "$SUB" SUB
echo "RAW SUB: $SUB"

ensureRawFile "$Vaa3D" "$OUTPUT" "$TAR" TAR
echo "RAW TAR: $TAR"

##################
# Rescaling
##################

if ( is_file_exist "$OUTPUT_FILE" )
then
echo " OUTPUT_FILE exists"
else
#---exe---#
message " Rescaling $TAR "
$Vaa3D -x ireg -f rescaleInt -o $OUTPUT_FILE -p "#s $SUB #t $TAR"
fi


