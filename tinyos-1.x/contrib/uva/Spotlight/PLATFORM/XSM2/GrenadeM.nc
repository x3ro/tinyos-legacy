/*
 *
 * Authors:		Mike Grimmer
 * Date last modified:  3/6/03
 *
 */

module GrenadeM 
{
  provides interface Grenade;
  uses interface OneWire;
}
implementation
{
  uint8_t tod[4];
  uint8_t todcount;
/***********************************************************/
/*  tos commands  */
/*********************************************************/  
  command result_t Grenade.skipROM()
  {
    int i; 

    call OneWire.reset(); // reset the device
    call OneWire.write(0xcc); // command to skip ROM

    return SUCCESS;
  }

  command result_t Grenade.PullPin()
  {
	TOSH_MAKE_WR_OUTPUT();
    TOSH_SET_WR_PIN();
    TOSH_CLR_WR_PIN();
	TOSH_MAKE_WR_INPUT();
    return SUCCESS;
  }

  command result_t Grenade.setInterrupt(uint8_t interval)
  {
    uint8_t i; 

    i = 0x07 & interval;
	i = (i<4)|0x8c;
    call OneWire.reset(); // reset the device
    call OneWire.write(0xcc); // command to skip ROM
	call OneWire.write(i);
//	TOSH_MAKE_WR_OUTPUT();
//    TOSH_SET_WR_PIN();
//    TOSH_CLR_WR_PIN();
//	TOSH_MAKE_WR_INPUT();

    return SUCCESS;
  }

  command result_t Grenade.clrInterrupt(uint8_t interval)
  {
    uint8_t i; 

    i = 0x07 & interval;
	i = (i<4)|0x0c;
    call OneWire.reset(); // reset the device
    call OneWire.write(0xcc); // command to skip ROM
	call OneWire.write(i);

    return SUCCESS;
  }

  command result_t Grenade.setRTClock(uint8_t* time)
  {
    call OneWire.reset(); // reset the device
    call OneWire.write(0xcc); // command to skip ROM
    call OneWire.write(0x99); // set clock cmd
//    call OneWire.write(0x); // device control byte
    call OneWire.write(time[3]); // tod ls byte
    call OneWire.write(time[2]); // tod byte
    call OneWire.write(time[1]); // tod byte
    call OneWire.write(time[0]); // tod ms byte

    return SUCCESS;
  }

  command result_t Grenade.readRTClock()
  { 
	todcount = 4;
    call OneWire.reset(); // reset the device
    call OneWire.write(0x66); // command to read clk
    call OneWire.read(); // device control byte

    return SUCCESS;
  }

  command result_t Grenade.FireReset()
  { 
    TOSH_SET_RD_PIN();
	TOSH_MAKE_RD_OUTPUT();
    TOSH_SET_RD_PIN();
    TOSH_CLR_RD_PIN();
    
    return SUCCESS;
  }

  event result_t OneWire.readDone(uint8_t val)
  {
    if (todcount == 4)
	{
	  todcount--;
	  call OneWire.read();
	}
	else
	{
      if (todcount > 0)
	  {
	    tod[todcount] = val;
	    todcount--;
	    call OneWire.read();
	  }
	  if (todcount == 0)
	  {
	    tod[todcount] = val;
		signal Grenade.readRTClockDone(tod);
	  }
    }
	  
    return SUCCESS;
  }

}

