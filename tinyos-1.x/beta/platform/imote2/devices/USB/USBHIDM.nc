/* 
 * Author:		Josh Herbach
 * Revision:	1.0
 * Date:		09/02/2005
 */

#include "PXA27XUSBClient.h"
includes usb;
includes usbhid;

module USBHIDM {
  provides {
    interface StdControl as StdControl;
    interface ReceiveData; /* Type is
			      IMOTE_HID_TYPE_CL_BLUSH or
			      IMOTE_HID_TYPE_CL_GENERAL.*/
    interface ReceiveMsg;  /* Type is 
			      IMOTE_HID_TYPE_CL_RPACKET.*/
    interface ReceiveBData;/* Type is 
			      IMOTE_HID_TYPE_CL_BINARY.*/
    
    interface SendVarLenPacket;/* Type is assumed to be 
				  IMOTE_HID_TYPE_CL_BLUSH.*/
    interface SendJTPacket[uint8_t channel];
    interface BareSendMsg; /* Type is assumed to be
			      IMOTE_HID_TYPE_CL_RPACKET */
    
  }
}
implementation {

#if 0
  /*In and Out follow USB specifications.
    IN = Device->Host, OUT = Host->Device*/
    
  /*
   * clearDescriptors is a function to clean up all the memory used in 
   * initializing the USB descriptors in the various write*Descriptor 
   * functions.
   */
  void clearDescriptors();
#endif  


#if 0
  /*
   * clearIn() clears the queue of data to be sent to the host PC. 
   * clearUSBData() is a helper function
   */ 
  void clearIn();
  void clearUSBData(USBData_t * Stream, uint8_t isConst);
  
  /*
   * The processOut() task handles converting data received from the host PC
   * in JT format into regular data.
   */
  task void processOut();
  
  /*
   * clearOut() is a helper function that clears the data structure for the 
   * current packet of received data. 
   */ 
  void clearOut();
  
  /*
   * clearOutQueue() wipes the queue of data received from the PC waiting to 
   * be processed
   */
  void clearOutQueue();
  
#endif
  
  command result_t StdControl.init() {
    static uint8_t init=0;
    if (init == 0){
      
      init =1;
    }
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
    
  command result_t SendVarLenPacket.send(uint8_t* packet, uint8_t numBytes){
    if(sendReport(packet, numBytes, IMOTE_HID_TYPE_CL_BLUSH, SENDVARLENPACKET, 0) == 1){
      return SUCCESS;
    }
    else{
      return FAIL;
    }
  }
  
  command result_t SendJTPacket.send[uint8_t channel](uint8_t* data, uint32_t numBytes, uint8_t type){
    if(sendReport(data, numBytes, type, SENDJTPACKET, channel) == 1){
      return SUCCESS;
    }
    else{
      return FAIL;
    }
  }
  
  command result_t BareSendMsg.send(TOS_MsgPtr msg){
    if(sendReport((uint8_t *)msg, sizeof(TOS_Msg), IMOTE_HID_TYPE_CL_RPACKET, SENDBAREMSG, 0) == 1){
      return SUCCESS;
    }
    else{
      return FAIL;
    }
  }
  
  default event result_t SendVarLenPacket.sendDone(uint8_t* packet, result_t success){
    return SUCCESS;
  }
 
  default event result_t SendJTPacket.sendDone[uint8_t channel](uint8_t* packet, uint8_t type,
								result_t success){
    return SUCCESS;
  }
 
  default event result_t BareSendMsg.sendDone(TOS_MsgPtr msg, result_t success){
    return SUCCESS;
  }
 
  default event result_t ReceiveData.receive(uint8_t* Data, uint32_t Length) {
    return SUCCESS;
  }
 
  default event result_t ReceiveBData.receive(uint8_t* buffer, uint8_t numBytesRead, uint32_t i, uint32_t n, uint8_t type){
    return SUCCESS;
  }
 
  default event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m){
    return NULL;
  }

  void USBHIDSendReportDone(USBData_t *pUSBData) __attribute__((C, spontaneous)){
    switch(pUSBData->source){
    case SENDVARLENPACKET:
      signal SendVarLenPacket.sendDone(pUSBData->src, SUCCESS);
      break;
    case SENDJTPACKET:
      signal SendJTPacket.sendDone[pUSBData->channel](pUSBData->src, pUSBData->type, SUCCESS);
      break;
    case SENDBAREMSG:
      signal BareSendMsg.sendDone((TOS_MsgPtr)pUSBData->src, SUCCESS);
      break;
    default:
      //printFatalErrorMsg("FATAL ERROR:  USBHIDM received senddone from unknown source !\r\n",1,pUSBData->source);
      trace(DBG_USR1,"USBHIDSendDone found unknown origin\r\n"); 
    }
  }
    
  void USBHIDReceive(USBData_t *pUSBData, uint8_t numBytes) __attribute__((C, spontaneous)){
    if((pUSBData->type & 0x3) == IMOTE_HID_TYPE_CL_RPACKET){
      signal ReceiveMsg.receive((TOS_MsgPtr) pUSBData->src);
    }
    else if((pUSBData->type & 0x3) == IMOTE_HID_TYPE_CL_BINARY){
      signal ReceiveBData.receive(pUSBData->src, numBytes, pUSBData->index, pUSBData->n, pUSBData->type);
    }
#ifdef BOOTLOADER
    /** 
     * Added for Boot Loader compatibility, All the messages from the boot loader
     * application will reboot the board. -junaith
     */
    else if ((((pUSBData->type) & 0xE3) == IMOTE_HID_TYPE_MSC_REBOOT) ||
	     (((pUSBData->type) & 0xE3) == IMOTE_HID_TYPE_MSC_BINARY) ||
	     (((pUSBData->type) & 0xE3) == IMOTE_HID_TYPE_MSC_COMMAND))
      {
	OSMR3 = OSCR0 + 9000;
	OWER = 1;
	while(1);     
      }
#endif
    else{
      signal ReceiveData.receive(pUSBData->src, numBytes);
    }
  }
}
