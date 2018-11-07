testArg=0;
run("Misc...", "divide=Infinity save");

if(testArg!=0)
args = split(testArg,",");
else
args = split(getArgument(),",");

path = args[0];// save dir

open(path);

run("Nrrd Writer", "compressed nrrd="+path);


run("Z Project...", "projection=[Max Intensity]");
run("Enhance Contrast", "saturated=0.3");
run("Apply LUT");
run("8-bit");

saveAs("PNG", halfpath+"_MIP.png");
close();


run("Misc...", "divide=Infinity save");
run("Quit");