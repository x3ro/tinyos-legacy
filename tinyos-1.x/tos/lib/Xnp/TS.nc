// $Id: TS.nc,v 1.3 2003/10/07 21:46:27 idgay Exp $

interface TS
{
  /*
   * set ts to the timestamp
    */
  command result_t get_timestamp(uint32_t *ts);
}
