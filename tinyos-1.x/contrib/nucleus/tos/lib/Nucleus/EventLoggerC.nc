//$Id: EventLoggerC.nc,v 1.4 2005/06/14 18:10:10 gtolle Exp $

includes EventLogger;

/**
 * This component is the main engine for sending Nucleus Events back
 * to a base station.
 *
 * @author Gilman Tolle
 */

configuration EventLoggerC {
  provides {
    interface StdControl;
  }
} 

implementation {
  components 
    EventLoggerM, 
    EventsC,
    DrainC,
    GenericComm,
    RandomLFSR,
    LedsC;

  StdControl = EventLoggerM;

  EventLoggerM.SubControl -> EventsC;
  EventLoggerM.SubControl -> DrainC;

  EventLoggerM.Leds -> LedsC;
  EventLoggerM.Random -> RandomLFSR;

  EventLoggerM.EventClient -> EventsC;
  
  EventLoggerM.ResponseSend -> GenericComm.SendMsg[AM_LOGENTRYMSG];
  EventLoggerM.ResponseSendMH -> DrainC.Send[AM_LOGENTRYMSG];
}

