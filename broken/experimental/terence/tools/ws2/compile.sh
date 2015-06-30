#!/usr/bin/bash
base_dir="C:/cygwin/home/terence/projects/broken/experimental/terence/tools/ws2"
compile_bin_dir="$base_dir/bin"
if [ -d $compile_bin_dir ]; then
	/usr/bin/rm -rf $compile_bin_dir/*
else
	/usr/bin/mkdir $compile_bin_dir
fi
/usr/bin/cp $base_dir/src/gui/*.fig $compile_bin_dir/
##############################################################################
FILELIST=$(c:/cygwin/bin/find.exe ./src/ -iname '*.m')
for eachfile in $FILELIST
do
    /usr/bin/cp $eachfile $compile_bin_dir/
done
if [ "$1" == "cg" ]; then
    cd $base_dir
    NEWLIST=$(c:/cygwin/bin/find.exe . -iname '*.m' -printf \ %f)
    for eachfile in $NEWLIST
    do
	./tools/substring '% COMPILE %' '' $compile_bin_dir/$eachfile > $compile_bin_dir/temp
	/usr/bin/cp $compile_bin_dir/temp $compile_bin_dir/$eachfile
    done
fi


