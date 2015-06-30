/*
 *
 * Systemic Realtime Design, LLC.
 * http://www.sysrtime.com
 *
 * Authors:  Qingwei Ma
 *           Michael Li
 *
 * Date last modified:  9/30/04
 *
 */


/*
 *  Workaround to wake up Mini by resetting it.
 *  Used for SkyeRead Minis with old firmware with
 *  wakeup bug. (present in firmware version C001)
 */
//#define WAKE_UP_BUG
#undef WAKE_UP_BUG


#define INT_DISABLE()    {cli(); outp(0x0, EIMSK);}
#define INT_ENABLE()     sei();
//#define	SW1_INT_ENABLE() sbi(EIMSK, 4)
#define	SW1_INT_ENABLE() sbi(EIMSK, 0)
#define	SW2_INT_ENABLE() sbi(EIMSK, 1)
//#define	SW2_INT_ENABLE() sbi(EIMSK, 5)
#define RISING_EDGE_INTERRUPT() outp(( (1<<ISC01) | (1<<ISC00) | (1<<ISC11) | (1<<ISC10) ), EICRA)
#define LEVEL_INTERRUPT() {uint8_t temp = inp(EICRB);  temp &= 0x0F; outp(temp, EICRA);}
//#define RISING_EDGE_INTERRUPT() outp(( (1<<ISC41) | (1<<ISC40) | (1<<ISC51) | (1<<ISC50) ), EICRB)
//#define LEVEL_INTERRUPT() {uint8_t temp = inp(EICRB);  temp &= 0xF0; outp(temp, EICRB);}
//#define	SW1_INT_CLEAR() sbi(EIFR, 4)
#define	SW1_INT_CLEAR() sbi(EIFR, 0)
#define	SW2_INT_CLEAR() sbi(EIFR, 1)
//#define	SW2_INT_CLEAR() sbi(EIFR, 5)
#define ANALOG_COMPARATOR_DISABLE() { cbi(ACSR, ACIE); sbi(ACSR, ACD); }


module SkyeReadMiniM {
  provides {
    interface SkyeReadMini as Mini;
    interface StdControl as Control;
  }
  uses {
    interface Timer as MiniSleep;
    interface Timer as ResponseTimeout; 
    interface Timer as WakeUpDelay; 
	interface SendVarLenPacket as SendUART;
    interface ReceiveVarLenPacket as ReceiveUART;
    interface StdControl as UARTControl;
    interface ADC as SGData;
    interface StdControl as SGControl;
  }
}

implementation {
  
  struct TagCommand *commandPtr;
  uint8_t commandBuffer[MAX_CMD_SIZE]; 
  uint8_t *cmdPtr;
  uint8_t msgSize;
  bool rawCmd, sleeping;

  norace bool pendingSearchTask;
  norace bool pendingTask;  /* if TRUE, Mini is currently processing a command,
                               FAIL a command if another one is still processing. */ 

  // makes MINI_RESET alias for the mini reset pin
#ifdef PLATFORM_MICA2DOT
  TOSH_ALIAS_OUTPUT_ONLY_PIN(MINI_RESET, ADC3);
#else
  TOSH_ALIAS_OUTPUT_ONLY_PIN(MINI_RESET, PW4);
#endif  

  void reset();

 /*
  *  To put Mini into sleep mode, send this write command to mini
  *  Reference: SkyeRead M1 Reference Guide Section 8.4 (page 28)
  */
  #define SLEEP_CMD_SIZE 14
  uint8_t MiniSleepCommand[SLEEP_CMD_SIZE] =
  {'2', '0', '4', '2', '0', '4', '0', '1', '0', '0', '3', '5', 'E', '9'};


  
/************************************************/
/**** CONTROL FUNCTIONS *************************/
/************************************************/


  command result_t Control.init()
    {
      cmdPtr = commandBuffer;
      commandPtr = (struct TagCommand *)commandBuffer;
      msgSize = 0;
      rawCmd = FALSE;
      sleeping = FALSE;
      pendingSearchTask = FALSE;
	  pendingTask = FALSE;

      TOSH_MAKE_INT0_INPUT();
      TOSH_MAKE_INT1_INPUT();

      // Reset Mini
      reset(); 
    
      ANALOG_COMPARATOR_DISABLE();
  
      call UARTControl.init(); 
      call SGControl.init();

      return SUCCESS;
    }

  
  command result_t Control.start()
    {

      INT_DISABLE();

      /* 
         If "Power Down" mode is used to put the atmel processor
	 to sleep, then the externel interrupts must be set to 
	 level ints instead of rising edge because only level ints
	 can wake the processor up from "Power Down" sleep mode.

	 INT 0-3 rising edge can wake from sleep mode.
	 INT 4-7 level int ONLY can wake from sleep mode.
	 Remember: external INT 1 and 2 on MICA2 is mapped to 4 and 5
	           on the atmel processor. 
 
         Reference: ATmega128.pdf document, section 
	            "Power-down Mode" page 43

         LEVEL_INTERRUPT(); 
      */	  
      RISING_EDGE_INTERRUPT();

      SW1_INT_ENABLE();
      SW2_INT_ENABLE();
      INT_ENABLE();

      call UARTControl.start();
      call SGControl.start();

      // setup sleep timer, then send a command to sleep 
      sleeping = TRUE;
      call SendUART.send(MiniSleepCommand, SLEEP_CMD_SIZE);       

      return SUCCESS;
    }


  command result_t Control.stop()
    {
      call UARTControl.stop();
      call SGControl.stop();
      return SUCCESS;
    }



/************************************************/
/**** HELPER FUNCTIONS **************************/
/************************************************/

  /**
   * Reset SkyeRead Mini. Wait until Mini is 
   * ready to accept commands.
   **/
  void reset ()
    {
      TOSH_MAKE_MINI_RESET_OUTPUT();
      TOSH_CLR_MINI_RESET_PIN();
      TOSH_uwait (100);      // hold reset for ~100 us 
      TOSH_SET_MINI_RESET_PIN();
       
      // need a delay to make sure mini is setup and ready
	  call WakeUpDelay.start (TIMER_ONE_SHOT, MINI_RESET_READY); 
    }


  /**
   * Wake up mini from sleep mode by sending it 
   * a byte. 
   **/
  void wakeUp()
    {
#ifdef WAKE_UP_BUG
     /*  Temporary workaround to wake up Mini by resetting
      *  it for SkyeRead Minis with old firmware with
      *  wakeup bug.
      */
      reset ();
#else
	  // send any byte to wake up Mini
      call SendUART.send(cmdPtr, 1);
	  call WakeUpDelay.start (TIMER_ONE_SHOT, MINI_WAKEUP_READY);
#endif       
    }


  /**
   *  Checks if Mini is sleeping.  If not
   *  then send command to Mini.  If sleeping
   *  wakes it up. 
   *  Note: the command buffer should 
   *  have already been set up by the 
   *  command functions at this point!
   **/
  void sendCommand ()
    {
	  /* if mini sleeping, wake it up first. WakeUpDelay.fired function will 
	     send the command to Mini when it is ready to accept commands */
      if (sleeping == TRUE)
        wakeUp();
      else 
	    call SendUART.send(cmdPtr, msgSize);       
    }


  /**
   * Event when WakeUpDelay timer expires.
   * Checks pendingTasks flags to see if 
   * there is a task waiting to be sent. 
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t WakeUpDelay.fired () 
    {
      call WakeUpDelay.stop();
      sleeping = FALSE;

	  if (pendingTask == TRUE)
        sendCommand();
      return SUCCESS;
    }


  /**
   * Event when ResponseTimeout timer expires.
   * Cancels pending tasks if any. Notify 
   * app of a response timeout. 
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t ResponseTimeout.fired()
    {
      atomic {
	    call ResponseTimeout.stop();
        pendingSearchTask = FALSE;
        pendingTask = FALSE;
        rawCmd = FALSE;
        signal Mini.miniDone (MINI_TIMEOUT);
      }
      return SUCCESS;
    }


  /**
   * Event when MiniSleep timer expires.
   * sends a sleep command to SkyeRead Mini 
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t MiniSleep.fired () 
    {
      call MiniSleep.stop();
      sleeping = TRUE;
      call SendUART.send(MiniSleepCommand, SLEEP_CMD_SIZE);       
      return SUCCESS;
    }

  
  /**
   * Module scoped function.
   * Task sends a command to search for a tag 
   * within the timeout parameter
   **/
  task void sendSearchCmd ()
    {
      if (FAIL == call Mini.searchTag (MINI_SEARCH_TAG_TIMEOUT))
        signal Mini.miniDone (MINI_FAIL);
    }



  char getDigit( char c )
    {
      if ( (c >= '0') && (c <= '9') )
	    return( c - '0' );
	  if ( (c >= 'a') && (c <= 'f') )
	    return( c - 'a' + 10 );
	  if ( (c >= 'A') && (c <= 'F') )
	    return( c - 'A' + 10 );
	  return( -1 );
    }


  /**
   * Module scoped function.
   * Use tagInfo to get index into tag specs
   * lookup table (RFID_tags.h)
   **/

  void getTagSpecs (uint8_t *tagInfo, uint8_t *idx)
    {
      uint8_t i, type, typeExt1, typeExt2, typeExt3; 
	  tagType_t *tag = (tagType_t *) tagInfo;

      // convert ascii tag types into hex digits
	  type   = getDigit (tag->type[0]);
	  type <<= 4;
      type  |= getDigit (tag->type[1]);
     
	  typeExt1   = getDigit (tag->typeExt1[0]);
	  typeExt1 <<= 4;
      typeExt1  |= getDigit (tag->typeExt1[1]);

	  typeExt2   = getDigit (tag->typeExt2[0]);
	  typeExt2 <<= 4;
      typeExt2  |= getDigit (tag->typeExt2[1]);

	  typeExt3   = getDigit (tag->typeExt3[0]);
	  typeExt3 <<= 4;
      typeExt3  |= getDigit (tag->typeExt3[1]);


      // use taginfo in lookup table for tag specs
      for (i=0; i < NUM_TAG_SPEC_TYPES; i++)
        {
           if ((type     == RFIDtags[i].type) && 
			   (typeExt1 == RFIDtags[i].typeExt1) &&
			   (typeExt2 == RFIDtags[i].typeExt2) &&
			   (typeExt3 == RFIDtags[i].typeExt3))
			  break;
			   
        }

      // tag type not found in database
      if (i==NUM_TAG_SPEC_TYPES)
	    i=0;

      *idx = i; 
    }


  void searchTag ()
    {
      // 0014 is the command to search for a tag (Skyetek Protocol V.2 Section 2.2 and 2.3)
      commandPtr->flag[0]    = '0';
      commandPtr->flag[1]    = '0';
      commandPtr->request[0] = '1';
      commandPtr->request[1] = '4';

      // defines the type of tag we are searching for
      // 00 = any tag type that can be recognized by mini (Skyetek Protocol V.2 Section 2.4)
      commandPtr->type[0] = '0';
      commandPtr->type[1] = '0';

      cmdPtr = (uint8_t *) commandPtr;
      msgSize = 6;  // the search tag command size = flag + request + type

      sendCommand ();
    }



/************************************************/
/**** SKYREAD MINI IMPLEMENTATION ***************/
/************************************************/


  command result_t Mini.searchTag (uint8_t timeout)
    { 
      if ((pendingSearchTask == FALSE) && (pendingTask == FALSE))
        {
          atomic {
            pendingSearchTask = TRUE;
            pendingTask = TRUE;
          }

          // no timeout requested, just send 1 searchTag command, don't use timer
          if (timeout == 0)
            atomic pendingSearchTask = FALSE;
		  else 
			call ResponseTimeout.start(TIMER_ONE_SHOT, timeout*1024);

          searchTag ();
          return SUCCESS;
        }
      else
		return FAIL; 
    }
 
  
  command result_t Mini.readTag(uint8_t* tagInfo, uint8_t tagInfoSize, uint8_t blockIndex)
    {
      if (pendingTask == FALSE)
		{
		  atomic pendingTask = TRUE;

		  // need a response or else timeout sends a fail to app (1024 multiplication = 1 second)
		  call ResponseTimeout.start(TIMER_ONE_SHOT, MINI_RESPONSE_TIMEOUT*1024); 
        }
      else
		  return FAIL;

      // 4024 is the command to read fromo the memory of a tag (Skyetek Protocol V.2 Section 2.2 and 2.3)
      commandPtr->flag[0]    = '4';
      commandPtr->flag[1]    = '0';
      commandPtr->request[0] = '2';
      commandPtr->request[1] = '4';

      // tagInfo specifies which tag to read from 
      memcpy (commandPtr->type, tagInfo, tagInfoSize);

      // the index of the block of memory to read from
      commandPtr->start[0] = '0' + blockIndex / 16;
      commandPtr->start[1] = '0' + blockIndex % 16;

      // always read only 1 block at a time
      commandPtr->length[0] = '0';
      commandPtr->length[1] = '1';

      cmdPtr = (uint8_t *) commandPtr;
      msgSize = tagInfoSize + 8;  // 8 = flag + request + start + length

      sendCommand ();
      return SUCCESS;
    }

  
  command result_t Mini.writeTag(uint8_t* tagInfo, uint8_t tagInfoSize, uint8_t blockIndex, 
                                                       uint8_t* data, uint8_t dataSize)
    {
      if (pendingTask == FALSE)
	    {
	      atomic pendingTask = TRUE;
		
		  // need a response or else timeout sends a fail to app (1024 multiplication = 1 second)
		  call ResponseTimeout.start(TIMER_ONE_SHOT, MINI_RESPONSE_TIMEOUT*1024); 
        }
      else
		  return FAIL;

      // 4044 is the command to write to a tag (Skyetek Protocol V.2 Section 2.2 and 2.3)
      commandPtr->flag[0]    = '4';
      commandPtr->flag[1]    = '0';
      commandPtr->request[0] = '4';
      commandPtr->request[1] = '4';

      // tagInfo specifies which tag to write to
      memcpy (commandPtr->type, tagInfo, tagInfoSize);

      // the index of the block of memory to write to
      commandPtr->start[0]  = '0' + blockIndex / 16;
      commandPtr->start[1]  = '0' + blockIndex % 16;

      // always write 1 block at a time 
      commandPtr->length[0]  = '0';
      commandPtr->length[1]  = '1';

      // the actual data to write to tag
      memcpy (commandPtr->data, data, dataSize);

      cmdPtr = (uint8_t *) commandPtr;
      msgSize = tagInfoSize + dataSize + 8;  // 8 = flag + request + start + length 

      sendCommand ();
      return SUCCESS;
    }


  command result_t Mini.sendRaw (uint8_t* cmd, uint8_t len)
    {
      if (pendingTask == FALSE)
	    {
	      atomic pendingTask = TRUE;
		
		  // need a response or else timeout sends a fail to app (1024 multiplication = 1 second)
		  call ResponseTimeout.start(TIMER_ONE_SHOT, MINI_RESPONSE_TIMEOUT*1024); 
        }
      else
		  return FAIL;

      if (rawCmd == FALSE)
        {
          rawCmd = TRUE;
         
		  // copy the command into the global command buffer 
		  memcpy (commandPtr, cmd, len); 
          msgSize = len;
          cmdPtr = (uint8_t *) commandPtr;

          sendCommand();
          return SUCCESS;
        }
      else
        return FAIL;
    }


  command result_t Mini.getSignalStrength ()
    {
      call SGData.getData();
      return SUCCESS;
    }


  async event result_t SGData.dataReady (uint16_t data) 
    {
      signal Mini.SignalStrengthReady (data);
      return SUCCESS;
    }


#if 0
  command void Mini.MiniOffBus ()
    {
      TOSH_CLR_MINI_RESET_PIN();
    }


  command void Mini.MiniOnBus ()
    {
      /* after reset, it takes ~150 ms for 
         Mini to boot up.  */ 
      TOSH_SET_MINI_RESET_PIN();
    }
#endif


/************************************************/
/**** UART1 FUNCTIONS TO MINI *******************/
/************************************************/


  event uint8_t* ReceiveUART.receive (uint8_t* msg, uint8_t size)
    {
      miniResult_t stat = MINI_FAIL;
      bool miniResponse = TRUE;


      /* response code from sleep command. received before
         going to sleep and just after waking up  */
      if((msg[0] == '4') && 
		 (msg[1] == '2') &&
		 (msg[2] == '6') &&
		 (msg[3] == '1') &&
		 (msg[4] == '1') &&
		 (msg[5] == '6'))
        { 
          miniResponse = FALSE;
        }

      else if (rawCmd == TRUE)
        {
           rawCmd = FALSE;
           stat = MINI_SUCCESS;
           atomic pendingTask = FALSE;
           call ResponseTimeout.stop();
           signal Mini.replyRaw (msg, size); 
        }

      // "14" is response code for a tag found
      else if(msg[0] == '1' && msg[1] == '4')
        {
           uint8_t i;
           atomic {
		   getTagSpecs (msg+2, &i);
           stat = MINI_SUCCESS;
           pendingTask = FALSE;
		   pendingSearchTask = FALSE;
           call ResponseTimeout.stop();

           // send back data plus tag memory info, parse out response code (14)
           signal Mini.tagFound(msg+2, size-2, 
		                        RFIDtags[i].blockSize,
								RFIDtags[i].numBlocks);

           }

        }

      // "24" is response code for successful read from tag
      else if(msg[0] == '2' && msg[1] == '4')
        {
           stat = MINI_SUCCESS;
           atomic pendingTask = FALSE;
           call ResponseTimeout.stop();

           // send back only data, not response code
           signal Mini.tagDataReady(msg+2, size-2);
        }


      // "44" is response code for successful write to tag
      else if(msg[0] == '4' && msg[1] == '4')
        {
           stat = MINI_SUCCESS;
           atomic pendingTask = FALSE;
           call ResponseTimeout.stop();

           signal Mini.tagWriteDone();
        }


      // "94" is response code for search tag failure
      else if(msg[0] == '9' && msg[1] == '4')
        {
           // keep searching for a tag until one is found or timeout triggers 
           if (pendingSearchTask == TRUE)
             {
			   searchTag ();
			   miniResponse = FALSE;
             }
           else // no timer, just 1 search
             {
               atomic pendingTask = FALSE;
               stat = MINI_TIMEOUT;
             }
        }


      // activity on the mini, refresh sleep timer
      if (sleeping == FALSE)
        { 
	      call MiniSleep.stop ();
          call MiniSleep.start (TIMER_ONE_SHOT, MINI_SLEEP_TIMEOUT);
        }

      // some internal cases where you don't notify the app of a response
      if (miniResponse == TRUE)
        {
          // notify app that we got a fail response from mini and return status.
          atomic {
            pendingSearchTask = FALSE;
		    pendingTask = FALSE;
          }
	      call ResponseTimeout.stop();
          signal Mini.miniDone (stat);
        }
      return msg;  
    }



  event result_t SendUART.sendDone (uint8_t* packet, result_t success)
    {
      return SUCCESS;
    }



/************************************************/
/**** SKYEREAD MINI BUTTON INTERRUPTS ***********/
/************************************************/

#ifdef PLATFORM_MICA2DOT
  TOSH_INTERRUPT(SIG_INTERRUPT0)
#else
  TOSH_INTERRUPT(SIG_INTERRUPT4)
#endif
    { 
      post sendSearchCmd ();
      signal Mini.SW1Clicked();
    }

#ifdef PLATFORM_MICA2DOT 
  TOSH_INTERRUPT(SIG_INTERRUPT1)
#else
  TOSH_INTERRUPT(SIG_INTERRUPT5)
#endif
    {
      post sendSearchCmd ();
      signal Mini.SW2Clicked();
    }

} 
