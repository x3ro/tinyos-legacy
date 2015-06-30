/**
 * This is a parameterized state controller for any and every component's
 * state machine(s).
 *
 * There are several compelling reasons to use the State module/interface
 * in all your components that have any kind of state associated with them:
 *
 *   1) It provides a unified interface to control any state, which makes
 *      it easy for everyone to understand your code
 *   2) You can easily keep track of multiple state machines in one component
 *   3) You could have one state machine control several components
 *
 * Connect your component's State interface to StateM.State[unique("State")]; 
 * when creating a new state machine. If two components share the same states, 
 * use one unique("State") for both.
 *
 * Keep in mind, S_IDLE is always 0.
 * 
 * @author David Moss - dmm@rincon.com
 */
 

Alright, here's an butchered up example...

Notice how no variables are even defined or required in your component
to keep track of the state. 

And, "arithmeticking" aside, always avoid using cryptic state names.


////////////////////////////////////////////////////////////////////
module YourModule {
  provides {
    interface YourInterface;
  }
  uses {
    interface State;  // wire up YourModule.State -> StateM.State[unique("State")];
  }
}

implementation {

  /** Here's where you could define your states */
  enum {
    S_IDLE = 0,
    S_READING,
    S_WRITING,
    S_ARITHMETICKING,
  }; 

  /***************** Example Prototypes ****************/
  task void write();
  void read();
  void arithmetic();

  /***************** YourInterface Commands ****************/
  /**
   * Example showing no interruptions for the duration of our
   * inline command 
   */
  command result_t YourInterface.read() {
    if(!call State.requestState(S_READING)) {
      return FAIL;
    }

    read();
    call State.toIdle();
    return SUCCESS;
  }

  /**
   * Several step state mangling and checking example...
   */
  command result_t YourInterface.calculate() {
    if(!call State.requestState(S_WRITING)) {
      return FAIL;
    }
   
    post write();
    return SUCCESS;
  }

  /**
   * Task that double checks the current
   * state, and then forces our current state to
   * a different state
   */
  task void write() {
    if(call State.getState() != S_WRITING) {
      // Got here by accident - this check would be useful
      // when receiving messages over the radio for error
      // and attack prevention.
      return;
    }

    // We're already not in the IDLE state, and want to move
    // directly to another state without interruption, so
    // we force our state machine into another state:
    call State.forceState(S_ARITHMETICKING);
    arithmetic();
  }

  /**
   * Function that sets our state machine
   * back to idle and signals an event.
   */
  void arithmetic() {
    // Be sure to set it back to IDLE when you're done!
    call State.toIdle();
    signal YourInterface.calculateDone();
  }

  // ...