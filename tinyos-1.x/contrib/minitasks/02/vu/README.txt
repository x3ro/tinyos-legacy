TinyOS CVS repository of the Vanderbilt/ISIS Nest project.

Contact: miklos.maroti@vanderbilt.edu (Miklos Maroti, ISIS, Vanderbilt)

Please check out the whole directory structure to a separate directory. Do not overwrite
your existing tinyos-1.x directory, even though the directory names are the same.
You can compile the sample applications in place. The apps/Makerules are modified to
automatically include the Vanderbilt specific tos/* directories. 

If you want to use our components in your project, then create another separate directory 
(for example VU) and copy all the files you need into that directory. You have to pick 
the right components for your platform manually. (Or do some makefile magic). 
Put the following line into your makefile

	PFLAGS = -I../VU

This will tell the ncc compiler to use the Vanderbilt specific components instead of 
the native ones.
