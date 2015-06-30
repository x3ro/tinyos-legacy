// $Id: TSC.nc,v 1.3 2003/10/07 21:46:27 idgay Exp $

module TSC
{
  provides interface TS;
}

implementation
{
  // static consts to make the values easily accessible in the object code
  static const uint32_t unix_time = IDENT_UNIX_TIME;

  command result_t TS.get_timestamp(uint32_t* ts)
  {
    *ts = unix_time;
    return SUCCESS;
  }
}

