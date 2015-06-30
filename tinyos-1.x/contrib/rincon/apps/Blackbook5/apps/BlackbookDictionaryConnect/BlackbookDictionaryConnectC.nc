/*
 * Copyright (c) 2004-2006 Rincon Research Corporation.  
 * All rights reserved.
 * 
 * Rincon Research will permit distribution and use by others subject to
 * the restrictions of a licensing agreement which contains (among other things)
 * the following restrictions:
 * 
 *  1. No credit will be taken for the Work of others.
 *  2. It will not be resold for a price in excess of reproduction and 
 *      distribution costs.
 *  3. Others are not restricted from copying it or using it except as 
 *      set forward in the licensing agreement.
 *  4. Commented source code of any modifications or additions will be 
 *      made available to Rincon Research on the same terms.
 *  5. This notice will remain intact and displayed prominently.
 * 
 * Copies of the complete licensing agreement may be obtained by contacting 
 * Rincon Research, 101 N. Wilmot, Suite 101, Tucson, AZ 85711.
 * 
 * There is no warranty with this product, either expressed or implied.  
 * Use at your own risk.  Rincon Research is not liable or responsible for 
 * damage or loss incurred or resulting from the use or misuse of this software.
 */

/**
 * BlackbookDictionaryConnect Module
 * This interacts with the com.rincon.blackbook.BlackbookDictionaryConnect
 * program to provide direct access to the Blackbook interfaces
 * from your desktop.
 * 
 * You can also use com.rincon.blackbook.memorystick.MemoryStick
 * to upload/download files on your computer to flash.
 *
 * @author David Moss - dmm@rincon.com
 */

includes Blackbook;
includes BlackbookDictionaryConnect;

configuration BlackbookDictionaryConnectC {
}

implementation {
  components Main, BlackbookDictionaryConnectM, BlackbookDictionaryC, FlashBridgeViewerC, StateC, TransceiverC, LedsC;
  components NodeMapC, SectorMapC;

  Main.StdControl -> BlackbookDictionaryConnectM;
  Main.StdControl -> BlackbookDictionaryC;
  Main.StdControl -> FlashBridgeViewerC;
  Main.StdControl -> TransceiverC;
  Main.StdControl -> StateC;
  
  BlackbookDictionaryConnectM.Transceiver -> TransceiverC.Transceiver[AM_BLACKBOOKCONNECTMSG];
  BlackbookDictionaryConnectM.NodeTransceiver -> TransceiverC.Transceiver[AM_BLACKBOOKNODEMSG];
  BlackbookDictionaryConnectM.FileTransceiver -> TransceiverC.Transceiver[AM_BLACKBOOKFILEMSG];
  BlackbookDictionaryConnectM.SectorTransceiver -> TransceiverC.Transceiver[AM_BLACKBOOKSECTORMSG];
  BlackbookDictionaryConnectM.State -> StateC.State[unique("State")];
  BlackbookDictionaryConnectM.Leds -> LedsC;
  
  // This stuff is for debugging purposes.
  BlackbookDictionaryConnectM.NodeMap -> NodeMapC;
  BlackbookDictionaryConnectM.SectorMap -> SectorMapC;

  // These are all the actual Blackbook interfaces you can wire up to your app.
  BlackbookDictionaryConnectM.BBoot -> BlackbookDictionaryC;
  BlackbookDictionaryConnectM.BClean -> BlackbookDictionaryC;
  BlackbookDictionaryConnectM.BFileDelete -> BlackbookDictionaryC.BFileDelete[unique("BFileDelete")];
  BlackbookDictionaryConnectM.BFileDir -> BlackbookDictionaryC.BFileDir[unique("BFileDir")];
  BlackbookDictionaryConnectM.BDictionary -> BlackbookDictionaryC.BDictionary[unique("BDictionary")];

}
