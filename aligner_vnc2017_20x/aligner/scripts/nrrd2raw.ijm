fullpath = getArgument;
if (fullpath=="") exit ("No argument!");
setBatchMode(true);
ch1 = replace(fullpath, "warp.raw", "SGwarp.nrrd");
ch2 = replace(fullpath, "warp.raw", "BGwarp.nrrd");
print("Channel 1: "+ch1);
print("Channel 2: "+ch2);
run("Nrrd ...", "load=[" + ch1 + "]");
run("Nrrd ...", "load=[" + ch2 + "]");
run("Merge Channels...", "c1=" + ch1 + " c2=" + ch2 + " create ignore");


run("raw writer", "save=[" + fullpath +"]");


close();
run("Quit");

