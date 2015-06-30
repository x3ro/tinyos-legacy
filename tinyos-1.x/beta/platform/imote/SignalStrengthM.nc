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
module SignalStrengthM {

  provides {
    interface SignalStrength;
  }

  uses {

    interface Timer;
    interface HCIStatus;
    interface HCIBaseband;
    interface NetworkTopology;

  }
}


implementation
{
#define TRACE_DEBUG_LEVEL 0ULL

  #define MAX_NEIGHBORS 16
  #define SIGNAL_STRENGTH_SAMPLE_INTERVAL 1000  // 1 second

  uint32 Neighbors[MAX_NEIGHBORS];
  uint32 NumNeighbors;

  command result_t SignalStrength.start() {
    call Timer.start(TIMER_REPEAT, SIGNAL_STRENGTH_SAMPLE_INTERVAL); 

    return SUCCESS;
  }

  command result_t SignalStrength.stop() {
    call Timer.stop();

    return SUCCESS;
  }

  command int8_t SignalStrength.GetNodeSignalStrength(uint32 NodeID) {
    tHandle Handle;

    call NetworkTopology.GetNextConnection(NodeID, NULL, &Handle);
    return (call NetworkTopology.GetRSSI(Handle));
    
  }

  command int8_t SignalStrength.GetHandleSignalStrength(tHandle Handle) {
    return (call NetworkTopology.GetRSSI(Handle));
  }


  task void CollectTransmitPowers() {
    tHandle Handle;

    call NetworkTopology.Get1HopDestinations( MAX_NEIGHBORS, 
                                              &NumNeighbors,
                                              &(Neighbors[0]));
    trace(TRACE_DEBUG_LEVEL,"Collecting %d transmit powers for %05X\n\r", NumNeighbors, Neighbors[0]);
    
    if (NumNeighbors > 0) {
      if (call NetworkTopology.GetNextConnection(Neighbors[--NumNeighbors],
        NULL, &Handle) == SUCCESS) {

        // read the current transmit power level
        call HCIBaseband.Read_Transmit_Power_Level(Handle, 0);
      } else { 
        post CollectTransmitPowers();
      }
    }
  }


  task void CollectSignalStrengths() {
    tHandle Handle;

    call NetworkTopology.Get1HopDestinations( MAX_NEIGHBORS, 
                                              &NumNeighbors,
                                              &(Neighbors[0]));
    trace(TRACE_DEBUG_LEVEL,"Collecting %d signal strengths for %05X\n\r", NumNeighbors, Neighbors[0]);
    
    if (NumNeighbors > 0) {
      if (call NetworkTopology.GetNextConnection(Neighbors[--NumNeighbors],
        NULL, &Handle) == SUCCESS) {

        call HCIStatus.Read_RSSI(Handle);
      } else { 
        post CollectSignalStrengths();
      }
    } else {
      post CollectTransmitPowers();
    }
  }



  event result_t Timer.fired() {
    post CollectSignalStrengths();
    return SUCCESS;
  }

  event result_t HCIStatus.Command_Complete_Read_RSSI( uint8 Status,
                                                       tHandle Handle,
                                                       int8_t RSSI) {

      trace(TRACE_DEBUG_LEVEL, "Read RSSI complete status %d, Handle %d, signal strength %d\n\r", Status, Handle, RSSI);

    if (Status == 0) {
      call NetworkTopology.SetRSSI(Handle, RSSI);
    }

    if (NumNeighbors > 0) {
      if (call NetworkTopology.GetNextConnection(Neighbors[--NumNeighbors],
        NULL, &Handle) == SUCCESS) {

        call HCIStatus.Read_RSSI(Handle);
      } else { 
        post CollectSignalStrengths();
      }
    } else {
      post CollectTransmitPowers();
    }

    return SUCCESS;

  }

  event result_t HCIStatus.Command_Complete_Read_Absolute_RSSI( uint8 Status,
                                                                int8_t RSSI) {
    return SUCCESS;
  }

  /*
   * Start of HCBaseband interface
   */

  event result_t HCIBaseband.Command_Complete_Write_Scan_Enable( uint8 Status) {
    return SUCCESS;
  }

  event result_t HCIBaseband.Command_Complete_Read_Link_Supervision_Timeout(
                                                     uint8 Reason,
                                                     tHandle Connection_Handle,
                                                     uint16 Timeout ) {
    return SUCCESS;
  }

  event result_t HCIBaseband.Command_Complete_Write_Current_IAC_LAP(
                                                     uint8 Status ) {
    return SUCCESS;
  }

  event result_t HCIBaseband.Command_Complete_Read_Transmit_Power_Level(
                                                  uint8 Status,
                                                  tHandle Connection_Handle,
                                                  int8_t Transmit_Power_Level) {
      trace(TRACE_DEBUG_LEVEL,"Read transmit power status %d, Handle %d, power %d\n\r", Status, Connection_Handle, Transmit_Power_Level);
      if (Status == 0) {
      call NetworkTopology.SetTransmitPower( Connection_Handle,
                                             Transmit_Power_Level);
    }

    if (NumNeighbors > 0) {
      if (call NetworkTopology.GetNextConnection(Neighbors[--NumNeighbors],
        NULL, &Connection_Handle) == SUCCESS) {

        // read the current transmit power level
        call HCIBaseband.Read_Transmit_Power_Level(Connection_Handle, 0);
      } else { 
        post CollectTransmitPowers();
      }
    }

    return SUCCESS;
  }

  /*
   * Start of HCBaseband interface
   */

}

