fullpath = getArgument;
if (fullpath=="") exit ("No argument!");
setBatchMode(true);
ch1 = replace(fullpath, "AlignedFlyVNC.v3draw", "VNC-PP-BGwarp.nrrd");
ch2 = replace(fullpath, "AlignedFlyVNC.v3draw", "VNC-PP-SGwarp.nrrd");
print("Channel 1: "+ch2);
print("Channel 2: "+ch1);
run("Nrrd ...", "load=[" + ch1 + "]");
run("Nrrd ...", "load=[" + ch2 + "]");
run("Merge Channels...", "c1=VNC-PP-BGwarp.nrrd c2=VNC-PP-SGwarp.nrrd create ignore");
run("V3Draw...", "save=[" + fullpath +"]");

close();
run("Quit");
