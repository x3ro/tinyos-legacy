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
 * This component manages the network properties.
 */


module NetworkPropertiesM
{
  provides {
    interface NetworkProperty;
  }

  uses {
    interface NetworkPacket;
    interface NetworkTopology;
    interface StatsLogger;
  }
}


implementation
{

  enum {PROPERTY_QUERY,
        PROPERTY_REPLY};

  #define PROPERTY_QUERY_LENGTH 4

  command result_t NetworkProperty.GetNetworkProperties(uint32 NodeID) {
    char   *buffer;
    uint32 *t;

    if ( call NetworkTopology.IsPropertySupported(NodeID,NETWORK_PROPERTY_NULL)
         == TRUE){
      buffer = call NetworkPacket.AllocateBuffer(PROPERTY_QUERY_LENGTH);
      if (buffer == NULL) return FAIL;

      t = (uint32 *) buffer;
      t[0] = (uint32) PROPERTY_QUERY;
      if (call NetworkPacket.Send(NodeID, buffer,PROPERTY_QUERY_LENGTH)==FAIL) {
        call NetworkPacket.ReleaseBuffer(buffer);
        return FAIL;
      }
    }

    return SUCCESS;
  }
    

/*
 * Start of NetworkPacket interface.
 */

  void SendProperties(uint32 Dest) {
    uint32 Properties[4], NumProperties, *t, i;
    uint16 length;
    char   *buffer;
    uint32 ThisNodeID;

    NumProperties = 4;
    call NetworkTopology.GetNodeID(&ThisNodeID);
    call NetworkTopology.GetProperties( ThisNodeID, &(Properties[0]),
                                        &NumProperties);
    length = (1 + NumProperties) * sizeof(uint32);
    buffer = call NetworkPacket.AllocateBuffer(length);
    t = (uint32 *) buffer;
    t[0] = PROPERTY_REPLY;
    for (i = 0; i < NumProperties; i++) t[i + 1] = Properties[i];
    if (call NetworkPacket.Send(Dest, buffer, length) == FAIL) {
      call NetworkPacket.ReleaseBuffer(buffer);
    }
  }



  default event result_t NetworkProperty.NodePropertiesReady(uint32 NodeID) {
    return SUCCESS;
  }



  void AddNewProperties( uint32 OtherNodeID, uint8 *Data, uint16 Length) {

    uint32 *t;
    uint16 length;
    int    i;

    t = (uint32 *)Data;
    length = (Length / sizeof(uint32)) - 1;

    if (length > 0) { // other node has some properties
      for (i = 0; i < length; i++) {
        call NetworkTopology.SetProperty(OtherNodeID, t[i+1]);
      }
    } else { // other node has no properties so remove PROPERTY_NULL
      call NetworkTopology.UnsetProperty(OtherNodeID, NETWORK_PROPERTY_NULL);
    }

    signal NetworkProperty.NodePropertiesReady(OtherNodeID);

  }

  event result_t NetworkPacket.Receive( uint32 Source, uint8 *Data,
                                        uint16 Length) {

    uint32 Command;

    call StatsLogger.BumpCounter(NUM_NP_RECV, 1);

    Command = *((uint32 *) (Data));
    switch (Command) {

      case (uint32) PROPERTY_QUERY:
        SendProperties(Source);
        break;

      case (uint32) PROPERTY_REPLY:
        AddNewProperties(Source, Data, Length);
        break;

      default:
    }

    return SUCCESS;
  }

  event result_t NetworkPacket.SendDone (char *data) {
    call NetworkPacket.ReleaseBuffer ( data );
    call StatsLogger.BumpCounter(NUM_NP_SEND, 1);

    return SUCCESS;
  }

}
