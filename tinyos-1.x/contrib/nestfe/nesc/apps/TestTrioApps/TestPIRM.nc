/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/**
 * Implementation file for TestPIR. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

includes sensorboard;
includes TestTrioMsg;

module TestPIRM
{
  provides {
    interface StdControl;
  }
  uses {
    interface Leds;
    interface StdControl as CommControl;
    interface SendMsg;
    interface ReceiveMsg;
    interface ADCControl;
    interface ADC as PIRADC; 
    interface StdControl as PIRControl;
    interface PIR;
    interface StdControl as IOSwitch1Control;
    interface IOSwitch as IOSwitch1;
    interface StdControl as IOSwitch2Control;
    interface IOSwitch as IOSwitch2;
    interface Timer as SampleTimer;
    interface Oscope as OscopeCh3;
  }
}

implementation
{
  TOS_Msg send_msg;
  TOS_MsgPtr m_received_msg = NULL;
  uint8_t detect_pot = 0;
  uint8_t quad_pot = 0;
  uint8_t port0_bits = 0;
  uint8_t port1_bits = 0;

  uint16_t adc_data;
  uint8_t adc_port;

  uint8_t state;
  uint8_t mask = 0;

  task void data_send_task();
  task void detect_report_task();
  task void quad_report_task();
  task void report_adc_task();

  command result_t StdControl.init() {
    call CommControl.init();
    call PIRControl.init();
    call IOSwitch1Control.init();
    call IOSwitch2Control.init();
    call Leds.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call CommControl.start();
    call PIRControl.start();
    call IOSwitch1Control.start();
    call IOSwitch2Control.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call CommControl.stop();
    call PIRControl.stop();
    call IOSwitch1Control.stop();
    call IOSwitch2Control.stop();
    return SUCCESS;
  }

  task void detect_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_PIR_POT_READ;
    pMsg->subcmd = SUBCMD_PIR_DETECT;
    pMsg->arg[0] = detect_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  task void quad_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_PIR_POT_READ;
    pMsg->subcmd = SUBCMD_PIR_QUAD;
    pMsg->arg[0] = quad_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  event void PIR.readDetectDone(uint8_t val) {
    atomic detect_pot = val;
    post detect_report_task();
  }

  event void PIR.readQuadDone(uint8_t val) {
    atomic quad_pot = val;
    post quad_report_task();
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr sent, result_t result) {
    return SUCCESS;
  }

  task void processMsgTask() {
    struct TestTrioMsg *pMsg;

    atomic {
      pMsg = (TestTrioMsg *) m_received_msg->data;
    }

    switch (pMsg->cmd) {
    case CMD_REDLED:
      if (pMsg->subcmd == 0) call Leds.redOff();
      else call Leds.redOn();
      break;
    case CMD_GREENLED:
      if (pMsg->subcmd == 0) call Leds.greenOff();
      else call Leds.greenOn();
      break;
    case CMD_YELLOWLED:
      if (pMsg->subcmd == 0) call Leds.yellowOff();
      else call Leds.yellowOn();
      break;
    case CMD_PIR:
      if (pMsg->subcmd == SUBCMD_ON) {
        call PIR.PIROn();
      }
      else if (pMsg->subcmd == SUBCMD_OFF) {
        call PIR.PIROff();
      }
      break;
    case CMD_PIR_POT_ADJUST:
      if (pMsg->subcmd == SUBCMD_PIR_DETECT) {
        call PIR.adjustDetect(pMsg->arg[0]);
      }
      else if (pMsg->subcmd == SUBCMD_PIR_QUAD) {
        call PIR.adjustQuad(pMsg->arg[0]);
      }
      break;
    case CMD_PIR_POT_READ:
      if (pMsg->subcmd == SUBCMD_PIR_DETECT) {
        call PIR.readDetect();
      }
      else if (pMsg->subcmd == SUBCMD_PIR_QUAD) {
        call PIR.readQuad();
      }
      break;
    case CMD_PIR_GETADC:
      if (pMsg->subcmd == SUBCMD_ON) {
        call SampleTimer.start(TIMER_REPEAT, 25);
      }
      else if (pMsg->subcmd == SUBCMD_OFF) {
        call SampleTimer.stop();
      }
      break;
    case CMD_IOSWITCH1_SET:
      call IOSwitch1.setPort0Pin(pMsg->subcmd, TRUE);
      break;
    case CMD_IOSWITCH1_CLR:
      call IOSwitch1.setPort0Pin(pMsg->subcmd, FALSE);
      break;
    case CMD_IOSWITCH1_READ:
      call IOSwitch1.getPort();
      break;
    case CMD_IOSWITCH2_SET:
      call IOSwitch2.setPort0Pin(pMsg->subcmd, TRUE);
      break;
    case CMD_IOSWITCH2_CLR:
      call IOSwitch2.setPort0Pin(pMsg->subcmd, FALSE);
      break;
    case CMD_IOSWITCH2_READ:
      call IOSwitch2.getPort();
      break;
    case CMD_DEBUG_MSG:
      break;
    }
  }

  event result_t SampleTimer.fired() {
    call PIRADC.getData();
    return SUCCESS;
  }

  task void report_adc_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_PIR_ADCREADY;
    atomic {
      pMsg->subcmd = adc_port;
      pMsg->arg[0] = (uint8_t) (adc_data & 0xff);
      pMsg->arg[1] = (uint8_t) ((adc_data >> 8) & 0xff);
    }
    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  async event result_t PIRADC.dataReady(uint16_t _data) {
    call OscopeCh3.put(_data);
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    atomic m_received_msg = m;
    post processMsgTask();
    return m;
  }

  event void PIR.adjustDetectDone(bool result) { }
  event void PIR.adjustQuadDone(bool result) { }

  task void data_send1_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_IOSWITCH1_READ;
    pMsg->subcmd = 2;
    pMsg->arg[0] = port0_bits;
    pMsg->arg[1] = port1_bits;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  event void IOSwitch1.getPortDone(uint16_t _bits, result_t _success) {
    atomic {
      port0_bits = (uint8_t) (_bits & 0xff);
      port1_bits = (uint8_t) ((_bits >> 8) & 0xff);
    }
    post data_send1_task();
  }

  task void data_send2_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_IOSWITCH2_READ;
    pMsg->subcmd = 2;
    pMsg->arg[0] = port0_bits;
    pMsg->arg[1] = port1_bits;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  event void IOSwitch2.getPortDone(uint16_t _bits, result_t _success) {
    atomic {
      port0_bits = (uint8_t) (_bits & 0xff);
      port1_bits = (uint8_t) ((_bits >> 8) & 0xff);
    }
    post data_send2_task();
  }

  task void interrupt_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_IOSWITCH1_INTERRUPT;
    atomic {
      pMsg->subcmd = mask;
      mask = 0;
    }

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  event void IOSwitch1.setPortDone(result_t result) { }
  event void IOSwitch2.setPortDone(result_t result) { }

  event void PIR.firedPIR() {
    atomic mask = IOSWITCH1_INT_PIR;
    post interrupt_report_task();
  }

}










