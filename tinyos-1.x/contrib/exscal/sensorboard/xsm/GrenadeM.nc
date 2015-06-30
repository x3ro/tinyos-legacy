/*
 *
 * Authors:		Mike Grimmer, Martin Turon
 * Date last modified:  3/6/03
 *
 */

#define IDLE 0
#define BUSY 1
#define READID 2
#define READTOD 3
#define SETTOD 4
#define SETINTERVAL 5

module GrenadeM 
{
  provides interface Grenade;
  uses interface OneWire;
}
implementation
{
  uint8_t todset[4];
  uint8_t todread[4];
  uint8_t bytecount;
  uint8_t id[8];
  bool busy = FALSE;
  uint8_t state;
  uint8_t clkinterval;
  uint8_t ctrlbyte = 0;
  uint8_t ctrlread;
  bool settime = FALSE;
  bool setinterrupt = FALSE;
  bool clearinterrupt = FALSE;

/***********************************************************/
/*  tos commands  */
/*********************************************************/  

  command result_t Grenade.readID()
  {
    if (!busy)
	{
	  busy = TRUE;
	  state = READID;
	  bytecount = 0;
      call OneWire.reset(); // reset the device
      call OneWire.write(0x33); // command to read id
      call OneWire.read();

      return SUCCESS;
	}
	else
	  return FAIL;
  }

/*********************************************************/  
  command result_t Grenade.readRTClock()
  { 
	bytecount = 4;
	state = READTOD;
	busy = TRUE;

    call OneWire.reset(); // reset the device
	call OneWire.write(0xcc); // skip rom code
    call OneWire.write(0x66); // command to read clk
    call OneWire.read(); // device control byte

    return SUCCESS;
  }
/*********************************************************/  

  command result_t Grenade.PullPin()
  {
	TOSH_MAKE_WR_OUTPUT();
    TOSH_SET_WR_PIN();
    TOSH_CLR_WR_PIN();
	TOSH_MAKE_WR_INPUT();
    return SUCCESS;
  }
/*********************************************************/  

  command result_t Grenade.setInterval(uint8_t interval)
  {
    clkinterval = 0x07 & interval;
    clkinterval = clkinterval<<4;
    state = SETINTERVAL;
	busy = TRUE;
    call OneWire.reset(); // reset the device
	call OneWire.write(0xcc); // skip rom code
    call OneWire.write(0x66); // command to read clk
    call OneWire.read(); // device control byte

    return SUCCESS;
  }

/*********************************************************/  

 /**
  * Arm the Grenade timer on the XSM.
  *
  * @author    Martin Turon
  * @version   2004/9/23      mturon       Initial version
  */
  command result_t Grenade.ArmNow(uint8_t interval)
  {
	uint8_t control;
    control   = interval & 0x07; // mask given interval 
    control <<= 4;               // shift interval to proper location
	control  |= 0x8c;            // default to: interrupts on, clock on

	while (
		call OneWire.reset()	 // reset the device 
	!= SUCCESS) ;        

	call OneWire.write(0xcc);    // skip rom code
    call OneWire.write(0x99);    // command to write clk
    call OneWire.write(control); // device control byte

    call OneWire.write(0x00);    // pass four time bytes
    call OneWire.write(0x00);    // (Start time at zero)
    call OneWire.write(0x00); 
    call OneWire.write(0x00); 

	while (
	    call OneWire.reset()     // finalize write operation
	!= SUCCESS) ;

	call Grenade.PullPin();

    return SUCCESS;
  }

/*********************************************************/  

  command result_t Grenade.setRTClock(uint8_t* time)
  {
    uint8_t i; 

    todset[0] = time[3];
    todset[1] = time[2];
    todset[2] = time[1];
    todset[3] = time[0];
    settime = TRUE;

    state = SETINTERVAL;
	busy = TRUE;
    call OneWire.reset(); // reset the device
	call OneWire.write(0xcc); // skip rom code
    call OneWire.write(0x66); // command to read clk
    call OneWire.read(); // device control byte

    return SUCCESS;
  }


/*********************************************************/  

  command result_t Grenade.setInterrupt()
  {
    setinterrupt = TRUE;
	busy = TRUE;
    state = SETINTERVAL;

    call OneWire.reset(); // reset the device
	call OneWire.write(0xcc); // skip rom code
    call OneWire.write(0x66); // command to read clk
    call OneWire.read(); // device control byte

    return SUCCESS;
  }
/*********************************************************/  

  command result_t Grenade.clrInterrupt()
  {
    clearinterrupt = TRUE;
	busy = TRUE;
    state = SETINTERVAL;

    call OneWire.reset(); // reset the device
	call OneWire.write(0xcc); // skip rom code
    call OneWire.write(0x66); // command to read clk
    call OneWire.read(); // device control byte

    return SUCCESS;
  }
/*********************************************************/  

  command result_t Grenade.FireReset()
  { 
    TOSH_SET_RD_PIN();
	TOSH_MAKE_RD_OUTPUT();
    TOSH_SET_RD_PIN();
    TOSH_CLR_RD_PIN();
    
    return SUCCESS;
  }

/*********************************************************/  

  event result_t OneWire.readDone(uint8_t val)
  {
    uint8_t i;

    if (state == READID)
    {
	  id[bytecount] = val;
	  bytecount++;
	  if (bytecount >= 8)
	  {
	    state = IDLE;
		busy = FALSE;
	    signal Grenade.readIDDone(&id[0]);
	  }
	  else
        call OneWire.read();
	}

    if ((state == READTOD)||(state == SETINTERVAL))
	{
      if (bytecount == 4)
	  {
	    ctrlread = val;
	    bytecount--;
	    call OneWire.read();
	  }
	  else
	  {
        if (bytecount > 0)
	    {
	      todread[bytecount] = val;
	      bytecount--;
	      call OneWire.read();
	    }
	    if (bytecount <= 0)
	    {
	      todread[bytecount] = val;
		  busy = FALSE;
		  if (state == READTOD)
		  {
            state = IDLE;
	        signal Grenade.readRTClockDone(&todread[0]);
		  }



		  if (state == SETINTERVAL)
          {
		    ctrlbyte = ctrlread & 0x8f;
			ctrlbyte = ctrlbyte | clkinterval;
			if (setinterrupt)
			{
			  ctrlbyte = ctrlbyte | 0x80;  // set interrupt
			  ctrlbyte = ctrlbyte & 0xf0;  // turn off timer
            }
			if (settime)
			  ctrlbyte = ctrlbyte | 0x0c; // start clock
			if (clearinterrupt)
			  ctrlbyte = ctrlbyte & 0x7f;

            call OneWire.reset(); // reset the device
            call OneWire.write(0xcc); // command to skip ROM
            call OneWire.write(0x99); // set clock cmd
            call OneWire.write(ctrlbyte); // device control byte

	        for (i=0;i<4;i++)
			{
			  if (settime)
                call OneWire.write(todset[i]); // tod ls byte first
			  else
                call OneWire.write(todread[i]); // tod ls byte first
            }
/*
            if (setinterrupt)
            {
			  ctrlbyte = ctrlbyte | 0x0c;  // turn on timer
              call OneWire.reset(); // reset the device
              call OneWire.write(0xcc); // command to skip ROM
              call OneWire.write(0x99); // set clock cmd
              call OneWire.write(ctrlbyte); // device control byte
	          for (i=0;i<4;i++)
                call OneWire.write(todread[i]); // tod ls byte first
            }
*/
			settime = FALSE;
			setinterrupt = FALSE;
			clearinterrupt = FALSE;
			state = IDLE;
		  }

	    }
      }
	}	  
    return SUCCESS;
  }
}

