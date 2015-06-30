//$Id: BoringAttrM.nc,v 1.6 2005/06/14 18:10:10 gtolle Exp $

includes MgmtQuery;

module BoringAttrM {
  provides interface Attr<uint16_t> as Boring @nucleusAttr("Boring");
  provides interface AttrSet<uint16_t> as BoringSet @nucleusAttr("Boring");
}
implementation {
  uint16_t boring = 255;
  
  command result_t Boring.get(uint16_t* buf) { 
    memcpy(buf, &boring, sizeof(uint16_t));
    signal Boring.getDone(buf);
    return SUCCESS; 
  }

  command result_t BoringSet.set(uint16_t* buf) {
    memcpy(&boring, buf, sizeof(uint16_t));
    signal BoringSet.setDone(buf);
    return SUCCESS;
  }
}

