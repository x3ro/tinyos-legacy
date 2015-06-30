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

module UltrasoundSensorM {
  provides interface StdControl;
  uses {
    interface Range;
    interface ReceiveMsg as ResetCounterMsg;
    interface SendMsg as DataMsg;
    interface Leds;
  }
}
implementation {

  uint8_t packetReadingNumber;
  uint16_t readingNumber;
  TOS_Msg msg[2];
  uint8_t currentMsg;
  uint16_t prevRange;
  uint8_t state;

  // Constants
  enum {
    RANGE_THRESHOLD = 350,  //mm
    INIT = 0,
    NORMAL = 1,
  };

  /**
   * Initializes variables.
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.init() {
    currentMsg = 0;
    packetReadingNumber = 0;
    readingNumber = 0;
    prevRange = 0;
    state = INIT;

    return SUCCESS;
  }

  /**
   * Starts the component (?).
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.start() {
    return SUCCESS;
  }

  /**
   * Stops the component (?).
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  task void dataTask() {
    struct OscopeMsg *pack;
    pack = (struct OscopeMsg *)msg[currentMsg].data;
    packetReadingNumber = 0;
    pack->lastSampleNumber = readingNumber;
    pack->channel = TOS_LOCAL_ADDRESS;
    pack->sourceMoteID = TOS_LOCAL_ADDRESS;
    
    /* Try to send the packet. Note that this will return
     * failure immediately if the packet could not be queued for
     * transmission.
     */
    if (call DataMsg.send(TOS_BCAST_ADDR, sizeof(struct OscopeMsg),
			      &msg[currentMsg])) {
      currentMsg ^= 0x1;
    }
  }
  
  /**
   * Signalled when I receive a range begin event.
   * @return Always returns SUCCESS.
   */
  event result_t Range.rangeBegin(uint16_t seqNum) {
    call Leds.redToggle();
    return SUCCESS;
  }

  /**
   * Signalled when I receive a range estimate.
   * @return Always returns SUCCESS.
   */
  event result_t Range.rangeDone(uint16_t seqNum,
				 uint16_t range,
				 uint16_t ts,
				 uint8_t confidence) {
    struct OscopeMsg *pack;

    // Initialize previous range
    if (state == INIT) {
      prevRange = range;
    }

    // If I've experienced a dramatic change, this is most likely an
    // outlier -- use prevRange instead
    if (((range - prevRange) > RANGE_THRESHOLD) || 
	((prevRange - range) > RANGE_THRESHOLD))
      range = prevRange;
    prevRange = range;

    pack = (struct OscopeMsg *)msg[currentMsg].data;
    pack->data[packetReadingNumber].seqNo = seqNum;
    pack->data[packetReadingNumber].range = range;
    packetReadingNumber++;
    readingNumber++;
    if (packetReadingNumber == BUFFER_SIZE) {
      packetReadingNumber = 0;
      pack->lastSampleNumber = readingNumber;
      pack->channel = TOS_LOCAL_ADDRESS;
      pack->sourceMoteID = TOS_LOCAL_ADDRESS;
    
      /* Try to send the packet. Note that this will return
       * failure immediately if the packet could not be queued for
       * transmission.
       */
      if (call DataMsg.send(TOS_BCAST_ADDR, sizeof(struct OscopeMsg),
			    &msg[currentMsg])) {
	currentMsg ^= 0x1;
      }
    }
    return SUCCESS;
  }

  /**
   * Signalled when the previous packet has been sent.
   * @return Always returns SUCCESS.
   */
  event result_t DataMsg.sendDone(TOS_MsgPtr sent, result_t success) {
    return SUCCESS;
  }

  /**
   * Signalled when the reset message counter AM is received.
   * @return The free TOS_MsgPtr. 
   */
  event TOS_MsgPtr ResetCounterMsg.receive(TOS_MsgPtr m) {
    readingNumber = 0;
    return m;
  }


}
