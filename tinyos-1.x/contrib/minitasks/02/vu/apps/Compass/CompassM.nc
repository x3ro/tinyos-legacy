/**
 * Compass - Copyright (c) 2003 ISIS
 *
 * Author: Peter Volgyesi
 **/
 


module CompassM {
  provides {
    interface StdControl;
  }
  uses {
    interface Clock;
    interface Leds;
    interface StdControl as SmartMagControl;
    interface SmartMag;
    interface StdControl as CommControl;
    interface SendMsg as DataMsg;
    interface ReceiveMsg as CalibrateMsg;
  }
}
implementation {

  /** 
   * state variables
   */
  uint8_t readingNumber;
  TOS_Msg msg[2];
  uint8_t currentMsg;

  /**
   * Initialize the component.
   **/
  command result_t StdControl.init() {
    call Leds.init();
    call Leds.yellowOff(); call Leds.redOff(); call Leds.greenOff();
    
    call SmartMagControl.init();
    call CommControl.init();
    
    currentMsg = 0;
    readingNumber = 0;
    
    return SUCCESS;
  }


  /**
   * Start things up.  This just sets the rate for the clock component.
   **/
  command result_t StdControl.start() {
    call SmartMagControl.start();
    call CommControl.start();
    
    return call Clock.setRate(TOS_I4PS, TOS_S4PS);
  }

  /**
   * Halt execution of the application.
   * This just disables the clock component.
   **/
  command result_t StdControl.stop() {
    call SmartMagControl.stop();
    call CommControl.stop();
    call Clock.setRate(TOS_I0PS, TOS_S0PS);
    return SUCCESS;
  }


  /**
   * Clock tick
   **/
  event result_t Clock.fire()
  {
    result_t result = call SmartMag.read();
    if (result != SUCCESS) {
    	call Leds.redOn();
    }
    else {
    	call Leds.redOff();
    }
    return SUCCESS;
  }
  
  /**
   * Signalled when data is ready from the MAG. Stuffs the sensor
   * reading into the current packet, and sends off the packet when both values are available
   */
  event result_t SmartMag.readDone(MagValue* values) {
    struct MagMsg *pack = (struct MagMsg *)msg[currentMsg].data;
    pack->readingNumber = readingNumber++;
    pack->X = values->X;
    pack->Y = values->Y;
    pack->biasX = values->biasX;
    pack->biasY = values->biasY;
    
     /* Try to send the packet. Note that this will return
     * failure immediately if the packet could not be queued for
     * transmission.
     */
    if (call DataMsg.send(TOS_BCAST_ADDR, sizeof(struct MagMsg),
			       &msg[currentMsg])) {
    	currentMsg ^= 0x1;
    	call Leds.greenToggle();
    }
    return SUCCESS;
  }
  
  
  /**
  * Signalled when the previous packet has been sent.
  */
  event result_t DataMsg.sendDone(TOS_MsgPtr sent, result_t success) {
    return SUCCESS;
  }
  
  /**
   * Signalled when the calibration message is received.
   * @return The free TOS_MsgPtr. 
   */
  event TOS_MsgPtr CalibrateMsg.receive(TOS_MsgPtr calmsg) {
    struct CalMsg *pack = (struct CalMsg *)calmsg->data;
    call SmartMag.calibrate(pack->bias_center, pack->bias_scale);
    call Leds.yellowToggle();
    return calmsg;
  }
  
}


