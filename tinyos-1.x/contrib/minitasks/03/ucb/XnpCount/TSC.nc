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

