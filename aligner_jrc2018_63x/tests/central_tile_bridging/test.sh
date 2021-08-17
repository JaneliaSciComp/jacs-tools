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
    set -x
    bsub -K $LSF_OPTS -e $OUT/stderr.log -o $OUT/stdout.log -n $NSLOTS $TOOLS_DIR/scripts/testAligner.sh \
        "singularity run -B $B1 -B $B2 --app align_bridging $CONTAINER" $NSLOTS $OUT $OUT/align.yml debug
    set +x
fi

. $TOOLS_DIR/scripts/asserts.sh $OUT
assertExists REG_JFRC2010_20x.v3dpbd
assertExists REG_JFRC2013_63x.v3dpbd
assertExists REG_JRC2018_FEMALE_63x.v3dpbd
assertExists REG_UNISEX_63x.v3dpbd
assertExists REG_UNISEX_ColorMIP_HR.v3dpbd
assertContains REG_JFRC2010_20x.properties "alignment.image.size=1024x512x218"
assertContains REG_JFRC2010_20x.properties "alignment.resolution.voxels=0.62x0.62x1.00"
assertContains REG_JFRC2013_63x.properties "alignment.image.size=1450x725x436"
assertContains REG_JFRC2013_63x.properties "alignment.resolution.voxels=0.38x0.38x0.38"
assertContains REG_JRC2018_FEMALE_63x.properties "alignment.image.size=3333x1550x478"
assertContains REG_JRC2018_FEMALE_63x.properties "alignment.resolution.voxels=0.1882680x0.1882680x0.38"
assertContains REG_UNISEX_63x.properties "alignment.image.size=1652x773x456"
assertContains REG_UNISEX_63x.properties "alignment.resolution.voxels=0.38x0.38x0.38"
assertContains REG_UNISEX_ColorMIP_HR.properties "alignment.image.size=1210x566x174"
assertContains REG_UNISEX_ColorMIP_HR.properties "alignment.resolution.voxels=0.5189161x0.5189161x1.0"

