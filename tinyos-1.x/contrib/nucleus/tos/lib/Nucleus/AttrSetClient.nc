//$Id: AttrSetClient.nc,v 1.4 2005/06/14 18:10:10 gtolle Exp $

interface AttrSetClient {
  command uint8_t getAttrLength();

  command result_t setAttr(void *buf);
  event result_t setAttrDone(void *buf);
}

