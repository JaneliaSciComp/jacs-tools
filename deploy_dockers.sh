#!/bin/bash

if [ -z "$JACS_SINGULARITY_DIR" ]; then
  echo "Set the JACS_SINGULARITY_DIR environment variable to the directory where containers will be deplo  yed"
  exit 1
fi

echo "Deploying to $JACS_SINGULARITY_DIR"

#singularity build -F /tmp/out.sif docker://janeliascicomp/vaa3d:redhat-mark13
#cp /tmp/out.sif $JACS_SINGULARITY_DIR/vaa3d-redhat-mark13.img

V=1.4.0
singularity build -F /tmp/out.sif docker-daemon://janeliascicomp/flylight_tools:$V
cp /tmp/out.sif $JACS_SINGULARITY_DIR/flylight_tools-$V.img

#singularity build -F /tmp/out.sif docker://registry.int.janelia.org/jacs/jacs-storage:1.19.2
#cp /tmp/out.sif $JACS_SINGULARITY_DIR/jacs-storage-1.19.2.img

#V=1.0.5
#singularity build -F /tmp/out.sif docker://registry.int.janelia.org/jacs-scripts/flylight_perl:1.0.5
#cp /tmp/out.sif $JACS_SINGULARITY_DIR/flylight_perl-1.0.5.img

#singularity build -F /tmp/out.sif docker://janeliascicomp/neusep_flylight:1.0.0
#cp /tmp/out.sif $JACS_SINGULARITY_DIR/neusep_flylight-1.0.0.img

