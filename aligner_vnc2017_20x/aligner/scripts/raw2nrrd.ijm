name = getArgument;
if (name=="") exit ("No argument!");
setBatchMode(true);
run("raw reader", "open=" + name);
path = replace(name, ".raw", "");
run("Split Channels");
run("Nrrd ... ", "nrrd=[./" + path + "_C2.nrrd]");
close();
run("Nrrd ... ", "nrrd=[./" + path + "_C1.nrrd]");
close();
run("Quit");

