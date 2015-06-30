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
 * UltrasoundTransmitter sends an ultrasound chirp (radio packet + ultrasound
 * beep) at a periodic rate based on the mote ID.  If the moteID is < 1000, 
 * it will default to a rate of 1 chirp/sec.  Otherwise, the period between
 * chirps = the ID in milliseconds.
 *
 * The green LED turns on when the mote is sending a chirp and the yellow
 * LED toggles at the given rate.
 *
 */

configuration UltrasoundTransmitterC {
}
implementation{
  components Main, UltrasoundTransmitterM, TransmitterC, TimerC, LedsC,
    GenericComm as Comm;

  Main.StdControl -> UltrasoundTransmitterM;
  Main.StdControl -> TransmitterC;
  Main.StdControl -> TimerC;
  Main.StdControl -> Comm;

  UltrasoundTransmitterM.Transmit -> TransmitterC;
  UltrasoundTransmitterM.BeepTimer -> TimerC.Timer[unique("Timer")];
  UltrasoundTransmitterM.Leds -> LedsC;

}

