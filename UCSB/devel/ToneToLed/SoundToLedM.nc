/**
 * Implementation for SoundToLed application.
 * 
 * Detects 4kHz tone and turns the Leds on if present
 * 
 * @author Greg Moore
 **/


module SoundToLedM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface Leds;
    interface StdControl as MicControl;
    interface ADC as MicADC;
    interface Mic;
  }
}
implementation {

  // declare module static variables here  
  char state;
  char count;
  char detected;

  /**
   * Initialize the component. Initialize the Mic.
   *
   * @return returns <code>SUCCESS</code>
   **/                       
  command result_t StdControl.init() {
    state = FALSE;
    call Leds.init();
    call MicControl.init();
    call MicControl.init();
    call Mic.muxSel(1);  // Set the mux so that raw microhpone output is selected. (refer to Mic.ti)
    call Mic.gainAdjust(64);  // Set the gain of the microphone.  (refer to Mic.ti)

    return SUCCESS;
  }

  /**
   * Start the component, Mic, Timer, and Photo
   *
   * @return returns <code>SUCCESS</code> or <code>FAIL</code>
   **/                       
  command result_t StdControl.start() {
    call MicControl.start();
    call MicControl.start();

    return call Timer.start(TIMER_REPEAT, 8); // 128 pulses per second
  }

  /**
   * Stop the component, Mic, Timer, and Photo.
   *
   * @return returns <code>SUCCESS</code> or <code>FAIL</code>
   **/                       
  command result_t StdControl.stop() {
    call MicControl.stop();
    call MicControl.stop();

    return call Timer.stop();
  }

  /**
   * In response to the <code>Timer.fired</code> event, toggle the LED,
   * sample the tone detector's output from the microphone, and perform
   * simple filtering to eliminate false negatives and positives from the tone
   * detector.
   *
   * @return returns <code>SUCCESS</code>
   **/                       
  event result_t Timer.fired()
  {
    char in;
 
    /* Read the input from the tone detector */
    in = call Mic.readToneDetector();

    // Low pass filtering
    if (in == 0){
      if (count < 32)
	  count++;
    }else{
      if (count > 0)
	  count--;
    }       
    return SUCCESS;
  }

  /**
   * In response to the <code>MicADC.dataReady</code> event, do nothing.
   *
   * @return returns <code>SUCCESS</code>
   **/                       
  async event result_t MicADC.dataReady(uint16_t data)
  {
    return SUCCESS;
  }                
}
