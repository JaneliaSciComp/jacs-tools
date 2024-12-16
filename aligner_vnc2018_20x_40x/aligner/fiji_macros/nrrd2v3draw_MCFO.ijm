args = split(getArgument,",");//"/test/VNC_Test/AlignedFlyVNC.v3draw";

v3dpath=args[0];
fullpath=args[1];

print("fullpath; "+fullpath);

if (fullpath=="") exit ("No argument!");
setBatchMode(true);

ch1 = replace(fullpath, "AlignedFlyVNC.v3draw", "VNC-PP-BGwarp.nrrd");
ch2 = replace(fullpath, "AlignedFlyVNC.v3draw", "VNC-PP-SGwarp1.nrrd");
ch3 = replace(fullpath, "AlignedFlyVNC.v3draw", "VNC-PP-SGwarp2.nrrd");
ch4 = replace(fullpath, "AlignedFlyVNC.v3draw", "VNC-PP-SGwarp3.nrrd");

ch1exi=File.exists(ch1);
if(ch1exi==1){
	print("Channel 1: "+ch1);
	run("Nrrd ...", "load=[" + ch1 + "]");
}
ch2exi=File.exists(ch2);
if(ch2exi==1){
	print("Channel 2: "+ch2);
	run("Nrrd ...", "load=[" + ch2 + "]");
}
ch3exi=File.exists(ch3);
if(ch3exi==1){
	print("Channel 3: "+ch3);
	run("Nrrd ...", "load=[" + ch3 + "]");
}
ch4exi=File.exists(ch4);
if(ch4exi==1){
	run("Nrrd ...", "load=[" + ch4 + "]");
	print("Channel 4: "+ch4);
}

if(ch4exi==0 && ch3exi==0 && ch2exi==1 && ch1exi==1)
run("Merge Channels...", "c1=VNC-PP-BGwarp.nrrd c2=VNC-PP-SGwarp1.nrrd create ignore");
else if(ch4exi==0 && ch3exi==1 && ch2exi==1 && ch1exi==1)
run("Merge Channels...", "c1=VNC-PP-SGwarp1.nrrd c2=VNC-PP-SGwarp2.nrrd c3=VNC-PP-BGwarp.nrrd create ignore");
else if(ch4exi==1 && ch3exi==1 && ch2exi==1 && ch1exi==1)
run("Merge Channels...", "c1=VNC-PP-SGwarp1.nrrd c2=VNC-PP-SGwarp2.nrrd c3=VNC-PP-SGwarp3.nrrd c4=VNC-PP-BGwarp.nrrd create ignore");

run("V3Draw...", "save=[" + v3dpath +"]");

logsum=getInfo("log");

	
print("fullpath; "+fullpath);

filesepindex = lastIndexOf(fullpath,"/");

logpath=substring(fullpath,0,filesepindex+1);
	
File.saveString(logsum, logpath);


run("Quit");
