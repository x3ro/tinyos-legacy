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
 * Implementation file for TestTrio. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

includes sensorboard;
includes TestTrioMsg;

module TestTrioM
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
    interface ADC as MagXADC;
    interface ADC as MagYADC;
    interface StdControl as MagControl;
    interface Mag;
    interface ADC as MicADC;
    interface StdControl as MicControl;
    interface Mic;
    interface ADC as PIRADC;
    interface StdControl as PIRControl;
    interface PIR;
    interface StdControl as IOSwitch1Control;
    interface IOSwitch as IOSwitch1;
    interface StdControl as IOSwitch2Control;
    interface IOSwitch as IOSwitch2;
    interface Timer as SampleXTimer;
    interface Timer as SampleYTimer;
    interface Timer as MicSampleTimer;
    interface Timer as PIRSampleTimer;
    interface Oscope as OscopeCh1;  // mag mag_gainx_pot
    interface Oscope as OscopeCh2;  // magx_data
    interface Oscope as OscopeCh3;  // mag mag_gainy_pot
    interface Oscope as OscopeCh4;  // magy_data
    interface Oscope as OscopeCh5;  // mic data
    interface Oscope as OscopeCh6;  // PIR data
  }
}

implementation
{
  enum {
    BIAS_WAIT = 0,
  };

  TOS_Msg send_msg;
  TOS_MsgPtr m_received_msg = NULL;
  uint8_t port0_bits = 0;
  uint8_t port1_bits = 0;
  uint8_t mag_gainx_pot = 120;
  uint8_t mag_gainy_pot = 120;
  uint8_t mic_detect_pot = 0;
  uint8_t mic_gain_pot = 0;
  uint8_t mic_lpf0_pot = 0;
  uint8_t mic_lpf1_pot = 0;
  uint8_t mic_hpf0_pot = 0;
  uint8_t mic_hpf1_pot = 0;
  uint8_t detect_pot = 0;
  uint8_t quad_pot = 0;
  
  uint16_t adc_data;
  uint8_t adc_port;

  uint16_t magx_data = 0;
  uint16_t magy_data = 0;
  bool auto_bias_x = TRUE;
  bool auto_bias_y = TRUE;
  int16_t biasx_wait = 0;
  int16_t biasy_wait = 0;
  uint8_t mask = 0;

  task void gainx_report_task();
  task void gainy_report_task();

  task void mic_detect_report_task();
  task void mic_gain_report_task();
  task void mic_lpf0_report_task();
  task void mic_lpf1_report_task();
  task void mic_hpf0_report_task();
  task void mic_hpf1_report_task();

  task void detect_report_task();
  task void quad_report_task();

  command result_t StdControl.init() {
    call CommControl.init();
    call MagControl.init();
    call MicControl.init();
    call PIRControl.init();
    call IOSwitch1Control.init();
    call IOSwitch2Control.init();
    call Leds.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call CommControl.start();
    call MagControl.start();
    call MicControl.start();
    call PIRControl.start();
    call IOSwitch1Control.start();
    call IOSwitch2Control.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call CommControl.stop();
    call MagControl.stop();
    call MicControl.stop();
    call PIRControl.stop();
    call IOSwitch1Control.stop();
    call IOSwitch2Control.stop();
    return SUCCESS;
  }

  task void gainx_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MAG_POT_READ;
    pMsg->subcmd = SUBCMD_MAG_GAINX;
    pMsg->arg[0] = mag_gainx_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  task void gainy_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MAG_POT_READ;
    pMsg->subcmd = SUBCMD_MAG_GAINY;
    pMsg->arg[0] = mag_gainy_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  event void Mag.readGainXDone(uint8_t val) {
    atomic mag_gainx_pot = val;
    post gainx_report_task();
  }

  event void Mag.readGainYDone(uint8_t val) {
    atomic mag_gainy_pot = val;
    post gainy_report_task();
  }

  task void mic_detect_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MIC_POT_READ;
    pMsg->subcmd = SUBCMD_MIC_DETECT;
    pMsg->arg[0] = mic_detect_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  task void mic_gain_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MIC_POT_READ;
    pMsg->subcmd = SUBCMD_MIC_GAIN;
    pMsg->arg[0] = mic_gain_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  task void mic_lpf0_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MIC_POT_READ;
    pMsg->subcmd = SUBCMD_MIC_LPF0;
    pMsg->arg[0] = mic_lpf0_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  task void mic_lpf1_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MIC_POT_READ;
    pMsg->subcmd = SUBCMD_MIC_LPF1;
    pMsg->arg[0] = mic_lpf1_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  task void mic_hpf0_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MIC_POT_READ;
    pMsg->subcmd = SUBCMD_MIC_HPF0;
    pMsg->arg[0] = mic_hpf0_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  task void mic_hpf1_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MIC_POT_READ;
    pMsg->subcmd = SUBCMD_MIC_HPF1;
    pMsg->arg[0] = mic_hpf1_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  event void Mic.readDetectDone(uint8_t val) {
    atomic mic_detect_pot = val;
    post mic_detect_report_task();
  }

  event void Mic.readGainDone(uint8_t val) {
    atomic mic_gain_pot = val;
    post mic_gain_report_task();
  }

  event void Mic.readLpfFreq0Done(uint8_t val) {
    atomic mic_lpf0_pot = val;
    post mic_lpf0_report_task();
  }

  event void Mic.readLpfFreq1Done(uint8_t val) {
    atomic mic_lpf1_pot = val;
    post mic_lpf1_report_task();
  }

  event void Mic.readHpfFreq0Done(uint8_t val) {
    atomic mic_hpf0_pot = val;
    post mic_hpf0_report_task();
  }

  event void Mic.readHpfFreq1Done(uint8_t val) {
    atomic mic_hpf1_pot = val;
    post mic_hpf1_report_task();
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
    case CMD_MAG:
      if (pMsg->subcmd == SUBCMD_ON) {
        call Mag.MagOn();
        //call DebugTimer.start(TIMER_ONE_SHOT, 200);
      }
      else if (pMsg->subcmd == SUBCMD_OFF) {
        call Mag.MagOff();
      }
      break;
    case CMD_MAG_POT_ADJUST:
      if (pMsg->subcmd == SUBCMD_MAG_GAINX) {
        call Mag.adjustGainX(pMsg->arg[0]);
      }
      else if (pMsg->subcmd == SUBCMD_MAG_GAINY) {
        call Mag.adjustGainY(pMsg->arg[0]);
      }
      break;
    case CMD_MAG_POT_READ:
      if (pMsg->subcmd == SUBCMD_MAG_GAINX) {
        call Mag.readGainX();
      }
      else if (pMsg->subcmd == SUBCMD_MAG_GAINY) {
        call Mag.readGainY();
      }
      break;
    case CMD_MAG_GETADC:
      if (pMsg->subcmd == SUBCMD_MAG_ADC0) {
        if (pMsg->arg[0] == SUBCMD_ON) {
          call SampleXTimer.start(TIMER_REPEAT, 10);
        }
        else if (pMsg->arg[0] == SUBCMD_OFF) {
          call SampleXTimer.stop();
        }
      }
      else if (pMsg->subcmd == SUBCMD_MAG_ADC1) {
        if (pMsg->arg[0] == SUBCMD_ON) {
          call SampleYTimer.start(TIMER_REPEAT, 10);
        }
        else if (pMsg->arg[0] == SUBCMD_OFF) {
          call SampleYTimer.stop();
        }
      }
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
        call MicSampleTimer.start(TIMER_REPEAT, 25);
      }
      else if (pMsg->subcmd == SUBCMD_OFF) {
        call MicSampleTimer.stop();
      }
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
        call PIRSampleTimer.start(TIMER_REPEAT, 25);
      }
      else if (pMsg->subcmd == SUBCMD_OFF) {
        call PIRSampleTimer.stop();
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
    }
  }

  event result_t SampleXTimer.fired() {
    call MagXADC.getData();
    return SUCCESS;
  }

  event result_t SampleYTimer.fired() {
    call MagYADC.getData();
    return SUCCESS;
  }

  uint8_t getNewBias( uint16_t mag, uint8_t bias ) {
    if( mag < 1100 ) {
      return (bias <= 0) ? 0 : (bias-1);
    } else if( mag > 3500 ) {
      return (bias >= 255) ? 255 : (bias+1);
    }
    return bias;
  }

  task void processMagXData()
  {
    if( auto_bias_x ) {
      if( biasx_wait <= 0 ) {
        uint8_t newbias = getNewBias( magx_data, mag_gainx_pot );
        if( newbias != mag_gainx_pot ) {
          call Mag.adjustGainX( mag_gainx_pot=newbias );
        }
        biasx_wait = BIAS_WAIT;
      } else {
        biasx_wait--;
      }
    }
    call OscopeCh1.put(mag_gainx_pot);
    call OscopeCh2.put(magx_data);
  }

  task void processMagYData()
  {
    if( auto_bias_y ) {
      if( biasy_wait <= 0 ) {
        uint8_t newbias = getNewBias( magy_data, mag_gainy_pot );
        if( newbias != mag_gainy_pot ) {
          call Mag.adjustGainY( mag_gainy_pot=newbias );
        }
        biasy_wait = BIAS_WAIT;
      } else {
        biasy_wait--;
      }
    }
    call OscopeCh3.put(mag_gainy_pot);
    call OscopeCh4.put(magy_data);
  }

  async event result_t MagXADC.dataReady(uint16_t _data) {
    magx_data = _data;
    post processMagXData();
    return SUCCESS;
  }

  async event result_t MagYADC.dataReady(uint16_t _data) {
    magy_data = _data;
    post processMagYData();
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    atomic m_received_msg = m;
    post processMsgTask();
    return m;
  }

  event void Mag.adjustGainXDone(bool result) { }
  event void Mag.adjustGainYDone(bool result) { }

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

  event result_t MicSampleTimer.fired() {
    call MicADC.getData();
    return SUCCESS;
  }

  async event result_t MicADC.dataReady(uint16_t _data) {
    call OscopeCh5.put(_data);
    return SUCCESS;
  }

  event void Mic.adjustDetectDone(bool result) { }
  event void Mic.adjustGainDone(bool result) { }
  event void Mic.adjustLpfFreq0Done(bool result) { }
  event void Mic.adjustLpfFreq1Done(bool result) { }
  event void Mic.adjustHpfFreq0Done(bool result) { }
  event void Mic.adjustHpfFreq1Done(bool result) { }

  task void interrupt_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_IOSWITCH1_INTERRUPT;
    atomic pMsg->subcmd = mask;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  event void IOSwitch1.setPortDone(result_t result) { }
  event void IOSwitch2.setPortDone(result_t result) { }

  event void Mic.firedAcoustic() {
    atomic mask = IOSWITCH1_INT_ACOUSTIC;
    post interrupt_report_task();
  }

  event result_t PIRSampleTimer.fired() {
    call PIRADC.getData();
    return SUCCESS;
  }

  async event result_t PIRADC.dataReady(uint16_t _data) {
    call OscopeCh6.put(_data);
    return SUCCESS;
  }

  event void PIR.adjustDetectDone(bool result) { }
  event void PIR.adjustQuadDone(bool result) { }
  event void PIR.firedPIR() {
    atomic mask = IOSWITCH1_INT_PIR;
    post interrupt_report_task();
  }



}










