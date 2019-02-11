run("Misc...", "divide=Infinity save");
testArg=0
//testArg="/test/,tile-2580114806669312021_01.nrrd,/test/20x_brain_alignment/fail/tile-2580114806669312021_01.nrrd";
setBatchMode(true);

if(testArg!=0)
args = split(testArg,",");
else
args = split(getArgument(),",");

savedir = args[0];// save dir
filename = args[1];//file name
path = args[2];// full file path for inport LSM

open(path);
run("A4095 normalizer", "subtraction=0 start=1 end="+nSlices+"");

run("Nrrd Writer", "nrrd="+savedir+filename);

run("Misc...", "divide=Infinity save");
run("Quit");
