includes Schedule;
configuration ScheduleC
{
    provides
    {
        interface Scheduler;
        interface StdControl;
    }
}
implementation
{
    components   TimerC		    
		    ,ScheduleM;
		   		    

    // Map interfaces used to implementations provided.
        
    ScheduleM.Timer -> TimerC.Timer[unique("Timer")];
    ScheduleM.TimerControl -> TimerC;
    
     
 
    // Map interfaces provided by this configuration to interface providers.

    Scheduler = ScheduleM;
    StdControl = ScheduleM;

}
