//$Id: LedsAttrM.nc,v 1.1 2005/06/19 01:53:20 cssharp Exp $

module LedsAttrM
{
  provides interface Attr<uint8_t> as LedsAttr @nucleusAttr("Leds");
  provides interface AttrSet<uint8_t> as LedsSetAttr @nucleusAttr("Leds");
  uses interface Leds;
}
implementation
{
  command result_t LedsAttr.get( uint8_t* buf )
  {
    *buf = call Leds.get();
    signal LedsAttr.getDone(buf);
    return SUCCESS;
  }

  default event result_t LedsAttr.getDone( uint8_t* buf )
  {
    return SUCCESS;
  }

  default event result_t LedsAttr.changed( uint8_t* buf )
  {
    return SUCCESS;
  }

  command result_t LedsSetAttr.set( uint8_t* buf )
  {
    call Leds.set(*buf);
    signal LedsSetAttr.setDone(buf);
    return SUCCESS;
  }

  default event result_t LedsSetAttr.setDone( uint8_t* buf )
  {
    return SUCCESS;
  }
}

