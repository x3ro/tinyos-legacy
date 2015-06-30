//$Id: EventsC.nc,v 1.2 2005/06/14 18:10:10 gtolle Exp $

/**
 * This component is the interchange point for named Nucleus events.
 *
 * @author Gilman Tolle
 */

configuration EventsC {
  provides {
    interface StdControl;
    interface EventClient[EventID id];
  }
  uses {
    interface AnyEvent[AttrID id];
  }
}

implementation {
  
  components 
    EventsM,
    EventGenC;

  StdControl = EventsM;

  EventClient = EventsM;
  AnyEvent = EventsM;
}

