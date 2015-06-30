/* @author Cory Sharp, Phoebus Chen
 * @modified 7/21/2005 copied over from apps/TestDetectionEvent 
 */

//$Id: DummyEventGenM.nc,v 1.3 2005/07/26 18:18:58 phoebusc Exp $

includes Rpc;
includes DetectionEvent;

module DummyEventGenM {
  provides interface StdControl;

  uses interface DetectionEvent;
  uses interface Timer;
  uses interface Leds;
  uses interface Attribute<uint16_t> as DummyDetectionTimer @registry("DummyDetectionTimer");
  uses interface Attribute<uint16_t> as DetectionEventAddr @registry("DetectionEventAddr");

  provides command result_t fakeDetect( uint16_t strength ) @rpc();
}
implementation {

  uint8_t dir;
  uint16_t strength;
  uint16_t fake_strength;

  void startTimer( uint16_t period ) {
    if( period == 0 ) {
      call Timer.stop();
    } else {
      call Timer.start( TIMER_REPEAT, period );
    }
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }
  command result_t StdControl.start() {
    call DummyDetectionTimer.set(DEFAULT_SAMPLE_PERIOD);
    startTimer( call DummyDetectionTimer.get() );
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    call Timer.stop();
    return SUCCESS;
  }

  event result_t Timer.fired() {
    call Leds.yellowToggle();

    if (strength == 4 && dir == 0) {
      dir = 1;
    } else if (strength == 0 && dir == 1) {
      dir = 0;
    }

    if (dir == 0) {
      strength++;
    } else if (dir == 1) {
      strength--;
    }

    if (call DetectionEvent.detected(strength) == FAIL) {
      call Leds.redToggle();
    }

    return SUCCESS;
  }

  event void DummyDetectionTimer.updated( uint16_t val ) {
    startTimer( val );
  }

  event void DetectionEventAddr.updated( uint16_t val ) { }

  command result_t fakeDetect( uint16_t val ) {
    return call DetectionEvent.detected(val);
  }
}

