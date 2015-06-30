//$Id: EventsM.nc,v 1.2 2005/06/14 18:10:10 gtolle Exp $

module EventsM {
  provides {
    interface StdControl;
    interface EventClient[EventID id];
  }
  uses {
    interface AnyEvent[EventID id];
  }
}
implementation {

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t AnyEvent.fire[EventID id](uint8_t length, void *eventBuf) {
    return signal EventClient.fired[id](length, eventBuf);
  }

  event result_t AnyEvent.log[EventID id](uint8_t length, 
					  uint8_t class,
					  void *eventBuf) {
    return signal EventClient.logged[id](length, class, eventBuf);
  }
}
