//$Id: AttrSetBridgeM.nc,v 1.3 2005/06/14 18:10:10 gtolle Exp $

/**
 * This module is instantiated once for each Nucleus Attribute, to
 * transform the typed object into a void pointer and provide the
 * length of the type.
 *
 * @author Gilman Tolle
 */

generic module AttrSetBridgeM(typedef t) {
  provides interface AnyAttrSet;
  uses interface AttrSet<t>;
}
implementation {

  command bool AnyAttrSet.isImplemented() { return TRUE; }
  
  command uint8_t AnyAttrSet.length() {
    return sizeof(t);
  }

  command result_t AnyAttrSet.set(void* buf) {
    return call AttrSet.set((t*) buf);
  }
  event result_t AttrSet.setDone(t* buf) {
    return signal AnyAttrSet.setDone((void*) buf);
  }
}

