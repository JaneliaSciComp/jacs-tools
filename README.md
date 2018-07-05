# JACS Tools

This repository contains tools which JACS runs on the cluster to process data.

Each sub directory contains a single tool which can be built into a Singularity container.

## Build
To build one or more tools:
```
./manage.sh build [tool1] [tool2] [tool3] ...
```
This creates a set of corresponding img files in the build directory which can be run with Singularity.

## Shell
To open a shell into a built container:
```
./manage.sh shell [tool]
```

## Deploy
To deploy a built container to another location, you must first define the target location in your environment, 
e.g. in your ~/.bashrc file:
```
export JACS_SINGULARITY_DIR=/groups/jacs/jacsDev/servers/jacs-data/executables/singularity
```

Then
```
./manage.sh deploy [tool1] [tool2] [tool3] ...
```

## Clean
You can delete existing builds for one or more containers with the ```clean``` command:
```
./manage.sh clean [tool1] [tool2] [tool3] ...
```

## Versioning
Container versioning is done in the Singularity build file. When making changes to a container, make sure to increment the
VERSION variable in the Singularity file before building or deploying that container.

## Run
To use container named <container.img> which contains an app called <appName> you can invoke Singularity as follows. 
```
B1=/external/path1
B2=/external/path2
singularity run -B $B1 -B $B2 --app appName container.img -i $B1 -o $B2
```
All external paths which the container needs to access must be mounted with -B flags.

