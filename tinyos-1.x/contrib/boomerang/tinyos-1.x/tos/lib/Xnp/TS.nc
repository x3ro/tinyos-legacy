// $Id: TS.nc,v 1.1.1.1 2007/11/05 19:10:05 jpolastre Exp $

interface TS
{
  /*
   * set ts to the timestamp
    */
  command result_t get_timestamp(uint32_t *ts);
}
