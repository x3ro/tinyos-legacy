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
 * Demo to show how to connect to and use ConfigurationC
 *
 * This only demonstrates connecting ConfigurationC to one component,
 * but the same concepts apply to connecting ConfigurationC to many
 * components.
 *
 * Because the FlashBridgeViewer component is added in here,
 * you can view the contents of flash to verify everything is
 * working correctly.  You'll see the first two bytes of flash
 * are a CRC, followed by 4 bytes of a uint32_t with
 * the number of times the mote has rebooted.
 *
 * @author David Moss
 */
 
configuration RebootCountC {
}

implementation {
  components Main, 
      RebootCountM,
      ConfigurationC,
      FlashBridgeViewerC,
      LedsC;
     
  Main.StdControl -> LedsC; 
  Main.StdControl -> ConfigurationC;
  Main.StdControl -> FlashBridgeViewerC;
  
  RebootCountM.Configuration -> ConfigurationC.Configuration[unique("Configuration")];
  RebootCountM.Leds -> LedsC;
  
}

