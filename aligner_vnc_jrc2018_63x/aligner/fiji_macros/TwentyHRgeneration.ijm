
run("Misc...", "divide=Infinity save");

testArg=0;

//testArg="H:/Registration2/63x_align/reformatted/,Temp1_PRE_PROCESSED_01_warp_m0g80c8e1e-1x26r4.nrrd,H:/Registration2/63x_align/reformatted/Temp1_PRE_PROCESSED_01_warp_m0g80c8e1e-1x26r4.nrrd,N:/test_folder/JRC_SS23221_20160803_31_E5translation.txt,1";
setBatchMode(true);

if(testArg!=0)
args = split(testArg,",");
else
args = split(getArgument(),",");

savedir = args[0];// save dir
inumber = args[1];//file name
VolPath = args[2];//file path


print("savedir; "+savedir);
print("inumber; "+inumber);
print("VolPath; "+VolPath);


titlelistOri=getList("image.titles");
IJ.redirectErrorMessages();
open(VolPath);

titlelistAfter=getList("image.titles");

if(titlelistOri.length == titlelistAfter.length){
	print("The file cannot open; "+VolPath);
	logsum=getInfo("log");
	File.saveString(logsum, savedir+"TwentyHRgeneration.txt");
	
	run("Quit");
}


print("Opened; "+VolPath);
logsum=getInfo("log");
logpath=savedir+"TwentyHRgeneration.txt";
File.saveString(logsum, logpath);


run("Size...", "width=1210 height=566 depth=174 interpolation=Bicubic");
run("Unsharp Mask...", "radius=0.5 mask=0.60 stack");

run("Nrrd Writer", "compressed nrrd="+savedir+"/"+"REG_UNISEX_20x_HR_0"+inumber+".nrrd");

close();



run("Misc...", "divide=Infinity save");
run("Quit");











