//$Id: TimeSyncAttrM.nc,v 1.1 2005/06/15 08:19:32 cssharp Exp $

includes TimeSyncAttr;

module TimeSyncAttrM
{
  provides interface Attr<uint32_t> as LocalAttr @nucleusAttr("LocalTime");
  provides interface Attr<GlobalTimeAttr_t> as GlobalAttr @nucleusAttr("GlobalTime");
  uses interface GlobalTime;
}
implementation
{
  command result_t LocalAttr.get( uint32_t* buf )
  {
    uint32_t t = call GlobalTime.getLocalTime();
    memcpy( buf, &t, sizeof(uint32_t) );
    signal LocalAttr.getDone(buf);
    return SUCCESS;
  }

  command result_t GlobalAttr.get( GlobalTimeAttr_t* buf )
  {
    uint32_t t = 0;
    buf->in_sync = call GlobalTime.getGlobalTime( &t );
    memcpy( &buf->t, &t, sizeof(uint32_t) );
    signal GlobalAttr.getDone(buf);
    return SUCCESS;
  }

  default event result_t LocalAttr.changed( uint32_t* buf )
  {
    return SUCCESS;
  }

  default event result_t GlobalAttr.changed( GlobalTimeAttr_t* buf )
  {
    return SUCCESS;
  }
}

