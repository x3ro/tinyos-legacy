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


interface SkyeReadMini 
{


/************************************************/
/**** SEARCH TAG INTERFACE **********************/
/************************************************/

  /* 
   *  Request Mini to find a tag.
   *  If Mini doesn't find a tag by "timeout" seconds,
   *  then Mini gives up and miniDone is signalled with a TIMEOUT result.
   *  If another searchTag command is issued while a 
   *  previous command timeout has not fired, searchTag 
   *  will return FAIL. 
   *  Also returns FAIL if a previous command is still being processed.
   *
   *  "0" seconds is a valid timeout. If no tag 
   *  is found immediately, then tagSearchTimeout is 
   *  signalled.
   *
   *  Result will be returned by event tagFound 
   */
  command result_t searchTag (uint8_t timeout);

  /*
   *  Event handler as a tag is found. 
   *  tagInfo is the tag type and TID of the tag found.
   *  tagInfoSize is the size of tagInfo.
   *  blockSize is the size in bytes of 1 block of memory on the tag.
   *  numBlocks is the number of blocks of memory.
   */
  event result_t tagFound(uint8_t *tagInfo, uint8_t tagInfoSize, 
                          uint8_t blockSize, uint8_t numBlocks);




/************************************************/
/**** WRITE TAG INTERFACE ***********************/
/************************************************/

  /* 
   *  Write a data block to a specified tag.
   *  Result will be returned by event tagWriteDone.
   *  TagInfo includes tag type and TID which are get by calling searchTag;
   *  blockIndex is the index of data block to be written;
   *  data is the data to write to the block.
   *  dataSize is the number of data bytes writing to tag.
   *  Return FAIL if a previous command is still being processed.
   */
  command result_t writeTag (uint8_t* tagInfo, uint8_t tagInfoSize, uint8_t blockIndex, 
                                               uint8_t* data, uint8_t dataSize);

  /*  Event handler as writing to a tag is done. */
  event result_t tagWriteDone();




/************************************************/
/**** READ TAG INTERFACE ************************/
/************************************************/
  
  /*  
   *  Read a data block from a specified tag.
   *  Result will be returned by event tagDataReady. 
   *  tagInfo includes tag type and TID which are get by calling searchTag;
   *  blockIndex is the index of data block to be written.
   *  Return FAIL if a previous command is still being processed.
   */
  command result_t readTag (uint8_t* tagInfo, uint8_t tagInfoSize, uint8_t blockIndex);  

  /*  Event handler as tag block data is ready to read. */
  event result_t tagDataReady(uint8_t *data, uint8_t size); 



  
/************************************************/
/**** SIGNAL STRENGTH INTERFACE *****************/
/************************************************/

  /* 
   *  Get radio signal strength.
   *  Result will be returned by event SignalStrengthReady.
   */
  command result_t getSignalStrength();

  /*  Event handler as signal strength is ready to read. */
  async event result_t SignalStrengthReady(uint16_t data);




/************************************************/
/**** BUTTON INTERFACE **************************/
/************************************************/

  /*  Event handler as SW1 is clicked. */
  async event result_t SW1Clicked();

  /*  Event handler as SW2 is clicked. */
  async event result_t SW2Clicked();




/************************************************/
/**** MISCELLANEOUS INTERFACE *******************/
/************************************************/

  /*  
   *  Send a raw command to the Mini
   *  Return FAIL if a previous command is still being processed.
   */
  command result_t sendRaw (uint8_t *cmd, uint8_t len); 


  /* Event handler when Mini replies to raw command */ 
  event result_t replyRaw (uint8_t *reply, uint8_t len); 


  /* 
   *  This event can be used to ensure that the Mini is finished 
   *  with the previous command before the application issues another 
   *  command.
   *  "result" returns SUCCESS for returned response event,
   *  FAIL for a failed mini command response, or a TIMEOUT 
   *  if a command timed out while waiting for a response from the 
   *  Mini.
   */ 
  event void miniDone (miniResult_t result);  
  

#if 0   
  /*   
   *  IMPORTANT NOTE:
   *  Be careful when using the SkyeReadMini commands on the MICA2.  MICA2
   *  uses UART1 to communicate with the SkyeRead Mini.  UART1 and flash 
   *  on the MICA2 are on the same bus lines.  MiniOffBus takes the 
   *  Skyetek Mini off the bus so that the MICA2 can safely write to 
   *  flash.  Writing to flash while the Skyetek Mini is on the bus
   *  may inadvertantly send commands to the Mini.  The Mini's responses 
   *  could then corrupt the flash data.
   * 
   *  After finishing writing to flash, the Mini can be put back on 
   *  the bus.  Note that it will take some time before the Mini 
   *  will be ready after calling MiniOnBus. Wait ~150 ms before 
   *  sending a command to the mini after calling MiniOnBus.
   */
  command void MiniOffBus ();
  command void MiniOnBus ();
#endif
}
