//
// Converts a set of nrrd single channel files into a v3draw file. 
// Example arguments:
//   "/output/path/for/v3draw/file,/input/ch1.nrrd,input/ch2.nrrd"
//
setBatchMode(true);

var arg = getArgument();
var args = split(arg,",");
var numArgs = lengthOf(args);
if (numArgs<2) exit("Macro requires at least 2 arguments, got: "+arg);

var s = "";
var rawfile = args[0];
for (i=1; i<numArgs; i++) {
    nrrdpath = args[i];
    print("Channel "+i+": "+nrrdpath);
    run("Nrrd ...", "load=[" + nrrdpath + "]");
    var name = File.getName(nrrdpath);
    s += "c"+i+"="+name+" ";
}

s += "create ignore";
print("Merge Channels... "+s);
run("Merge Channels...", s);
run("V3Draw...", "save=[" + rawfile +"]");

print("Done");
close();
run("Quit");
