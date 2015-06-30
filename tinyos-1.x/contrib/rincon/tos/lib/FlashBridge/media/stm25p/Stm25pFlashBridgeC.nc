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
 * Blackbook to Flash bridge implementation 
 * For the STM25P
 * 
 * Components using this interface should connect 
 * to the parameterized interface unique("FlashBridge")
 * @author David Moss (dmm@rincon.com)
 * @author Mark Kranz
 *
 */

includes FlashSettings;

configuration Stm25pFlashBridgeC {
  provides {
    interface StdControl;
    interface FlashSettings;
    interface FlashBridge[uint8_t id];
  }
}

implementation {
  components Stm25pFlashBridgeM, StateC, HALSTM25PC, TimerC;
#ifdef STM25P_BOOMERANG_VERSION  
  components new STM25PResourceC() as CmdReadCrcC;
  Stm25pFlashBridgeM.CmdReadCrc -> CmdReadCrcC;
#endif  
  
  StdControl = Stm25pFlashBridgeM;
  StdControl = StateC;
  StdControl = TimerC;
  StdControl = HALSTM25PC;
  
  FlashSettings = Stm25pFlashBridgeM;
  FlashBridge = Stm25pFlashBridgeM;
  
  Stm25pFlashBridgeM.HALSTM25P -> HALSTM25PC.HALSTM25P[unique("HALSTM25P")];
  Stm25pFlashBridgeM.State -> StateC.State[unique("State")];
  Stm25pFlashBridgeM.Timer -> TimerC.Timer[unique("Timer")];

}














