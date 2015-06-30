/*
 * Copyright (c) 2008 Trinity College Dublin.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Trinity College Dublin nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL TRINITY
 * COLLEGE DUBLIN OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

	----------------------------------------------------------------
	PowerTOSSIM-Z: Realistic Energy Modeling of MicaZ in Tossim 2.x
		    Releases in: TinyOS 2.0.2
		                 TinyOS 2.1.1
						 TinyOS 2.1.2
			https://www.cs.tcd.ie/~carbajrs/powertossimz/index.html
	----------------------------------------------------------------

****************************************************************************
For further information contact Ricardo Simon Carbajo (carbajor at {tcd.ie})
and check the paper:
    "PowerTOSSIM z: realistic energy modelling for wireless sensor network
                   environments"
		    http://portal.acm.org/citation.cfm?id=1454630.1454636
****************************************************************************

[0] - TinyOS modified code

Files to be modified or replaced in Tossim to enable PowerTOSSIM-Z energy traces
are contained under the folder tinyos_files/ for the corresponding version 
(2.0.1 || 2.1.1 || 2.1.2) of TinyOS.
List of altered/created files:
   - In tos/lib/tossim
        - ActiveMessageC.nc (changes)
		- SimSchedulerBasicP.nc (changes)
		- TinySchedulerC.nc (changes)
		- TossimPacketModelC.nc (changes) (fix bug - "duration =")
		                                  (remove sweepMe variable,
						   causing Control.startDone not
						   to be fired every second time
						   Control.start(is called,
						   thanks to Ricardo Carrano)
		- PacketEnergyEstimator.nc (new)
		- PacketEnergyEstimatorC.nc (new)
		- PacketEnergyEstimatorP.nc (new)

   - In tos/chips/at45db/sim
        - All files are new in this folder
	- Implementation of the At45dB driver by Chieh-Jan Mike Liang
	- At45db includes the code to delay Write/Read/Sync operations
	  according to measurements provided under /apps/At45dbTest

   - In tos/chips/atm128/pins/sim
        - HplAtm128GeneralIOPortP.nc (new)
		- HplAtm128GeneralIOPinP.nc (changes)

   - In tos/chips/atm128/sim
        - Atm128EnergyHandler.nc (new)
		- Atm128EnergyHandlerC.nc (new)
		- Atm128EnergyHandlerP.nc (new)
		- McuSleepC.nc (changes)

   - In support/make/sim.extra
	- Added "build_storage" to the sim-exe line to build required flash .h file

   - In tos/platforms/micaz/sim/.platform
        - Include in the includes directories, the location of the at45db code
	       required to compile. i.e.
		    %T/platforms/mica2/chips/at45db
		    %T/platforms/mica/chips/at45db
		    %T/chips/at45db


Only from TinyOS version 2.1.1, the preprocessor directive "POWERTOSSIMZ" has
been included for all the changes. Just add in the makefile: 
CFLAGS += -DPOWERTOSSIMZ to enable it and start logging from the channel 
"ENERGY_HANDLER".

Under the folder apps/, you can find the RadioCountsToLeds application and 
configuration files to run it, including noise and topologies. Note that the 
makefile needs to include the directive POWERTOSSIMZ. It also includes a .py 
script to start the simulation after the application is compiled 
"make micaz sim". The .py scripts outputs the energy trace produced by PT-Z in 
the folder Simulations/ as Energy.txt. This is the file which will be analysed
by the postprocessor [1].

Also under the folder apps/, a modified application to write and read to/from 
the flash memory (/At45dbTest) is included. In this folder you can find real 
measurements of the time to write and read, to and from, the at45db flash
chip in a micaz mote. These times establish the delay per operation/bytes in 
the at45db simulator driver. Check the file postprocessZ/micaz_energy_model.txt
to modify the current consumed in every operation.

NOTE: This version of PowerTossimZ is configured to go to CPU POWERDOWN state
when the mote goes to sleep. The default CPU state in Tossim when sleeping
is CPU IDLE. To change this behaviour, you can modify the McuSleepC.nc file,
specifically at the function "McuPowerOverride.lowestState".


[1] - The postprocessor

In the postprocessZ/ directory you can find the postprocessor script employed
to analyse the energy trace generated in the simulation. This script produces
the partials and totals values of energy consumed per node in the network.
Just run:

     python postprocessZ.py

to have a quick view of all the commands available.
The trace files we used are also included (if you want to test them directly) 
and our micaz battery model.

If you add the switch --powercurses, the postprocessor outputs data suitable
for PowerCURSES parsing.

    python postprocessZ.py --powercurses Energy.txt > EnergyPowerCurses.txt


[2] - PowerCURSES

In the powercurses/ directory you can find the the PowerCURSES implementation,
employed to graphically visualize the battery level in each node as the energy
trace is analysed. It uses the ncurses library.
It is normally run in pipe with the postprocessor, but if you want to test
it quickly you can run it with the powertest.txt file, i.e. a saved output 
from the postprocessor) :

    cat EnergyPowerCurses.txt | ./powercurses 11

As you see from the example you have to pass powercurses the number of
motes involved in the simulation.






