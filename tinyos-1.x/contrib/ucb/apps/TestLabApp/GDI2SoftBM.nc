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

/* Authors:             Joe Polastre
 * 
 * $Id: GDI2SoftBM.nc,v 1.2 2003/10/07 21:45:32 idgay Exp $
 *
 */

includes GDI2SoftMsg;
includes avr_eeprom;
includes gdi_const;

/**
 * 
 */
module GDI2SoftBM {
  provides {
    interface StdControl;
    command result_t ForwardDone(uint8_t id);
  }
  uses {
    command result_t SetListeningMode(uint8_t power);
    command uint8_t GetListeningMode();
    command result_t SetTransmitMode(uint8_t power);
    command uint8_t GetTransmitMode();

    command result_t PowerEnable();
    command result_t PowerDisable();

    command void setRouteUpdateInterval(uint32_t millisec);

    interface CC1000Control;

    interface RouteState;

    interface Leds;
    interface Timer;
    interface Timer as WaitTimer;
    interface Timer as BackoffTimer;
    interface Timer as NetworkTimer;

    interface Reset;

    interface Random;

    interface SplitControl as HumidityControl;
    interface SplitControl as MelexisControl;
    interface ADCControl as VoltageControl;

    interface ADC as Humidity;
    interface ADC as HumidityTemp;
    interface ADC as Thermopile;
    interface ADC as Temperature;
    interface ADC as Voltage;
    interface ADCError as HumidityError;
    interface ADCError as HumidTempError;
    interface Calibration;

    interface Send as Send;
    interface Send as SendCalib;
    interface Send as SendAck;
    interface Receive as ReceiveCalib;
    interface ReceiveMsg as ReceiveCalibLocal;
    interface Receive as ReceiveRate;
    interface Receive as ReceiveReset;
    interface Receive as ReceiveQuery;
    interface Receive as ReceiveNetwork;
  }
}
implementation {

#define MOTE_TYPE 1
#define CONST_30_SEC 30720

  TOS_Msg msg_buf;
  TOS_MsgPtr msg;

  TOS_Msg calib_msg_buf;
  TOS_MsgPtr calib_msg;

  TOS_Msg ack_msg_buf;
  TOS_MsgPtr ack_msg;

  GDI2Soft_B_REV2_Msg* datastruct;
  GDI2Soft_Calib_Msg* calibstruct;
  GDI2Soft_Calib_In_Msg* calibinstruct;
  GDI2Soft_Ack_REV2_Msg* ackstruct;

  uint8_t calib_count;
  uint8_t wait_timer;

  uint16_t command_id;

  uint16_t calibration[4];

  uint8_t wait_state;
  uint8_t working;

  uint8_t state;
  uint16_t min_counter;
  uint8_t sec_counter;

  uint8_t minutes;
  uint8_t seconds;

  bool sec_timer;

  uint8_t temp[10];

  uint32_t current_seqno;

  enum {
    IDLE = 0, SAMPLE, CALIB, WAITING, RATE
  };

  inline unsigned long int get_eeprom_next_seqno()
  {
    unsigned long int rval = 0;
    unsigned long int seqno = 0;
    unsigned char *ptr =
        (unsigned char *) &seqno;

    ptr[0] = eeprom_read_byte((uint8_t*)0);
    ptr[1] = eeprom_read_byte((uint8_t*)1);
    ptr[2] = eeprom_read_byte((uint8_t*)2);
    ptr[3] = eeprom_read_byte((uint8_t*)3);

    rval = ++seqno;

    atomic {
      eeprom_write_byte((uint8_t*)0, ptr[0]);
      eeprom_write_byte((uint8_t*)1, ptr[1]);
      eeprom_write_byte((uint8_t*)2, ptr[2]);
      eeprom_write_byte((uint8_t*)3, ptr[3]);
    }

    return(rval);
  }

  inline uint32_t eeprom_next_seqno() {
    current_seqno = get_eeprom_next_seqno();
    return current_seqno;
  }

  inline uint32_t get_current_seqno() {
    return current_seqno;
  }

  uint8_t get_sample_min()
  {
    return minutes;
  }

  inline uint8_t get_eeprom_sample_min()
  {
    return eeprom_read_byte((uint8_t *)4);
  }

  inline void set_sample_min(uint8_t value)
  {
    minutes = value;
    atomic eeprom_write_byte((uint8_t *)4, value);
  }

  uint8_t get_sample_sec()
  {
    return seconds;
  }

  inline uint8_t get_eeprom_sample_sec()
  {
    return eeprom_read_byte((uint8_t *)5);
  }

  inline void set_sample_sec(uint8_t value)
  {
    seconds = value;
    atomic eeprom_write_byte((uint8_t *)5, value);
  }

  task void adjustRate() {
    uint16_t rand_value;

    call Leds.redOn();
    min_counter = sec_counter = 0;
    sec_timer = FALSE;
    call BackoffTimer.stop();
    call Timer.stop();

    rand_value = call Random.rand();
    call BackoffTimer.start(TIMER_ONE_SHOT, rand_value);
    
    ackstruct->command_id = command_id;
    ackstruct->source = TOS_LOCAL_ADDRESS;
    ackstruct->seqno = get_current_seqno();
    ackstruct->sample_rate_min = get_sample_min();
    ackstruct->sample_rate_sec = get_sample_sec();
    ackstruct->args = rand_value;
    ackstruct->parent = call RouteState.getParent();
    call SendAck.send(ack_msg, sizeof(GDI2Soft_Ack_REV2_Msg));
    working = IDLE;
  }

  task void sendQuery() {
    call Leds.redOn();
    ackstruct->args = 0;
    ackstruct->source = TOS_LOCAL_ADDRESS;
    ackstruct->seqno = get_current_seqno();
    ackstruct->sample_rate_min = get_sample_min();
    ackstruct->sample_rate_sec = get_sample_sec();
    ackstruct->command_id = command_id;
    ackstruct->parent = call RouteState.getParent();
    call SendAck.send(ack_msg, sizeof(GDI2Soft_Ack_REV2_Msg));
  }

  task void sendMsg() {
    datastruct->sample_rate_min = get_sample_min();
    datastruct->sample_rate_sec = get_sample_sec();
    datastruct->parent = call RouteState.getParent();
    call Send.send(msg, sizeof(GDI2Soft_B_REV2_Msg));
    working = IDLE;
  }

  task void sendCalibData() {
    calibstruct->source = TOS_LOCAL_ADDRESS;
    calibstruct->word1 = calibration[0];
    calibstruct->word2 = calibration[1];
    calibstruct->word3 = calibration[2];
    calibstruct->word4 = calibration[3];
    call SendCalib.send(calib_msg, sizeof(GDI2Soft_Calib_Msg));
    working = IDLE;
  }

  task void getRealVoltage() {
    TOSH_CLR_PW7_PIN();
    TOSH_MAKE_PW7_OUTPUT();
    TOSH_CLR_PW6_PIN();
    TOSH_MAKE_PW6_INPUT();
    call Voltage.getData();
  }
  
  task void getVoltage() {
    post getRealVoltage();
  }

  task void goToWork() {
    state = 0;
    datastruct->seqno = eeprom_next_seqno();
    call Leds.redOn();
    call MelexisControl.start();
  }

  task void getCalib() {
    calibstruct->seqno = get_current_seqno();
    calibstruct->command_id = command_id;
    calib_count = 0;
    call MelexisControl.start();
  }

  /**
   * Initialize this and all low level components used in this application.
   * 
   * @return returns <code>SUCCESS</code> or <code>FAIL</code>
   */
  command result_t StdControl.init() {
    msg = &msg_buf;
    calib_msg = &calib_msg_buf;
    ack_msg = &ack_msg_buf;
    datastruct = (GDI2Soft_B_REV2_Msg*)msg_buf.data;
    calibstruct = (GDI2Soft_Calib_Msg*)calib_msg_buf.data;
    ackstruct = (GDI2Soft_Ack_REV2_Msg*)ack_msg_buf.data;

    calibstruct->mote_type = MOTE_TYPE;
    ackstruct->mote_type = MOTE_TYPE;

    command_id = 0;

    minutes = get_eeprom_sample_min();
    seconds = get_eeprom_sample_sec();

    call Random.init();

    // set multihop routing to update routes every 5 minutes
    call setRouteUpdateInterval(NETWORK_UPDATE_SLOW);

    // eeprom has been chip-erased
    if ((minutes == 0xFF) && (seconds == 0xFF)) {
      minutes = DEFAULT_TIME_MIN;
      seconds = DEFAULT_TIME_SEC;
    }

    // set low power listening mode
    call SetListeningMode(OFF_MODE);
    call SetTransmitMode(OFF_MODE);

    call CC1000Control.SetRFPower(RF_POWER_LEVEL);

    call HumidityControl.init();
    call MelexisControl.init();
    call VoltageControl.init();
    call Leds.init();

    call PowerEnable();

    return SUCCESS;
  }

  /**
   * Start this component.
   * 
   * @return returns <code>SUCCESS</code>
   */
  command result_t StdControl.start(){
    uint16_t rand_value;

    working = IDLE;
    wait_state = IDLE;
    state = 0;
    min_counter = sec_counter = 0;
    sec_timer = FALSE;

    call HumidityError.enable();
    call HumidTempError.enable();

    rand_value = call Random.rand();
    call BackoffTimer.start(TIMER_ONE_SHOT, rand_value);

    datastruct->source = TOS_LOCAL_ADDRESS;

    return SUCCESS;
  }

  /**
   * Stop this component.
   * 
   * @return returns <code>SUCCESS</code>
   */
  command result_t StdControl.stop() {
    call BackoffTimer.stop();
    call Timer.stop();
    return SUCCESS;
  }

  event result_t BackoffTimer.fired() {
    sec_timer = FALSE;
    min_counter = sec_counter = 0;
    if (get_sample_min() > 0)
      call Timer.start(TIMER_REPEAT, CONST_30_SEC);
    else
      if (get_sample_sec() > 30) {
        sec_timer = TRUE;
        sec_counter = 2;
        call Timer.start(TIMER_ONE_SHOT, (get_sample_sec()*512));
      }
      else {
        sec_timer = TRUE;
        sec_counter = 1;
        call Timer.start(TIMER_ONE_SHOT, (get_sample_sec()*1024));
      }

    return SUCCESS;
  }

  event result_t WaitTimer.fired() {
    wait_timer++;
    if (wait_timer >= WAIT_TIMEOUT) {
	call WaitTimer.stop();
//      call Reset.reset();
    }
    return SUCCESS;
  }

  event result_t Timer.fired() {
    // sample
    if ((sec_timer == FALSE) && (get_sample_min() > 0)) {
      min_counter++;
      if ((min_counter >> 1) >= get_sample_min()) {
        call Timer.stop();
        min_counter = 0;
        if (get_sample_sec() > 0) {
          sec_timer = TRUE;
          if (get_sample_sec() > 30) {
            sec_counter = 2;
            return call Timer.start(TIMER_ONE_SHOT, (get_sample_sec()*512));
          }
          else {
            sec_counter = 1;
            return call Timer.start(TIMER_ONE_SHOT, (get_sample_sec()*1024));
          }
        }
      }
      else 
        return SUCCESS;
    }
    else if (sec_timer == TRUE) {
      sec_counter--;
      if (sec_counter > 0)
        return call Timer.start(TIMER_ONE_SHOT, (get_sample_sec()*512));
    }

    call PowerDisable();
    call Timer.stop();

    wait_timer = 0;
    call WaitTimer.start(TIMER_REPEAT, WAIT_TIME_MS);

    atomic working = SAMPLE;
    sec_timer = FALSE;
    min_counter = sec_counter = 0;

    if (get_sample_min() > 0)
      call Timer.start(TIMER_REPEAT, CONST_30_SEC);
    else
      if (get_sample_sec() > 30) {
        sec_timer = TRUE;
        sec_counter = 2;
        call Timer.start(TIMER_ONE_SHOT, (get_sample_sec()*512));
      }
      else {
        sec_timer = TRUE;
        sec_counter = 1;
        call Timer.start(TIMER_ONE_SHOT, (get_sample_sec()*1024));
      }

    post goToWork();
    return SUCCESS;
  }

  event result_t HumidityControl.startDone() {
    call Humidity.getData();
    return SUCCESS;
  }

  event result_t MelexisControl.startDone() {
    if (working == SAMPLE)  {
      call HumidityControl.start();
      call Thermopile.getData();
    }
    else if (working == CALIB) {
      call Calibration.getData();
    }
    return SUCCESS;
  }

  event result_t Humidity.dataReady(uint16_t data) {
    datastruct->humidity = data;
    return call HumidityTemp.getData();
  }

  event result_t HumidityError.error(uint8_t token) {
    datastruct->humidity = 0;
    return call HumidityTemp.getData();
  }    

  event result_t HumidityTemp.dataReady(uint16_t data) {
    datastruct->humidity_temp = data;
    atomic state |= HUMIDITY_MASK;
    call HumidityControl.stop();
    if (state == TOTAL_MASK_B) 
      post getVoltage();
    return SUCCESS;
  }

  event result_t HumidTempError.error(uint8_t token) {
    datastruct->humidity_temp = 0;
    call HumidityControl.stop();
    atomic state |= HUMIDITY_MASK;
    if (state == TOTAL_MASK_B) 
      post getVoltage();
    return SUCCESS;
  }

  event result_t Thermopile.dataReady(uint16_t data) {
    datastruct->thermopile = data;
    return call Temperature.getData();
  }

  event result_t Temperature.dataReady(uint16_t data) {
    datastruct->therm_temp = data;
    call MelexisControl.stop();
    return SUCCESS;
  }

  event result_t HumidityControl.initDone() {
    return SUCCESS;
  }

  event result_t HumidityControl.stopDone() {
    return SUCCESS;
  }

  event result_t MelexisControl.initDone() {
    return SUCCESS;
  }

  event result_t MelexisControl.stopDone() {
    atomic state |= MELEXIS_MASK;
    if (state == TOTAL_MASK_B) 
      post getVoltage();
    return SUCCESS;
  }

  event result_t NetworkTimer.fired() {
    call Leds.redOff();
    call setRouteUpdateInterval(NETWORK_UPDATE_SLOW);
    if (call GetListeningMode() != OFF_MODE) {
      if (call SetListeningMode(OFF_MODE) != SUCCESS)
        // keep retrying to set ourselves in low power listening
        call NetworkTimer.start(TIMER_ONE_SHOT, 512);
    }
    call SetTransmitMode(OFF_MODE);
    return SUCCESS;
  }

  event result_t Send.sendDone(TOS_MsgPtr sent_msgptr, result_t success){
    call WaitTimer.stop();
    call Leds.redOff();
    call PowerEnable();
    return SUCCESS;
  }

  event result_t SendCalib.sendDone(TOS_MsgPtr sent_msgptr, result_t success){
    call Leds.redOff();
    return SUCCESS;
  }

  event result_t SendAck.sendDone(TOS_MsgPtr sent_msgptr, result_t success){
    call Leds.redOff();
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveNetwork.receive(TOS_MsgPtr m, void* payload, uint16_t payloadLen) {
    call Leds.redOn();
    call SetListeningMode(ON_MODE);
    call SetTransmitMode(OFF_MODE);
    call setRouteUpdateInterval(NETWORK_UPDATE_FAST);
    call NetworkTimer.start(TIMER_ONE_SHOT, NETWORK_UPDATE_FAST_TIMEOUT);

    return m;
  }

  command result_t ForwardDone(uint8_t id) {
    if (id == AM_GDI2SOFT_NETWORK_MSG) {
      call SetTransmitMode(ON_MODE);
    }
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveCalib.receive(TOS_MsgPtr m, void* payload, uint16_t payloadLen) {
    if (working == IDLE) {
      calibinstruct = (GDI2Soft_Calib_In_Msg*)(m->data);
      if ((calibinstruct->dest == TOS_LOCAL_ADDRESS) ||
          (calibinstruct->dest == 0xFFFF)) {
        command_id = calibinstruct->command_id;
        atomic working = CALIB;
        post getCalib();
      }
    }
    return m;
  }

  event TOS_MsgPtr ReceiveCalibLocal.receive(TOS_MsgPtr m) {
    return signal ReceiveCalib.receive(m, (void*)m->data, m->length);
  }

  event TOS_MsgPtr ReceiveRate.receive(TOS_MsgPtr m, void* payload, uint16_t payloadLen) {
    GDI2Soft_Rate_Msg* datamsg = (GDI2Soft_Rate_Msg*) m->data;
    if ((working == IDLE) && ((datamsg->dest == TOS_LOCAL_ADDRESS) || 
        (datamsg->dest == 0xFFFF))) {
      atomic working = RATE;
      call Timer.stop();
      call BackoffTimer.stop();
      command_id = datamsg->command_id;

      // doesn't make sense to have more than 59 seconds
      if (datamsg->sample_rate_sec > 59)
        datamsg->sample_rate_sec = 0;

      set_sample_min(datamsg->sample_rate_min);
      set_sample_sec(datamsg->sample_rate_sec);
      post adjustRate();
    }
    return m;
  }

  event TOS_MsgPtr ReceiveQuery.receive(TOS_MsgPtr m, void* payload, uint16_t payloadLen) {
    calibinstruct = (GDI2Soft_Calib_In_Msg*)(m->data);
    if ((calibinstruct->dest == TOS_LOCAL_ADDRESS) ||
        (calibinstruct->dest == 0xFFFF)) {
      command_id = calibinstruct->command_id;
      post sendQuery();
    }
    return m;
  }

  event TOS_MsgPtr ReceiveReset.receive(TOS_MsgPtr m, void* payload, uint16_t payloadLen) {
    calibinstruct = (GDI2Soft_Calib_In_Msg*)(m->data);
    if ((calibinstruct->dest == TOS_LOCAL_ADDRESS) ||
        (calibinstruct->dest == 0xFFFF)) {
      call Leds.redOn();
      call Reset.reset();
    }
    return m;
  }

  event result_t Calibration.dataReady(char word, uint16_t value) {

    // make sure we get all the calibration bytes
    calib_count++;

    calibration[word-1] = value;

    if (calib_count == 2) {
      call MelexisControl.stop();
      working = IDLE;
      post sendCalibData();
    }

    return SUCCESS;
  }

  event result_t Voltage.dataReady(uint16_t data) {
    datastruct->voltage = data;
    TOSH_SET_PW7_PIN();
    TOSH_MAKE_PW7_INPUT();
    post sendMsg();
    return SUCCESS;
  }

}
