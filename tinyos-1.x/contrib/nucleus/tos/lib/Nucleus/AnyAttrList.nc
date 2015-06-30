//$Id: AnyAttrList.nc,v 1.3 2005/06/14 18:10:09 gtolle Exp $

interface AnyAttrList {
  command bool isImplemented();

  command uint8_t length();

  command result_t get(void *buf, uint8_t pos);
  event result_t getDone(void *buf);

  event result_t changed(void *buf, uint8_t pos);
}
