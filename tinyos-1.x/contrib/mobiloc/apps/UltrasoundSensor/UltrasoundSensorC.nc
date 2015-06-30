/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Authors:		Sarah Bergbreiter
 * Date last modified:  11/11/03
 *
 * UltrasoundSensorC gathers ultrasound ranging estimates and sends them
 * back to the base station.
 *
 * I am currently using the Oscope msg format so that I can easily see
 * my results using the oscilloscope visualization program.
 *
 */

includes OscopeMsg;

configuration UltrasoundSensorC {
}
implementation {
  components Main, UltrasoundSensorM, UltrasoundReceiveC,
    GenericComm as Comm, LedsC as Debug;

  Main.StdControl -> UltrasoundSensorM;
  Main.StdControl -> UltrasoundReceiveC;
  Main.StdControl -> Comm;

  UltrasoundSensorM.Range -> UltrasoundReceiveC;

  UltrasoundSensorM.ResetCounterMsg -> Comm.ReceiveMsg[AM_OSCOPERESETMSG];
  UltrasoundSensorM.DataMsg -> Comm.SendMsg[AM_OSCOPEMSG];

  UltrasoundSensorM.Leds -> Debug;

}
