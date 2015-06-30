/**
 * Implementation of the Snooze component for TOSSIM
 * @author Bor-rong Chen
 **/

module SnoozeM
{
  provides interface Snooze;
  uses interface StdControl as CC1000StdControl;
  uses interface CC1000Control;
  uses interface PowerState;
}



implementation {

  /**
   * Triggers the mote to put itself in a low power sleep state for
   * a specified amount of time.
   * 
   * @param length Length of the low power sleep in units of 1/32 of a second.
   * For example, length=32 would snooze for 1 second, length=32*5 would
   * snooze for 5 seconds.  If length=0, the mote will snooze for 4 seconds
   * (this is the default snooze time).
   *
   * @return SUCCESS if the mote is about to enter the sleep state
   **/
  
  void event_snooze_wakeup_handle (event_t*,struct TOS_state*);
  
  command result_t Snooze.snooze(uint16_t length) {

    //calculate clock ticks from the snooze length parameter
    long long ticks = (int)length * (CPU_FREQ / 32);

    // cpu power save mode selection
    // info from ATmega128L manual pp.42
    // sm2  sm1   sm0    cpu_state
    //   0    0     0    Idle
    //   0    0     1    ADC Noise Reduction
    //   0    1     0    Power-down
    //   0    1     1    Power-save
    //   1    0     0    Reserved
    //   1    0     1    Reserved
    //   1    1     0    Standby
    //   1    1     1    Extended Standby 

    //set the cpu to Power-Save mode
    uint8_t sm2 = 0;
    uint8_t sm1 = 1;
    uint8_t sm0 = 1;
    
    //enque the wake up event
    event_t* event_snooze = (event_t*)malloc(sizeof(event_t));
    dbg(DBG_MEM, "malloc snooze wakeup event: 0x%x.\n", (int)event_snooze);
    
    event_snooze->mote = NODE_NUM;
    event_snooze->force = 0;
    event_snooze->pause = 1;
    event_snooze->data = NULL;
    event_snooze->time = tos_state.tos_time + ticks;
    event_snooze->handle = event_snooze_wakeup_handle;
    //event_snooze->cleanup = event_snooze_wakeup_cleanup;
    
    //enqueue the wake up event into the simulator queue
    TOS_queue_insert_event(event_snooze);

    // set the PA_POW to 00h to ensure lowest possible leakage current
    call CC1000Control.SetRFPower(0x00);

    // power down the radio
    call CC1000StdControl.stop();

    call PowerState.snoozeStart();
    call PowerState.cpuState( (sm2<<2) + (sm1<<1) + sm0 );

    return SUCCESS;
  }  

  TOS_INTERRUPT_HANDLER(SIG_SNOOZE_WAKEUP, ()) {

    uint8_t sm2 = 0;
    uint8_t sm1 = 0;
    uint8_t sm0 = 0;

    call PowerState.cpuState( (sm2<<2) + (sm1<<1) + sm0 );
    call PowerState.snoozeWakeup();

    // activates to TxMode from power down mode
    call CC1000StdControl.start();
    call CC1000Control.RxMode();
    call CC1000Control.SetRFPower(0xFF);

    signal Snooze.wakeup();
  }

  void event_snooze_wakeup_handle(event_t* event_snooze,
			    struct TOS_state* state) {  
    TOS_ISSUE_INTERRUPT(SIG_SNOOZE_WAKEUP)();
  }
}

