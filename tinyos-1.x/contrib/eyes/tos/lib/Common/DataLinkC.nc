/*
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
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.2 $
 * $Date: 2005/04/07 19:03:54 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

configuration DataLinkC {
   provides {
     interface StdControl;
     interface BareSendMsg as Send;
     interface ReceiveMsg as Receive;
   }
}
implementation
{
  components EncoderDecoderM as EncoderDecoder,
             //Change components below as desired
             CodecNone          as Codec,             //Codec used to code bytes
             TDA5250C           as Radio,             //The physical layer radio configuration
             MarshallerM        as Marshaller,        //The Marshaller for Bytes actually sent
             BasicMACC         as MAC,               //The MAC protocol to use
             BasicLLCC         as LLC;               //The Link Layer Control module to use
  //Don't change wirings below this point, just change which components
  //They are compposed of in the list above             
  StdControl = EncoderDecoder;             
  StdControl = Radio;
  StdControl = Marshaller;
  StdControl = MAC;
  StdControl = LLC;
  
  Send = LLC.Send;
  Receive = LLC.Receive;
  
  LLC.GenericMsgComm->MAC;
  LLC.MarshallerControl->Marshaller;
  LLC.PacketRx->Radio;
  
  MAC.MarshallerGenericMsgComm->Marshaller;
  MAC.RadioControl->Radio;
  
  Marshaller.ByteComm->EncoderDecoder;
  Marshaller.PacketTx->EncoderDecoder;
  
  EncoderDecoder.PacketRx->Radio;
  EncoderDecoder.Codec->Codec;
  EncoderDecoder.RadioByteComm->Radio;
  EncoderDecoder.RadioPacketTx->Radio;
}
