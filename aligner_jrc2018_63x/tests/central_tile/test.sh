DIR=$(cd "$(dirname "$0")"; pwd)

TOOLS_DIR=$1
CONTAINER=$2
OUT=$3

NSLOTS=5
B1=$TEMPLATES_DIR/configured_templates
B2=$TEST_DATA_DIR

cat >$OUT/align.yml <<EOL
template_dir: $B1
inputs:
- area: Brain
  filepath: $B2/aligner_jrc2018_63x/central_tile/JRC_SS50477-20180601_25_A5.v3dpbd
  gender: f
  image_size: 1024x1024x463
  mounting_protocol: DPX PBS Mounting
  neuron_mask: $B2/aligner_jrc2018_63x/central_tile/JRC_SS50477-20180601_25_A5-ConsolidatedLabel.v3dpbd
  num_channels: 4
  objective: 63x
  ref_channel: 4
  voxel_size: 0.19x0.19x0.38
EOL

if [[ -e $OUT/stdout.log ]]; then
    echo "Test was already run"
else
    bsub -K -e $OUT/stderr.log -o $OUT/stdout.log -n $NSLOTS $TOOLS_DIR/scripts/testAligner.sh \
        "singularity run -B $B1 -B $B2 --app align_both_ol_missing $CONTAINER" $NSLOTS $OUT $OUT/align.yml debug
fi

. $TOOLS_DIR/scripts/asserts.sh $OUT
assertExists REG_JFRC2010_40x.v3dpbd
assertExists REG_JFRC2013_40x.v3dpbd
assertExists REG_JRC2018_FEMALE_40x.v3dpbd
assertExists REG_UNISEX_40x.v3dpbd
assertExists REG_UNISEX_ColorMIP_HR.v3dpbd
assertContains REG_JFRC2010_40x.properties "alignment.image.size=1024x512x218"
assertContains REG_JFRC2010_40x.properties "alignment.resolution.voxels=0.62x0.62x1.00"
assertContains REG_JFRC2013_40x.properties "alignment.image.size=1184x592x218"
assertContains REG_JFRC2013_40x.properties "alignment.resolution.voxels=0.4653716x0.4653716x0.76"
assertContains REG_JRC2018_FEMALE_40x.properties "alignment.image.size=1427x664x413"
assertContains REG_JRC2018_FEMALE_40x.properties "alignment.resolution.voxels=0.44x0.44x0.44"
assertContains REG_UNISEX_40x.properties "alignment.image.size=1427x668x394"
assertContains REG_UNISEX_40x.properties "alignment.resolution.voxels=0.44x0.44x0.44"
assertContains REG_UNISEX_ColorMIP_HR.properties "alignment.image.size=1210x566x174"
assertContains REG_UNISEX_ColorMIP_HR.properties "alignment.resolution.voxels=0.5189161x0.5189161x1.0"

