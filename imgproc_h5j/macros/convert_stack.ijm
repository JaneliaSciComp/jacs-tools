/*
 * Convert a file to a support output format, optionally splitting each channel into a separate file. 
 */
var args = split(getArgument(),",");
var inputFile = args[0];
var outputFile = args[1];
var splitChannels = args[2];

if (indexOf(inputFile, "/")<0 || indexOf(outputFile, "/")<0) {
    print("Paths must be fully qualified");
    run("Quit");
}

inputFilename = File.getName(inputFile);
inputBasename = substring(inputFilename, 0, indexOf(inputFilename, "."));
print("inputFile: "+inputFile);
print("inputFilename: "+inputFilename);
print("inputBasename: "+inputBasename);

outputFilename = File.getName(outputFile);
outDir = substring(outputFile, 0, lastIndexOf(outputFile, "/"));
format = substring(outputFilename, indexOf(outputFilename, ".")+1);
print("outputFile: "+outputFile);
print("outputFilename: "+outputFilename);
print("outputDir: "+outDir);
print("outputFormat: "+format);
print("splitChannels: "+splitChannels);

open(inputFile);
title = getTitle();
getDimensions(width, height, channels, slices, frames);

if (splitChannels=="1") {
    run("Split Channels");
    for(c=0; c<channels; c++) {
        selectWindow("C"+(c+1)+"-"+title);
        run("Grays");
        saveCurrentWindow(format, outDir+"/"+inputBasename+"_c"+c+"."+format);  
    }
}
else {
    saveCurrentWindow(format, outDir+"/"+inputBasename+"."+format);
}

print("Done");
run("Close All");
run("Quit");

function saveCurrentWindow(format, outfile) {
    print("Saving "+outfile);
    if (format=='nrrd') {
        run("Nrrd Writer", "compressed nrrd="+outfile);
    }
    else if (format=='tif' || format=='tiff') {
        saveAs("Tiff", outfile);
    }
    else if (format=='v3draw') {
        run("V3Draw...", "save=[" + outfile +"]");
    }
    else if (format=='h5j') {
        run("H5J Writer", "save="+outfile+" threads="+numThreads);
    }
    else {
        print("Unsupported output format: "+format);
        run("Quit");
    }
    close();
}
