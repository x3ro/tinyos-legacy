interface UARTTimeSync
{
  /* send out a single sync byte to pc */
  command result_t sync();    
  event void syncDone(uint32_t timeStamp);
}

