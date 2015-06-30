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
 * This module provides a HCI interface to the lower level Bluetooth stack.
 * The HCI commands are the same as those described in the Bluetooth
 * specification.  This module interfaces with the software implementation of
 * the lower level stack provided in the motelib library.  Code in that library
 * is not available for public distribution.
 * 
 * At this time, only a subset of the HCI interface has been implemented.  The
 * rest will be added on an as-needed basis.
 */

includes motelib;

module BTLowerLayersM
{
  provides {
    interface StdControl as Control;
    interface HCILinkControl as HCILinkControl;
    interface HCILinkPolicy as HCILinkPolicy;
    interface HCIBaseband as HCIBaseband;
    interface HCICommand as HCICommand;
    interface HCIStatus as HCIStatus;
    interface HCIData as HCIData;
  }
}



implementation
{

#define TRACE_DEBUG_LEVEL DBG_RADIO

  #define BLL_PACKETS_INFLIGHT 4

  #define MAX_INQUIRY_RESPONSES 8
  typedef struct tIRParameters {
    tBD_ADDR   BD_ADDR [MAX_INQUIRY_RESPONSES];
    uint8      Page_Scan_Repetition_Mode [MAX_INQUIRY_RESPONSES];
    uint8      Page_Scan_Period_Mode [MAX_INQUIRY_RESPONSES];
    uint8      Page_Scan_Mode [MAX_INQUIRY_RESPONSES];
    uint32     Class_of_Device [MAX_INQUIRY_RESPONSES];
    uint16     Clock_Offset [MAX_INQUIRY_RESPONSES];
  } tIRParameters;

  uint8           CurrentTransactionID; // 0-255 ID to track interaction with
                                        // lower layers.
  tIRParameters   IRParameters;         // Storage container for the inquiry
                                        // result parameter list

  int             SendPacketsPending;    // Number of packets sent to the lower
                                        // level which have been neither ack'd
                                        // nor nack'd

  int             ReceivePacketsPending;// Number of packets for which the
                                        // lower level has sent a data ready
                                        // but have not yet been passed up the
                                        // stack

  bool            RadioInitialized;     // Flag to allow multiple calls to init,
                                        // but only one execution

  uint32          InquiryTransac;       // Transaction for inquiry request.
                                        // Used to route Command Status result                                        

  // Utility routine to convert BD address from BlueOS to TinyOS
  void BD_ADDR_BOS2TOS(tBdAddr *BdAddr, tBD_ADDR *BD_ADDR) __attribute__ ((C, spontaneous)) {
    int i;
    for (i = 0; i < 6; i++) {
      BD_ADDR->byte[i] = BdAddr->Byte[i];
    }
  }


  void BD_ADDR_TOS2BOS(tBD_ADDR *BD_ADDR, tBdAddr *BdAddr) __attribute__ ((C, spontaneous)) {
    int i;
    for (i = 0; i < 6; i++) {
      BdAddr->Byte[i] = BD_ADDR->byte[i];
    }
  }


  void ULS_SendAclAck(tTransac TransactionID, tHandleId ConnectionHandle)
    __attribute__ ((C, spontaneous)) 
  {
    SendPacketsPending--;
    signal HCIData.SendDone((uint32) TransactionID, (tHandle)ConnectionHandle, SUCCESS);
  }



  void ULS_SendAclNak(tTransac TransactionID, tHandleId ConnectionHandle)
    __attribute__ ((C, spontaneous)) 
  {
    SendPacketsPending--;
    signal HCIData.SendDone((uint32) TransactionID, (tHandle)ConnectionHandle, FAIL);
  }



  /*
   * The receiveData task queries the lower level for a pointer to the incoming
   * packet.  It removes the first 4 bytes (L2CAP header) and passes the packet
   * up the stack.  This is in the task context so the upper levels can process
   * the data as needed.  The higher levels must copy any of the packet contents
   * they want to hold on to since the packet buffer is released when the call
   * returns.
   */


  void DisplayReceivePacketsPending() {
   
    trace(TRACE_DEBUG_LEVEL,"Warning - %d receive packets pending\r\n", ReceivePacketsPending);
  }


  task void receiveData() {

    tTransac      Transac;
    tHandleId     Current_Handle;
    uint8         *DataPtr;
    uint16        DataSize;
    tDataFlags    DataFlags;

    if (ReceivePacketsPending >= 3) DisplayReceivePacketsPending();

    while (ReceivePacketsPending) {
      ReceivePacketsPending--;

      LM_GetRecAcl(&Transac, &Current_Handle, &DataPtr,
                   &DataSize, &DataFlags, TRUE);

      signal HCIData.ReceiveACL( CurrentTransactionID,
                                 Current_Handle,
                                 &(DataPtr[4]), // remove L2CAP header
                                 DataSize - 4,
                                 DataFlags);

      CurrentTransactionID++;  CurrentTransactionID &= 0xff;

      LM_RecAclAck(Transac); // when done with the data
    }
  }



  void ULS_RecAclAvailable () __attribute__ ((C, spontaneous)) 
  {
    ReceivePacketsPending++;
      
    post receiveData();
  }



/*
 * Start of hooks for lower level event callbacks.  These closely mirror the
 * BT HCI interface.
 */

  void HCIEvent_Command_Status (tSIG_LmStatus *p) __attribute__ ((C, spontaneous)) {
    // The p->Transac parameter appears to encode the Num_HCI_Command_Packet,
    // Command_Opcode, and requesting Transac into this Transac parameter
    uint16 Command;

    Command = p->Transac & 0xFFFF;

    if (Command == 0x1) { // Inquiry Request
      signal HCILinkControl.Command_Status_Inquiry(p->Reason);
    }
  }


  void HCIEvent_Inquiry_Result (tSIG_LmInquiryResult *p) __attribute__ ((C, spontaneous)) {
    int i, j;

    for (i = 0; i < p->NumResponses; i++) {
      for (j = 0; j < 6; j++) {
        IRParameters.BD_ADDR[i].byte[j] = p->InqResp[i].BdAddr.Byte[j];
      }
      IRParameters.Page_Scan_Repetition_Mode[i] = p->InqResp[i].PageScanRepMode;
      IRParameters.Page_Scan_Period_Mode[i] = p->InqResp[i].PageScanPeriodMode;
      IRParameters.Page_Scan_Mode[i] = p->InqResp[i].PageScanMode;
      IRParameters.Class_of_Device[i] = p->InqResp[i].COD;
      IRParameters.Clock_Offset[i] = p->InqResp[i].ClockOffset;
    }

    signal HCILinkControl.Inquiry_Result(p->NumResponses,
                                   &(IRParameters.BD_ADDR[0]),
                                   &(IRParameters.Page_Scan_Repetition_Mode[0]),
                                   &(IRParameters.Page_Scan_Period_Mode[0]),
                                   &(IRParameters.Page_Scan_Mode[0]),
                                   &(IRParameters.Class_of_Device[0]),
                                   &(IRParameters.Clock_Offset[0]));
  }


  void HCIEvent_Hardware_Error (tSIG_LmHardwareError *p) __attribute__ ((C, spontaneous)) {
      trace(TRACE_DEBUG_LEVEL,"Hardware Error %d \n", p->ErrorCode);
  }
  void HCIEvent_PIN_Code_Request (tSIG_LmPinCodeRequest *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_Link_Key_Request (tSIG_LmLinkKeyRequest *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_Link_Key_Notification (tSIG_LmLinkKeyNotification *p)
                                      __attribute__ ((C, spontaneous)) {}
  void HCIEvent_Return_Link_Keys (tSIG_LmReturnLinkKey *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_Inquiry_Complete (tSIG_LmInquiryCon *p) __attribute__ ((C, spontaneous)) {
    signal HCILinkControl.Inquiry_Complete(p->Reason);
  }
  void HCIEvent_InquiryCancelCmdCompl (tSIG_LmInquiryCancelCon *p) __attribute__ ((C, spontaneous)) {
    signal HCILinkControl.Command_Complete_Inquiry_Cancel(p->Reason);
  }



  void HCIEvent_Connection_Request (tSIG_LmConnectInd *p) __attribute__ ((C, spontaneous)) {
    tBD_ADDR BD_ADDR;

    BD_ADDR_BOS2TOS(&p->BdAddr, &BD_ADDR);
    signal HCILinkControl.Connection_Request(BD_ADDR, p->Cod, p->LinkType);
  }


  void HCIEvent_Connection_Complete (tSIG_LmConnectCon *p) __attribute__ ((C, spontaneous)) {
    tBD_ADDR BD_ADDR;

    BD_ADDR_BOS2TOS(&p->BdAddr, &BD_ADDR);
    signal HCILinkControl.Connection_Complete(p->Reason, p->Handle, BD_ADDR,
      p->LinkType, p->EncryptionMode);
  }



  void HCIEvent_Disconnection_Complete (tSIG_LmDisconnectCon *p) __attribute__ ((C, spontaneous)) {
     signal HCILinkControl.Disconnection_Complete(p->Status, p->Handle, p->Reason);
  }
  void HCIEvent_Authentication_Complete (tSIG_LmAuthenticationRequestedCon *p)
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_Encryption_Change (tSIG_LmSetConnectionEncryptionCon *p)
                                  __attribute__ ((C, spontaneous)) {}
  void HCIEvent_Remote_Name_Request_Complete (tSIG_LmRemoteNameRequestCon *p)
                                             __attribute__ ((C, spontaneous)) {}
  void HCIEvent_Mode_Change (tSIG_LmModeChangeEvt *p) __attribute__ ((C, spontaneous)) {
    signal HCILinkPolicy.Mode_Change(p->Reason, p->Handle, p->CurrentMode, p->Interval);
  }
  void HCIEvent_Role_Change (tSIG_LmSwitchRoleInd *p) __attribute__ ((C, spontaneous)) {
    tBD_ADDR BD_ADDR;

    BD_ADDR_BOS2TOS(&p->BdAddr, &BD_ADDR);
    signal HCILinkPolicy.Role_Change(p->Reason, BD_ADDR, p->NewRole);
  }
  void HCIEvent_RoleDiscovery (tSIG_LmRoleDiscoveryCon *p) __attribute__ ((C, spontaneous)) {
    signal HCILinkPolicy.Command_Complete_Role_Discovery( p->Reason, p->Handle,
                                                     p->Current_Role);
  }

  void HCIEvent_ReadLinkPolicySettings (tSIG_LmReadLinkPolicySettingsCon *p)
                                       __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteLinkPolicySettings (tSIG_LmWriteLinkPolicySettingsCon *p)
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadVoiceSettingsCompl (tSIG_LmReadVoiceSettingCon *p)
                                       __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteVoiceSettingsCompl (tSIG_LmWriteVoiceSettingCon *p)
                                        __attribute__ ((C, spontaneous)) {}

  void HCIEvent_LinkKeyRequestReplyCompl(tSIG_LmLinkKeyRequestReplyCon *p)
                                         __attribute__ ((C, spontaneous)) {}
  void HCIEvent_LinkKeyNegativeReplyCompl(tSIG_LmLinkKeyNegativeReplyCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_PinCodeRequestReplyCompl(tSIG_LmPinCodeRequestReplyCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_PinCodeRequestNegativeReplyCompl(tSIG_LmPinCodeRequestNegativeReplyCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ChangeConnectionPacketTypeCompl(tSIG_LmChangeConnectionPacketTypeCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ChangeConnectionLinkKeyCompl(tSIG_LmChangeConnectionLinkKeyCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadRemoteSupportedFeaturesCompl(tSIG_LmReadRemoteSupportedFeaturesCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadRemoteVersionInformationCompl(tSIG_LmReadRemoteVersionInformationCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadClockOffsetCompl(tSIG_LmReadClockOffsetCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_SetEventMaskCompl(tSIG_LmSetEventMaskCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ResetCompl(tSIG_LmResetCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_SetEventFilterCompl(tSIG_LmSetEventFilterCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadPinTypeCompl(tSIG_LmReadPinTypeCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WritePinTypeCompl(tSIG_LmWritePinTypeCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_CreateNewUnitKeyCompl(tSIG_LmCreateNewUnitKeyCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadStoredLinkKeyCompl(tSIG_LmReadStoredLinkKeyCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteStoredLinkKeyCompl(tSIG_LmWriteStoredLinkKeyCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_DeleteStoredLinkKeyCompl(tSIG_LmDeleteStoredLinkKeyCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ChangeLocalNameCompl(tSIG_LmChangeLocalNameCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadLocalNameCompl(tSIG_LmReadLocalNameCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadConnectionAcceptTimeoutCompl(tSIG_LmReadConnectionAcceptTimeoutCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteConnectionAcceptTimeoutCompl(tSIG_LmWriteConnectionAcceptTimeoutCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadPageTimeoutCompl(tSIG_LmReadPageTimeoutCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WritePageTimeoutCompl(tSIG_LmWritePageTimeoutCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadScanEnableCompl(tSIG_LmReadScanEnableCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteScanEnableCompl(tSIG_LmWriteScanEnableCon *p) __attribute__ ((C, spontaneous)) {
    signal HCIBaseband.Command_Complete_Write_Scan_Enable( p->Reason );
  }
  void HCIEvent_ReadPageScanActivityCompl(tSIG_LmReadPageScanActivityCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WritePageScanActivityCompl(tSIG_LmWritePageScanActivityCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadInquiryScanActivityCompl(tSIG_LmReadInquiryScanActivityCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteInquiryScanActivityCompl(tSIG_LmWriteInquiryScanActivityCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadAuthenticationEnableCompl(tSIG_LmReadAuthenticationEnableCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteAuthenticationEnableCompl(tSIG_LmWriteAuthenticationEnableCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadEncryptionModeCompl(tSIG_LmReadEncryptionModeCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteEncryptionModeCompl(tSIG_LmWriteEncryptionModeCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadCodCompl(tSIG_LmReadCodCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteCodCompl(tSIG_LmWriteCodCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadAutomaticFlushTimeoutCompl(tSIG_LmReadAutomaticFlushTimeoutCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteAutomaticFlushTimeoutCompl(tSIG_LmWriteAutomaticFlushTimeoutCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadTransmitPowerLevelCompl(tSIG_LmReadTransmitPowerLevelCon *p) __attribute__ ((C, spontaneous)) {
    signal HCIBaseband.Command_Complete_Read_Transmit_Power_Level(p->Reason,
                                                       p->Handle,
                                                       p->Transmit_Power_Level);
  }
  void HCIEvent_HostBufferSizeCompl(tSIG_LmHostBufferSizeCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadLinkSupervisionTimeoutCompl(tSIG_LmReadLinkSupervisionTimeoutCon *p) 
                                        __attribute__ ((C, spontaneous)) {
    signal HCIBaseband.Command_Complete_Read_Link_Supervision_Timeout (p->Reason, p->Handle, p->Link_Supervision_Timeout);
  }

  void HCIEvent_WriteLinkSupervisionTimeoutCompl(tSIG_LmWriteLinkSupervisionTimeoutCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadNoOfSuppIacCompl(tSIG_LmReadNoOfSuppIacCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadIacLapCompl(tSIG_LmReadIacLapCon *p) __attribute__ ((C, spontaneous)) {}

  void HCIEvent_WriteIacLapCompl(tSIG_LmWriteIacLapCon *p) __attribute__ ((C, spontaneous)) {
    signal HCIBaseband.Command_Complete_Write_Current_IAC_LAP (p->Reason);
  }

  void HCIEvent_ReadLocalVersionInformationCompl(tSIG_LmReadLocalVersionInformationCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadLocalSupportedFeaturesCompl(tSIG_LmReadLocalSupportedFeaturesCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadBufferSizeCompl(tSIG_LmReadBufferSizeCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadCountryCodeCompl(tSIG_LmReadCountryCodeCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadBdAddrCompl(tSIG_LmReadBdAddrCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_GetLinkQualityCompl(tSIG_LmGetLinkQualityCon *p) __attribute__ ((C, spontaneous)) {}

  void HCIEvent_ReadRSSICompl(tSIG_LmReadRSSICon *p) __attribute__ ((C, spontaneous)) {
    signal HCIStatus.Command_Complete_Read_RSSI(p->Reason, p->Handle, p->RSSI);
  }

  void HCIEvent_EnableDeviceUnderTestModeCompl(tSIG_LmEnableDeviceUnderTestModeCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_MaxSlotsChange(tSIG_LmMaxSlotsChange *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteBdAddrCompl(tSIG_LmWriteBdAddrCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteFixedPinCompl(tSIG_LmWriteFixedPinCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadFixedPinCompl(tSIG_LmReadFixedPinCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteKeyTypeCompl(tSIG_LmWriteKeyTypeCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadKeyTypeCompl(tSIG_LmReadKeyTypeCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteMinEncrKeySizeCompl(tSIG_LmWriteMinEncrKeySizeCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadMinEncrKeySizeCompl(tSIG_LmReadMinEncrKeySizeCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ChangeBaudRateCompl(tSIG_LmChangeBaudRateCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteSchedulingTypeCompl(tSIG_LmWriteSchedulingTypeCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadSchedulingTypeCompl(tSIG_LmReadSchedulingTypeCon *p) 
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadAbsoluteRSSICompl(tSIG_LmReadAbsoluteRSSICon *p) __attribute__ ((C, spontaneous)) {
    signal HCIStatus.Command_Complete_Read_Absolute_RSSI(p->Reason, p->RSSI);
  }
  void HCIEvent_MicGainCompl(tSIG_LmMicGainCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_SpeakerGainCompl(tSIG_LmSpeakerGainCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_SetAFHChannelClassificationCompl (tSIG_LmSetAFHChannelClassificationCon *p)
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteInquiryScanTypeCompl(tSIG_LmWriteInquiryScanModeCon *p)
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadInquiryScanTypeCompl(tSIG_LmReadInquiryScanModeCon *p)
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteInquiryModeCompl(tSIG_LmWriteInquiryModeCon *p)
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadInquiryModeCompl(tSIG_LmReadInquiryModeCon *p) __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WritePageScanTypeCompl(tSIG_LmWritePageScanTypeCon *p)
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadPageScanTypeCompl(tSIG_LmReadPageScanTypeCon *p)
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadAFHChannelAssesmentModeCompl(tSIG_LmReadAFHChannelClassfnModeCon *p)
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_WriteAFHChannelAssesmentModeCompl(tSIG_LmWriteAFHChannelClassfnModeCon *p)
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_ReadAFHChannelMapReqCompl (tSIG_LmReadAFHChannelMapCon *p)
                                        __attribute__ ((C, spontaneous)) {}
  void HCIEvent_InquiryResultWithRSSI (tSIG_LmInquiryResultWithRSSI *p)
                                        __attribute__ ((C, spontaneous)) {}


  // Hooks for functionality not currently implemented
#if 0
  void LL_Read_RSSI_Callback( uint8 Status, uint16 Handle, int8_t RSSI)
                              __attribute__ ((C, spontaneous)) {
    signal HCIStatus.Command_Complete_Read_RSSI(Status, Handle, RSSI);
  }
#endif


/*
 * End of hooks for lower level event callbacks.
 */



/*
 * Start of StdControl interface
 */

  // Set up callbacks for BT lower layer events

  task void InitializeRadio() {

    tLMU_EventCallbacks HCIEvent_EventCallbacks = {
      HCIEvent_Command_Status,
      HCIEvent_Inquiry_Result,
      HCIEvent_Hardware_Error,
      HCIEvent_PIN_Code_Request,
      HCIEvent_Link_Key_Request,
      HCIEvent_Link_Key_Notification,
      HCIEvent_Return_Link_Keys,
      HCIEvent_Inquiry_Complete,
      HCIEvent_InquiryCancelCmdCompl, //Command Complete
      HCIEvent_Connection_Request,
      HCIEvent_Connection_Complete,
      HCIEvent_Disconnection_Complete,
      HCIEvent_Authentication_Complete,
      HCIEvent_Encryption_Change,
      HCIEvent_Remote_Name_Request_Complete,
      HCIEvent_Mode_Change,
      HCIEvent_Role_Change,
      HCIEvent_RoleDiscovery, //Command Complete
      HCIEvent_ReadLinkPolicySettings, //Command Complete
      HCIEvent_WriteLinkPolicySettings, //Command Complete
      HCIEvent_ReadVoiceSettingsCompl, //Command Complete
      HCIEvent_WriteVoiceSettingsCompl, //Command Complete
      HCIEvent_LinkKeyRequestReplyCompl,    
      HCIEvent_LinkKeyNegativeReplyCompl,     
      HCIEvent_PinCodeRequestReplyCompl,     
      HCIEvent_PinCodeRequestNegativeReplyCompl,     
      HCIEvent_ChangeConnectionPacketTypeCompl,     
      HCIEvent_ChangeConnectionLinkKeyCompl,     
      HCIEvent_ReadRemoteSupportedFeaturesCompl,     
      HCIEvent_ReadRemoteVersionInformationCompl,     
      HCIEvent_ReadClockOffsetCompl,     
      HCIEvent_SetEventMaskCompl,     
      HCIEvent_ResetCompl,     
      HCIEvent_SetEventFilterCompl,     
      HCIEvent_ReadPinTypeCompl,     
      HCIEvent_WritePinTypeCompl,     
      HCIEvent_CreateNewUnitKeyCompl,     
      HCIEvent_ReadStoredLinkKeyCompl,     
      HCIEvent_WriteStoredLinkKeyCompl,     
      HCIEvent_DeleteStoredLinkKeyCompl,     
      HCIEvent_ChangeLocalNameCompl,     
      HCIEvent_ReadLocalNameCompl,     
      HCIEvent_ReadConnectionAcceptTimeoutCompl,     
      HCIEvent_WriteConnectionAcceptTimeoutCompl,     
      HCIEvent_ReadPageTimeoutCompl,     
      HCIEvent_WritePageTimeoutCompl,     
      HCIEvent_ReadScanEnableCompl,     
      HCIEvent_WriteScanEnableCompl,     
      HCIEvent_ReadPageScanActivityCompl,     
      HCIEvent_WritePageScanActivityCompl,     
      HCIEvent_ReadInquiryScanActivityCompl,     
      HCIEvent_WriteInquiryScanActivityCompl,     
      HCIEvent_ReadAuthenticationEnableCompl,     
      HCIEvent_WriteAuthenticationEnableCompl,     
      HCIEvent_ReadEncryptionModeCompl,     
      HCIEvent_WriteEncryptionModeCompl,     
      HCIEvent_ReadCodCompl,     
      HCIEvent_WriteCodCompl,     
      HCIEvent_ReadAutomaticFlushTimeoutCompl,     
      HCIEvent_WriteAutomaticFlushTimeoutCompl,
      HCIEvent_ReadTransmitPowerLevelCompl,     
      HCIEvent_HostBufferSizeCompl,     
      HCIEvent_ReadLinkSupervisionTimeoutCompl,     
      HCIEvent_WriteLinkSupervisionTimeoutCompl,
      HCIEvent_ReadNoOfSuppIacCompl,     
      HCIEvent_ReadIacLapCompl,     
      HCIEvent_WriteIacLapCompl,   
      HCIEvent_ReadLocalVersionInformationCompl,     
      HCIEvent_ReadLocalSupportedFeaturesCompl,     
      HCIEvent_ReadBufferSizeCompl,     
      HCIEvent_ReadCountryCodeCompl,     
      HCIEvent_ReadBdAddrCompl,     
      HCIEvent_GetLinkQualityCompl,     
      HCIEvent_ReadRSSICompl,     
      HCIEvent_EnableDeviceUnderTestModeCompl,     
      HCIEvent_MaxSlotsChange,
      HCIEvent_WriteBdAddrCompl,
      HCIEvent_WriteFixedPinCompl,
      HCIEvent_ReadFixedPinCompl,
      HCIEvent_WriteKeyTypeCompl,
      HCIEvent_ReadKeyTypeCompl,
      HCIEvent_WriteMinEncrKeySizeCompl,
      HCIEvent_ReadMinEncrKeySizeCompl,
      HCIEvent_ChangeBaudRateCompl,
      HCIEvent_WriteSchedulingTypeCompl,
      HCIEvent_ReadSchedulingTypeCompl,
      HCIEvent_ReadAbsoluteRSSICompl,
      HCIEvent_MicGainCompl,
      HCIEvent_SpeakerGainCompl,
      HCIEvent_SetAFHChannelClassificationCompl,
      HCIEvent_WriteInquiryScanTypeCompl,
      HCIEvent_ReadInquiryScanTypeCompl,
      HCIEvent_WriteInquiryModeCompl,
      HCIEvent_ReadInquiryModeCompl,
      HCIEvent_WritePageScanTypeCompl,
      HCIEvent_ReadPageScanTypeCompl,
      HCIEvent_ReadAFHChannelAssesmentModeCompl,
      HCIEvent_WriteAFHChannelAssesmentModeCompl,
      HCIEvent_ReadAFHChannelMapReqCompl,
      HCIEvent_InquiryResultWithRSSI
    };

    if (RadioInitialized == TRUE) return; // allows multiple calls to init

    RadioInitialized = TRUE;

    LM_RegisterUpperModuleId(BP_ARM);

    UL_ACL_Init();
    UL_LMU_Init();

    LMU_RegisterEventCallbacks((tLMU_EventCallbacks *)&HCIEvent_EventCallbacks);

    LM_RegisterUpperLayerCallBacks( ULS_SendAclAck, ULS_SendAclNak,
      ULS_RecAclAvailable, NULL);
  } 

  command result_t Control.init() {

    RadioInitialized = FALSE;
    post InitializeRadio();
    SendPacketsPending = 0;
    ReceivePacketsPending = 0;

    InquiryTransac = 0xFFFFFFFF;

    return SUCCESS;
  }



  command result_t Control.start() {
    return SUCCESS;
  }

  command result_t Control.stop() {
    return SUCCESS;
  }

/*
 * End of StdControl interface
 */



/*
 * Start of HCICommand interface
 */

  command result_t HCILinkControl.Inquiry( tLAP LAP,
                                       uint8 Inquiry_Length,
                                       uint8 Num_Responses) {

    uint8 Lap[3];

    if (Num_Responses > MAX_INQUIRY_RESPONSES) {
      Num_Responses = MAX_INQUIRY_RESPONSES;
    }

    Lap[0] = LAP.byte[0];
    Lap[1] = LAP.byte[1];
    Lap[2] = LAP.byte[2];

    LMU_Inquiry( CurrentTransactionID,
                 Lap,
                 Inquiry_Length,
                 Num_Responses);
    InquiryTransac = CurrentTransactionID;
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }



  command result_t HCILinkControl.Inquiry_Cancel( ) {

    LMU_InquiryCancel( CurrentTransactionID );
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }



  command result_t HCILinkControl.Periodic_Inquiry_Mode ( uint16 Max_Period_Length,
                                                      uint16 Min_Period_Length,
                                                      tLAP LAP,
                                                      uint8 Inquiry_Length,
                                                      uint8 Num_Responses) {

    uint8 Lap[3];

    if (Num_Responses > MAX_INQUIRY_RESPONSES) {
      Num_Responses = MAX_INQUIRY_RESPONSES;
    }

    Lap[0] = LAP.byte[0];
    Lap[1] = LAP.byte[1];
    Lap[2] = LAP.byte[2];

    LMU_PeriodicInqMode (CurrentTransactionID, Max_Period_Length,
                         Min_Period_Length, Lap, Inquiry_Length, Num_Responses);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }


  command result_t HCILinkControl.Create_Connection(tBD_ADDR BD_ADDR,
                                                uint16 Packet_Type,
                                                uint8 Page_Scan_Repetition_Mode,
                                                uint8 Page_Scan_Mode,
                                                uint16 Clock_Offset,
                                                uint8 Allow_Role_Switch) {

    tBdAddr BdAddr;

    BD_ADDR_TOS2BOS(&BD_ADDR, &BdAddr);

    LMU_CreateConn( CurrentTransactionID,
                    &BdAddr,
                    Packet_Type,
                    Page_Scan_Repetition_Mode,
                    Page_Scan_Mode,
                    Clock_Offset,
                    Allow_Role_Switch);

    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }


  command result_t HCILinkControl.Disconnect( tHandle Connection_Handle,
                                          uint8 Reason) {

    LMU_Disconnect (CurrentTransactionID, Connection_Handle, Reason);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }

  command result_t HCILinkControl.Accept_Connection_Request( tBD_ADDR BD_ADDR,
                                                         uint8 Role) {
    tBdAddr BdAddr;

    BD_ADDR_TOS2BOS(&BD_ADDR, &BdAddr);
    LMU_AcceptConn (CurrentTransactionID, &BdAddr, Role);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }


  command result_t HCILinkControl.Reject_Connection_Request( tBD_ADDR BD_ADDR,
                                                         uint8 Reason) {
    tBdAddr BdAddr;

    BD_ADDR_TOS2BOS(&BD_ADDR, &BdAddr);
    LMU_RejectConn (CurrentTransactionID, &BdAddr, Reason);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }


  command result_t HCIBaseband.Write_Scan_Enable( uint8 Scan_Enable) {

    LMU_WriteScanEnable( CurrentTransactionID, Scan_Enable);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;
    return SUCCESS;
  }


  command result_t HCIBaseband.Write_Page_Scan_Activity(
                                                  uint16 Page_Scan_Interval,
                                                  uint16 Page_Scan_Window) {

    LMU_WritePageScanActivity( CurrentTransactionID, Page_Scan_Interval,
                               Page_Scan_Window);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;
    return SUCCESS;
  }


  command result_t HCIBaseband.Write_Inquiry_Scan_Activity(
                                                  uint16 Inquiry_Scan_Interval,
                                                  uint16 Inquiry_Scan_Window) {

    LMU_WriteInqScanActivity( CurrentTransactionID, Inquiry_Scan_Interval,
                               Inquiry_Scan_Window);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;
    return SUCCESS;
  }

  /*
   * Determine condition length based on Filter_Type and Filter_Condition_Type
   * Return failure if the type is unknown.
   */

  command result_t HCIBaseband.Set_Event_Filter( uint8 Filter_Type,
                                                uint8 Filter_Condition_Type,
                                                uint8 *Condition) {

    int conditionLength;

    if (Filter_Type == 0x00) { // Clear all filters
      conditionLength = 0;
    } else if (Filter_Type == 0x01) { // Inquiry Result
      if (Filter_Condition_Type == 0x00) { // a new device responded
        conditionLength = 0;
      } else if (Filter_Condition_Type == 0x01) { // specific class of device
        conditionLength = 6;
      } else if (Filter_Condition_Type == 0x02) { // specific BT address
        conditionLength = 6;
      } else { // unknown
        return FAIL;
      }
    } else if (Filter_Type == 0x02) { // Connection setup
      if (Filter_Condition_Type == 0x00) { // all devices
        conditionLength = 1;
      } else if (Filter_Condition_Type == 0x01) { // specific class of device
        conditionLength = 7;
      } else if (Filter_Condition_Type == 0x02) { // specific BT address
        conditionLength = 7;
      } else { // unknown
        return FAIL;
      }
    } else { // unknown
      return FAIL;
    }

    LMU_SetEventFilter (CurrentTransactionID, Filter_Type,
                        Filter_Condition_Type, Condition, conditionLength);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }


  command result_t HCIBaseband.Write_Page_Timeout( uint16 Page_Timeout) {
    LMU_WritePageTimeout(CurrentTransactionID, Page_Timeout);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;
  }




  command result_t HCICommand.Change_Local_Name( char *Name) {

    LMU_ChangeName( CurrentTransactionID, (tBdName *) Name);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }


  command result_t HCICommand.Read_BD_ADDR( tBD_ADDR *BD_ADDR) {
    tBdAddr BdAddr;

    LM_ReadBdAddr(&BdAddr, eFixedBdAddr);
    BD_ADDR_BOS2TOS(&BdAddr, BD_ADDR);

    return SUCCESS;
  }

extern void LMU_WriteLinkPolicySettings(uint8 Transac, uint16 Handle, uint16 Link_Policy_Settings) __attribute__ ((C, spontaneous));

  command result_t HCILinkPolicy.Write_Link_Policy_Settings( tHandle Connection_Handle, uint16 Link_Policy_Settings) {
    LMU_WriteLinkPolicySettings(CurrentTransactionID, Connection_Handle, Link_Policy_Settings);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;
    return SUCCESS;
  }


  // Check parameters against BT spec
  command result_t HCILinkPolicy.Hold_Mode( tHandle Connection_Handle,
                                         uint16 Hold_Mode_Max_Interval, 
                                         uint16 Hold_Mode_Min_Interval ) {

    LMU_HoldMode( CurrentTransactionID, Connection_Handle,
                  Hold_Mode_Max_Interval, Hold_Mode_Max_Interval);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }

  command result_t HCIBaseband.Write_Hold_Mode_Activity (uint8 Hold_Mode_Activity) {
    LMU_WriteHoldModeActivity(CurrentTransactionID, Hold_Mode_Activity);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;
    return SUCCESS;
  }


  command result_t HCILinkPolicy.Sniff_Mode( tHandle Connection_Handle,
                                          uint16 Sniff_Max_Interval, 
                                          uint16 Sniff_Min_Interval,
                                          uint16 Sniff_Attempt,
                                          uint16 Sniff_Timeout) { 

    LMU_SniffMode( CurrentTransactionID, Connection_Handle, Sniff_Max_Interval,
                   Sniff_Max_Interval, Sniff_Attempt, Sniff_Timeout);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }

  command result_t HCILinkPolicy.Exit_Sniff_Mode( tHandle Connection_Handle ) {

    LMU_ExitSniffMode( CurrentTransactionID, Connection_Handle );
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }

  command result_t HCILinkPolicy.Park_Mode( tHandle Connection_Handle,
                                         uint16 Beacon_Max_Interval, 
                                         uint16 Beacon_Min_Interval) {

    LMU_ParkMode( CurrentTransactionID, Connection_Handle, Beacon_Max_Interval,
                  Beacon_Max_Interval);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }

  command result_t HCILinkPolicy.Exit_Park_Mode( tHandle Connection_Handle ) {

    LMU_ExitParkMode( CurrentTransactionID, Connection_Handle );
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }

  command result_t HCILinkPolicy.Switch_Role( tBD_ADDR BD_ADDR, uint8 Role) {
    tBdAddr BdAddr;

    BD_ADDR_TOS2BOS(&BD_ADDR, &BdAddr);

    LMU_SwitchRole( CurrentTransactionID, &BdAddr, Role);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }

  command result_t HCIBaseband.Write_Automatic_Flush_Timeout(
                              tHandle Connection_Handle,
                              uint16 Flush_Timeout) {

    LMU_WriteAutoFlushTimeout( CurrentTransactionID, Connection_Handle,
                               Flush_Timeout);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }

  command result_t HCILinkPolicy.Role_Discovery ( tHandle Connection_Handle) {

    LMU_RoleDiscovery( CurrentTransactionID, Connection_Handle);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }



  command result_t HCIStatus.Read_RSSI ( tHandle Connection_Handle) {

    LMU_ReadRSSI( CurrentTransactionID, Connection_Handle);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }

  command result_t HCIStatus.Read_Absolute_RSSI ( tHandle Connection_Handle) {

    LMU_ReadAbsoluteRSSI( CurrentTransactionID, Connection_Handle);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }

  command result_t HCIBaseband.Read_Transmit_Power_Level ( tHandle Connection_Handle,
                                                  uint8 Type) {

    LMU_ReadTxPower( CurrentTransactionID, Connection_Handle, Type);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }



  command result_t HCIBaseband.Read_Link_Supervision_Timeout(
                                                   tHandle Connection_Handle) {

    LMU_ReadLinkSuperTimeout (CurrentTransactionID, Connection_Handle);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }

  command result_t HCIBaseband.Write_Link_Supervision_Timeout(
                                                   tHandle Connection_Handle,
                                                   uint16 Timeout) {

    LMU_WriteLinkSuperTimeout(CurrentTransactionID, Connection_Handle, Timeout);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;

  }



  command result_t HCIBaseband.Write_Current_IAC_LAP ( uint8 Num_Current_IAC,
                                                  tLAP IAC_LAP) {

    uint8 Lap[3];

    Lap[0] = IAC_LAP.byte[0];
    Lap[1] = IAC_LAP.byte[1];
    Lap[2] = IAC_LAP.byte[2];

    LMU_WriteCurIacLap( CurrentTransactionID, Num_Current_IAC, Lap);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;

    return SUCCESS;
  }

  // Vendor specific
  command result_t HCICommand.Write_Scheduling_Type ( uint8 Schedule_Type) {
    LMU_WriteSchedulingType(CurrentTransactionID, Schedule_Type);
    CurrentTransactionID++;  CurrentTransactionID &= 0xff;
    return SUCCESS;
  }

/*
 * End of HCICommand interface
 */



/*
 * Start of HCIEvent interface
 */

  default event result_t HCILinkControl.Inquiry_Result( uint8 Num_Responses,
                                 tBD_ADDR *BD_ADDR_ptr,
                                 uint8 *Page_Scan_Repetition_Mode_ptr,
                                 uint8 *Page_Scan_Period_Mode,
                                 uint8 *Page_Scan_Mode,
                                 uint32 *Class_of_Device,
                                 uint16 *Clock_Offset) {
    return SUCCESS;
  }


  default event result_t HCILinkControl.Connection_Complete( uint8 Status,
                                      tHandle Connection_Handle,
                                      tBD_ADDR BD_ADDR,
                                      uint8 Link_Type,
                                      uint8 Encryption_Mode) {
    return SUCCESS;
  }


  default event result_t HCILinkControl.Disconnection_Complete( uint8 Status,
                                         tHandleId Connection_Handle,
                                         uint8 Reason) {
    return SUCCESS;
  }

  default event result_t HCILinkPolicy.Mode_Change( uint8 Status,
                                               uint16 Connection_Handle,
                                               uint8 Current_Mode,
                                               uint16 Interval) {
    return SUCCESS;
  }

  default event result_t HCILinkPolicy.Role_Change( uint8 Status,
                                               tBD_ADDR BD_ADDR,
                                               uint8 New_Role) {
    return SUCCESS;
  }

  default event result_t HCILinkPolicy.Command_Complete_Role_Discovery( uint8 Status,
                                  tHandleId Connection_Handle,
                                  uint8 Current_Role) {
    return SUCCESS;
  }

  default event result_t HCIBaseband.Command_Complete_Write_Current_IAC_LAP( uint8 Status) {
    return SUCCESS;
  }

  default event result_t HCIBaseband.Command_Complete_Read_Transmit_Power_Level(
                                  uint8 Status,
                                  tHandleId Connection_Handle,
                                  int8_t Transmit_Power_Level) {
    return SUCCESS;
  }

  default event result_t HCIStatus.Command_Complete_Read_RSSI( uint8 Status,
                                  tHandleId Connection_Handle,
                                  int8_t RSSI) {
    return SUCCESS;
  }

  default event result_t HCIStatus.Command_Complete_Read_Absolute_RSSI(
                                  uint8 Status,
                                  int8_t RSSI) {
    return SUCCESS;
  }


/*
 * End of HCIEvent interface
 */




/*
 * Start of HCIData interface
 */

  /*
   * The data pointer passed to Send needs to have 4 bytes available before
   * the data packet for the L2CAP header.  The Data parameter should point
   * to the data packet.  The Send routines will then subtract 4 bytes from
   * this pointer and add the L2CAP header.
   */

  command result_t HCIData.Send( uint32 TransactionID,
                                 tHandle Connection_Handle,
                                 uint8 *Data,
                                 uint16 Data_Total_Length) {

    uint8 *pData;

    if (SendPacketsPending < BLL_PACKETS_INFLIGHT) {
      pData = (uint8 *) ((uint32)Data - 4);
      pData[0] = Data_Total_Length & 0xff; // length LSB
      pData[1] = (Data_Total_Length >> 8) & 0xff; // length MSB
      pData[2] = 0x40;
      pData[3] = 0;
    
      LM_SendAcl( TransactionID, Connection_Handle, pData,
                  Data_Total_Length + 4, 0x2); // first packet and P2P
      SendPacketsPending++;

      return SUCCESS;
    } else {
      return FAIL;
    }
  }



  default event result_t HCIData.SendDone( uint32 TransactionID,
                           tHandle Connection_Handle,
                           result_t Acknowledge) {
    return SUCCESS;
  }



  default event result_t HCIData.ReceiveACL( uint32 TransactionID,
                                             tHandle Connection_Handle,
                                             uint8 *Data,
                                             uint16 DataSize,
                                             uint8 DataFlags) {
    return SUCCESS;
  }


/*
 * End of HCIData interface
 */

}

