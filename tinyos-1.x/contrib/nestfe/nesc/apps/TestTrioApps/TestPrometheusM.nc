// @author Jaein Jeong

includes sensorboard;
includes TestReadingMsg;
includes TestTrioMsg;
includes hardware;

module TestPrometheusM
{
  provides {
    interface StdControl;
  }
  uses {
    interface Leds;
    interface StdControl as CommControl;
    interface SendMsg;
    interface ReceiveMsg;
    interface ADC as PIRADC; 
    interface StdControl as PIRControl;
    interface PIR;
    interface Timer as InitTimer;

    interface StdControl as PrometheusControl;
    interface Prometheus;

    interface LocalTime;
  }
}

implementation
{
  TOS_Msg send_msg;
  TOS_MsgPtr m_received_msg = NULL;

  uint16_t PIR_val;
  uint16_t Batt_val;
  uint16_t Cap_val;
  uint16_t RefVol = 1500;
  uint16_t Vcc = 0;

  bool     bPowerSource;
  bool     bCharging;
  uint32_t ts_val;

  uint16_t adc_data;

  uint8_t state;

  bool bPIROn = FALSE;
  bool bPrometheusInit = FALSE;

  task void data_send_task();
  task void report_adc_task();

  command result_t StdControl.init() {
    call CommControl.init();
    call PIRControl.init();
    call PrometheusControl.init();
    call Leds.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    //call CommControl.start();
    call PIRControl.start();
    call PrometheusControl.start();
    call InitTimer.start(TIMER_ONE_SHOT, 2000);

    return SUCCESS;
  }

  event result_t InitTimer.fired() {
    if (bPIROn == FALSE) {
      call PIR.PIROn();
      call InitTimer.start(TIMER_ONE_SHOT, 200);
      bPIROn = TRUE;
      return SUCCESS;
    }
    else if (bPrometheusInit == FALSE) {
      call Prometheus.Init();
      bPrometheusInit = TRUE;
      return SUCCESS;
    }
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call CommControl.stop();
    call PIRControl.stop();
    call PrometheusControl.stop();
    return SUCCESS;
  }

  event void PIR.readDetectDone(uint8_t val) { }
  event void PIR.readQuadDone(uint8_t val) { }

  event result_t SendMsg.sendDone(TOS_MsgPtr sent, result_t result) {
    return SUCCESS;
  }

  task void report_adc_task() {
    struct TestReadingMsg *pMsg;
    pMsg = (TestReadingMsg *) send_msg.data;

    pMsg->PIR_val = PIR_val;
    pMsg->Cap_val = Cap_val;
    pMsg->Batt_val = Batt_val;
    pMsg->bPowerSource = bPowerSource;
    pMsg->bCharging = bCharging;
    pMsg->ts_val = call LocalTime.read();
    pMsg->RefVol = RefVol;
    pMsg->Vcc = Vcc;

    call SendMsg.send(TOS_BCAST_ADDR,sizeof(struct TestReadingMsg),&send_msg);
  }

  async event result_t PIRADC.dataReady(uint16_t _data) {
    return SUCCESS;
  }

  event void Prometheus.automaticUpdate( bool runningOnBattery, 
    bool chargingBattery, uint16_t batteryVoltage, uint16_t capVoltage ) {
    atomic {
      Batt_val = batteryVoltage;
      Cap_val = capVoltage;
      bPowerSource = runningOnBattery;
      bCharging = chargingBattery;
    }
    //post report_adc_task();
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
    case CMD_PROMETHEUS_SET_STATUS:
      if (pMsg->subcmd == SUBCMD_PROMETHEUS_POWERSOURCE) {
        call Prometheus.setPowerSource(pMsg->arg[0]);
      }
      else if (pMsg->subcmd == SUBCMD_PROMETHEUS_CHARGING) {
        call Prometheus.setCharging(pMsg->arg[0]);
      }
      break;
    default:
      break;
    }
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    atomic m_received_msg = m;
    post processMsgTask();
    return m;
  }

  event void Prometheus.getBattVolDone(uint16_t battVol,result_t success){} 
  event void Prometheus.getCapVolDone(uint16_t capVol, result_t success){}
  event void Prometheus.getPowerSourceDone(bool high, result_t success){}
  event void Prometheus.getChargingDone(bool high, result_t success){}
  event void Prometheus.getADCSourceDone(bool high, result_t success) { }
  event void Prometheus.getAutomaticDone(bool high, result_t success) { }
  
  event void PIR.adjustDetectDone(bool result) { }
  event void PIR.adjustQuadDone(bool result) { }
  event void PIR.firedPIR() { }
}










