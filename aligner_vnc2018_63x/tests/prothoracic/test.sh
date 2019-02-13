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
assertExists REG_JRC2018_MALE_VNC_63x.v3dpbd
assertExists REG_UNISEX_VNC_20x.v3dpbd
assertExists REG_UNISEX_VNC_63x.v3dpbd
assertExists REG_oldVNC_FEMALE.v3dpbd
assertExists REG_oldVNC_MALE.v3dpbd
#assertContains REG_JFRC2010_40x.properties "alignment.image.size=1024x512x218"
#assertContains REG_JFRC2010_40x.properties "alignment.resolution.voxels=0.62x0.62x1.00"
#assertContains REG_JFRC2013_40x.properties "alignment.image.size=1184x592x218"
#assertContains REG_JFRC2013_40x.properties "alignment.resolution.voxels=0.4653716x0.4653716x0.76"
#assertContains REG_JRC2018_FEMALE_40x.properties "alignment.image.size=1427x664x413"
#assertContains REG_JRC2018_FEMALE_40x.properties "alignment.resolution.voxels=0.44x0.44x0.44"
#assertContains REG_UNISEX_40x.properties "alignment.image.size=1427x668x394"
#assertContains REG_UNISEX_40x.properties "alignment.resolution.voxels=0.44x0.44x0.44"
#assertContains REG_UNISEX_ColorMIP_HR.properties "alignment.image.size=1210x566x174"
#assertContains REG_UNISEX_ColorMIP_HR.properties "alignment.resolution.voxels=0.5189161x0.5189161x1.0"

