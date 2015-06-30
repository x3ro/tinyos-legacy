/*
 *
 * Systemic Realtime Design, LLC.
 * http://www.sysrtime.com
 *
 * Authors:  Michael Li 
 *
 * Date last modified:  9/30/04
 *
 */


/* 
 *  MiniPacketizer takes the SkyeRead Mini data and formats it into packets 
 *  that can be understood by the Mini xcontrol program.  This "packetizer" 
 *  is required because some commands and responses are larger than the 
 *  maximum payload of a TOS_MSG. 
 *
 */ 


interface MiniPacketizer
{
  /*
   *  Packages skytek mini data and sends it out to xcontrol through UART
   *  sg   - signal strength (from SkyeReadMini.SignalStrengthReady)
   *  data - ptr to data 
   *  len  - length of data (len from SkyeReadMini response event)
   */ 
  command result_t sendData (uint16_t sg, uint8_t *data, uint8_t len);  

  /*
   *  Finished sending SkyeRead Mini data. You may send more data. 
   */ 
  event result_t sendDone (); 

  /*
   *  Received a command from MiniControl program. Forward data to 
   *  SkyeReadMini.sendraw command. 
   */ 
  event result_t sendRawCmd (uint8_t *cmd, uint8_t len);
}
