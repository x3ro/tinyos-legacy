/*									tab:4
 * Copyright (c) 2002 the University of Southern California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * UNIVERSITY OF SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Wei Ye
 * Date created: 1/21/2003
 *
 * This application tests functionalitis of Sensor-MAC (S-MAC), and shows how
 * to use S-MAC. 
 *
 */

includes config;     // include config.h first
includes testMsg;

configuration SMACTest { }

implementation
{
   components Main, SMACTestM, SMAC, LedsC;
   
   Main.StdControl -> SMACTestM;
   SMACTestM.MACControl -> SMAC;
   SMACTestM.MACComm -> SMAC;
   SMACTestM.LinkState -> SMAC;
   SMACTestM.MACTest -> SMAC;
   SMACTestM.Leds -> LedsC;
   
   // To use an external time stamp in S-MAC, provide the following wiring
   // SMAC.TimeStamp -> YourComponent.TimeStamp;
}




