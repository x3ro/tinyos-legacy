TinyOS CVS repository of the Vanderbilt/ISIS Nest project.

Contact: janos.sallai@vanderbilt.edu (Janos Sallai, ISIS, Vanderbilt)
	 miklos.maroti@vanderbilt.edu (Miklos Maroti, ISIS, Vanderbilt)

 
Please check out the whole directory structure to a separate directory. Do not overwrite
your existing tinyos-1.x directory, even though the directory names are the same.
Set the VUTOS environment variable to wherever your contrib/vu/tos directory is. For
example, type at the bash shell:

    export VUTOS=/opt/tinyos-1.x/contrib/vu/tos
    
You can compile the sample applications in place. The apps/Makerules are modified to
automatically include the Vanderbilt specific tos/* directories. 

If you want to use our components in your project, then create another separate directory 
(for example VU) and copy all the files you need into that directory. You have to pick 
the right components for your platform manually. (Or do some makefile magic). 
