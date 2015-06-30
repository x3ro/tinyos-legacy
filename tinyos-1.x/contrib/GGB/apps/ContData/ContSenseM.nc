// $Id: ContSenseM.nc,v 1.3 2006/11/30 23:57:24 binetude Exp $

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
/*
 *
 * Authors:		Sukun Kim
 * Date last modified:  11/30/06
 *
 */

/**
 * @author Sukun Kim
 */

#define SAMPLE_INTERVAL 100000 // us
#define CHANNEL1_SELECT 1 // Low resolution, Vertical
#define CHANNEL2_SELECT 1 // Low resolution, Horizontal
#define CHANNEL3_SELECT 1 // High resolution, Vertical
#define CHANNEL4_SELECT 1 // High resolution, Horizontal
#define CHANNEL5_SELECT 1 // Temperature
#define CHANNEL6_SELECT 1 // Jitter
// LEAVE IT AS 6 regardless of channel selection
#define NUM_CHANNELS 6


module ContSenseM {
  provides interface StdControl;
  uses {
    interface SendMsg;
    interface MicroTimer;
    interface mADC;
    interface ADC;
    interface Leds;
  }
}
implementation {
  norace char head;
  norace uint8_t currentBuffer;
  norace TOS_Msg dataBuffer[NUM_CHANNELS][2];
  norace uint16_t* bufferPtr[NUM_CHANNELS][2];
  
  norace int channel_index;
  norace bool channel_select[NUM_CHANNELS];
  norace uint16_t data_value[NUM_CHANNELS];

  norace uint16_t readingNumber;

  norace uint16_t prev_time;
  norace uint16_t current_time;


  task void sendBuffer()
  {
    struct OscopeMsg* temp_OscopeMsg = (struct OscopeMsg*)dataBuffer[channel_index][currentBuffer^0x01].data;
    temp_OscopeMsg->sourceMoteID = TOS_LOCAL_ADDRESS;
    temp_OscopeMsg->lastSampleNumber = readingNumber;
    temp_OscopeMsg->channel = channel_index + 1;
    call SendMsg.send(TOS_BCAST_ADDR, sizeof(struct OscopeMsg),
      &dataBuffer[channel_index][currentBuffer^0x01]);
  } 
  void send_next_channel() {
    while (!channel_select[channel_index]) {
      channel_index++;
    }
    if (channel_index < NUM_CHANNELS) {
      post sendBuffer();
    } else {
      channel_index = 0;
      call Leds.redToggle();
    }
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.start() {
    int i, j;
    call Leds.init();

    head = 0;
    currentBuffer = 0;
    for (i = 0; i < NUM_CHANNELS; i++)
      for (j = 0; j < 2; j++)
        bufferPtr[i][j] = ((struct OscopeMsg*)(dataBuffer[i][j].data))->data;

    channel_index = 0;
    channel_select[0] = CHANNEL1_SELECT;
    channel_select[1] = CHANNEL2_SELECT;
    channel_select[2] = CHANNEL3_SELECT;
    channel_select[3] = CHANNEL4_SELECT;
    channel_select[4] = CHANNEL5_SELECT;
    channel_select[5] = CHANNEL6_SELECT;

    readingNumber = 0;
 
    sbi(TCCR3B, CS30);
    prev_time = inw(TCNT3);
    call MicroTimer.start(SAMPLE_INTERVAL);
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success)
  {
    channel_index++;
    send_next_channel();
    return SUCCESS;
  }

  async event result_t MicroTimer.fired()
  {
    current_time = inw(TCNT3);
    data_value[5] = current_time - prev_time;
    prev_time = current_time;

    call mADC.getData(data_value);
    call ADC.getData();
    return SUCCESS;
  }

  async event result_t ADC.dataReady(uint16_t data) {
    int i;
    data_value[4] = data;
    for (i = 0; i < NUM_CHANNELS; i++)
      bufferPtr[i][currentBuffer][(int)head] = data_value[i];

    readingNumber++;
    head++;
    if (head == BUFFER_SIZE) {
      head = 0;
      currentBuffer ^= 0x01;
      channel_index = 0;
      send_next_channel();
    }
    return SUCCESS;
  }
}

