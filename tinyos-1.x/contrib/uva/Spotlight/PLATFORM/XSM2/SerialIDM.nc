/*
 *
 * Authors:		Mike Grimmer
 * Date last modified:  3/6/03
 *
 */

module SerialIDM 
{
  provides interface SerialID;
  uses interface OneWire;
}
implementation
{

  uint8_t count;
  uint8_t* serial_id;
  bool busy = FALSE;

/***********************************************************/
/*  tos commands  */
/*********************************************************/  

  command result_t SerialID.read(uint8_t* idloc)
  {
    int i; 
    serial_id = idloc;

    if (!busy)
	{
	  busy = TRUE;
      call OneWire.reset(); // reset the device
      call OneWire.write(0x33); // command to read id
	  count = 0;
      call OneWire.read();

//    for(i=0;i<8;i++) // read 8 byte id
//      serial_id[i] = one_wire_read();  // read a byte
      return SUCCESS;
	}
	else
	  return FAIL;
  }

/***********************************************************/
/*  tos events  */
/*********************************************************/  

  event result_t OneWire.readDone(uint8_t val)
  {
    serial_id[count] = val;
    count++;
    if (count < 8)
      call OneWire.read();
    else
	{
	  busy = FALSE;
	  signal SerialID.readDone();
	}
    return SUCCESS;
  }
}



