# Contributing Tools

The purpose of this repository is to serve as a central resource for tools which are productionized in JACS. Containerization and standardization has several benefits:
1. The tools will work independent of their environment, and are not affected by infrastructure changes
2. Versioning is enforced, and changes can be easily tracked
3. It's easier for scientists and programmers who are unfamiliar with the JACS architecture to add new tools and algorithms to the pipelines
4. Secondary results are always 100% reproducible by using a consistent version of the tool

## Creating a New Tool

Creating a new tool in the Workstation is simple:

1. Create a subdirectory in this repository with your tool name. Follow the naming conventions: all lower case, separated by underscores, the first word should be either "imgproc" for image processing or "aligner" for image alignment. 

2. Add all of your code inside the subdirectory. Whenever possible, include source code to build, instead of binaries. Any source code should be built inside the container, during the container build.

3. Create a file called `Singularity` recipe file which describes how to build your tool into a container. Singularity has [good documentation](http://singularity.lbl.gov/docs-recipes), and you can use the other existing tools in this repo as examples. You must define a VERSION in your Singularity, as well as one or more "apps", which will serve as entry points into your container.

4. Create a ContainerizedService within the JACS database (i.e. in the "containerizedService" collection) with the following properties:
    * **name** - Name of the tools, must match the name of your tool subdirectory.
    * **version** - Current version number, must match the version number in your Singularity file.
    * **description** - A text description of what the service does.
    * **harnessClass** - The fully qualified name of the Java Class that will call your tool. See [Harness Classes](#harness-classes) below.
    * **apps** - A list of ContainerizedApp objects listing all the possible apps in your container. Each app consists of a name and a description.

*Note: in the future, it will be possible to register your service using e a user-friendly web page, but for now it's a manual step which can be accomplished directly with MongoDB, or with the Java API.*

## Interface

There is an explicit interface defined between the pipeline and any prospective plugin tools created here. In particular, you should expect a set of inputs and produce a set of outputs as follows:

### Inputs
Your container app will be called with two arguments:
1. Path to a YAML file describing the input arguments (precise content is determined by each harness class)
2. Path of the working directory which should be used for all temporary outputs. No other directories should be used for output, not even /tmp. 

### Outputs
Any final outputs should be created within the working directory, under a subdirectory called `FinalOuputs`. For every output there must be a .properties file. The precise content (e.g. properties) defined by the properties file are determined by the harness. 

### Environment
Before your container is run, an XVFB session is started just in case some of your tools cannot be run headlessly. A working directory is created on NFS.

When your container is run, the following environment variables are guaranteed to be set:
1. `NSLOTS` - number of CPU cores which can be utilized
2. `XVFB_PORT` - port on which an XVFB (virtual framebuffer) session is running
3. `XVFB_PID` - PID of the XVFB process

## Harness Classes

Harness classes specify the precise content of the input and output files described above. The following harness classes are currently available:

### org.janelia.it.jacs.compute.service.align.ConfiguredAlignmentService

The input is a YAML file containing a template directory with all the brain templates, and an array of one input stack. The input stack has some metadata as in the example below.

```
template_dir: /nrs/jacs/jacsData/AlignTemplates/configured_templates
inputs:
- area: Brain
  filepath: /groups/jacs/jacsDev/devstore/wolfft/Sample/471/061/2561318836544471061/merge/tile-2561318837219754005.v3dpbd
  gender: f
  image_size: 1024x1024x138
  mounting_protocol: DPX PBS Mounting
  neuron_mask: /groups/jacs/jacsDev/devstore/wolfft/Separation/690/325/2561320402030690325/separate/ConsolidatedLabel.v3dpbd
  num_channels: 4
  objective: 20x
  ref_channel: 4
  voxel_size: 0.52x0.52x1.00
```

Note that there are standard functions for parsing this file format into Bash variables in the common.sh file found in any existing aligner.

## org.janelia.it.jacs.compute.service.align.ConfiguredVNCAlignmentService

Same as ConfiguredAlignmentService, but the input is a VNC image.

## org.janelia.it.jacs.compute.service.align.ConfiguredPairAlignmentService

Same as ConfiguredAlignmentService, but there are two inputs. The first is a 20x brain for reference purposes and the second is the 63x brain to align.

