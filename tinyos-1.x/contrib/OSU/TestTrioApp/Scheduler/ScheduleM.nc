includes Schedule;
module ScheduleM
{
    provides
    {
        interface StdControl;
	  interface Scheduler;
    }
    uses
    {   
	  interface Timer;
        interface StdControl as TimerControl;
    }
}
implementation
{   uint8_t cnt;

    command result_t StdControl.init()
    {
        return call TimerControl.init();
    }

    command result_t StdControl.start()
    {
        call TimerControl.start();
	  return call Timer.start(TIMER_REPEAT, PM_SAMPLING_PERIOD_MILLIS);
    }

    command result_t StdControl.stop()
    {
         return call Timer.stop();
    }

    event result_t Timer.fired()
    {
	  signal Scheduler.getPirSample();
        return SUCCESS;
    }

    result_t command Scheduler.pirSampleComplete()
    {
      //signal Scheduler.getMagSample();
	return SUCCESS;
    }

    result_t command Scheduler.magSampleComplete()
    { 
	/*
	if (cnt==0) {
      signal Scheduler.getAcoSnippet();}
      
	cnt=(cnt+1)%ACOUSTIC_FREQ;
	*/
	
	return SUCCESS;
    }
}
