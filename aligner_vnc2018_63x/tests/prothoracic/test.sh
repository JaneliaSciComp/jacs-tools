TOOLS_DIR=$1
CONTAINER=$2
OUT=$3

NSLOTS=3
B1=$TEMPLATES_DIR/configured_templates
B2=$TEST_DATA_DIR

cat >$OUT/align.yml <<EOL
template_dir: $B1
inputs:
- area: VNC
  filepath: $B2/aligner_vnc2018_63x/prothoracic/JRC_SS37652-20180410_31_G1.v3dpbd
  gender: m
  image_size: 1024x1024x421
  mounting_protocol: DPX PBS Mounting
  num_channels: 3
  objective: 63x
  ref_channel: 3
  tiles:
  - prothoracic
  voxel_size: 0.19x0.19x0.38
EOL

if [[ -e $OUT/stdout.log ]]; then
    echo "Test was already run"
else
    set -x
    bsub -K -e $OUT/stderr.log -o $OUT/stdout.log -n $NSLOTS $TOOLS_DIR/scripts/testAligner.sh \
        "singularity run -B $B1 -B $B2 --app align_half $CONTAINER" $NSLOTS $OUT $OUT/align.yml debug
    set +x
fi

. $TOOLS_DIR/scripts/asserts.sh $OUT
echo "TEST COMPLETE. CHECK OUTPUT MANUALLY IN $OUT"
# Check for output stacks
assertExists REG_JRC2018_MALE_63x.v3dpbd
assertExists REG_UNISEX_20x.v3dpbd
assertExists REG_UNISEX_63x.v3dpbd
assertExists REG_VNC2017F.v3dpbd
assertExists REG_VNC2017M.v3dpbd
# Check for properties files
assertExists REG_JRC2018_MALE_63x.properties
assertExists REG_UNISEX_20x.properties
assertExists REG_UNISEX_63x.properties
assertExists REG_VNC2017F.properties
assertExists REG_VNC2017M.properties
# Check for verification movie
assertExists REG_JRC2018_MALE_63x_01.mp4
assertContains REG_JRC2018_MALE_63x.properties "alignment.verify.filename=REG_JRC2018_MALE_63x_01.mp4"
# Check for specific properties
assertContains REG_JRC2018_MALE_63x.properties "alignment.resolution.voxels=0.4611220x0.4611220x0.7"

