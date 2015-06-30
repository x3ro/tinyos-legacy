module AggregatorM
{
    provides
    {
        interface StdControl;
    }
    uses
    {
	  interface Leds;
	  interface PirDetector;
	  interface StdControl as PirControl;
	  interface StdControl as ScheduleControl;
    }
}

implementation
{
command result_t StdControl.init()
{
	  call Leds.init();
        call PirControl.init();
	  call ScheduleControl.init();
	  
        return SUCCESS;
}

command result_t StdControl.start()
{
	  call PirControl.start();
	  call ScheduleControl.start();
	  
	  return SUCCESS;
}

command result_t StdControl.stop()
{
	  call PirControl.stop();
	  call ScheduleControl.stop();
}

event result_t PirDetector.start()
{
	return SUCCESS;	
}

event result_t PirDetector.stop()
{
	return SUCCESS;
}
}
