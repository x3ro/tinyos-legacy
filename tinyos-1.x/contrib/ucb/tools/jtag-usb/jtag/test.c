//  $Id: test.c,v 1.2 2004/12/15 04:06:33 szewczyk Exp $
/* "Copyright (c) 2000-2004 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */


/*
  @author Robert Szewczyk <szewczyk@eecs.berkeley.edu>
  
  a sample test for the JTAG library.  Erase the device.

*/
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
//#include <conio.h>
#include "Basic_Types.h"
#include "MSP430mspgcc.h"
int main() {
    MSP430_Initialize("1", NULL);
    MSP430_Open();
    MSP430_Erase(ERASE_ALL, 0xfffe, 0);
    MSP430_Close(3000);
}
