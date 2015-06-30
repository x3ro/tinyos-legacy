/* -*-C-*- */
/**********************************************************************
Copyright ©2003 The Regents of the University of California (Regents).
All Rights Reserved.

Permission to use, copy, modify, and distribute this software and its 
documentation for any purpose, without fee, and without written 
agreement is hereby granted, provided that the above copyright notice 
and the following three paragraphs appear in all copies and derivatives 
of this software.

IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY 
FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES 
ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF 
THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE 
PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF 
CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, 
ENHANCEMENTS, OR MODIFICATIONS.

This software was created by Ram Kumar {ram@ee.ucla.edu}, 
Saurabh Ganeriwal {saurabh@ee.ucla.edu} at the 
Networked & Embedded Systems Laboratory (http://nesl.ee.ucla.edu), 
University of California, Los Angeles. Any publications based on the 
use of this software or its derivatives must clearly acknowledge such 
use in the text of the publication.
**********************************************************************/
/****************************************************************
 Description: The interface used by the TPSN middleware for getting
 precise byte-level time stamps from the radio.
 *****************************************************************/


interface TimeStamp{

  /**
   * Event generated from the protocol stack every time the SPI interrupt handler
   * routine is executed. This event is the first one to be signalled so as to 
   * minimize the jitter and hence improve the synchronization accuracy. The time
   * synchronization protocol timestamps every byte.
   **/
  async event void byteTime();


  /**
   * Event generated upon the receipt of the Start Symbol. The offset denotes the 
   * number of bits into the received byte after which Start Symbol was found.
   **/
  async event void startSymbol(uint8_t offset);

  
  /**
   * Event generated from the protocol stack upon initiation of packet transmission. 
   * The pointer to the packet is also passed and we modify its contents *just* 
   * prior to CRC computations. The outgoing packet is thus accurately timestamped.
   **/
  async event void sentPacket(TOS_MsgPtr m);
}
