There are several types of files in this directory, comprising the fly alignment pipelines.

They breakdown as follows:

-------------------
Configuration files
-------------------

    systemvars.apconf

--------------
Common scripts
--------------

    common.sh
    createVerificationMovie.sh
    rescaleIntensityRange.sh

-------------------
Alignment pipelines
-------------------

    The scripts are organized by input file objective. Outputs are indicated by the output
    file objective. Any output that also has an associated warped label file is marked warping.
    Objective outputs without warped neurons are marked with a question mark.

    [20x]

        flyalign20x_dpx_1024px_INT.sh (20x/warping)
            brainalignPolarity20xBrainVNCRescale_dpx.sh (20x/warping)

        flyalign20x_JBA_Qiscore.sh (20x/?)

        flybrainaligner20x_ditp_JBA.sh (20x/warping)

    [40x]

        brainalign63xFlpout_1024px_INT.sh (20x/warping, 63x/warping)
        brainalign63xFlpout_512px_INT.sh (20x/warping, 63x/warping)
        brainalign63xLexAGAL4_1024px_INT.sh (20x/warping, 63x/warping)
        brainalign63xLexAGAL4_512px_INT.sh (20x/warping, 63x/warping)

    [63x]

        brainalignPolarityPair_ds_dpx_1024px_INT_v3.sh (20x/warping, 63x/warping)
        flyrightopticlobealign_512px_INT_MT.sh (20x/warping, 63x/warping)
            flyleftopticlobealign_512px_INT_MT.sh (20x/warping, 63x/warping)

---------------
Transformations
---------------

    transformYtoA_leftopticlobe_63x.sh
    transformYtoA_rightopticlobe_63x.sh



