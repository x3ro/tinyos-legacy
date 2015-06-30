This project contains the source files for the Boomerang Operating System,
an extension of TinyOS originally developed by Sentilla Corporation 
(formerly Moteiv Corporation). 

Boomerang is based on TinyOS 1.x with significant overlap to TinyOS 2.x.
Boomerang supports the Tmote Sky, Tmote Invent, Tmote Mini, and Tmote
Connect hardware lines.

Code in this repository is licensed under the Moteiv Public License
available at http://www.moteiv.com/MOTEIV_LICENSE.txt.  Contributions to
this code base may be licensed under terms of your choice, and files from
this code base may be used in other projects as long as the license
information remains intact.

This source tree depends on other TinyOS projects.  In particular,
it relies on:

tinyos-1.x/
tinyos-1.x/contrib/nestfe/scripts/
tinyos-1.x/contrib/ucb/

A script is included in the root directory that sets up all environment
variables assuming that the Boomerang source tree is available at
/opt/moteiv/ and the TinyOS 1.x source tree is available at
/opt/tinyos-1.x/

The tinyos-1.x/ directory within this code base overrides defaults from
the original TinyOS 1.x code base.

Anyone is welcome to contribute, use, redistribute, or maintain
this code base at will.  
