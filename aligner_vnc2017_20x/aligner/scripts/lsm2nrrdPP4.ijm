
name = getArgument;
if (name=="") exit ("No argument!");
parts=split(name,"/");
filename = "";
filename = parts[parts.length-1];
setBatchMode(true);

Angle = 45; // leave positive - rotation direction automated.
Ymove = (-300);
Xmove = 0;

//run("LSM Reader", "open=[" + name + "]");
open(name);
wait(800);
ch1 = replace(filename, ".lsm", "-PP_C1.nrrd");
ch2 = replace(filename, ".lsm", "-PP_C2.nrrd");
logfile = replace(filename, ".lsm", "-PP_Meta.log");
run("Split Channels");
wait(800);
slices = 0;
// we need to know only how many slices there are
getDimensions(dummy, dummy, dummy, slices, dummy);
run("Grouped Z Project...", "projection=[Max Intensity] group="+slices);
wait(300);
getMinAndMax(hmin, hmax);
wait(100);
levlog="Ch2:"+d2s(hmin,0)+","+d2s(hmax,0);
print ("Original background (min,max): " + d2s(hmin,0) + "," + d2s(hmax,0));
run("Enhance Contrast", "saturated=0.35");
wait(300);
getMinAndMax(hmin, hmax);
wait(100);
levlog=levlog+"->"+d2s(hmin,0)+","+d2s(hmax,0)+".";
print ("Adjusted to (min,max): " + d2s(hmin,0) + "," + d2s(hmax,0));

// check which channel is BG
getStatistics(dummy, C2m);
// check rotation direction
Iw = getWidth();
Ih = getHeight();
Imp = round(Iw/2);
Itp = round(Ih/10);
Iw = Iw -1;
makeRectangle(1, 1, Imp, Itp);
getStatistics(dummy, Lm);
makeRectangle(Imp, 1, Iw, Itp);
getStatistics(dummy, Rm);
if (Lm > Rm){
    Angle = Angle;
    print ("rotating clockwise " + d2s(Angle,0) + "degrees");
}else{
    print ("rotating anti-clockwise " + d2s(Angle,0) + "degrees");
    Angle = (360 - Angle);
}

close();
wait(300);
setMinAndMax(hmin, hmax);
wait(300);
run("Rotate... ", "angle=Angle grid=1 interpolation=Bilinear enlarge stack"); //remove diagonal tilt
wait(800);

// trial measure
run("Translate...", "x=Xmove y=Ymove interpolation=None stack");
levlog=levlog+"[A:" + d2s(Angle,0) + "e,Y:" + d2s(Ymove,0) + ",X:" + d2s(Xmove,0) + "]";

wait(300);
run("8-bit");
wait(300);
run("Nrrd ... ", "nrrd=[./" + ch2 + "]");
wait(800);
close();
wait(100);
run("Grouped Z Project...", "projection=[Max Intensity] group="+slices);
wait(300);
getMinAndMax(hmin, hmax);
wait(100);
levlog=levlog+"Ch1:"+d2s(hmin,0)+","+d2s(hmax,0);
print ("Original signal (min,max): " + d2s(hmin,0) + "," + d2s(hmax,0));
run("Enhance Contrast", "saturated=0.35");
wait(300);
getMinAndMax(hmin, hmax);
wait(100);
levlog=levlog+"->"+d2s(hmin,0)+","+d2s(hmax,0)+".";
print ("Adjusted to (min,max): " + d2s(hmin,0) + "," + d2s(hmax,0));

// check which channel is BG
getStatistics(dummy, C1m);

close();
wait(300);
setMinAndMax(hmin, hmax);
wait(300);
run("Rotate... ", "angle=Angle grid=1 interpolation=Bilinear enlarge stack"); //remove diagonal tilt
wait(800);

// trial measure
run("Translate...", "x=Xmove y=Ymove interpolation=None stack");
levlog=levlog+"[A:" + d2s(Angle,0) + "e,Y:" + d2s(Ymove,0) + ",X:" + d2s(Xmove,0) + "]";

// rename according to mean values (largest = BG)
nCh2 = ch2;
nCh1 = ch1;
if (C2m > C1m){
    levlog=levlog+"(Ch2 is BG)";
    print ("BG: C2");
    print ("SG: C1");
    nCh2 = replace(ch2, "PP_C2", "PP_BG");
    nCh1 = replace(ch1, "PP_C1", "PP_SG");
}else{
    levlog=levlog+"(Ch1 is BG)";
    print ("BG: C1");
    print ("SG: C2");
    nCh2 = replace(ch2, "PP_C2", "PP_SG");
    nCh1 = replace(ch1, "PP_C1", "PP_BG");
}

if (File.rename(ch2, nCh2) > 0){
    print ("File renamed OK.");
}else{
    print ("Files rename FAILED.");
}

wait(300);
run("8-bit");
wait(300);
run("Nrrd ... ", "nrrd=[./" + nCh1 + "]");
wait(800);
close();

File.saveString(levlog+"\r\n","./"+logfile);

run("Quit");
