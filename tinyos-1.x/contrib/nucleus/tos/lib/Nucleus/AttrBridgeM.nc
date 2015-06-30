//$Id: AttrBridgeM.nc,v 1.4 2005/06/14 18:10:09 gtolle Exp $

/**
 * This module is instantiated once for each Nucleus Attribute.
 *
 * @author Gilman Tolle
 */

generic module AttrBridgeM(typedef t) {
  provides interface AnyAttr;
  uses interface Attr<t>;
}
implementation {

  command bool AnyAttr.isImplemented() { return TRUE; }

  command uint8_t AnyAttr.length() {
    return sizeof(t);
  }
  command result_t AnyAttr.get(void* buf) {
    return call Attr.get((t*) buf);
  }
  event result_t Attr.getDone(t* buf) {
    return signal AnyAttr.getDone((void*) buf);
  }
  event result_t Attr.changed(t* buf) {
    return signal AnyAttr.changed((void*) buf);
  }
}

