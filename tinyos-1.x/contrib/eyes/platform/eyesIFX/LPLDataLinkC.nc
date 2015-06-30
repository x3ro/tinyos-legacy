/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * provides preamble sampling csma with timestamping
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2005/10/31 11:41:45 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

configuration LPLDataLinkC {
    provides {
        interface StdControl;
        interface BareSendMsg as Send;
        interface ReceiveMsg as Receive;
    }
}
implementation
{
    components 
        //Change components below as desired
        TDA5250C           as Radio,             //The physical layer radio configuration
        MarshallerC  as Marshaller,        //The Marshaller for    Bytes actually sent
        SyncSampleMACC as MAC,               //The MAC protocol to use
        PreambleSampleLLCC as LLC;      //The Link Layer Control module to use
    //Don't change wirings below this point, just change which components
    //They are compposed of in the list above             
    StdControl = Radio;
    StdControl = Marshaller;
    StdControl = MAC;
    StdControl = LLC;
  
    Send = LLC.Send;
    Receive = LLC.Receive;
  
    LLC.GenericMsgComm->MAC;
    LLC.MarshallerControl->Marshaller;
    LLC.PacketRx->MAC.UpPacketRx;
    LLC.LPLControl->MAC.LPLControl;
    
    LLC.ChannelMonitorData->MAC.ChannelMonitorData;
    MAC.MarshallerGenericMsgComm->Marshaller;
    MAC.RadioModes->Radio;
    MAC.DownPacketRx->Marshaller.UpPacketRx;
    MAC.FrameSync->Radio.FrameSync;

    Marshaller.ByteComm->Radio;
    Marshaller.PacketTx->Radio;
    Marshaller.DownPacketRx->Radio.PacketRx;
}
