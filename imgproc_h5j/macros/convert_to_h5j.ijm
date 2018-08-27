//
// Converts the given stack into an H5J file.
// Example arguments:
//   "/input/file.v3dpbd,/output/path/for/file.h5j"
//
setBatchMode(true);

var numThreads = 8;
var arg = getArgument();
var args = split(arg,",");
var numArgs = lengthOf(args);
if (numArgs<2) exit("Macro requires at least 2 arguments, got: "+arg);

var input = args[0];
var h5jfile = args[1];
open(input);
//run("Janelia H265 Writer", "save="+h5jfile);
run("H5J Writer", "save="+h5jfile+" threads="+numThreads);

print("Done");
close();
run("Quit");
