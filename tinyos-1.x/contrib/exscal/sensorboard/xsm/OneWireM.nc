/*
 *
 * Authors:		Mike Grimmer
 * Date last modified:  3/6/03
 *
 */

module OneWireM 
{
  provides interface OneWire;
}
implementation
{
/***********************************************************/
/*  local functions  */
/*********************************************************/  


/***********************************************************/
/*  one wire drivers  */
/*********************************************************/  

  command result_t OneWire.reset()
  {
	char device = 0;
//    uint16_t i;

	TOSH_MAKE_SERIAL_ID_OUTPUT();
    TOSH_SET_SERIAL_ID_PIN();
    TOSH_uwait(500);

/*  debug
    for (i=0;i<5;i++)
	{
      TOSH_CLR_SERIAL_ID_PIN(); // drive bus low
	  TOSH_uwait(252); // 192 us
      TOSH_SET_SERIAL_ID_PIN(); // drive bus hi
    }
*/

	TOSH_CLR_SERIAL_ID_PIN(); // drive bus low
    TOSH_uwait(252);  // 480us 
	TOSH_SET_SERIAL_ID_PIN(); // drive bus hi

	TOSH_MAKE_SERIAL_ID_INPUT(); // release bus
	TOSH_SET_SERIAL_ID_PIN(); // enable pullup

    TOSH_uwait(37);  // 70 us

	if(!TOSH_READ_SERIAL_ID_PIN())
		device = 1; // device is present
    TOSH_uwait(216);  // 410 us
    if (device == 1)
	  return SUCCESS;
	else
      return FAIL;
  }

  command result_t OneWire.write(uint8_t byte)
  {
	uint8_t i;
	char temp;
//send data lsb first
	for (i=0;i<8;i++)
    {
      temp = (byte>>i)&0x01;
      if (temp)
      {
// write a one bit
        TOSH_MAKE_SERIAL_ID_OUTPUT();
        TOSH_CLR_SERIAL_ID_PIN(); // drive bus low
        TOSH_uwait(3); // hold low 6us
        TOSH_MAKE_SERIAL_ID_INPUT(); // release bus
        TOSH_SET_SERIAL_ID_PIN(); // enable pullup
        TOSH_uwait(34);   // delay 64us
      }
      else
      {
// write a zero bit
        TOSH_MAKE_SERIAL_ID_OUTPUT();
        TOSH_CLR_SERIAL_ID_PIN(); // drive bus low
        TOSH_uwait(32); // hold low 60us
        TOSH_MAKE_SERIAL_ID_INPUT(); // release bus
        TOSH_SET_SERIAL_ID_PIN(); // enable pullup
        TOSH_uwait(5); // delay 10us
      }
    }
    return SUCCESS;
  }

  command result_t OneWire.read()
  {
    uint8_t i;
    uint8_t temp = 0;
//send data lsb first
    for (i=0;i<8;i++)
    {
      temp = (temp>>1)&0x7f;
// read a bit
      TOSH_MAKE_SERIAL_ID_OUTPUT();
      TOSH_CLR_SERIAL_ID_PIN(); // drive bus low
      TOSH_uwait(3); // delay 6 us
      TOSH_MAKE_SERIAL_ID_INPUT(); // release bus
      TOSH_SET_SERIAL_ID_PIN(); // enable pullup
      TOSH_uwait(4); // delay 8 us
      if(TOSH_READ_SERIAL_ID_PIN()) // sample the bus
        temp |= 0x80;
      TOSH_uwait(29); // delay 55us
    }
    signal OneWire.readDone(temp);

    return SUCCESS;
  }


}

