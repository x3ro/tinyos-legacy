//$Id: KrakenMainM.nc,v 1.3 2005/08/24 00:44:30 gtolle Exp $

module KrakenMainM
{
  provides interface StdControl;
  uses interface StdControl as PreInitControl;
  uses interface SplitInit as Init;
  uses interface SplitControl as RadioControl;
  uses interface StdControl as AppControl;
  uses interface BusArbitration;
}
implementation
{
  bool started = FALSE;

  command result_t StdControl.init()
  {
    call PreInitControl.init();
    call AppControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call PreInitControl.start();
    call Init.init();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  task void startRadio() {
    result_t result;
    atomic {
      result = call BusArbitration.getBus();
      if ( result == SUCCESS ) {
	call BusArbitration.releaseBus();
	call RadioControl.start();
      }
      else {
	post startRadio();
      }
    }
  }

  event void Init.initDone()
  {
    post startRadio();
  }

  event result_t RadioControl.startDone() 
  {
    if (!started) {
      started = TRUE;
      call AppControl.start();
    }
    return SUCCESS;
  }

  event result_t RadioControl.initDone() { return SUCCESS; }
  event result_t RadioControl.stopDone() { return SUCCESS; }
  event result_t BusArbitration.busFree() { return SUCCESS; }

  default command result_t Init.init()
  {
    signal Init.initDone();
    return SUCCESS;
  }
}
