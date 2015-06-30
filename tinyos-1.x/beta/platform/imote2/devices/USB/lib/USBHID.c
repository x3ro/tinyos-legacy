/* 
 * Author:		Robbie Adler based on code from Josh Herbach
 * Revision:	
 * History:		09/02/2005  Original written by Josh Herbach
 *                      04/16/2007  Updated by Robbie Adler....
 *                                   changed to be C library with static descriptor structs
*/

#include "PXA27XUSBClient.h"
#include "trace.h"
#include "usb.h"
#include "usbhid.h"
#include "stdlib.h"
#include "assert.h"
#include "string.h"
#include "bufferManagementHelper.h"
#include "MMU.h"
#include "queue.h"

extern _PTR memalign(size_t, size_t);

//this queue contains data that is destined for the Host
static ptrqueue_t outgoingUSBQueue;  

#define NUMBUFFERS (4)
#define MAXPACKETSIZE (64)

DECLARE_DMABUFFER(receive,NUMBUFFERS,MAXPACKETSIZE);

USBHIDReportDescriptor_t USBHIDReportDescriptor= {34,
						  {0x06, 0xA0, 0xFF, 0x09,
						   0xA5, 0xA1, 0x01, 0x09,
						   0xA6, 0x09, 0xA7, 0x15,
						   0x80, 0x25, 0x7F, 0x75,
						   0x08, 0x95, 0x40, 0x81,
						   0x02, 0x09, 0xA9, 0x15,
						   0x80, 0x25, 0x7F, 0x75,
						   0x08, 0x95, 0x40, 0x91,
						   0x02, 0xC0}};
  
uint8_t USBHIDClassDescriptor[] = {0x09,  //bLength;
				   0x21,  //bDescriptorType
				   0x10,  //BCD low
				   0x01,  //BCD high
				   0x00,  //bCountryCode
				   0x01,  //bNumDescriptors
				   0x22,  //bDescriptorType (HIDREPORT)
				   0x22,  //wDescriptorLength Low
				   0x00}; //wDescriptorLength high


USBEndpointDescriptor_t USBHIDInterface0Endpoints[] ={/*ENDPOINT DESCRIPTOR*/{7,                        //bLength  ...descriptor 0
									      USB_DESCRIPTOR_ENDPOINT,  //bDescriptorType
									      0x81,                     //bEndpointAddress IN Descriptor
									      0x3,                      //bmAttributes
									      MAXPACKETSIZE,                     //wMaxPacketSize
									      0x1},                     //bInterval
						      /*ENDPOINT DESCRIPTOR*/{7,                        //bLength ...descriptor 1
									      USB_DESCRIPTOR_ENDPOINT,  //bDescriptorType
									      0x2,                      //bEndpointAddress  OUT Descriptor
									      0x3,                      //bmAttributes
									      MAXPACKETSIZE,                     //wMaxPacketSize
									      0x1}};                     //bInterval

USBInterface_t USBHIDInterface0 = {/*INTERFACE DESCRIPTOR*/{9,                         //bLength
							    USB_DESCRIPTOR_INTERFACE,  //bDescriptorType
							    0x0,                       //bInterfaceID
							    0x0,                       //bAlternateSetting
							    0x2,                       //bNumEndpoints
							    0x3,                       //bInterfaceClass
							    0x0,                       //bInterfaceSubClass
							    0x0,                       //bInterfaceProtocol
							    0x0},                      //iInterface
				   USBHIDClassDescriptor,
				   USBHIDInterface0Endpoints};

USBInterface_t *USBHIDInterfaces[] = {&USBHIDInterface0};  

USBConfiguration_t USBHIDConfiguration = {{9,                            //bLength
					   USB_DESCRIPTOR_CONFIGURATION, //bDescriptorType
					   41,                           //wTotalLength
					   1,                            //bNumInterfaces
					   1,                            //bConfigurationValue
					   1,                            //iConfiguration
					   0x80,                         //bmAttributes
					   USBPOWER},                    //MaxPower
					  USBHIDInterfaces};



void initializeUSBHIDStack(){
  INIT_DMABUFFER(receive, NUMBUFFERS,MAXPACKETSIZE);
  initptrqueue(&outgoingUSBQueue, defaultQueueSize);
}
  
/*
 * allocateReportPackets preallocated all packets required to send a report
 */
int allocateReportPackets(USBData_t *pUSBData);


int sendReport(uint8_t *data, uint32_t datalen, uint8_t type, uint8_t source, uint8_t channel){
  USBData_t *pUSBData;
  int queueSize;
  
  if(USBHAL_isUSBConfigured() == 0){
    return 0;
  }
   
  pUSBData = malloc(sizeof(USBData_t));
  
  pUSBData->channel = channel;
  pUSBData->endpointDR = 1;
  pUSBData->fifosize = USBHIDInterface0Endpoints[0].wMaxPacketSize;
  pUSBData->pindex = pUSBData->index = 0;
  pUSBData->type = type;
  pUSBData->source = source;
  pUSBData->len = datalen;
  pUSBData->src = data;
  pUSBData->param = (uint8_t *)IMOTE_HID_REPORT;
  
  if(datalen <= IMOTE_HID_TYPE_L_BYTE_SIZE){
    pUSBData->type |= (IMOTE_HID_TYPE_L_BYTE << IMOTE_HID_TYPE_L);
    //n is the number of report packets that will be sent minus 1
    pUSBData->n =  (uint8_t)(datalen / IMOTE_HID_BYTE_MAXPACKETDATA);
    //tlen is the total number of bytes that will be sent..i.e. n packets at fifosize + leftover
    pUSBData->tlen = pUSBData->n * pUSBData->fifosize + 3 +
      datalen % IMOTE_HID_BYTE_MAXPACKETDATA;
  }
  else if(datalen <= IMOTE_HID_TYPE_L_SHORT_SIZE){
    pUSBData->type |= (IMOTE_HID_TYPE_L_SHORT << IMOTE_HID_TYPE_L);
    //n is the number of report packets that will be sent minus 1
    pUSBData->n =  (uint16_t)(datalen / IMOTE_HID_SHORT_MAXPACKETDATA);
    //tlen is the total number of bytes that will be sent..i.e. n packets at fifosize + leftover
    pUSBData->tlen = pUSBData->n * pUSBData->fifosize + 4 +
      datalen % IMOTE_HID_SHORT_MAXPACKETDATA;
  }
  else if(datalen <= IMOTE_HID_TYPE_L_INT_SIZE){
    pUSBData->type |= (IMOTE_HID_TYPE_L_INT << IMOTE_HID_TYPE_L);
    //n is the number of report packets that will be sent minus 1
    pUSBData->n = datalen / IMOTE_HID_SHORT_MAXPACKETDATA;
    //tlen is the total number of bytes that will be sent..i.e. n packets at fifosize + leftover
    pUSBData->tlen = pUSBData->n * pUSBData->fifosize + 6 +
      datalen % IMOTE_HID_INT_MAXPACKETDATA;
  }
  else{//too much data...which isn't really possible in this case so not a big deal
    ;
  }
  
  allocateReportPackets(pUSBData);
  queueSize = getCurrentPtrQueueSize(&outgoingUSBQueue);
  if(queueSize == defaultQueueSize){
    if(pUSBData->n == 0){
      USBHAL_sendDataToEndpoint(1, pUSBData->packets[0],pUSBData->tlen);
    }
    else{
      USBHAL_sendDataToEndpoint(1, pUSBData->packets[0],pUSBData->fifosize);
    }
  }
  
  if(pushptrqueue(&outgoingUSBQueue, pUSBData) == 0){
    trace(DBG_USR1,"ERROR:  USBClient.SendReport found outgoingUSBQueue full\r\n");
    free(pUSBData->src);
    free(pUSBData);
    return 0;
  }
  
  return 1;
}
  
void sendDataToEndpointDone(uint8_t endpoint){
  int i,controlQueueStatus;
  uint32_t numBytes;
  USBData_t * pUSBData;
  
  if(endpoint == 1){
    pUSBData = peekptrqueue(&outgoingUSBQueue, &controlQueueStatus);
    assert(controlQueueStatus);
    
    //increment the packet index
    pUSBData->pindex++;
    
    if(pUSBData->pindex > pUSBData->n){
      //we're done
      pUSBData = popptrqueue(&outgoingUSBQueue, &controlQueueStatus);
      for(i=0; i<=pUSBData->n; i++){
	free(pUSBData->packets[i]);
      }
      free(pUSBData->packets);
      //need to signal done now
      USBHIDSendReportDone(pUSBData);
      free(pUSBData);
      
      //check to see how many are left so that we can start again
      pUSBData = peekptrqueue(&outgoingUSBQueue, &controlQueueStatus);
      if(controlQueueStatus){
	if(pUSBData->n == 0){
	  USBHAL_sendDataToEndpoint(1, pUSBData->packets[0],pUSBData->tlen);
	}
	else{
	  USBHAL_sendDataToEndpoint(1, pUSBData->packets[0],pUSBData->fifosize);
	}
      }
    }
    else{
      if(pUSBData->pindex == pUSBData->n){
	//last packet to be sent out
	numBytes = pUSBData->tlen - (pUSBData->n * pUSBData->fifosize);
      }
      else{
	numBytes = pUSBData->fifosize;
      }
      USBHAL_sendDataToEndpoint(1, pUSBData->packets[pUSBData->pindex],numBytes);
    }
  }
}

int allocateReportPackets(USBData_t *pUSBData){
  uint16_t i = 0;
  uint8_t *buf;
  uint8_t valid;
   
  if(pUSBData == NULL){
    return 0;
  }
  
  if((uint32_t)pUSBData->param != IMOTE_HID_REPORT){
    //sendControlIn();//should never happen
    return 0;
  }
  
  //the packet element of pUSBData is a uint8_t **.  It acts as an array of pointers to fifosize
  //arrays of data.  This allows us to precreate all of the data that will be sent out for this
  //transaction so that we need to simply index into the packet array when new data is requested
  //for this transfer
  pUSBData->packets = malloc((pUSBData->n + 1) * sizeof(uint8_t *));
  if(pUSBData->packets == NULL){
    trace(DBG_USR1,"ERROR:  USBClient unable to allocate memory for report\r\n");
    return 0;
  }
  for(i=0; i<(pUSBData->n + 1); i++){
    pUSBData->packets[i] = memalign(32, DMA_BUFFER_SIZE(pUSBData->fifosize));
    assert(pUSBData->packets[i]);
  }

  for(pUSBData->pindex =0; pUSBData->pindex <=pUSBData->n; pUSBData->pindex++){
    buf = pUSBData->packets[pUSBData->pindex];
    assert(buf);
    
    if(pUSBData->pindex <= pUSBData->n){
      if(((pUSBData->type >> IMOTE_HID_TYPE_L) & 0x3) == IMOTE_HID_TYPE_L_BYTE){
	buf[IMOTE_HID_TYPE] = pUSBData->type;
      
	if(pUSBData->pindex == 0){
	  buf[IMOTE_HID_TYPE] |= _UDC_bit(IMOTE_HID_TYPE_H);
	  buf[IMOTE_HID_NI] = pUSBData->n;
	}
	else
	  buf[IMOTE_HID_NI] = pUSBData->pindex;
       
	if(pUSBData->pindex == pUSBData->n){
	  valid = (uint8_t)(pUSBData->len % IMOTE_HID_BYTE_MAXPACKETDATA);
	  buf[IMOTE_HID_NI + 1] = valid;
	}
	else
	  valid = (uint8_t)IMOTE_HID_BYTE_MAXPACKETDATA;
	memcpy(buf + IMOTE_HID_NI + 1 + (pUSBData->pindex==pUSBData->n?1:0),
	       pUSBData->src + pUSBData->pindex * IMOTE_HID_BYTE_MAXPACKETDATA, valid);
      }
      else if(((pUSBData->type >> IMOTE_HID_TYPE_L) & 0x3) == IMOTE_HID_TYPE_L_SHORT){
	buf[IMOTE_HID_TYPE] = pUSBData->type;
	if(pUSBData->pindex == 0){
	  buf[IMOTE_HID_TYPE] |= _UDC_bit(IMOTE_HID_TYPE_H);
	  buf[IMOTE_HID_NI] = (uint8_t)(pUSBData->n >> 8);
	  buf[IMOTE_HID_NI + 1] = (uint8_t)pUSBData->n;
	}
	else{
	  buf[IMOTE_HID_NI] = (uint8_t)(pUSBData->pindex >> 8);
	  buf[IMOTE_HID_NI + 1] = (uint8_t)pUSBData->pindex;
	}
       
	if(pUSBData->pindex == pUSBData->n){
	  valid = (uint8_t)(pUSBData->len % IMOTE_HID_SHORT_MAXPACKETDATA);
	  buf[IMOTE_HID_NI + 2] = valid;
	}
	else
	  valid = (uint8_t)IMOTE_HID_SHORT_MAXPACKETDATA;
	memcpy(buf + IMOTE_HID_NI + 2 + (pUSBData->pindex==pUSBData->n?1:0),
	       pUSBData->src + pUSBData->pindex * IMOTE_HID_SHORT_MAXPACKETDATA, valid);
      }
      else if(((pUSBData->type >> IMOTE_HID_TYPE_L) & 0x3) == IMOTE_HID_TYPE_L_INT){
	buf[IMOTE_HID_TYPE] = pUSBData->type;
	if(pUSBData->pindex == 0){
	  buf[IMOTE_HID_TYPE] |= _UDC_bit(IMOTE_HID_TYPE_H);
	  buf[IMOTE_HID_NI] = (uint8_t)(pUSBData->n >> 24);
	  buf[IMOTE_HID_NI + 1] = (uint8_t)(pUSBData->n >> 16);
	  buf[IMOTE_HID_NI + 2] = (uint8_t)(pUSBData->n >> 8);
	  buf[IMOTE_HID_NI + 3] = (uint8_t)pUSBData->n;
	}
	else{
	  buf[IMOTE_HID_NI] = (uint8_t)(pUSBData->pindex >> 24);
	  buf[IMOTE_HID_NI + 1] = (uint8_t)(pUSBData->pindex >> 16);
	  buf[IMOTE_HID_NI + 2] = (uint8_t)(pUSBData->pindex >> 8);
	  buf[IMOTE_HID_NI + 3] = (uint8_t)pUSBData->pindex;
	}
       
	if(pUSBData->pindex == pUSBData->n){
	  valid = (uint8_t)(pUSBData->len % IMOTE_HID_INT_MAXPACKETDATA);
	  buf[IMOTE_HID_NI + 4] = valid;
	}
	else{
	  valid = (uint8_t)IMOTE_HID_INT_MAXPACKETDATA;
	}
	memcpy(buf + IMOTE_HID_NI + 4 + (pUSBData->pindex == pUSBData->n?1:0),
	       pUSBData->src + pUSBData->pindex * IMOTE_HID_INT_MAXPACKETDATA, 
	       valid);
      }
    }
    cleanDCache(buf, DMA_BUFFER_SIZE(pUSBData->fifosize));
  }
  pUSBData->pindex=0;
 
  return 1;
}


//get a new buffer for this endpoint.  This allows the HAL code to request data buffers for queuing purposes
uint8_t* getNewBufferForEndpoint(uint8_t endpoint){
  if(endpoint == 2){
    return getNextBuffer(&receiveBufferSet);
  }
  else{
    return NULL;
  }
}

//get a new bufferinfo for this endpoint.  This allows the HAL code to request data buffers for queuing purposes
bufferInfo_t *getNewBufferInfoForEndpoint(uint8_t endpoint){
  if(endpoint == 2){
    return getNextBufferInfo(&receiveBufferInfoSet);
  }
  else{
    return NULL;
  }
}

//processOut takes care of processing USB OUT data (i.e. data from host->device).  Effectively, it parses
//the JT protocol data and eventuall calls a callback function that will handle the received data.
void processOut(uint8_t *buff){
  uint8_t type, valid = 0;
  USBData_t USBData, *pUSBData;
  
#if DEBUG
  //trace(DBG_USR1,"processOut;\r\n");
#endif
   
  type = *(buff + IMOTE_HID_TYPE);
  pUSBData = &USBData;
  if(isFlagged(type, _UDC_bit(IMOTE_HID_TYPE_H))){
    //clearOut();
    pUSBData->type = type;
    pUSBData->endpointDR = 2;
     
    switch((pUSBData->type >> IMOTE_HID_TYPE_L) & 3){
    case IMOTE_HID_TYPE_L_BYTE:
      pUSBData->n = *(buff + IMOTE_HID_NI);
      if(pUSBData->n == 0){
	valid = *(buff + IMOTE_HID_NI + 1);
	pUSBData->len = valid;
      }
      else{
	valid = IMOTE_HID_BYTE_MAXPACKETDATA;
	pUSBData->len = (pUSBData->n + 1) * 
	  IMOTE_HID_BYTE_MAXPACKETDATA - 1;
      }
      pUSBData->src = (uint8_t *)malloc(valid);
      assert(pUSBData->src);
       
      memcpy(pUSBData->src, buff + IMOTE_HID_NI + 1 + 
	     (pUSBData->n == 0?1:0), valid);
      break;
    case IMOTE_HID_TYPE_L_SHORT:
      pUSBData->n = (*(buff + IMOTE_HID_NI) << 8) | *(buff + IMOTE_HID_NI + 1);
      if(pUSBData->n == 0){
	valid = *(buff + IMOTE_HID_NI + 2);
	pUSBData->len = valid;
      }
      else{
	valid = IMOTE_HID_SHORT_MAXPACKETDATA;
	pUSBData->len = (pUSBData->n + 1) * 
	  IMOTE_HID_SHORT_MAXPACKETDATA - 1;
      }
      pUSBData->src = (uint8_t *)malloc(valid);
      assert(pUSBData->src);
       
      memcpy(pUSBData->src, buff + IMOTE_HID_NI + 2 +
	     (pUSBData->n == 0?1:0), valid);
      break;
    case IMOTE_HID_TYPE_L_INT:
      pUSBData->n = (*(buff + IMOTE_HID_NI) << 24) | (*(buff + IMOTE_HID_NI + 1) << 16) | (*(buff + IMOTE_HID_NI + 2) << 8) | *(buff + IMOTE_HID_NI + 3);
      if(pUSBData->n == 0){
	valid = *(buff + IMOTE_HID_NI + 4);
	pUSBData->len = valid;
      }
      else{
	valid = IMOTE_HID_INT_MAXPACKETDATA;
	pUSBData->len = (pUSBData->n + 1) *
	  IMOTE_HID_INT_MAXPACKETDATA - 1;
      }
      pUSBData->src = (uint8_t *)malloc(valid);
      assert(pUSBData->src);
      
      memcpy(pUSBData->src, buff + IMOTE_HID_NI + 4 + 
	     (pUSBData->n == 0?1:0), valid);
    }
  }
  else if(isFlagged(pUSBData->type, _UDC_bit(IMOTE_HID_TYPE_H))){
    switch((pUSBData->type >> IMOTE_HID_TYPE_L) & 3){
    case IMOTE_HID_TYPE_L_BYTE:
      if(pUSBData->index != *(buff + IMOTE_HID_NI)){
	//	 trace("Received packet has incorrect index\r\n");
	//clearOut();
	//free(buff);
	buff = NULL;
	//_PXAREG(_udcdrb - _udcdr0 + _udccsr0) |= _UDC_bit(UDCCSRAX_PC);
	//post processOut();
	return;
      }
      if(pUSBData->n == pUSBData->index)
	valid = *(buff + IMOTE_HID_NI + 1);
      else
	valid = IMOTE_HID_BYTE_MAXPACKETDATA;
       
      pUSBData->src = (uint8_t *)malloc(valid);
      assert(pUSBData->src);

      memcpy(pUSBData->src, buff + IMOTE_HID_NI + 1 + 
	     (pUSBData->n == pUSBData->index?1:0), valid);
      break;
    case IMOTE_HID_TYPE_L_SHORT:
      if(pUSBData->index != ((*(buff + IMOTE_HID_NI) << 8) | *(buff + IMOTE_HID_NI + 1))){
	//	 trace("Received packet has incorrect index\r\n");
	//clearOut();
	//free(buff);
	//buff = NULL;
	//_PXAREG(_udcdrb - _udcdr0 + _udccsr0) |= _UDC_bit(UDCCSRAX_PC);
	//post processOut();
	return;
      }
       
      if(pUSBData->n == pUSBData->index)
	valid = *(buff + IMOTE_HID_NI + 2);
      else
	valid = IMOTE_HID_SHORT_MAXPACKETDATA;
       
      pUSBData->src = (uint8_t *)malloc(valid);
      assert(pUSBData->src);
      
      memcpy(pUSBData->src, buff + IMOTE_HID_NI + 2 +
	     (pUSBData->n == pUSBData->index?1:0), valid);
      break;
    case IMOTE_HID_TYPE_L_INT:
      if(pUSBData->index != ((*(buff + IMOTE_HID_NI) << 24) | (*(buff + IMOTE_HID_NI + 1) << 16) | (*(buff + IMOTE_HID_NI + 2) << 8) | *(buff + IMOTE_HID_NI + 3))){
	//trace("Received packet has incorrect index\r\n");
	//clearOut();
	//free(buff);
	//buff = NULL;
	//_PXAREG(_udcdrb - _udcdr0 + _udccsr0) |= _UDC_bit(UDCCSRAX_PC);
	//post processOut();
	return;
      }
      if(pUSBData->n == pUSBData->index)
	valid = *(buff + IMOTE_HID_NI + 4);
      else
	valid = IMOTE_HID_INT_MAXPACKETDATA;
       
      pUSBData->src = (uint8_t *)malloc(valid);
      assert(pUSBData->src);

      memcpy(pUSBData->src, buff + IMOTE_HID_NI + 4 + (pUSBData->n == pUSBData->index?1:0), valid);
      break;
    }
  }
  else //assume in this case it can be ignored
    ;

  //pass the resulting data to the callback function that is responsible for handling the HID data
  USBHIDReceive(pUSBData, valid);

  free(pUSBData->src);
  pUSBData->src = NULL;
  pUSBData->index++;

}

//handle data received from an endpoint
//this function must not be called from an interrupt
void receiveDataFromEndpoint(uint8_t endpoint, bufferInfo_t *pBI){
  if(pBI == NULL){
    return;
  }

  if(endpoint == 2){
    processOut(pBI->pBuf);
    returnBuffer(&receiveBufferSet,pBI->pBuf);
    returnBufferInfo(&receiveBufferInfoSet,pBI);
  }
}

//handle the USB HID specific get descriptor requestes.  Returns 0 if it didn't handle the request.  1 if it did
int USBHIDhandleGetDescriptor(USBSetupData_t *pUSBSetupData){
  switch(pUSBSetupData->bRequest){
  case USB_HID_GETREPORT:
    //write THIS IS REQUIRED...TODO!
    break;
  case USB_HID_GETIDLE:
    //fairly optional
    break;
  case USB_HID_GETPROTOCOL:
    //fairly optional
    break;
  case USB_HID_SETREPORT:
    //fairly optional
    break;
  case USB_HID_SETIDLE:
    //called but optional...should stall in response to this according to the book
    USBHAL_sendStall();
    break;
  case USB_HID_SETPROTOCOL:
    //fairly optional
    break;
  default:
    return 0;
  }
  return 1;
}
  
void sendHidReportDescriptor(uint16_t wLength){
       
  USBData_t *pUSBData;
  USBHIDReportDescriptor_t *pReportDescriptor;
  
#if DEBUG_DESCRIPTOR
  trace(DBG_USR1,"sendHidReportDescriptor\r\n");
#endif
  
  pReportDescriptor = &USBHIDReportDescriptor;
  
  if(pReportDescriptor==NULL){
    trace(DBG_USR1,"ERROR:  USBClient.sendHidReportDescriptor could not find find descriptor\r\n");
    return;
  }
  
  if(wLength == 0){
    return;
  }
  
  pUSBData = malloc(sizeof(*pUSBData));
  if(pUSBData == NULL){
    trace(DBG_USR1,"ERROR:  USBClient.sendStringDescriptor unable to allocate memory\r\n");
    return;
  }
  
  pUSBData->endpointDR = 0;
  pUSBData->fifosize = 16;
  
  pUSBData->src = malloc(pReportDescriptor->bLength);
  if(pUSBData->src == NULL){
    trace(DBG_USR1,"ERROR:  USBClient.sendHidReportDescriptor unable to allocate memory for data\r\n");
    free(pUSBData);
    return;
  }
  
  memcpy(pUSBData->src, &(pReportDescriptor->bString[0]), pReportDescriptor->bLength);
  
  pUSBData->len = (wLength < pReportDescriptor->bLength) ? wLength:pReportDescriptor->bLength;
  pUSBData->index = 0;
  pUSBData->param = 0;
  
  USBHAL_sendControlDataToHost(pUSBData);
}
