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
 *          (CRC calculation is based on code from Jason Hill)
 * Date created: 1/21/2003
 * 
 * This is the physical layer that sends and receives a packet
 *   - accept any type and length (<= PHY_MAX_PKT_LEN in phy_radio_msg.h) of packet
 *   - sending a packet: encoding and byte spooling
 *   - receiving a packet: decoding, byte buffering
 *   - Optional CRC check
 *   - interface to radio control and physical carrier sense
 *
 */

configuration PhyRadio
{
   provides {
      interface StdControl as PhyControl;
      interface RadioState;
      interface PhyComm;
      interface CarrierSense;
      interface PhyStreamByte;
   }
}

implementation
{
   components PhyRadioM, RadioControl, CodecManchester;
   
   PhyControl = PhyRadioM;
   RadioState = PhyRadioM;
   PhyComm = PhyRadioM;
   CarrierSense = RadioControl;
   PhyStreamByte = PhyRadioM;
   
   // wiring to lower layers
   
   PhyRadioM.RadControl -> RadioControl;
   PhyRadioM.RadioState -> RadioControl;
   PhyRadioM.RadioByte -> RadioControl;
   PhyRadioM.CodecControl -> CodecManchester;
   PhyRadioM.Codec -> CodecManchester;
}
