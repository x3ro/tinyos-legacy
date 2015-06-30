//$Id: AnyAttr.nc,v 1.4 2005/06/14 18:10:09 gtolle Exp $

interface AnyAttr {
  command bool isImplemented();

  command uint8_t length();

  command result_t get(void *buf);
  event result_t getDone(void *buf);

  event result_t changed(void *buf);
}
