//$Id: EventBridgeM.nc,v 1.3 2005/06/14 18:10:10 gtolle Exp $

/**
 * This module is instantiated once for each event, to transform the
 * typed object into a void pointer, and provide the length.
 *
 * @author Gilman Tolle
 */

generic module EventBridgeM(typedef t) {
  provides interface AnyEvent;
  uses interface Event<t>;
}
implementation {
  event result_t Event.fire(t* buf) {
    return signal AnyEvent.fire(sizeof(t), (void*) buf);
  }

  event result_t Event.log(uint8_t class, t* buf) {
    return signal AnyEvent.log(sizeof(t), class, (void*) buf);
  }
}

