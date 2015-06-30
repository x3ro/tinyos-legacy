//$Id: AnyAttrSet.nc,v 1.4 2005/06/14 18:10:09 gtolle Exp $

interface AnyAttrSet {
  command bool isImplemented();

  command uint8_t length();

  command result_t set(void *buf);
  event result_t setDone(void *buf);
}
