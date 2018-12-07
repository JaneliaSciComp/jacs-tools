testArg=0;
run("Misc...", "divide=Infinity save");

if(testArg!=0)
args = split(testArg,",");
else
args = split(getArgument(),",");

path = args[0];// save dir

open(path);

run("Nrrd Writer", "compressed nrrd="+path);



run("Misc...", "divide=Infinity save");
run("Quit");