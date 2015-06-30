/*
 *
 * Authors:		Mike Grimmer
 * Date last modified:  3/6/03
 *
 */

module SerialFLASHM 
{
  provides interface SerialFLASH;
}
implementation
{

/*******************************************/
// local functions
/******************************************/

  char send_byte(char input)
  {
    int i;

    for(i=0;i<8;i++)
    {
      TOSH_CLR_FLASH_CLK_PIN();
      if(input & 0x80) 
        TOSH_SET_FLASH_OUT_PIN();
      else
        TOSH_CLR_FLASH_OUT_PIN();
      input <<= 1;
      TOSH_SET_FLASH_CLK_PIN();
    }
    return input;
  }

  char read_byte()
  {
    int i;
    char input = 0;

    for(i=0;i<8;i++)
    {
      input <<= 1;
      TOSH_SET_FLASH_CLK_PIN();
	  TOSH_uwait(2);
      TOSH_CLR_FLASH_CLK_PIN();
	  TOSH_uwait(2);
      if(TOSH_READ_FLASH_IN_PIN())
      {
        input |= 0x01;
      }
      else
      {
        input &= 0xfe;
      }
    }
    return input;
  }

  char verify_pattern(char *buf)
  {
    int i;
    char test = 0;
    int pass = 0;
    int temp;

    for(i=0;i<8;i+=2)
    {		
      temp = buf[i]+(buf[i+1]*256);
      if (temp==0xaa55)
        test++;
    }
    if (test==4)
      pass = 1;
    else
      pass = 0;	
    return pass;
  }

  result_t write_block(char *buf)
  {
    int i;
    TOSH_CLR_FLASH_SELECT_PIN();
    //send_byte(0x84); //buffer 1 write
    send_byte(0x82); //Main memory Page Program Through buffer 1
    send_byte(0x0);
    send_byte(0x0);
    send_byte(0x0);
    for(i=0;i<8;i++)
      send_byte(buf[i]);
//		send_byte((i<<4) + i);
    TOSH_SET_FLASH_SELECT_PIN();
    for (i=0;i<20;i++)  // need 20ms for write
	  TOSH_uwait(200);
    return SUCCESS;
  }

  result_t read_block(char *buf)
  {
    int i;

    TOSH_CLR_FLASH_CLK_PIN();  
	TOSH_MAKE_FLASH_SELECT_OUTPUT();
    TOSH_CLR_FLASH_SELECT_PIN();
  //send_byte(0xD4); //buf 1 read
    send_byte(0xD2); //main memory page read
    send_byte(0x0);
    send_byte(0x0);
    send_byte(0x0);	
    for(i=0;i<4;i++)  // need 32 bits of dont care
      send_byte(0x0);	
    for(i=0;i<8;i++)  // data now valid
    {
      buf[i] = read_byte(); 
    }
    TOSH_CLR_FLASH_OUT_PIN();
    TOSH_SET_FLASH_SELECT_PIN();
    return SUCCESS;
  }

/*******************************************/
/*  serial flash drivers  */
/******************************************/  

  command result_t SerialFLASH.check_flash()
  {
	int i;
//	int test = 1;
	char buffer[8];

    cli();
    for(i=0;i<8;i++)
    {
      if (i%2==1)
        buffer[i] = 0xaa;
      else
        buffer[i] = 0x55;
    }
    write_block(buffer);
    for (i=0;i<20;i++)  // need 20ms for write
	  TOSH_uwait(200);
    for (i=0;i<8;i++)
      buffer[i] = 0;
    read_block(buffer);
	sei();
    if (verify_pattern(buffer))
      return SUCCESS;
    else
      return FAIL;
  }

  command result_t SerialFLASH.write_flash_block(char *buf)
  {
    int i;
    TOSH_CLR_FLASH_SELECT_PIN();
    //send_byte(0x84); //buffer 1 write
    send_byte(0x82); //Main memory Page Program Through buffer 1
    send_byte(0x0);
    send_byte(0x0);
    send_byte(0x0);
    for(i=0;i<8;i++)
      send_byte(buf[i]);
//		send_byte((i<<4) + i);
    TOSH_SET_FLASH_SELECT_PIN();
    TOSH_uwait(2000);
    return SUCCESS;
  }

  command result_t SerialFLASH.read_flash_block(char *buf)
  {
    int i;

    TOSH_CLR_FLASH_CLK_PIN();  
	TOSH_MAKE_FLASH_SELECT_OUTPUT();
    TOSH_CLR_FLASH_SELECT_PIN();
  //send_byte(0xD4); //buf 1 read
    send_byte(0xD2); //main memory page read
    send_byte(0x0);
    send_byte(0x0);
    send_byte(0x0);	
    for(i=0;i<4;i++)  // need 32 bits of dont care
      send_byte(0x0);	
    for(i=0;i<8;i++)  // data now valid
    {
      buf[i] = read_byte(); 
    }
    TOSH_CLR_FLASH_OUT_PIN();
    TOSH_SET_FLASH_SELECT_PIN();
    return SUCCESS;
  }

}
