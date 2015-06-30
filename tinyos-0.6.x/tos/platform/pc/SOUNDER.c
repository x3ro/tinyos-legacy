/*									tab:4
 * SOUNDER.c - TOS abstraction of the sounder
 *
 * "Copyright (c) 2002 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:		Alec Woo
 *
 */

/*  OS component abstraction of the analog sounder */

/*  SOUNDER_INIT command initializes the device */
/*  SOUNDER_PWR_ON command turns on the sounder to make sound */
/*  SOUNDER_PWR_OFF command turns off the sounder */

#include "tos.h"
#include "SOUNDER.h"
#include "sensorboard.h"
#include "dbg.h"

char TOS_COMMAND(SOUNDER_INIT)(){
  dbg(DBG_BOOT, ("SOUNDER initialized.\n"));
  return 1;
}

char TOS_COMMAND(SOUNDER_PWR_ON)(){
  dbg(DBG_SOUNDER, ("SOUNDER on.\n"));
  return 1;
}

char TOS_COMMAND(SOUNDER_PWR_OFF)(){
  dbg(DBG_SOUNDER, ("SOUNDER off.\n"));
  return 1;
}
 
