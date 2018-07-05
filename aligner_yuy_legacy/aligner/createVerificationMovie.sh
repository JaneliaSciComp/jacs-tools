#!/bin/bash
#
# Create an alignment verification movie which shows the green subject
# brain on top of a magenta standard brain template.
#

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
SUBREF=""
OUTPUT_FILE=""

while getopts "c:k:w:s:i:r:o:h" opt
do case "$opt" in
    c) CONFIGFILE="$OPTARG";;
    k) TOOLDIR="$OPTARG";;
    w) WORKDIR="$OPTARG";;
    s) SUB="$OPTARG";;
    i) TAR="$OPTARG";;
    r) SUBREF="$OPTARG";;
    o) OUTPUT_FILE="$OPTARG";;
h) echo "Usage: $0 [-c configuration_file] [-k toolkits_dir] [-w work_dir] [-s input_sub] [-i input_tar] [-r ref_channel] [-o output_file]" >&2
        exit 1;;
    esac
done
shift $((OPTIND-1))

# tools
Vaa3D=`readItemFromConf $CONFIGFILE "Vaa3D"`
Vaa3D=${TOOLDIR}"/"${Vaa3D}

# debug inputs
message "Inputs..."
echo "CONFIGFILE: $CONFIGFILE"
echo "TOOLDIR: $TOOLDIR"
echo "WORKDIR: $WORKDIR"
echo "SUB: $SUB"
echo "TAR: $TAR"
echo "SUBREF: $SUBREF"
echo "OUTPUT_FILE: $OUTPUT_FILE"
message "Tools..."
echo "Vaa3D: $Vaa3D"
echo ""

SUB_NAME=`basename $SUB`
SUB_EXT=${SUB#*.}
SUBREF=$((SUBREF-1));
OUTPUT=${WORKDIR}

if [ ! -d $OUTPUT ]; then
mkdir $OUTPUT
fi

cd $WORKDIR

if ( is_file_exist "$OUTPUT_FILE" )
then
echo " OUTPUT_FILE exists"
else
#---exe---#
ln -s $SUB $SUB_NAME
SUB=$WORKDIR/${SUB_NAME}
message " Splitting channels $SUB "
$Vaa3D -x ireg -f splitColorChannels -i $SUB

#---exe---#
message " Merging channels "
SUB_STUB=${SUB%.*}
SUBR="${SUB_STUB}_c${SUBREF}.v3draw"
$Vaa3D -x ireg -f mergeColorChannels -i $TAR $SUBR $TAR -o $WORKDIR/out.v3draw

#---exe---#
message "Generating movie "
$Vaa3D -cmd image-loader -convert $WORKDIR/out.v3draw $OUTPUT_FILE

fi

