// $Id: MonibusSensorsToUSBM.nc,v 1.2 2005/07/04 09:30:41 neturner Exp $

/**
 * Query the sensors on the monibus sensor board once
 * every abitrary TIME_INTERVAL and send its
 * response via USB.  A PC application (e.g. MsgReader)
 * is intended to receive and
 * print the response.
 * <p>
 * @author Neil E. Turner
 */

includes MonibusSensorMsg;

module MonibusSensorsToUSBM {

  provides interface StdControl;

  uses {
    interface ADC as PAR; //photosynthetically active radiation
    interface ADC as TSR; //total solar radiation
    interface ADC as Voltage12;
    interface Leds;
    interface SendMsg;
    interface StdControl as HamamatsuControl;
    interface StdControl as MessageControl;
    interface StdControl as TimerControl;
    interface StdControl as Voltage12Control;
    interface Timer;
  }
}

implementation {

  //////////////// Constants ////////////////
  enum {
    TIMER_INTERVAL = 5000
  };

  //////////////// Member variables ////////////////
  /**
   *
   */
  uint16_t PARReading;

  /**
   * The flag that, when TRUE, indicates that the PAR
   * sensor has returned at least one
   * new reading since the last message was sent out.
   */
  bool PARReady = FALSE;

  /**
   * The message to be sent.
   * <p>
   */
  TOS_Msg TOSMessage;

  /**
   *
   */
  uint16_t TSRReading;

  /**
   * The flag that, when TRUE, indicates that the TSR
   * sensor has returned at least one
   * new reading since the last message was sent out.
   */
  bool TSRReady = FALSE;

  /**
   *
   */
  uint16_t voltage12Reading;

  /**
   * The flag that, when TRUE, indicates that the voltage
   * sensor has returned at least one
   * new reading since the last message was sent out.
   */
  bool voltage12Ready = FALSE;

  ////////////////  Tasks  ////////////////
  /**
   * Assemble and send the message.
   */
  task void assembleAndSendMessage() {
    struct MonibusSensorMsg *message;
    call Leds.yellowToggle();
    atomic {
      message = (struct MonibusSensorMsg *) TOSMessage.data;
    }

    //assemble the message
    message->sourceMoteID = TOS_LOCAL_ADDRESS;
    message->PAR = PARReading;
    message->TSR = TSRReading;
    message->voltage12 = voltage12Reading;
    //reset the flags
    PARReady = FALSE;
    TSRReady = FALSE;
    voltage12Ready = FALSE;

    /* Try to send the packet over the telos' USB (which is done thru the
     * UART). Note that this will return
     * failure immediately if the packet could not be queued for
     * transmission.
     */
    call SendMsg.send(TOS_UART_ADDR,
		      sizeof(struct MonibusSensorMsg),
		      &TOSMessage);

    call Timer.start(TIMER_ONE_SHOT, TIMER_INTERVAL);
  }

  /**
   * Query the sensors.
   */
  task void querySensors() {
    if (call PAR.getData() != SUCCESS) {

      PARReady = TRUE;
      PARReading = 0x1111;

      TSRReady = TRUE;
      TSRReading = 0x1111;
    }

    if (call Voltage12.getData() != SUCCESS) {
      voltage12Ready = TRUE;
      voltage12Reading = 0x1111;
    }
  }

  ////////////////  StdControl commands  ////////////////
  /**
   * Call init() on the HamamatsuC, LedsC, GenericComm,
   * Voltage12C, and TimerC
   * components.
   * <p>
   * @return Always return SUCCESS.
   */
  command result_t StdControl.init() {

    call HamamatsuControl.init();
    call Leds.init();
    call MessageControl.init();
    call TimerControl.init();
    call Voltage12Control.init();

    return SUCCESS;
  }

  /**
   * Call start() on the GenericComm, HamamatsuC,
   * Voltage12C, and TimerC components.
   * <p>
   * @return Always return SUCCESS.
   */
  command result_t StdControl.start() {

    call HamamatsuControl.start();
    call MessageControl.start();
    call Timer.start(TIMER_ONE_SHOT, TIMER_INTERVAL);
    call Voltage12Control.start();

    return SUCCESS;
  }

  /**
   * Call stop() on the MessageControl and Timer components
   * and turn off all LEDs.
   * <p>
   * @return Always return SUCCESS.
   */
  command result_t StdControl.stop() {
    call Timer.stop();
    call MessageControl.stop();
    call Leds.greenOff();
    call Leds.yellowOff();
    call Leds.redOff();
    return SUCCESS;
  }

  ////////////////  Timer events  ////////////////
  /**
   * Post the task to query the sensors. Toggle the red LED as well.
   * <p>
   * @return Always return SUCCESS.
   */
  event result_t Timer.fired() {
    call Leds.redToggle();

    post querySensors();

    return SUCCESS;
  }

  ////////////////  SendMsg events  ////////////////
  /**
   * Do nothing.
   * <p>
   * @return Always return SUCCESS.
   */
  event result_t SendMsg.sendDone(TOS_MsgPtr sent, result_t success) {
    return SUCCESS;
  }

  ////////////////  PAR events  ////////////////
  /**
   * Save the sensor reading and set the flag indicating that
   * a fresh PAR reading is available. Query the TSR sensor now.
   * <p>
   * @return Always return SUCCESS.
   */
  async event result_t PAR.dataReady(uint16_t data) {

    atomic{
      PARReading = data;
      PARReady = TRUE;
    }

    if (call TSR.getData() != SUCCESS) {
      TSRReady = TRUE;
      TSRReading = 0x1112;
    }

    return SUCCESS;
  }

  ////////////////  TSR events  ////////////////
  /**
   * Save the sensor reading and set the flag indicating that
   * a fresh TSRreading is available. If all sensors have
   * reported back with fresh sensor readings since the last
   * message was sent, then post the task responsible for
   * sending the next message.
   * <p>
   * @return Always return SUCCESS.
   */
  async event result_t TSR.dataReady(uint16_t data) {

    atomic {
      TSRReading = data;
      TSRReady = TRUE;

      if (PARReady && TSRReady && voltage12Ready) {
	post assembleAndSendMessage();
      }
    }

    return SUCCESS;
  }

  ////////////////  Voltage12 events  ////////////////
  /**
   * Save the sensor reading and set the flag indicating that
   * a fresh PAR reading is available. If all sensors have
   * reported back with fresh sensor readings since the last
   * message was sent, then post the task responsible for
   * sending the next message.
   * <p>
   * @return Always return SUCCESS.
   */
  async event result_t Voltage12.dataReady(uint16_t data) {

    atomic{
      voltage12Reading = data;
      voltage12Ready = TRUE;

      if (PARReady && TSRReady && voltage12Ready) {
	post assembleAndSendMessage();
      }
    }

    return SUCCESS;
  }
}
