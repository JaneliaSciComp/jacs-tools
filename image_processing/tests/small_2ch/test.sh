TOOLS_DIR=$1
CONTAINER=$2
OUT=$3

NSLOTS=2
B1=$TEST_DATA_DIR
INPUT=$B1/image_processing/small_2ch/tile-2627567810317910052.zip

if [[ -e $OUT/stdout.log ]]; then
    echo "Test was already run"
else

cat >$OUT/submit.sh <<EOL
#!/bin/bash

export NSLOTS=$NSLOTS

. $TOOLS_DIR/scripts/asserts.sh $OUT

function convert {
    local _in="\$1"
    local _out="\$2"
    local _split="\$3"
    local _ref="\$4"
    local _signals="\$5"
    set -x
    singularity run -B $B1 -B $OUT --app convert $CONTAINER \$_in $OUT/\$_out \$_split \$_ref \$_signals
    set +x
}

# Test rsync into place
convert $INPUT test.zip 0
assertNotEmpty test.zip

# Test bzip2 into place
convert $INPUT test.zip.bz2 0
assertNotEmpty test.zip.bz2

# Test conversion to RAW
convert $INPUT test.v3draw 0
assertNotEmpty test.v3draw

# Test conversion to PBD
convert $INPUT test.v3dpbd 0
assertNotEmpty test.v3dpbd

# Test channel splitting
convert $INPUT test.v3draw 1
assertNotEmpty test_c0.v3draw
assertNotEmpty test_c1.v3draw

# Test H5J encoding
convert $INPUT test.h5j 0 2 1
assertNotEmpty test.h5j

# Test conversion to gzipped TIFF
convert $INPUT test.tiff.gz 0
assertNotEmpty test.tiff.gz

# Test conversion to gzipped, split raw
convert $INPUT test.v3draw.gz 1
assertNotEmpty test_c0.v3draw.gz
assertNotEmpty test_c1.v3draw.gz

# Test conversion to NRRD (must split)
convert $INPUT test.nrrd 1
assertNotEmpty test_c0.nrrd
assertNotEmpty test_c1.nrrd

# Test splitting H5J file
convert $OUT/test.h5j test.h5j 1 2 1
assertNotEmpty test_c0.h5j
assertNotEmpty test_c1.h5j

# Test converting from PBD back to ZIP
convert $OUT/test.v3dpbd test.zip 0
assertNotEmpty test.zip

EOL

fi

chmod +x $OUT/submit.sh
bsub -K -e $OUT/stderr.log -o $OUT/stdout.log -n $NSLOTS $OUT/submit.sh

cat $OUT/std*

if grep -q "Exited with exit code" $OUT/std*; then
    exit 1
else
    echo "TEST COMPLETE. CHECK OUTPUT MANUALLY IN $OUT"
fi


