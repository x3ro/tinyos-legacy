$Id: README.txt,v 1.1 2005/04/13 17:10:57 hjkoerber Exp $


* General

This contrib directory contains the basic port of TinyOS 1.1.5 to the commercial
Microchip PIC18F452 based platform TCM 120. 
We implemented the following TinyOS modules:
	  - radio interface (ASK, 120Kbps)
          - Uart
	  - ADC
	  - Timer
	  - PowerManagement

Besides this contrib directory contains the update of the MCU to the 
Microchip PIC18F4620 on which we are focussing now. 

This port has been done by Hans-Joerg Koerber and Housam Wattar,Electrical 
Measurement Engineering Department at the Helmut-Schmidt-University,Hamburg. 
See http://http://www.hsu-hh.de/emt/ for more information.

The hardware TCM 120  has been developed by  EnOcean GmbH. More information 
about this hardware can be found at http://www.enocean.com 

Since the Microchip PIC18F452/ PIC18F4620 are not supported by ncc/ gcc the following 
workaround is used. The "app.c"-file is modified by a perl script in such a way that 
the modified "app.c"-file called "app_pic.c" can be compiled by the Microchip C18 compiler. 
Therefore to make use of this TinyOS port it is assumed that the Micorchip MPLAB IDE 
including the C18 compiler is installed on the local machine and that a Microchip
ICD2 is available.
 


* Point of contact (POC)

Please direct any questions about this port to hj.koerber@hsu-hh.de 



* License and copyright

These files are all, unless explicitly otherwise noted, licensed under
the GNU Public License (GPL) version 2 or later. See the file COPYING
for details. Derivate files from the Tiny OS distribution are licensed
under their original license. Unless otherwise noted, the files are
copyright Helmut-Schmidt-University, Hamburg, Dpt.of Electrical 
Measurement Engineering. 

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
