//$Id: AttrListBridgeM.nc,v 1.3 2005/06/14 18:10:10 gtolle Exp $

/** 
 * This module is instantiated for each Nucleus List Attribute.
 *
 * @author Gilman Tolle
 */

generic module AttrListBridgeM(typedef t) {
  provides interface AnyAttrList;
  uses interface AttrList<t>;
}
implementation {

  command bool AnyAttrList.isImplemented() { return TRUE; }
  
  command uint8_t AnyAttrList.length() {
    return sizeof(t);
  }
  command result_t AnyAttrList.get(void* buf, uint8_t pos) {
    return call AttrList.get((t*) buf, pos);
  }
  event result_t AttrList.getDone(t* buf) {
    return signal AnyAttrList.getDone((void*) buf);
  }
  event result_t AttrList.changed(t* buf, uint8_t pos) {
    return signal AnyAttrList.changed((void*) buf, pos);
  }
}









