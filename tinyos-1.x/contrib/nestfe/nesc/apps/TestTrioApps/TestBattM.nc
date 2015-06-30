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
 * Implementation file for TestBatt. <p>
 *
 * @modified 6/6/05
 *
 * @author Jaein Jeong
 */

module TestBattM
{
  provides {
    interface StdControl;
  }
  uses {
    interface StdControl as PrometheusControl;
    interface Prometheus;
    interface StdControl as CommControl;
    interface ReceiveMsg;
    interface SendMsg;
    interface Leds;
    interface Timer as InitTimer;
  }
}

implementation
{
  TOS_Msg send_msg;
  TOS_MsgPtr m_received_msg = NULL;

  task void report_task();

  command result_t StdControl.init() {
    call CommControl.init();
    call PrometheusControl.init();
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call CommControl.start();
    call PrometheusControl.start();
    call InitTimer.start(TIMER_ONE_SHOT, 300);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call CommControl.stop();
    call PrometheusControl.stop();
    return SUCCESS;
  }

  event result_t InitTimer.fired() {
    return call Prometheus.Init();
  }

  event void Prometheus.getBattVolDone(uint16_t refVol, uint16_t battVol, 
                                       result_t success){ 
    struct TestTrioMsg *pMsg;

    if (success) {
      pMsg = (TestTrioMsg *) send_msg.data;
      pMsg->cmd = REPLY_PROMETHEUS_GETVOLTAGE;
      pMsg->subcmd = SUBCMD_PROMETHEUS_BATTVOL;
      pMsg->arg[0] = refVol & 0xff;
      pMsg->arg[1] = (refVol >> 8) & 0xff;
      pMsg->arg[2] = battVol & 0xff;
      pMsg->arg[3] = (battVol >> 8) & 0xff;
      post report_task();
    }
  } 

  event void Prometheus.getCapVolDone (uint16_t refVol, uint16_t capVol, 
                                       result_t success){ 
    struct TestTrioMsg *pMsg;

    if (success) {
      pMsg = (TestTrioMsg *) send_msg.data;
      pMsg->cmd = REPLY_PROMETHEUS_GETVOLTAGE;
      pMsg->subcmd = SUBCMD_PROMETHEUS_CAPVOL;
      pMsg->arg[0] = refVol & 0xff;
      pMsg->arg[1] = (refVol >> 8) & 0xff;
      pMsg->arg[2] = capVol & 0xff;
      pMsg->arg[3] = (capVol >> 8) & 0xff;
      post report_task();
    }
  } 

  event void Prometheus.getRefVolDone (uint16_t refVol, result_t success) { 
    struct TestTrioMsg *pMsg;

    if (success) {
      pMsg = (TestTrioMsg *) send_msg.data;
      pMsg->cmd = REPLY_PROMETHEUS_GETVOLTAGE;
      pMsg->subcmd = SUBCMD_PROMETHEUS_REFVOL;
      pMsg->arg[0] = refVol & 0xff;
      pMsg->arg[1] = (refVol >> 8) & 0xff;
      post report_task();
    }
  } 

  event void Prometheus.getADCSourceDone(bool high, result_t success) { 
    struct TestTrioMsg *pMsg;

    if (success) {
      pMsg = (TestTrioMsg *) send_msg.data;
      pMsg->cmd = REPLY_PROMETHEUS_GET_STATUS;
      pMsg->subcmd = SUBCMD_PROMETHEUS_ADCSOURCE;

      if (high) {
        pMsg->arg[0] = SUBCMD_ON;
      }
      else {
        pMsg->arg[0] = SUBCMD_OFF;
      }

      post report_task();
    }
  } 

  event void Prometheus.getPowerSourceDone(bool high, result_t success) { 
    struct TestTrioMsg *pMsg;

    if (success) {
      pMsg = (TestTrioMsg *) send_msg.data;
      pMsg->cmd = REPLY_PROMETHEUS_GET_STATUS;
      pMsg->subcmd = SUBCMD_PROMETHEUS_POWERSOURCE;

      if (high) {
        pMsg->arg[0] = SUBCMD_ON;
      }
      else {
        pMsg->arg[0] = SUBCMD_OFF;
      }

      post report_task();
    }
  } 

  event void Prometheus.getAutomaticDone(bool high, result_t success) {
    struct TestTrioMsg *pMsg;

    if (success) {
      pMsg = (TestTrioMsg *) send_msg.data;
      pMsg->cmd = REPLY_PROMETHEUS_GET_STATUS;
      pMsg->subcmd = SUBCMD_PROMETHEUS_AUTOMATIC;

      if (high) {
        pMsg->arg[0] = SUBCMD_ON;
      }
      else {
        pMsg->arg[0] = SUBCMD_OFF;
      }

      post report_task();
    }
  }

  event void Prometheus.getChargingDone(bool high, result_t success) { 
    struct TestTrioMsg *pMsg;

    if (success) {
      pMsg = (TestTrioMsg *) send_msg.data;
      pMsg->cmd = REPLY_PROMETHEUS_GET_STATUS;
      pMsg->subcmd = SUBCMD_PROMETHEUS_CHARGING;

      if (high) {
        pMsg->arg[0] = SUBCMD_ON;
      }
      else {
        pMsg->arg[0] = SUBCMD_OFF;
      }

      post report_task();
    }
  } 

  task void report_task() {
    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestTrioMsg),&send_msg);
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
    case CMD_PROMETHEUS_GETVOLTAGE:
      if (pMsg->subcmd == SUBCMD_PROMETHEUS_CAPVOL) {
        call Prometheus.getCapVol();
      }
      else if (pMsg->subcmd == SUBCMD_PROMETHEUS_BATTVOL) {
        call Prometheus.getBattVol(); 
      }
      else if (pMsg->subcmd == SUBCMD_PROMETHEUS_REFVOL) {
        call Prometheus.getRefVol();
      }
      break;
    case CMD_PROMETHEUS_SET_STATUS:
      if (pMsg->subcmd == SUBCMD_PROMETHEUS_AUTOMATIC) {
        call Prometheus.setAutomatic(pMsg->arg[0]);
      }
      else if (pMsg->subcmd == SUBCMD_PROMETHEUS_POWERSOURCE) {
        call Prometheus.setPowerSource(pMsg->arg[0]);
      }
      else if (pMsg->subcmd == SUBCMD_PROMETHEUS_CHARGING) {
        call Prometheus.setCharging(pMsg->arg[0]);
      }
      else if (pMsg->subcmd == SUBCMD_PROMETHEUS_ADCSOURCE) {
        call Prometheus.selectADCSource(pMsg->arg[0]);
      }
      break;
    case CMD_PROMETHEUS_GET_STATUS:
      if (pMsg->subcmd == SUBCMD_PROMETHEUS_AUTOMATIC) {
        call Prometheus.getAutomatic();
      }
      else if (pMsg->subcmd == SUBCMD_PROMETHEUS_POWERSOURCE) {
        call Prometheus.getPowerSource();
      }
      else if (pMsg->subcmd == SUBCMD_PROMETHEUS_CHARGING) {
        call Prometheus.getCharging();
      }
      else if (pMsg->subcmd == SUBCMD_PROMETHEUS_ADCSOURCE) {
        call Prometheus.getADCSource();
      }
      break;
    }
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    atomic m_received_msg = m;
    post processMsgTask();
    return m;
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr sent, result_t result) {
    return SUCCESS;
  }

}










