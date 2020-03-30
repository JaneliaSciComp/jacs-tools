DIR=$(cd "$(dirname "$0")"; pwd)

TOOLS_DIR=$1
CONTAINER=$2
OUT=$3

NSLOTS=3
B1=$TEMPLATES_DIR/configured_templates
B2=$TEST_DATA_DIR

cat >$OUT/align.yml <<EOL
template_dir: $B1
inputs:
- area: Brain
  filepath: $B2/aligner_jrc2018_20x_gen1/tests/female_mcfo/JRC_SS44601-20181214_19_C4.v3dpbd
  gender: f
  image_size: 1024x1024x134
  mounting_protocol: DPX PBS Mounting
  neuron_mask: $B2/aligner_jrc2018_20x_gen1/tests/female_mcfo/JRC_SS44601-20181214_19_C4-ConsolidatedLabel.v3dpbd
  num_channels: 4
  objective: 20x
  ref_channel: 4
  voxel_size: 0.52x0.52x1.00
  tiles:
  - brain
EOL

if [[ -e $OUT/stdout.log ]]; then
    echo "Test was already run"
else
    bsub -K -e $OUT/stderr.log -o $OUT/stdout.log -n $NSLOTS $TOOLS_DIR/scripts/testAligner.sh \
        "singularity run -B $B1 -B $B2 --app align_ol_unknown_bridging $CONTAINER" $NSLOTS $OUT $OUT/align.yml debug
fi

. $TOOLS_DIR/scripts/asserts.sh $OUT
assertExists REG_JFRC2010_20x_HR.v3dpbd
assertExists REG_JFRC2013_20x_HR.v3dpbd
assertExists REG_JRC2018_FEMALE_20x_HR.v3dpbd
assertExists REG_JRC2018_FEMALE_20x_HR_ConsolidatedLabel.v3dpbd
assertExists REG_UNISEX_20x_HR.v3dpbd
assertExists REG_UNISEX_20x_HR_ConsolidatedLabel.v3dpbd
assertContains REG_JFRC2010_20x_HR.properties "alignment.image.size=1024x512x218"
assertContains REG_JFRC2010_20x_HR.properties "alignment.resolution.voxels=0.62x0.62x1.00"
assertContains REG_JFRC2010_20x_HR.properties "alignment.bridged.from=REG_JRC2018_FEMALE_20x_HR.v3dpbd"
assertContains REG_JFRC2013_20x_HR.properties "alignment.image.size=1184x592x218"
assertContains REG_JFRC2013_20x_HR.properties "alignment.resolution.voxels=0.4653716x0.4653716x0.76"
assertContains REG_JRC2018_FEMALE_20x_HR.properties "alignment.image.size=1210x563x182"
assertContains REG_JRC2018_FEMALE_20x_HR.properties "alignment.resolution.voxels=0.5189161x0.5189161x1.0"
assertContains REG_UNISEX_20x_HR.properties "alignment.image.size=1210x566x174"
assertContains REG_UNISEX_20x_HR.properties "neuron.masks.filename=REG_UNISEX_20x_HR_ConsolidatedLabel.v3dpbd"
assertContains REG_UNISEX_20x_HR.properties "alignment.bridged.from=REG_JRC2018_FEMALE_20x_HR.v3dpbd"

