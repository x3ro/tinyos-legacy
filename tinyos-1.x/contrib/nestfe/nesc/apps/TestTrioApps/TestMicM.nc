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
 * Implementation file for TestMic. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

includes sensorboard;
includes TestTrioMsg;

module TestMicM
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
    interface ADC as MicADC; 
    interface StdControl as MicControl;
    interface Mic;
    interface StdControl as IOSwitch1Control;
    interface IOSwitch as IOSwitch1;
    interface StdControl as IOSwitch2Control;
    interface IOSwitch as IOSwitch2;
    interface Timer as SampleTimer;
    interface Oscope as OscopeCh0; 
  }
}

implementation
{
  TOS_Msg send_msg;
  TOS_MsgPtr m_received_msg = NULL;
  uint8_t detect_pot = 0;
  uint8_t gain_pot = 0;
  uint8_t lpf0_pot = 0;
  uint8_t lpf1_pot = 0;
  uint8_t hpf0_pot = 0;
  uint8_t hpf1_pot = 0;
  uint8_t port0_bits = 0;
  uint8_t port1_bits = 0;

  uint16_t adc_data;
  uint8_t adc_port;

  uint8_t state;

  task void data_send_task();
  task void detect_report_task();
  task void gain_report_task();
  task void lpf0_report_task();
  task void lpf1_report_task();
  task void hpf0_report_task();
  task void hpf1_report_task();
  task void report_adc_task();

  command result_t StdControl.init() {
    call CommControl.init();
    call MicControl.init();
    call IOSwitch1Control.init();
    call IOSwitch2Control.init();
    call Leds.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call CommControl.start();
    call MicControl.start();
    call IOSwitch1Control.start();
    call IOSwitch2Control.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call CommControl.stop();
    call MicControl.stop();
    call IOSwitch1Control.stop();
    call IOSwitch2Control.stop();
    return SUCCESS;
  }

  task void detect_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MIC_POT_READ;
    pMsg->subcmd = SUBCMD_MIC_DETECT;
    pMsg->arg[0] = detect_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  task void gain_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MIC_POT_READ;
    pMsg->subcmd = SUBCMD_MIC_GAIN;
    pMsg->arg[0] = gain_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  task void lpf0_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MIC_POT_READ;
    pMsg->subcmd = SUBCMD_MIC_LPF0;
    pMsg->arg[0] = lpf0_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  task void lpf1_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MIC_POT_READ;
    pMsg->subcmd = SUBCMD_MIC_LPF1;
    pMsg->arg[0] = lpf1_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  task void hpf0_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MIC_POT_READ;
    pMsg->subcmd = SUBCMD_MIC_HPF0;
    pMsg->arg[0] = hpf0_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  task void hpf1_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MIC_POT_READ;
    pMsg->subcmd = SUBCMD_MIC_HPF1;
    pMsg->arg[0] = hpf1_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  event void Mic.readDetectDone(uint8_t val) {
    atomic detect_pot = val;
    post detect_report_task();
  }

  event void Mic.readGainDone(uint8_t val) {
    atomic gain_pot = val;
    post gain_report_task();
  }

  event void Mic.readLpfFreq0Done(uint8_t val) {
    atomic lpf0_pot = val;
    post lpf0_report_task();
  }

  event void Mic.readLpfFreq1Done(uint8_t val) {
    atomic lpf1_pot = val;
    post lpf1_report_task();
  }

  event void Mic.readHpfFreq0Done(uint8_t val) {
    atomic hpf0_pot = val;
    post hpf0_report_task();
  }

  event void Mic.readHpfFreq1Done(uint8_t val) {
    atomic hpf1_pot = val;
    post hpf1_report_task();
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
    case CMD_MIC:
      if (pMsg->subcmd == SUBCMD_ON) {
        call Mic.MicOn();
      }
      else if (pMsg->subcmd == SUBCMD_OFF) {
        call Mic.MicOff();
      }
      break;
    case CMD_MIC_POT_ADJUST:
      if (pMsg->subcmd == SUBCMD_MIC_DETECT) {
        call Mic.adjustDetect(pMsg->arg[0]);
      }
      else if (pMsg->subcmd == SUBCMD_MIC_GAIN) {
        call Mic.adjustGain(pMsg->arg[0]);
      }
      else if (pMsg->subcmd == SUBCMD_MIC_LPF0) {
        call Mic.adjustLpfFreq0(pMsg->arg[0]);
      }
      else if (pMsg->subcmd == SUBCMD_MIC_LPF1) {
        call Mic.adjustLpfFreq1(pMsg->arg[0]);
      }
      else if (pMsg->subcmd == SUBCMD_MIC_HPF0) {
        call Mic.adjustHpfFreq0(pMsg->arg[0]);
      }
      else if (pMsg->subcmd == SUBCMD_MIC_HPF1) {
        call Mic.adjustHpfFreq1(pMsg->arg[0]);
      }
      break;
    case CMD_MIC_POT_READ:
      if (pMsg->subcmd == SUBCMD_MIC_DETECT) {
        call Mic.readDetect();
      }
      else if (pMsg->subcmd == SUBCMD_MIC_GAIN) {
        call Mic.readGain();
      }
      else if (pMsg->subcmd == SUBCMD_MIC_LPF0) {
        call Mic.readLpfFreq0();
      }
      else if (pMsg->subcmd == SUBCMD_MIC_LPF1) {
        call Mic.readLpfFreq1();
      }
      else if (pMsg->subcmd == SUBCMD_MIC_HPF0) {
        call Mic.readHpfFreq0();
      }
      else if (pMsg->subcmd == SUBCMD_MIC_HPF1) {
        call Mic.readHpfFreq1();
      }
      break;
    case CMD_MIC_GETADC:
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
    call MicADC.getData();
    return SUCCESS;
  }

  task void report_adc_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MIC_ADCREADY;
    atomic {
      pMsg->subcmd = adc_port;
      pMsg->arg[0] = (uint8_t) (adc_data & 0xff);
      pMsg->arg[1] = (uint8_t) ((adc_data >> 8) & 0xff);
    }
    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  async event result_t MicADC.dataReady(uint16_t _data) {
    call OscopeCh0.put(_data);
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    atomic m_received_msg = m;
    post processMsgTask();
    return m;
  }

  event void Mic.adjustDetectDone(bool result) { }
  event void Mic.adjustGainDone(bool result) { }
  event void Mic.adjustLpfFreq0Done(bool result) { }
  event void Mic.adjustLpfFreq1Done(bool result) { }
  event void Mic.adjustHpfFreq0Done(bool result) { }
  event void Mic.adjustHpfFreq1Done(bool result) { }

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
    atomic pMsg->subcmd = IOSWITCH1_INT_ACOUSTIC;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  event void IOSwitch1.setPortDone(result_t result) { }
  event void IOSwitch2.setPortDone(result_t result) { }

  event void Mic.firedAcoustic() {
    post interrupt_report_task();
  }

}










