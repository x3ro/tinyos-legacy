// $Id: TestByteEEPROMC.nc,v 1.4 2003/10/07 21:45:16 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * This program is a simple test of ByteEEPROM, a component which
 * provides a byte-level abstraction to the EEPROM. This application was used
 * to debug ByteEEPROM, and is a good example on how to wire and use it.
 *
 * Requests are made for different memory regions, and a write followed by a read
 * is made from the same region.  If the data in the write buffer is the same
 * as the data in the read buffer, the red led should remain on when execution
 * of the application ends. 
 *
 * Currently GenericComm is wired to this application so that buffers read and written
 * could be written over the UART.  The full functionality of this debugging
 * mechanism has not been implemented fully.  It currently supports the output of one packet
 * over the UART, which can be observed using the java tool "ListenRaw"
 */

module TestByteEEPROMC {
  provides {
    interface StdControl;
  }
  
  uses {
    interface AllocationReq as AllocationReq1;
    interface WriteData as WriteData1;
    interface ReadData as ReadData1;

    interface AllocationReq as AllocationReq2;
    //interface WriteData as WriteData2;
    //interface ReadData as ReadData2;

    interface AllocationReq as AllocationReq3;
    //interface WriteData as WriteData3;
    //interface ReadData as ReadData3;

    interface AllocationReq as AllocationReq4;
    interface WriteData as WriteData4;

    interface StdControl as ByteEEPROMStdControl;
    interface Leds;
    interface StdControl as GenericCommStdControl;
    interface SendMsg;
  }
}

implementation {
  uint8_t blah[300];
  char wee[64];
  enum {
    READ1, READ2
  } state;

  void expect(uint32_t val1, uint32_t val2) {
    if (val1 != val2)
      call Leds.yellowOn();
  }
  
  /**
   * Initialize the application by initializing the
   * character array blah, whose data will be written.
   * Initialize GenericComm, Leds, and ByteEEPROM. 
   *
   * Turn on the red Led and request for distinct memory
   * regions
   * 
   * @return Always returns <code>SUCCESS</code>
   */  
  command result_t StdControl.init() {
    blah[0] = 0xda;
    blah[1] = 0xaa;
    blah[2] = 0xaa;
    blah[3] = 0xff;
    blah[4] = 0xaa;
    blah[5] = 0xaa;
    blah[6] = 0xdd;
    blah[7] = 0x11;
    blah[8] = 0xda;
    blah[9] = 0xaa;
    blah[10] = 0xaa;
    blah[11] = 0xff;
    blah[12] = 0xaa;
    blah[13] = 0xaa;
    blah[14] = 0xdd;
    blah[15] = 0x11;
    blah[16] = 0xda;
    blah[17] = 0xaa; 
    blah[18] = 0xaa;
    blah[19] = 0xff;
    blah[20] = 0xaa;
    blah[21] = 0xab;
    blah[22] = 0xdd;
    blah[23] = 0x11;
    blah[24] = 0xda;
    blah[25] = 0xaa;
    blah[26] = 0xaa;
    blah[27] = 0xff;
    blah[28] = 0xaa;
    blah[29] = 0xaa;
    blah[30] = 0xdd;
    blah[31] = 0x11;
    blah[32] = 0xda;
    blah[33] = 0xaa;
    
    blah[34] = 0xaa;
    blah[35] = 0xff;
    blah[36] = 0xaa;
    blah[37] = 0xaa;
    blah[38] = 0xdd;
    blah[39] = 0x11;
    blah[40] = 0xda;
    blah[41] = 0xaa;
    blah[42] = 0xaa;
    blah[43] = 0xff;
    blah[44] = 0xaa;
    blah[45] = 0xaa;
    blah[46] = 0xdd;
    blah[47] = 0x11;
    blah[48] = 0xda;
    blah[49] = 0xaa;
    blah[50] = 0xaa;
    blah[51] = 0xff;
    blah[52] = 0xaa;
    blah[53] = 0xaa;
    blah[54] = 0xdd;
    blah[55] = 0x11;
    blah[56] = 0xda;
    blah[57] = 0xaa;
    blah[58] = 0xaa;
    blah[59] = 0xff;
    blah[60] = 0xaa;
    blah[61] = 0xaa;
    blah[62] = 0xdd;
    blah[63] = 0x11;
    blah[299] = 43;
    
    call GenericCommStdControl.init();
    call Leds.init();
    call ByteEEPROMStdControl.init();

    // Except if page size is 1 byte, a prime starting address should fail
    expect(call AllocationReq1.requestAddr(19, 600), FAIL); 

    expect(call AllocationReq1.requestAddr(512, 600), SUCCESS);
    expect(call AllocationReq2.request(100), SUCCESS);
    expect(call AllocationReq3.request(257), SUCCESS);

    return SUCCESS;
  }
  
  task void dotest();

  /**
   * call <code>ByteEEPROMStdControl.start()</code>.
   * ByteEEPROM will allocate memory and signal AllocationReq.requestProcessed
   * to applications that had successful calls to either <code>request</code> or
   * <code>requestAddr</code>.
   *
   * call <code>WriteData.write(...)</code>.
   * Write out a portion of the write buffer to the EEPROM.
   * 
   * @return Always returns <code>SUCCESS</code>
   */
  command result_t StdControl.start() {
    call ByteEEPROMStdControl.start();
    post dotest();
    return SUCCESS;
    
  }

  /**
   * Stop things; does nothing really
   * 
   * @return Always returns <code>SUCCESS</code>
   */
  command result_t StdControl.stop() {
    return SUCCESS;

  }

  /**
   * Signalled when ByteEEPROM processes a particular allocation request.
   * if the memory was allocated, meaning <code>SUCCESS</code> was signalled, turn
   * the red Led off
   *
   * @return Always returns <code>SUCCESS</code>
   */

  event result_t AllocationReq1.requestProcessed(result_t success) {
    expect(success, SUCCESS);
    return SUCCESS;
  }

  event result_t AllocationReq2.requestProcessed(result_t success) {
    expect(success, SUCCESS);
    return SUCCESS;
  }

  event result_t AllocationReq3.requestProcessed(result_t success) {
    expect(success, SUCCESS);
    return SUCCESS;
  }

  event result_t AllocationReq4.requestProcessed(result_t success) {
    expect(FAIL, SUCCESS);
    return SUCCESS;
  }

  task void dotest() {
    call Leds.redOn();
    expect(call WriteData1.write(1000, blah, 30), FAIL);
    expect(call WriteData4.write(1000, blah, 30), FAIL);
    expect(call WriteData1.write(250, blah, 300), SUCCESS);
  }

  /**
   * Signalled when ByteEEPROM has finished writing.
   * Output dbg statements indicating whether or not the write was successful.
   * 
   * call <code>ReadData.read(...)</code>
   * Read out the portion of the write buffer previously written.
   *
   * @return Always returns <code>SUCCESS</code>
   */
  event result_t WriteData1.writeDone(uint8_t* data, uint32_t numBytesWrite, result_t success) {
    if (SUCCESS == success)
      {
	state = READ1;
	expect(call ReadData1.read(270, wee, 3), SUCCESS);
      }
    else
      expect(FAIL, SUCCESS);
	
    return SUCCESS;
  }

  event result_t WriteData4.writeDone(uint8_t* data, uint32_t numBytesWrite, result_t success) {
    expect(FAIL, SUCCESS);
    return SUCCESS;
  }

  /**
   * Signalled when ByteEEPROM has finished reading.
   * Turns the yellow Led on if the read was successful. Outputs
   * the buffer read through dbg statments.
   * Also does a comparison with the buffer written and the buffer read;
   * if they are the same, the red Led is turned on.
   *
   * @return Always returns <code>SUCCESS</code>
   */
  event result_t ReadData1.readDone(uint8_t* buffer, uint32_t numBytesRead, result_t success) {
    uint16_t i, offset;
    bool readWriteCorrectly = TRUE;

    if (success == FAIL)
      {
	expect(FAIL, SUCCESS);
	return SUCCESS;
      }
    
    dbg(DBG_LOG, "LOGGER: Log read completed.\n");
    dbg_clear(DBG_LOG, "\t[");
    for (i = 0; i < numBytesRead; i++) {
      dbg_clear(DBG_LOG, "%2hhx", buffer[i]);
    }
    dbg_clear(DBG_LOG, "]\n");

    if (state == READ1)
      offset = 20;
    else
      offset = 298;
    
    for (i = 0; i < numBytesRead; i++)
	if (buffer[i] != blah[i + offset])
	  readWriteCorrectly = FALSE;
    if (readWriteCorrectly)
      {
	if (state == READ1)
	  {
	    state = READ2;
	    expect(call ReadData1.read(250 + 298, wee, 2), SUCCESS);
	  }
	else
	  call Leds.greenOn();
      }
    else
      expect(FAIL, SUCCESS);
    
    return SUCCESS;
  }
  
  /**
   * does nothing right now.
   * 
   * @return Always returns <code>SUCCESS</code>
   */
  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
}
