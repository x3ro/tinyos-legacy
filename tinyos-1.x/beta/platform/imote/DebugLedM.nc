/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
/*
 * This is an LED debug module, it changes the LED color based on the node's
 * level in the tree.  It also blinks the LED if data is flowing through the
 * node
 * It does that by intercepting all sends & receives 
 */

module DebugLedM
{
  provides {
     interface HCIData;
     interface StdControl;
  }

  uses {
     interface HCIData as RealHCIData;
     interface Timer;
     interface NetworkTopology;
     interface LowPower;
     interface StatsLogger;
     command result_t GetRootNodeID(uint32 *ID);
  }
}

implementation
{
#define DEBUG_TIMER_TICK 125
#define DEBUG_LAG_TIME 2	// Blink upto a second after last packet received
#define INVALID_NODE 0xFFFFF

   uint32 MyTime;
   uint32 LastPacketTransfer;
   bool LedOn;
   uint32 RootNodeID;
   uint32 ThisNodeID;
   bool RootNode;
   bool LowPowerMode;
   bool StopLed;
   
   /*
    * StdControl interface
    */
   command result_t StdControl.init() {
      MyTime = 10;
      LastPacketTransfer = 1;
      LedOn = false;
      RootNodeID = INVALID_NODE;
      LowPowerMode = false;
      StopLed = false;
      return SUCCESS;
   }

   command result_t StdControl.start() {
      call Timer.start(TIMER_REPEAT, DEBUG_TIMER_TICK);
      call NetworkTopology.GetNodeID(&ThisNodeID);
      return SUCCESS;
   }
    
   command result_t StdControl.stop() {
      StopLed = true;
      return SUCCESS;
   }

   result_t GetMyHopCount(uint32 *HopCount) {

      if (RootNodeID == ThisNodeID) {
         *HopCount = 0;
         return SUCCESS;
      } else {
         return call NetworkTopology.GetHops(RootNodeID, HopCount);
      }
   }

   void TurnOnLed(uint32 HopCount) {
      switch (HopCount) {
         case 0 :  // Red	
            TM_ResetPio(4);
            TM_SetPio(5);
            TM_ResetPio(6);
            break;
         case 1 :  // Yellow
            TM_ResetPio(4);
            TM_SetPio(5);
            TM_SetPio(6);
            break;
         case 2 :  // Green
            TM_ResetPio(4);
            TM_ResetPio(5);
            TM_SetPio(6);
            break;
         case 3 :  // Cyan
            TM_SetPio(4);
            TM_ResetPio(5);
            TM_SetPio(6);
            break;
         default :  // Magenta
            TM_SetPio(4);
            TM_SetPio(5);
            TM_ResetPio(6);
            break;
      }
   }

   /*
    * Timer Interface
    */
   event result_t Timer.fired() {
      uint32 HopCount;
      uint32 NextNode;
      tHandle NextHandle;

      MyTime++;

      if (LowPowerMode || StopLed) {
         // In Low Power, turn off all LEDS
         TM_ResetPio(4);
         TM_ResetPio(5);
         TM_ResetPio(6);
         LedOn = false;
         if (StopLed) {
            call Timer.stop();
         }
         return SUCCESS;
      }

      if (RootNodeID == INVALID_NODE) {
#if 0	// For now don't rely on routing table, cluster head doesn't send prop
         call NetworkTopology.GetNodesSupportingProperty(NETWORK_PROPERTY_CLUSTER_HEAD, 1, &RootNodeID);
#else
         call GetRootNodeID(&RootNodeID);
#endif
         return SUCCESS;
      }

      // Found RootNode
      if ((GetMyHopCount(&HopCount) == FAIL) || (HopCount >= 0xFF)) {
         // If entry is not there, or hop count is too large
         RootNodeID = INVALID_NODE;
         TM_ResetPio(5);
         TM_ResetPio(6);
         LedOn = false;
         return SUCCESS;
      }

      call StatsLogger.OverwriteCounter(HOP_COUNT_TO_CH, HopCount);
      call NetworkTopology.GetNextConnection(RootNodeID, &NextNode, &NextHandle);
      call StatsLogger.OverwriteCounter(ID_OF_NEXT_HOP, NextNode);
      
      if (MyTime > LastPacketTransfer + DEBUG_LAG_TIME) {
         // Stop blinking
         TurnOnLed(HopCount);
         LedOn = true;
         return SUCCESS;
      }

      // Continue blinking
      if (LedOn) {
         TM_ResetPio(4);
         TM_ResetPio(5);
         TM_ResetPio(6);
         LedOn = false;
      } else {
         TurnOnLed(HopCount);
         LedOn = true;
      }

      return SUCCESS;
   }

   /*
    * HCI Data interface
    */
   event result_t RealHCIData.SendDone(uint32 TransactionID, tHandle Connection_Handle, 
                                   result_t Acknowledge) {

      return signal HCIData.SendDone(TransactionID, Connection_Handle, Acknowledge);
   }

   event result_t RealHCIData.ReceiveACL(uint32  TransactionID, tHandle Connection_Handle,
                                     uint8   *Data, uint16  DataSize, uint8   DataFlags) {

      tiMoteHeader    *headerPtr;

      headerPtr = (tiMoteHeader *) Data;
      if (headerPtr->channel == 0) {
         // Data channel
         LastPacketTransfer = MyTime;
      }
      return signal HCIData.ReceiveACL(TransactionID, Connection_Handle, Data, DataSize, DataFlags);
   }

   command result_t HCIData.Send(uint32 TransactionID, tHandle Connection_Handle, 
                                 uint8 *Data, uint16 Data_Total_Length) {

      tiMoteHeader    *headerPtr;
      headerPtr = (tiMoteHeader *) Data;
      if (headerPtr->channel == 0) {
         // Data channel
         LastPacketTransfer = MyTime;
      }

      return call RealHCIData.Send(TransactionID, Connection_Handle, Data, Data_Total_Length);
   }

   /*
    * Low Power interface
    */
   event result_t LowPower.EnterLowPowerComplete () {
      return SUCCESS;
   }

   event result_t LowPower.PowerModeChange(bool Mode) {
      LowPowerMode = Mode;
     return SUCCESS;
   }
}
