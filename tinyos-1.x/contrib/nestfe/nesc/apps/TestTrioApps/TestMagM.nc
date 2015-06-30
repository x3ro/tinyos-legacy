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
 * Implementation file for TestMag. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

includes sensorboard;
includes TestTrioMsg;

module TestMagM
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
    interface StdControl as IOSwitch1Control;
    interface IOSwitch as IOSwitch1;
    interface StdControl as IOSwitch2Control;
    interface IOSwitch as IOSwitch2;
    interface Timer as SampleXTimer;
    interface Timer as SampleYTimer;
    interface Oscope as OscopeCh1;
    interface Oscope as OscopeCh2;
    interface Oscope as OscopeCh3;
    interface Oscope as OscopeCh4;
  }
}

implementation
{
  enum {
    BIAS_WAIT = 0,
  };

  TOS_Msg send_msg;
  TOS_MsgPtr m_received_msg = NULL;
  uint8_t gainx_pot = 120;
  uint8_t gainy_pot = 120;
  uint8_t port0_bits = 0;
  uint8_t port1_bits = 0;
  
  uint16_t adc_data;
  uint8_t adc_port;

  uint16_t magx_data = 0;
  uint16_t magy_data = 0;
  bool auto_bias_x = TRUE;
  bool auto_bias_y = TRUE;
  int16_t biasx_wait = 0;
  int16_t biasy_wait = 0;

  task void data_send_task();
  task void gainx_report_task();
  task void gainy_report_task();
  task void report_adc_task();

  command result_t StdControl.init() {
    call CommControl.init();
    call MagControl.init();
    call IOSwitch1Control.init();
    call IOSwitch2Control.init();
    call Leds.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call CommControl.start();
    call MagControl.start();
    call IOSwitch1Control.start();
    call IOSwitch2Control.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call CommControl.stop();
    call MagControl.stop();
    call IOSwitch1Control.stop();
    call IOSwitch2Control.stop();
    return SUCCESS;
  }

  task void gainx_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MAG_POT_READ;
    pMsg->subcmd = SUBCMD_MAG_GAINX;
    pMsg->arg[0] = gainx_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  task void gainy_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MAG_POT_READ;
    pMsg->subcmd = SUBCMD_MAG_GAINY;
    pMsg->arg[0] = gainy_pot;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  event void Mag.readGainXDone(uint8_t val) {
    atomic gainx_pot = val;
    post gainx_report_task();
  }

  event void Mag.readGainYDone(uint8_t val) {
    atomic gainy_pot = val;
    post gainy_report_task();
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
        //call MagXADC.getData();
      }
      else if (pMsg->subcmd == SUBCMD_MAG_ADC1) {
        if (pMsg->arg[0] == SUBCMD_ON) {
          call SampleYTimer.start(TIMER_REPEAT, 10);
        }
        else if (pMsg->arg[0] == SUBCMD_OFF) {
          call SampleYTimer.stop();
        }
        //call MagYADC.getData();
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

  task void report_adc_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_MAG_ADCREADY;
    atomic {
      pMsg->subcmd = adc_port;
      pMsg->arg[0] = (uint8_t) (adc_data & 0xff);
      pMsg->arg[1] = (uint8_t) ((adc_data >> 8) & 0xff);
    }
    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
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
        uint8_t newbias = getNewBias( magx_data, gainx_pot );
        if( newbias != gainx_pot ) {
          call Mag.adjustGainX( gainx_pot=newbias );
        }
        biasx_wait = BIAS_WAIT;
      } else {
        biasx_wait--;
      }
    }
    //atomic {
    //  adc_data = _data;
    //  adc_port = 0;
    //}
    //post report_adc_task();
    call OscopeCh1.put(gainx_pot);
    call OscopeCh2.put(magx_data);
  }

  task void processMagYData()
  {
    if( auto_bias_y ) {
      if( biasy_wait <= 0 ) {
        uint8_t newbias = getNewBias( magy_data, gainy_pot );
        if( newbias != gainy_pot ) {
          call Mag.adjustGainY( gainy_pot=newbias );
        }
        biasy_wait = BIAS_WAIT;
      } else {
        biasy_wait--;
      }
    }
    //atomic {
    //  adc_data = _data;
    //  adc_port = 1;
    //}
    //post report_adc_task();
    call OscopeCh3.put(gainy_pot);
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

  task void interrupt_report_task() {
    struct TestTrioMsg *pMsg;
    pMsg = (TestTrioMsg *) send_msg.data;
    pMsg->cmd = REPLY_IOSWITCH2_INTERRUPT;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
  }

  event void IOSwitch1.setPortDone(result_t result) { }
  event void IOSwitch2.setPortDone(result_t result) { }

}










