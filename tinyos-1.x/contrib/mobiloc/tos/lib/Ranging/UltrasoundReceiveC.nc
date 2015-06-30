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
 * UltrasoundReceiveC packages the receiving capabilities of the ultrasound
 * receiver.  It associates sequence numbers with distance measurements
 * and will ideally create confidence numbers based on what range I'm in
 * and past numbers.
 *
 * Currently, it provides interface Range which signals a rangeDone
 * event complete with sequence number, distance estimate, time stamp
 * (eventually) and confidence.
 *
 * I will eventually want to add my synchronized timer in here as well
 * to provide a time stamp on each distance estimate (to correlate it
 * with magnetometer estimates).
 *
 */

configuration UltrasoundReceiveC {
  provides {
    interface StdControl;
    interface Range;
  }
}
implementation {
  components UltrasoundReceiveM, ReceiverC, NoLeds as Debug,
    GenericComm as Comm;

  StdControl = UltrasoundReceiveM.StdControl;
  Range = UltrasoundReceiveM.Range;

  UltrasoundReceiveM.CommControl -> Comm;
  UltrasoundReceiveM.Receiver -> ReceiverC;
  UltrasoundReceiveM.ReceiverControl -> ReceiverC;
  UltrasoundReceiveM.Leds -> Debug;

}
