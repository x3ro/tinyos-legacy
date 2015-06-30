/*
 * Copyright (c) 2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

/**
 * Implementation for TestSPFlash application.
 * 
 * TestSPIFlash runs some read write tests on the spi flash and 
 * outputs the results to the LCD
 * 
 **/

module TestSPIFlashM {
  provides {
    interface StdControl;
    interface ParamView;

  }
  uses {
#ifdef IP
    interface StdControl as IPStdControl;
    interface StdControl as TelnetStdControl;
    interface StdControl as PVStdControl;
#endif

#ifdef IP
    interface UIP;
    interface Client;
#endif

    interface Leds;
    interface Timer;
    interface ReadData;
    interface WriteData;
  }
}

implementation {

  extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));

  int16_t NumData;  // counter
  uint16_t gWriteDone;
  uint16_t gReadDone;
  uint16_t gAddress = 0x0;
  char gWritten[32] = "";
  char gRead[32] = "Empty";
  
  
  
  /**
   * Module task.  Process sensor reading, compute the average, and
   * display it.
   * @return returns void
   **/
  task void readData()
    {
      call ReadData.read(gAddress,(uint8_t *) gRead,32);
    }
  

    task void writeData() 
  {
    call Leds.redToggle();
    strcpy(gWritten,"Froggy");    
    call WriteData.write(gAddress,(uint8_t *) gWritten,strlen(gWritten)+1);
			 
    
  }

  /**
   * Initialize the component. Initialize Leds
   * 
   * @return returns <code>SUCCESS</code> or <code>FAILED</code>
   **/
  command result_t StdControl.init() {
    atomic 
      {
	NumData = 0;

      }
#ifdef IP
    call PVStdControl.init();
    call TelnetStdControl.init();
    call IPStdControl.init();
#endif

    return call Leds.init();
  }

  /**
   * Starts the timer.
   * 
   * @return The value of calling <tt>Timer.start()</tt>.
   **/
  command result_t StdControl.start() {

#ifdef IP
    call IPStdControl.start();
    call TelnetStdControl.start();
#endif

    return call Timer.start(TIMER_REPEAT, 1000);
  }

  /**
   * Stops the timer.
   *
   * @return The value of calling <tt>Timer.stop()</tt>.
   **/
  command result_t StdControl.stop() {

#ifdef IP
    call TelnetStdControl.stop();
    call IPStdControl.stop();
#endif

    return call Timer.stop();
  }


  /*******************************************************************************/

#ifdef IP
  event void Client.connected( bool isConnected ) 
  {
  }
#endif


  /*******************************************************************************/
  
  /**
   * post the memory task every N fires
   *
   * @return SUCCESS
   **/
  event result_t Timer.fired() {
    call Leds.greenToggle();      
    NumData++;
    if (!(NumData%4))
      post writeData();
    return SUCCESS;
    
  }

  event result_t ReadData.readDone(uint8_t* buffer, uint32_t numBytesRead, result_t success) {
     gReadDone++;
    return SUCCESS;
  }
  event result_t WriteData.writeDone(uint8_t *data, uint32_t numBytesWrite, result_t success)  
    {
      gWriteDone++;
      post readData();      
      return SUCCESS;
    }


      /*****************************************************************/


  const struct Param s_TestFlash[] = {
    { "writeDone",PARAM_TYPE_UINT16,  &gWriteDone },
    { "readDone",PARAM_TYPE_UINT16,  &gReadDone },
    { "written",PARAM_TYPE_STRING,  &gWritten },
    { "read",PARAM_TYPE_STRING,  &gRead },
    { NULL, 0, NULL }
  };

  struct ParamList g_TestFlashList   = { "testFlash",   &s_TestFlash[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_TestFlashList );
    return SUCCESS;
  }

    
}
