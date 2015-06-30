/*
 * TestSkyeReadMini Module - sample application for SkyeReadMini
 *
 * Description:
 *
 * When a tag is found by the SkyeReadMini component (in this case triggered
 * by a button), the app receives the tag information through the event 
 * Mini.tagFound.  Depending on the "miniTask", the app uses the tag info 
 * to either read or write data to the tag's memory. 
 *  
 * When read data reply (tagDataReady) has been received, the data is packaged
 * up to be sent out through UART/Radio by MiniPacketizer. Before
 * this is done, a request for the signal strength (getSignalStrength)
 * is sent to the SkyeReadMini. When this data is received, the app
 * adds it to the package to be sent to MiniPacketizer.  MiniPacketizer
 * sends the whole package to the PC to be analyzed by "xRFID".
 * 
 * If no tag has been found, the app will receive a searchTagTimeout.
 *
 * A similar process occurs when a write command is sent to the Mini.
 * When SkyeReadMini component is finished writing sample data it 
 * receives tagWriteDone event. 
 * 
 * Since there is no data to send out from a write command, the tag ID
 * is sent out to the PC instead. 
 *
 * A raw command received by the app from MiniPacketizer 
 * is forwarded to SkyeReadMini.sendRaw. The reply from this 
 * command (replyRaw) is packaged up with signal strength data 
 * to the MiniPacketizer for analysis by "xRFID".
 *
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


module TestSkyeReadMiniM {
  provides {
    interface StdControl as Control;
  }
  uses {
    interface SkyeReadMini as Mini;
    interface StdControl as MiniControl;
    interface MiniPacketizer as Packetizer;
    interface Leds;
  }
}

implementation {

  norace bool miniTask;
  enum { READ=0, WRITE };
  uint8_t tagData[8] = { '1', '2', '3', '4', '5', '6', '7', '8' };

  // used for sending data out to Packetizer
  uint8_t replySize;
  uint8_t replyData[MAX_RSP_SIZE + PACKETIZER_OVERHEAD];  // only supports reading 1 block of data from tag memory
  norace uint16_t signalStrength;



/************************************************/
/**** CONTROL FUNCTIONS *************************/
/************************************************/


  /**
   * Initialize the application.
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t Control.init()
    {
      miniTask = READ;
      replySize=0;
      signalStrength=0;

      call Leds.init();
      return SUCCESS;
    }
  
  /**
   * Starts the application. 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t Control.start()
    {
      return SUCCESS;
    }

  /**
   * Stops the application. 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t Control.stop()
    {
      return SUCCESS;
    }


/************************************************/
/**** HELPER FUNCTIONS **************************/
/************************************************/

  /**
   * Module scoped functions. Helper functions 
   * for Packetizer. Copies data, size, SG 
   * and send the package to MiniPacketizer. 
   **/
  void packageData (uint8_t *data, uint8_t size)
    {
      // limits reply data to a maximum response size
	  // MAX_RSP_SIZE is the respose from a tag search.
      if (size > (MAX_RSP_SIZE + PACKETIZER_OVERHEAD))
        size = MAX_RSP_SIZE + PACKETIZER_OVERHEAD;

      memcpy (replyData, data, size);
      replySize = size;
    }

  void packageSG (uint16_t sg)
    {
      signalStrength = sg;
    }

  task void sendReplyData ()
    {
      call Packetizer.sendData (signalStrength, replyData, replySize);
    }



/************************************************/
/**** MINI READER EVENTS ************************/
/************************************************/


  /**
   * MINI response to the <code>Mini.searchTag</code> command.
   * Sends read or write command to SkyeReadMini depending on miniTask.
   * If miniTask is WRITE, the tagInfo data is saved by packageData. 
   * This data will be sent out to Packetizer later. 
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Mini.tagFound (uint8_t* tagInfo, uint8_t size, uint8_t blockSize, uint8_t numBlocks)
    {
      if (miniTask == READ)
        {
          // read block 0 of the tag with ID tagInfo 
          if (FAIL == call Mini.readTag(tagInfo, size, 0))
            call Leds.redOn();
        }
      else if (miniTask == WRITE)
        {
          /* response code has been parsed out by SkyeReadMini so only relevant data
             is sent back but when sending data out to xRFID, we need the raw data */
          packageData ( CONVERT_TO_RAW_DATA(tagInfo), CONVERT_TO_RAW_SIZE(size));

          // write tagData to block 0. 8 = sizeof(tagData)
          if (FAIL == call Mini.writeTag(tagInfo, size, 0, tagData, 8))
            call Leds.redOn();
        }

      return SUCCESS;
    }



  /**
   * Mini response to the <code>Mini.getSignalStrength</code> command.
   * Package the signal strength data.  This is the last step in data 
   * packaging before requesting MiniPacketizer to send the data to 
   * UART/Radio. finishedTask is also posted because the app is finished 
   * with all requested tasks and may now accept a new command from the 
   * buttons.
   * @return Always returns <code>SUCCESS</code>
   **/
  async event result_t Mini.SignalStrengthReady (uint16_t data) 
    {
      packageSG (data);
      post sendReplyData ();
      return SUCCESS;
    }


  /**
   * Mini response to the <code>Mini.readTag</code> command.
   * Package the data read from the tag and then request signal 
   * strength data.
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Mini.tagDataReady (uint8_t *data, uint8_t size)
    {
      /* response code has been parsed out by Mini so only relevant data
         is sent back but when sending data out to xRFID, we need the raw data */
      packageData ( CONVERT_TO_RAW_DATA(data), CONVERT_TO_RAW_SIZE(size));
      call Mini.getSignalStrength();
      return SUCCESS;
    }

 
  /**
   * Mini response to the <code>Mini.writeTag</code> command.
   * No data is returned from a write.  Request signal strength data.
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Mini.tagWriteDone() 
    {
      call Mini.getSignalStrength();
      return SUCCESS;
    }


  /**
   * Mini response to the <code>Mini.sendRaw</code> command.
   * Package raw data and request signal strength.
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Mini.replyRaw (uint8_t *reply, uint8_t len)
    {
      call Leds.greenOff();

      /* already raw data so we don't need to use macro "CONVERT_TO_RAW_DATA" */
      packageData (reply, len);  // send out raw reply data

      call Mini.getSignalStrength();
      return SUCCESS;
    }


  /**
   * Mini event when finished with a command.
   * miniResult_t is defined in SkyeReadMini.h in component level.
   **/
  event void Mini.miniDone (miniResult_t result)
    {
      /* event may be used to signal that another 
	     command can be sent to SkyeRead Mini */ 
      call Leds.yellowOff();

      if ((result == MINI_TIMEOUT) || (result == MINI_SUCCESS))
        {
          call Leds.greenOff();
          call Leds.redOff();
        }
      else if (result == FAIL) 
        {
          call Leds.greenOff();
          call Leds.redOn();
        }
    }


/************************************************/
/**** MINI PACKETIZER EVENTS ********************/
/************************************************/


  /**
   * MiniPacketizer response to the <code>Packetizer.sendData</code> command.
   * Finished sending data out to UART/Radio.
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Packetizer.sendDone ()
    {
      return SUCCESS;
    }


  /**
   * MiniPacketizer event when a command has been 
   * received by MiniPacketizer. Forward command to 
   * Mini.sendRaw. 
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Packetizer.sendRawCmd (uint8_t *cmd, uint8_t len)
    {
      call Leds.greenOn();
      call Mini.sendRaw (cmd, len);
      return SUCCESS;
    }



/************************************************/
/**** MINI READER BUTTON EVENTS *****************/
/************************************************/

 
  /**
   * SkyeReadMini event when button 1 is clicked.
   * Set miniTask to READ. When a tag is found,
   * the task will be to read memory from that 
   * tag.
   * @return Always returns <code>SUCCESS</code>
   **/
  async event result_t Mini.SW1Clicked()
    {
      miniTask = READ;
      call Leds.yellowOn();
      return SUCCESS;
    }


  /**
   * SkyeReadMini event when button 2 is clicked.
   * Set miniTask to WRITE. When a tag is found,
   * the task will be to write a block of data 
   * (tagData) to tag memory.
   * @return Always returns <code>SUCCESS</code>
   **/
  async event result_t Mini.SW2Clicked()
    {
      miniTask = WRITE;
      call Leds.yellowOn();
      return SUCCESS;
    }


} 
