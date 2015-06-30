/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * @file USBClient.c
 * @author
 *
 * Ported from TinyOS repository - Junaith
 */
#include <HPLInit.h>
#include <pxa27x_registers.h>
#include <USBClient.h>
//#include <PXA27Xdynqueue.h>
#include <PXA27XGPIOInt.h>
#include <PXA27XInterrupt.h>
#include <PXA27XUDCRegAddrs.h>
#include <stdio.h>
#include <BinImageHandler.h>
#include <Leds.h>
#include <BootLoader.h>
#include <TOSSched.h>

static USBdevice Device; //Contains data for various descriptors
static USBhid Hid; //Contains Hid descriptor data
static USBhidReport HidReport; //Contains the HidReport descriptor
static USBstring Strings[STRINGS_USED + 1]; //Data for string descriptors
  
static DynQueue InQueue, OutQueue; /*Queues for sending and receiving data
				       from the host PC*/
static USBdata_t OutStream[IMOTE_HID_TYPE_COUNT]; 

volatile bool BufferRcvMode = FALSE;
uint16_t PckRcv = 0;      /* number of packets received per window*/
uint32_t TotalPckRcv = 0; /* Total number of packets received during download*/ 
uint32_t PckExpected = 0; /* Total Number of packet expected */

//uint8_t USB_Out_Buffers [65];

/*
 * Data about the four possible current 
 * transfer from the host PC (the four types
 * being specified by JT protocol)
 */
  
static USBdata InState = NULL; /**/
static uint32_t state = 0; /*State of the USB device: either 0, POWERED,
			       DEFAULT, or CONFIGURED*/
static uint8_t init = 0, InTask = 0; //, OutTask = 0; //, OutPaused = 0;

/**
 * USB_Init
 *
 * Initialize the USB interface and prepare enumeration data
 * to send to the host upon request. Create new queues for incomming
 * and out going packets and enable the GPIO and USB interrupts for
 * the required end points.
 *
 * @return SUCCESS | ERROR 
 */
result_t USB_Init() 
{
  uint8_t i;
  DynQueue QueueTemp;
  if(init == 0)
  {//one time initilization because of allocated memory
    writeDeviceDescriptor();
    writeStringDescriptor();
    writeHidDescriptor();
    writeHidReportDescriptor();
    QueueTemp = DynQueue_new();
    //atomic 
    InQueue = QueueTemp;
    QueueTemp = DynQueue_new();
    //atomic 
    OutQueue = QueueTemp;
  }

  //HPLUSBClientGPIO_Init ();

  //atomic
  {
    CKEN |= CKEN11_USBC;
    UDCICR1 |= _UDC_bit(INT_IRRS); //reset
    UDCICR1 |= _UDC_bit(INT_IRCC);
    UDCICR0 |= _UDC_bit(INT_END0);
    //UDCICR0 |= _UDC_bit(INT_ENDA);
    UDCICR0 |= _UDC_bit(INT_ENDB);
    for(i = 0; i < IMOTE_HID_TYPE_COUNT; i++)
    {
      OutStream[i].endpointDR = _udcdrb;
      OutStream[i].fifosize = Device.oConfigurations[1]->
                  oInterfaces[0]->oEndpoints[1]->wMaxPacketSize;
      OutStream[i].len = OutStream[i].index = OutStream[i].status = OutStream[i].type = 0;
    }
    state = 0;
  }
  PXA27XGPIOInt_Enable (USBC_GPION_DET, TOSH_BOTH_EDGE);

  PXA27XIrq_Allocate (PPID_USBC);
  isAttached();

  PXA27XIrq_Enable (PPID_USBC);
  return SUCCESS;
}

/**
 * HPLUSBClientGPIO_Init
 *
 * Initialize the required GPIO pins during USB initalization.
 *
 * @return SUCCESS 
 */
result_t HPLUSBClientGPIO_Init()
{
  _GPDR(USBC_GPION_DET) &= ~_GPIO_bit(USBC_GPION_DET); 
  _GPDR(USBC_GPIOX_EN) |= _GPIO_bit(USBC_GPIOX_EN);
  _GPSR(USBC_GPIOX_EN) |= _GPIO_bit(USBC_GPIOX_EN);
  return SUCCESS;
}

/**
 * HPLUSBClientGPIO_Stop
 *
 * Disable the USBC_GPIOX_EN GPIO pin.
 */
result_t HPLUSBClientGPIO_Stop()
{
  _GPCR(USBC_GPIOX_EN) |= _GPIO_bit(USBC_GPIOX_EN);
  return SUCCESS;
}

result_t USB_Stop ()
{
  PXA27XGPIOInt_Disable (USBC_GPION_DET);
  PXA27XIrq_Disable (PPID_USBC);
  HPLUSBClientGPIO_Stop ();
  state = 0;
  return SUCCESS;
}

/**
 * HPLUSBClientGPIO_CheckConnection
 *
 * The function checks to see if the USB GPIO pin
 * is enabled and returns a boolean result.
 * 
 * @return SUCCESS | FAIL
 */
result_t HPLUSBClientGPIO_CheckConnection()
{
  if(isFlagged(_GPLR(USBC_GPION_DET), _GPIO_bit(USBC_GPION_DET)))
    return SUCCESS;
  else
    return FAIL;
}

/**
 * USBInterrupt_Fired
 *
 * This function is the interrupt handler for the USB Client interface.
 * It performs the required checks to see where the interrupt
 * originated and sinals the appropriate higher level modules based
 * on the current context.
 *
 */
void USBInterrupt_Fired()
{
  uint32_t statusreg;
  uint8_t statetemp;
  DynQueue QueueTemp;
  USBdata InStateTemp;

  statetemp = state;
  switch(statetemp)
  {
    case POWERED:
      {
        if(isFlagged(UDCISR1, _UDC_bit(INT_IRRS)))
        {
          state = DEFAULT;
          UDCISR1 = _UDC_bit(INT_IRRS);
        }

        if(isFlagged(UDCISR0, _UDC_bit(INT_END0)))
          UDCISR0 = _UDC_bit(INT_END0);
        if(isFlagged(UDCISR0, _UDC_bit(INT_ENDB)))
          UDCISR0 = _UDC_bit(INT_ENDB);
        if(isFlagged(UDCISR1, _UDC_bit(INT_IRCC)))
          UDCISR1 = _UDC_bit(INT_IRCC);
      }
      break;     
    case DEFAULT:
    case CONFIGURED:
      if(isFlagged(UDCISR1, _UDC_bit(INT_IRRS)))
      {
        clearIn();
        state = DEFAULT;
        UDCISR1 = _UDC_bit(INT_IRRS);
      }

      if(isFlagged(UDCISR1, _UDC_bit(INT_IRCC)))
      {
        handleControlSetup();
        UDCISR1 = _UDC_bit(INT_IRCC);
      }
      else if(isFlagged(UDCISR0, _UDC_bit(INT_END0)))
      {
        {
          statusreg = UDCCSR0;
          UDCISR0 = _UDC_bit(0);
        }
        InStateTemp = InState;
        if(isFlagged(statusreg, _UDC_bit(UDCCSR0_SA)))
        {
          handleControlSetup();
        }
        else if(InStateTemp != NULL && InStateTemp->endpointDR == _udcdr0 && 
                            InStateTemp->index != 0) //packet sent from endpoint 0
        {
          if(!isFlagged(InStateTemp->status, _UDC_bit(MIDSEND)))
          {
#if DEBUG
	      trace("Packet Complete, no longer in progress; len %d\r\n");
#endif	     
            QueueTemp = InQueue;
            clearUSBdata(((USBdata)DynQueue_dequeue(QueueTemp)), 0);
            InState = NULL;
            if(DynQueue_getLength(QueueTemp) > 0)
              sendControlIn();
            else
              InTask = 0;
          }
          else
          {
#if DEBUG
	      trace("Packet Complete, continuing\r\n");
#endif
            sendControlIn();
          }
        }
        else //unrecognized control request
        {
          ///*atomic*/ UDCCSR0 |= _UDC_bit(UDCCSR0_FST);
          //trace("Unrecognized Control request\r\n");
        }
      }
      if(isFlagged(UDCISR0, _UDC_bit(INT_ENDA)))
      {
        statetemp = state;
        UDCISR0 = _UDC_bit(INT_ENDA);
        InStateTemp = InState;
        if(statetemp != CONFIGURED)
          UDCCSRB |= _UDC_bit(UDCCSRAX_PC);
        else if (InStateTemp != NULL && 
             InStateTemp->endpointDR == _udcdra && 
             InStateTemp->index != 0 && 
             statetemp == CONFIGURED) //packet sent from endpoint a
        {
          if(!isFlagged(InStateTemp->status, _UDC_bit(MIDSEND)))
          {
	     TOGGLE_LED(RED);
             QueueTemp = InQueue;
             InState = NULL;
             if(DynQueue_getLength(QueueTemp) > 0)
               sendIn();
             else
               InTask = 0;
          }
          else
          {
            sendIn();
          }
        }
      }
      if (isFlagged(UDCISR0, _UDC_bit(INT_ENDB)))
      {
        statetemp = state;
        UDCISR0 = _UDC_bit(INT_ENDB);
        if(statetemp == CONFIGURED)
          retrieveOut();
        else
        {
          UDCCSRB = _UDC_bit(UDCCSRAX_PC);
        }
      }
      break;
    default:
      if(isFlagged(UDCISR0, _UDC_bit(INT_END0)))
        UDCISR0 = _UDC_bit(INT_END0);
      if(isFlagged(UDCISR0, _UDC_bit(INT_ENDA)))
        UDCISR0 = _UDC_bit(INT_ENDA);
      if(isFlagged(UDCISR0, _UDC_bit(INT_ENDB)))
        UDCISR0 = _UDC_bit(INT_ENDB);
      if(isFlagged(UDCISR1, _UDC_bit(INT_IRCC)))
        UDCISR1 = _UDC_bit(INT_IRCC);
      if(isFlagged(UDCISR1, _UDC_bit(INT_IRRS)))
        UDCISR1 = _UDC_bit(INT_IRRS);
      break;
  }
}

/**
 * Prepare_Buffer_Download
 *
 * Prepare the USB driver for buffer download. The driver
 * does not post the task to process the packets untill the
 * complete buffer is received. 
 *
 * @param pckrcv Number of packets received.
 * @param pckexp Number of packets expected.
 *
 * @return SUCCESS | FAIL
 */
result_t Prepare_Buffer_Download (uint32_t pckrcv, uint32_t pckexp)
{
  BufferRcvMode = 1;
  TotalPckRcv = pckrcv;
  PckExpected = pckexp;
  PckRcv = 0;
  return SUCCESS;
}

/**
 * DMA_Done
 * 
 * Provision for DMA implementation, Currently not used.
 */
void DMA_Done ()
{
  return;
}

void processOut_Binary ()
{
  return;
}

void handleControlSetup()
{
  uint32_t data[2];
  uint8_t statetemp;

  clearIn();

  {
  __nesc_atomic_t atomic = __nesc_atomic_start();	

    statetemp = state;
    data[0] = UDCDR0;
    data[1] = UDCDR0;
     
#if DEBUG
    if(statetemp != CONFIGURED)
      trace("hCS; data: %x %x \r\n", data[0], data[1]);
#endif

    UDCCSR0 |= _UDC_bit(UDCCSR0_SA);//does both in one step...the magic of |=

  __nesc_atomic_end (atomic);	
  }

  if (getBit(getByte(data[0], 0), 6) == 0 && 
              getBit(getByte(data[0], 0), 5) == 0 && 
              getByte(data[0], 1) == USB_GETDESCRIPTOR)
  {
    switch(getByte(data[0], 3))
    {
      case USB_DESCRIPTOR_DEVICE:
        sendDeviceDescriptor((data[1] >> 16) & 0xFFFF);
      break;
      case USB_DESCRIPTOR_CONFIGURATION:
        sendConfigDescriptor(getByte(data[0],2),(data[1] >> 16) & 0xFFFF);
      break;
      case USB_DESCRIPTOR_STRING:
        sendStringDescriptor(getByte(data[0],2),(data[1] >> 16) & 0xFFFF);
      break;
      case USB_DESCRIPTOR_HID_REPORT:
        sendHidReportDescriptor((data[1] >> 16) & 0xFFFF);
      break;
      default:
        //trace("Unrecognized Descriptor request\r\n");
        // /*atomic*/ UDCCSR0 |= _UDC_bit(UDCCSR0_FST);
      break;
    }
  }
  else if(getBit(getByte(data[0], 0), 6) == 0 && 
              getBit(getByte(data[0], 0), 5) == 0 && 
              getByte(data[0], 1) == USB_SETCONFIGURATION)
  {
    UDCCR |= _UDC_bit(UDCCR_SMAC);
     
    if((UDCCR & _UDC_bit(UDCCR_EMCE)) != 0)
      //       state = CONFIGURED;
    //     else
#if DEBUG
       TRACE("Error: Memory configuration\r\n");
#else
     ;
#endif     
  }
  else if(getBit(getByte(data[0], 0), 6) == 0 && 
                    getBit(getByte(data[0], 0), 5) == 1)
  {
    switch(getByte(data[0], 1))
    {
      case USB_HID_GETREPORT:
        //write
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
        //called but optional...should stall in response to this 
        //according to the book
        UDCCSR0 |= _UDC_bit(UDCCSR0_FST);
      break;
      case USB_HID_SETPROTOCOL:
        //fairly optional
      break;
    }
  }
  else
  {
    //trace("Unrecognized Setup request\r\n");
    ///*atomic*/ UDCCSR0 |= _UDC_bit(UDCCSR0_FST);
  }
}

/**
 * sendDeviceDescriptor
 *
 * The device descriptor structure contains basic information about the device which
 * allows USB Host to retrieve further details about the device. This function is a
 * reponse for Get_Descriptor request from the USB HOST (high byte of setup
 * transaction's wValue field will be set to 1).
 *
 * @param wLength Length of the report. (Max Size = 16)
 */
void sendDeviceDescriptor(uint16_t wLength)
{
  USBdata InStream;
  uint8_t InTaskTemp;
  DynQueue QueueTemp;

#if DEBUG
  trace("Sending device descriptor;\r\n");
#endif
  if(wLength == 0)
    return;

  {/**ATOMIC**/
  __nesc_atomic_t atomic = __nesc_atomic_start();
    InStream = (USBdata)malloc(sizeof(USBdata_t));

    InStream->endpointDR = _udcdr0;
    InStream->fifosize = 16;
    InStream->src = (uint8_t *)malloc(0x12);

    InStream->len = wLength < 0x12?wLength:0x12;
    InStream->index = 0;
    InStream->param = 0;

    /* FIXME	I dont know why we have to fill SRC this way. CHANGE IT*/
    *(uint32_t *)(InStream->src) = 0x12 | (USB_DESCRIPTOR_DEVICE << 8) | 
                                          (Device.bcdUSB << 16);
    *(uint32_t *)(InStream->src + 4) = Device.bDeviceClass | 
                                       (Device.bDeviceSubclass << 8) | 
                                       (Device.bDeviceProtocol << 16) | 
                                       (Device.bMaxPacketSize0 << 24);

    *(uint32_t *)(InStream->src + 8) = Device.idVendor | (Device.idProduct << 16);
    *(uint32_t *)(InStream->src + 12) = Device.bcdDevice | 
                           (Device.iManufacturer << 16) | (Device.iProduct << 24);
    *(InStream->src + 16) = Device.iSerialNumber;
    *(InStream->src + 17) = Device.bNumConfigurations;
    InTaskTemp = InTask;
    QueueTemp = InQueue;
    DynQueue_enqueue(QueueTemp, InStream);
    if(DynQueue_getLength(QueueTemp) == 1 && InTaskTemp == 0)
    {
      InTask = 1;
      sendControlIn();
    }
  __nesc_atomic_end (atomic);
  }
}

/**
 * sendConfigDescriptor
 *
 * Configuration consists of the deive's power preference and the number of
 * interfaces supported. This function is a response by the USB Client driver
 * for Get_Descriptor request from the host with high byte of the setup
 * transaction's wValue set to 2.
 *
 * @param id	The current configuration ID to be sent.
 * @param	wLenght	
 */
void sendConfigDescriptor (uint8_t id, uint16_t wLength)
{
  USBconfiguration Config;
  USBinterface Inter;
  USBendpoint EndpointIn, EndpointOut;
  USBdata InStream;
  uint8_t InTaskTemp;
  DynQueue QueueTemp;

#if DEBUG   
  trace("Sending config descriptor; ID: %x\r\n", id);
#endif

  if(wLength == 0)
    return;
	
  {
    Config = Device.oConfigurations[1];
    Inter = Config->oInterfaces[0];
    EndpointIn = Inter->oEndpoints[0];
    EndpointOut = Inter->oEndpoints[1];

    InStream = (USBdata)malloc(sizeof(USBdata_t));

    InStream->endpointDR = _udcdr0;
    InStream->fifosize = 16;
    InStream->src = (uint8_t *)malloc(Config->wTotalLength);
     
    InStream->len = wLength < Config->wTotalLength?wLength:Config->wTotalLength;
    InStream->index = 0;
    InStream->param = 0;

    *(uint32_t *)(InStream->src) = 0x09 | (USB_DESCRIPTOR_CONFIGURATION << 8) | 
                                          (Config->wTotalLength<< 16);
    *(uint32_t *)(InStream->src + 4) = Config->bNumInterfaces | 
             (Config->bConfigurationID << 8) | (Config->iConfiguration << 16) | 
             (Config->bmAttributes << 24);
    *(uint32_t *)(InStream->src + 8) = Config->MaxPower | (0x09 << 8) | 
                 (USB_DESCRIPTOR_INTERFACE << 16) | (Inter->bInterfaceID << 24);
    *(uint32_t *)(InStream->src + 12) = Inter->bAlternateSetting | 
                 (Inter->bNumEndpoints << 8) | (Inter->bInterfaceClass << 16) | 
                 (Inter->bInterfaceSubclass << 24);
    *(uint32_t *)(InStream->src + 16) = Inter->bInterfaceProtocol | 
                 (Inter->iInterface << 8) | (0x09 << 16) | (USB_DESCRIPTOR_HID << 24);
    *(uint32_t *)(InStream->src + 20) = Hid.bcdHID | (Hid.bCountryCode << 16) | 
                 (Hid.bNumDescriptors << 24);
    *(uint32_t *)(InStream->src + 24) = USB_DESCRIPTOR_HID_REPORT | 
                 (Hid.wDescriptorLength << 8) | (0x07 << 24);
    *(uint32_t *)(InStream->src + 28) = USB_DESCRIPTOR_ENDPOINT | 
                 (EndpointIn->bEndpointAddress << 8) | (EndpointIn->bmAttributes << 16) | 
                 (EndpointIn->wMaxPacketSize << 24);
    *(uint32_t *)(InStream->src + 32) = ((EndpointIn->wMaxPacketSize >> 8) & 0xFF) | 
                 (EndpointIn->bInterval << 8) | (0x07 << 16) | (USB_DESCRIPTOR_ENDPOINT << 24);
    *(uint32_t *)(InStream->src + 36) =  EndpointOut->bEndpointAddress | 
                 (EndpointOut->bmAttributes << 8) | (EndpointOut->wMaxPacketSize << 16);
    *(uint8_t *)(InStream->src + 40) = EndpointOut->bInterval;
 
    InTaskTemp = InTask;
    QueueTemp = InQueue;
    DynQueue_enqueue(QueueTemp, InStream);
    if(DynQueue_getLength(QueueTemp) == 1 && InTaskTemp == 0)
    {
      InTask = 1;
      sendControlIn();
    }
  }
}

/**
 * sendStringDescriptor
 * 
 * The send*Descriptor functions convert the data initialized in the 
 * write*Descriptor functions into the data streams that are to be sent, and
 * then queues those data streams.
 *
 * @param id ID of the string descriptor.
 * @param wLength Length of the descriptor.
 */
void sendStringDescriptor(uint8_t id, uint16_t wLength)
{
  USBstring str;
  uint8_t count = 0, InTaskTemp;
  uint8_t *src = NULL;
  USBdata InStream = NULL;
  DynQueue QueueTemp;

  str = Strings[id];
   
  if(wLength == 0)
    return;

  {/**ATOMIC**/
  uint32_t atomic = __nesc_atomic_start();
    InStream = (USBdata)malloc(sizeof(USBdata_t));
    InStream->endpointDR = _udcdr0;
    InStream->fifosize = 16;
    InStream->src = (uint8_t *)malloc(str->bLength);
    InStream->param = 0;

    InStream->len = wLength < str->bLength?wLength:str->bLength;
    InStream->index = 0;

    if(id == 0)
      *(uint32_t *)(InStream->src) = str->bLength | (USB_DESCRIPTOR_STRING << 8) | 
                                                    (str->uMisc.wLANGID << 16);
    else
    {
      src = str->uMisc.bString;
      *(uint32_t *)(InStream->src) = str->bLength | 
                         (USB_DESCRIPTOR_STRING << 8) | (*src << 16);
      src++;
      for(count = 1; *src != '\0'; count++, src++)
      {
        if(*(src + 1) == '\0')
        {
          *(InStream->src + count * 4) = (uint8_t)*src;
          *(InStream->src + count * 4 + 1) = (uint8_t)0;
        }
        else
        {
          *(uint32_t *)(InStream->src + count * 4) = *src | 
                                                     (*(src+1) << 16);
          src++;
        }
      }
    }

    InTaskTemp = InTask;
    QueueTemp = InQueue;
    DynQueue_enqueue(QueueTemp, InStream);
    if(DynQueue_getLength(QueueTemp) == 1 && InTaskTemp == 0)
    {
      InTask = 1;
      sendControlIn();
    }
  __nesc_atomic_end (atomic);
  }
}

/**
 * sendStringDescriptor
 * 
 * The send*Descriptor functions convert the data initialized in the 
 * write*Descriptor functions into the data streams that are to be sent, and
 * then queues those data streams.
 *
 * @param wLength Length of the descriptor.
 */
void sendHidReportDescriptor(uint16_t wLength)
{
  USBdata InStream;
  uint8_t InTaskTemp;
  DynQueue QueueTemp;

  if(wLength == 0)
    return;

  {/**ATOMIC**/
  uint32_t atomic = __nesc_atomic_start();
    InStream = (USBdata)malloc(sizeof(USBdata_t));

    InStream->endpointDR = _udcdr0;
    InStream->fifosize = 16;
    InStream->src = (uint8_t *)malloc(HidReport.wLength);

    InStream->len = wLength < HidReport.wLength?wLength:HidReport.wLength;
    InStream->index = 0;
    InStream->param = 0;

    memcpy(InStream->src, HidReport.bString, HidReport.wLength);

    InTaskTemp = InTask;
    QueueTemp = InQueue;
    DynQueue_enqueue(QueueTemp, InStream);
    if(DynQueue_getLength(QueueTemp) == 1 && InTaskTemp == 0)
    {
      InTask = 1;
      sendControlIn();
    }
    state = CONFIGURED;
  __nesc_atomic_end (atomic);
  }
}

/**
 * USBMsg_Send
 *
 * Send Packet function for the higher level modules. The functions
 * calls the sendreport to transmit the data over USB. The "type"
 * parameter is specific to the JTProtocol currently, <I> refer to
 * PXA27XUSBClient.h</I>.
 *
 * @param data Data Packet to be sent to the host.
 * @param numBytes Size of the data packet.
 * @param type JT Protocol message type.
 *
 * @return SUCCESS | FAIL
 */
result_t USBMsg_Send (uint8_t* data, uint32_t numBytes, uint8_t type)
{
  sendReport(data, numBytes, type, SENDJTPACKET);
  return SUCCESS;
}

/**
 * sendReport
 * 
 * Once the device has been enumerated, sendReport is used to take data and
 * convert it into a queuable structure for sending. data is a pointer to the
 * buffer to be sent; datalen is the length of that buffer in bytes, type
 * is the type as specified in the JT protocol, and source is either 
 * SENDVARLENPACKET, SENDJTPACKET or SENDBAREMSG, depending on the 
 * interface used to send the data.
 *
 * @param data Data Packet to be sent to USB Host.
 * @param datalen Size of the data packet.
 * @param type JT Protocol type.
 * @param source Type of packet defined by JTProtocol
 */
void sendReport(uint8_t *data, uint32_t datalen, uint8_t type, uint8_t source)
{
  USBdata InStream;
  uint8_t statetemp, InTaskTemp;
  DynQueue QueueTemp;

  statetemp = state;

  if(statetemp != CONFIGURED)
    return;

  if(isFlagged(UDCCSRA, _UDC_bit(UDCCSRAX_PC)))
    UDCCSRA |= _UDC_bit(UDCCSRAX_PC);
   
  {/**ATOMIC**/
  __nesc_atomic_t atomic = __nesc_atomic_start();
    InStream = (USBdata)malloc(sizeof(USBdata_t));

    InStream->endpointDR = _udcdra;
    InStream->fifosize = Device.oConfigurations[1]->oInterfaces[0]->oEndpoints[0]->wMaxPacketSize;
    InStream->pindex = InStream->index = 0;
    InStream->type = type;
    InStream->source = source;
    InStream->len = datalen;
    InStream->src = data;
    InStream->param = (uint8_t *)IMOTE_HID_REPORT;
  __nesc_atomic_end (atomic);
  }

  if(datalen <= IMOTE_HID_TYPE_L_BYTE_SIZE)
  {
    InStream->type |= (IMOTE_HID_TYPE_L_BYTE << IMOTE_HID_TYPE_L);
    InStream->n =  (uint8_t)(datalen / IMOTE_HID_BYTE_MAXPACKETDATA);
    InStream->tlen = InStream->n * InStream->fifosize + 3 + 
                             datalen % IMOTE_HID_BYTE_MAXPACKETDATA;
  }
  else if(datalen <= IMOTE_HID_TYPE_L_SHORT_SIZE)
  {
    InStream->type |= (IMOTE_HID_TYPE_L_SHORT << IMOTE_HID_TYPE_L);
    InStream->n =  (uint16_t)(datalen / IMOTE_HID_SHORT_MAXPACKETDATA);
    InStream->tlen = InStream->n * InStream->fifosize + 4 + 
                               datalen % IMOTE_HID_SHORT_MAXPACKETDATA;
  }
  else if(datalen <= IMOTE_HID_TYPE_L_INT_SIZE)
  {
    InStream->type |= (IMOTE_HID_TYPE_L_INT << IMOTE_HID_TYPE_L);
    InStream->n = datalen / IMOTE_HID_SHORT_MAXPACKETDATA;
    InStream->tlen = InStream->n * InStream->fifosize + 6 + 
                           datalen % IMOTE_HID_INT_MAXPACKETDATA;
  }
  else
  {//too much data...which isn't really possible in this case so not a big deal
  }
	
  {/**ATOMIC**/
  __nesc_atomic_t atomic = __nesc_atomic_start();
    InTaskTemp = InTask;
    QueueTemp = InQueue;
  __nesc_atomic_end (atomic);
  }
  DynQueue_enqueue(QueueTemp, InStream);
  if(DynQueue_getLength(QueueTemp) == 1 && InTaskTemp == 0)
  {
    /*atomic*/ InTask = 1;
    sendIn();
    //Post_Send_In (InQueue);
  }
}

/**
 * retrieveOut
 * 
 * retrieveOut() queues JT data that has been received from the host PC
 * for translating into regular data.
 */
void retrieveOut()
{
  uint16_t i = 0;
  uint8_t *buff;
  uint32_t temp;
  uint8_t bufflen;//, OutPausedTemp, OutTaskTemp;
   
  for(i = 0; i < IMOTE_HID_TYPE_COUNT; i++)
    OutStream[i].endpointDR = _udcdrb;

  bufflen = Device.oConfigurations[1]->oInterfaces[0]->oEndpoints[1]->wMaxPacketSize;
  buff = (uint8_t *)malloc(bufflen);

  for(i = 0; (_PXAREG(OutStream[0].endpointDR - _udcdr0 + _udcbcr0) & 0x1FF) > 0
    	                                                       && i < bufflen; i+=4)
  {
    temp = _PXAREG(OutStream[0].endpointDR);
    *(uint32_t *)(buff + i) = temp;
  }

  DynQueue_enqueue(OutQueue, buff);
  TOS_post (&processOut);
  _PXAREG(_udcdrb - _udcdr0 + _udccsr0) |= _UDC_bit(UDCCSRAX_PC);
}
 

void processOut()
{
  uint8_t *buff;
  uint8_t type, valid = 0;//, OutPausedTemp;
  USBdata OutStreamTemp;
  uint8_t DataBuff [62];
   
  buff = (uint8_t *)DynQueue_dequeue(OutQueue);
  if (buff == NULL)
    return;
  
  {
  __nesc_atomic_t atomic = __nesc_atomic_start();
    OutStream[0].endpointDR = _udcdrb;
  __nesc_atomic_end (atomic);
  }
  type = *(buff + IMOTE_HID_TYPE);
  /*atomic*/ OutStreamTemp = &OutStream[type & 0x3];
  if(isFlagged(type, _UDC_bit(IMOTE_HID_TYPE_H)))
  {
    clearOut();
    {
    __nesc_atomic_t atomic = __nesc_atomic_start();
      OutStream[type & 0x3].type = type;
      OutStream[0].endpointDR = _udcdrb;
    __nesc_atomic_end (atomic);
    }

    switch((OutStreamTemp->type >> IMOTE_HID_TYPE_L) & 3)
    {
      case IMOTE_HID_TYPE_L_BYTE:
        OutStreamTemp->n = *(buff + IMOTE_HID_NI);
        if(OutStreamTemp->n == 0)
        {
          valid = *(buff + IMOTE_HID_NI + 1);
          OutStreamTemp->len = valid;
        }
        else
        {
          valid = IMOTE_HID_BYTE_MAXPACKETDATA;
          OutStreamTemp->len = (OutStreamTemp->n + 1) * 
                                 IMOTE_HID_BYTE_MAXPACKETDATA - 1;
        }
        OutStreamTemp->src = (uint8_t *)DataBuff;
        memcpy (OutStreamTemp->src, buff + IMOTE_HID_NI + 1 + 
                               (OutStreamTemp->n == 0?1:0), valid);
        break;
      case IMOTE_HID_TYPE_L_SHORT:
        OutStreamTemp->n = (*(buff + IMOTE_HID_NI) << 8) | 
               *(buff + IMOTE_HID_NI + 1);
        if(OutStreamTemp->n == 0)
        {
          valid = *(buff + IMOTE_HID_NI + 2);
          OutStreamTemp->len = valid;
        }
        else
        {
          valid = IMOTE_HID_SHORT_MAXPACKETDATA;
          OutStreamTemp->len = (OutStreamTemp->n + 1) * 
                           IMOTE_HID_SHORT_MAXPACKETDATA - 1;
        }
        OutStreamTemp->src = (uint8_t *)DataBuff;
        memcpy(OutStreamTemp->src, buff + IMOTE_HID_NI + 2 + 
                     (OutStreamTemp->n == 0?1:0), valid);
        break;
      case IMOTE_HID_TYPE_L_INT:
        OutStreamTemp->n = (*(buff + IMOTE_HID_NI) << 24) | 
                  (*(buff + IMOTE_HID_NI + 1) << 16) | 
                  (*(buff + IMOTE_HID_NI + 2) << 8) | *(buff + IMOTE_HID_NI + 3);
        if(OutStreamTemp->n == 0)
        {
          valid = *(buff + IMOTE_HID_NI + 4);
          OutStreamTemp->len = valid;
        }
        else
        {
          valid = IMOTE_HID_INT_MAXPACKETDATA;
          OutStreamTemp->len = (OutStreamTemp->n + 1) *
          IMOTE_HID_INT_MAXPACKETDATA - 1;
        }
        OutStreamTemp->src = (uint8_t *)DataBuff;
        memcpy(OutStreamTemp->src, buff + IMOTE_HID_NI + 4 + 
                            (OutStreamTemp->n == 0?1:0), valid);
    } //Switch End
  } // If End
  else if(isFlagged(OutStreamTemp->type, _UDC_bit(IMOTE_HID_TYPE_H)))
  {
    switch((OutStreamTemp->type >> IMOTE_HID_TYPE_L) & 3)
    {
      case IMOTE_HID_TYPE_L_BYTE:
        if(OutStreamTemp->index != *(buff + IMOTE_HID_NI))
        {
          clearOut();
          free(buff);
          buff = NULL;
          _PXAREG(_udcdrb - _udcdr0 + _udccsr0) |= _UDC_bit(UDCCSRAX_PC);
	  TOS_post (&processOut);
          return;
        }
        if(OutStreamTemp->n == OutStreamTemp->index)
          valid = *(buff + IMOTE_HID_NI + 1);
        else
          valid = IMOTE_HID_BYTE_MAXPACKETDATA;

        OutStreamTemp->src = (uint8_t *)DataBuff;
        memcpy(OutStreamTemp->src, buff + IMOTE_HID_NI + 1 + 
                    (OutStreamTemp->n == OutStreamTemp->index?1:0), valid);
      break;
      case IMOTE_HID_TYPE_L_SHORT:
        if(OutStreamTemp->index != ((*(buff + IMOTE_HID_NI) << 8) | 
                                      *(buff + IMOTE_HID_NI + 1)))
        {
          clearOut();
          free(buff);
          buff = NULL;
          _PXAREG(_udcdrb - _udcdr0 + _udccsr0) |= _UDC_bit(UDCCSRAX_PC);
          return;
        }
       
        if(OutStreamTemp->n == OutStreamTemp->index)
          valid = *(buff + IMOTE_HID_NI + 2);
        else
          valid = IMOTE_HID_SHORT_MAXPACKETDATA;

        OutStreamTemp->src = (uint8_t *)DataBuff;
        memcpy(OutStreamTemp->src, buff + IMOTE_HID_NI + 2 + 
                   (OutStreamTemp->n == OutStreamTemp->index?1:0), valid);
      break;
      case IMOTE_HID_TYPE_L_INT:
        if(OutStreamTemp->index != ((*(buff + IMOTE_HID_NI) << 24) | 
                   (*(buff + IMOTE_HID_NI + 1) << 16) | 
                   (*(buff + IMOTE_HID_NI + 2) << 8) | *(buff + IMOTE_HID_NI + 3)))
        {
          clearOut();
          free(buff);
          buff = NULL;
          _PXAREG(_udcdrb - _udcdr0 + _udccsr0) |= _UDC_bit(UDCCSRAX_PC);
	  TOS_post (&processOut);
          return;
        }
        if(OutStreamTemp->n == OutStreamTemp->index)
          valid = *(buff + IMOTE_HID_NI + 4);
        else
          valid = IMOTE_HID_INT_MAXPACKETDATA;

        OutStreamTemp->src = (uint8_t *)DataBuff;
        memcpy(OutStreamTemp->src, buff + IMOTE_HID_NI + 4 + 
                  (OutStreamTemp->n == OutStreamTemp->index?1:0), valid);
      break;
    }
  }
  else //assume in this case it can be ignored
    ;

  free(buff);
  buff = NULL;

  if (((OutStreamTemp->type) & 0xE3) == IMOTE_HID_TYPE_MSC_BINARY)
  {
    Binary_Image_Packet_Received ((uint8_t*)OutStreamTemp->src, valid, OutStreamTemp->n);
  }
  else if (((OutStreamTemp->type) & 0xE3) == IMOTE_HID_TYPE_MSC_COMMAND)
  {
    Command_Packet_Received ((uint8_t*)OutStreamTemp->src, valid);
  }
  else if (((OutStreamTemp->type) & 0xE3) == IMOTE_HID_TYPE_MSC_REBOOT)
  {
    Command_Packet_Received ((uint8_t*)OutStreamTemp->src, valid);
  }

  OutStreamTemp->src = NULL;
  OutStreamTemp->index++;
}

/**
 * sendIn
 * 
 * The sendIn() task prepends the necessary JT protocol information and
 * for a packet that has been queued and then handles sending it.
 */
void sendIn()
{
  uint16_t i = 0;
  uint8_t buf[64];//fifosize
  uint8_t valid;
  DynQueue QueueTemp;
  USBdata InStateTemp;

#if DEBUG
   trace("In sendIn;\r\n");
#endif
  {/*ATOMIC*/
  __nesc_atomic_t atomic = __nesc_atomic_start();
    QueueTemp = InQueue;
  __nesc_atomic_end (atomic);
  }

  if(DynQueue_getLength(QueueTemp) <= 0)
  {
    return;
  }

  {
  __nesc_atomic_t atomic = __nesc_atomic_start();
    InState = (USBdata)DynQueue_dequeue(QueueTemp);
    InStateTemp = InState;
  __nesc_atomic_end (atomic);
  }


  if((uint32_t)InStateTemp->param != IMOTE_HID_REPORT)
  {
    sendControlIn();//should never happen
    return;
  }

  if(InStateTemp->pindex <= InStateTemp->n)
  {
    if(((InStateTemp->type >> IMOTE_HID_TYPE_L) & 0x3) == IMOTE_HID_TYPE_L_BYTE)
    {
      buf[IMOTE_HID_TYPE] = InStateTemp->type;

      if(InStateTemp->pindex == 0)
      {
        buf[IMOTE_HID_TYPE] |= _UDC_bit(IMOTE_HID_TYPE_H);
        buf[IMOTE_HID_NI] = InStateTemp->n;
      }
      else
        buf[IMOTE_HID_NI] = InStateTemp->pindex;

      if(InStateTemp->pindex == InStateTemp->n)
      {
        valid = (uint8_t)(InStateTemp->len % IMOTE_HID_BYTE_MAXPACKETDATA);
        buf[IMOTE_HID_NI + 1] = valid;
      }
      else
        valid = (uint8_t)IMOTE_HID_BYTE_MAXPACKETDATA;
      memcpy (buf + IMOTE_HID_NI + 1 + (InStateTemp->pindex==InStateTemp->n?1:0), 
                  InStateTemp->src + InStateTemp->pindex * IMOTE_HID_BYTE_MAXPACKETDATA, 
                  valid);
    }
    else if (((InStateTemp->type >> IMOTE_HID_TYPE_L) & 0x3) == 
                                         IMOTE_HID_TYPE_L_SHORT)
    {
      buf[IMOTE_HID_TYPE] = InStateTemp->type;
      if(InStateTemp->pindex == 0)
      {
        buf[IMOTE_HID_TYPE] |= _UDC_bit(IMOTE_HID_TYPE_H);
        buf[IMOTE_HID_NI] = (uint8_t)(InStateTemp->n >> 8);
        buf[IMOTE_HID_NI + 1] = (uint8_t)InStateTemp->n;
      }
      else
      {
        buf[IMOTE_HID_NI] = (uint8_t)(InStateTemp->pindex >> 8);
        buf[IMOTE_HID_NI + 1] = (uint8_t)InStateTemp->pindex;
      }

      if(InStateTemp->pindex == InStateTemp->n)
      {
        valid = (uint8_t)(InStateTemp->len % IMOTE_HID_SHORT_MAXPACKETDATA);
        buf[IMOTE_HID_NI + 2] = valid;
      }
      else
        valid = (uint8_t)IMOTE_HID_SHORT_MAXPACKETDATA;
      memcpy(buf + IMOTE_HID_NI + 2 + (InStateTemp->pindex==InStateTemp->n?1:0),
           InStateTemp->src + InStateTemp->pindex * IMOTE_HID_SHORT_MAXPACKETDATA, valid);
    }
    else if(((InStateTemp->type >> IMOTE_HID_TYPE_L) & 0x3) == 
                                          IMOTE_HID_TYPE_L_INT)
    {
      buf[IMOTE_HID_TYPE] = InStateTemp->type;
      if(InStateTemp->pindex == 0)
      {
        buf[IMOTE_HID_TYPE] |= _UDC_bit(IMOTE_HID_TYPE_H);
        buf[IMOTE_HID_NI] = (uint8_t)(InStateTemp->n >> 24);
        buf[IMOTE_HID_NI + 1] = (uint8_t)(InStateTemp->n >> 16);
        buf[IMOTE_HID_NI + 2] = (uint8_t)(InStateTemp->n >> 8);
        buf[IMOTE_HID_NI + 3] = (uint8_t)InStateTemp->n;
      }
      else
      {
        buf[IMOTE_HID_NI] = (uint8_t)(InStateTemp->pindex >> 24);
        buf[IMOTE_HID_NI + 1] = (uint8_t)(InStateTemp->pindex >> 16);
        buf[IMOTE_HID_NI + 2] = (uint8_t)(InStateTemp->pindex >> 8);
        buf[IMOTE_HID_NI + 3] = (uint8_t)InStateTemp->pindex;
      }

      if(InStateTemp->pindex == InStateTemp->n)
      {
        valid = (uint8_t)(InStateTemp->len % IMOTE_HID_INT_MAXPACKETDATA);
        buf[IMOTE_HID_NI + 4] = valid;
      }
      else
        valid = (uint8_t)IMOTE_HID_INT_MAXPACKETDATA;
      memcpy (buf + IMOTE_HID_NI + 4 + (InStateTemp->pindex == InStateTemp->n?1:0), 
              InStateTemp->src + InStateTemp->pindex * IMOTE_HID_INT_MAXPACKETDATA, 
              valid);
    }
  }

  InStateTemp->pindex++;
  if(InStateTemp->index < InStateTemp->tlen)
  {
    while(i < InStateTemp->fifosize)
    {
      _PXAREG(InStateTemp->endpointDR) = *(uint32_t *)(buf + i);
      InStateTemp->index += 4;
      i += 4;
    }
  }

  InTask = 0;
  /* Stall till we have space for atleast one more buffer, incase
   * if the app wants to send one immedietly.
   */
  while (!(UDCCSRA &= (1 << 0)));

  if(InStateTemp->index >= InStateTemp->tlen && 
     InStateTemp->index % InStateTemp->fifosize != 0)
  {
    if(i < InStateTemp->fifosize)
      _PXAREG(InStateTemp->endpointDR - _udcdr0 + _udccsr0) |= 
        _UDC_bit(InStateTemp->endpointDR == _udcdr0?UDCCSR0_IPR:UDCCSRAX_SP);
    //InStateTemp->status &= ~_UDC_bit(MIDSEND);    
  }
  else if(InStateTemp->index >= InStateTemp->tlen && 
              InStateTemp->index % InStateTemp->fifosize == 0)
  {
    InStateTemp->index++;
  }
}

/**
 * sendControlIn
 * 
 * sendControlIn handles sending a queued control message.
 */
void sendControlIn()
{
  uint16_t i = 0;
  DynQueue QueueTemp;
  USBdata InStateTemp;

  QueueTemp = InQueue;
  if (DynQueue_getLength(QueueTemp) <= 0)
    return;

  InState = (USBdata)DynQueue_peek(QueueTemp);
  InStateTemp = InState;
  if((uint32_t)InStateTemp->param != 0)
    return;

  InState->status |= _UDC_bit(MIDSEND);

  {
    while(InStateTemp->index < InStateTemp->len && i < InStateTemp->fifosize)
    {
      if(InStateTemp->len - InStateTemp->index > 3 && InStateTemp->fifosize - i > 3)
      {
        _PXAREG(InStateTemp->endpointDR) = *(uint32_t *)
                                           (InStateTemp->src + InStateTemp->index);
        InStateTemp->index += 4;
        i += 4;
      }
      else
      {
        _PXAREG8(InStateTemp->endpointDR) = *(InStateTemp->src + InStateTemp->index);
        InStateTemp->index++;
        i++;
      }
    }
    if(InStateTemp->index >= InStateTemp->len && 
             InStateTemp->index % InStateTemp->fifosize != 0)
    {
      if(i < InStateTemp->fifosize)
        _PXAREG(InStateTemp->endpointDR - _udcdr0 + _udccsr0) |= 
                     _UDC_bit(InStateTemp->endpointDR == 
                        _udcdr0?UDCCSR0_IPR:UDCCSRAX_SP);
      InState->status &= ~_UDC_bit(MIDSEND);
    }
    else if(InStateTemp->index == InStateTemp->len && 
              InStateTemp->index % InStateTemp->fifosize == 0)
      InState->index++;

  }
}

/**
 * isAttached
 *
 * isAttached() checks if the mote is attached over USB to a power source
 * (assumed to be a host PC).
 */
void isAttached()
{
  uint8_t statetemp;

  if(HPLUSBClientGPIO_CheckConnection() == SUCCESS)
  {
    UDCCR |= _UDC_bit(UDCCR_UDE-1);
  }

  if((UDCCR & _UDC_bit(UDCCR_EMCE)) != 0);

  statetemp = state;
  if(statetemp == 0)
    state = POWERED;
  else
  {
    UDCCR &= ~_UDC_bit(UDCCR_UDE);
    state = 0;
    clearIn();
    clearOut();
  }
}

/**
 * USB_GPIO_Interrpt_Fired
 * 
 * Interrupt from the GPIO Pin.
 */
void USB_GPIO_Interrpt_Fired()
{
  isAttached();
  PXA27XGPIOInt_Clear(USBC_GPION_DET);
}

/**
 * writeHidDescriptor
 *
 * Populate the HID descriptor data in to a
 * structure to be sent to the host for enumenration.
 */
void writeHidDescriptor()
{
  Hid.bcdHID = 0x0110;
  Hid.bCountryCode = 0;
  Hid.bNumDescriptors = 1;
  Hid.bDescriptorType = USB_DESCRIPTOR_HID_REPORT;
  Hid.wDescriptorLength = 0x22;
}
 
/**
 * writeHidReportDescriptor
 *
 * Inorder for the client the identify itself as a HID device, the USB protocol defines
 * a set of TYPE=VALUE pair which could be combined together to form a report. This is a
 * part of USB Client Enumeration process.
 * 
 * This function actually assembles a HID Report. The report details are as follows
 * 
 * 0x06	- Usage Page
 * 	0xFFA0	Vendor Specific function of the device 
 * 		(could be desktop control, game control etc)
 * 	
 * 0x09	- Usage
 * 	0xA5	
 * 
 * 0xA1 - Collection (Application)
 * 	0x01	begins a group of items that together perform a single function.
 *
 *
 */
void writeHidReportDescriptor()
{
  //atomic
  {
    HidReport.wLength = Hid.wDescriptorLength;
    HidReport.bString = (uint8_t *)malloc(HidReport.wLength);
    *(uint32_t *)(HidReport.bString) = 0x06 | (0xA0 << 8) | (0xFF << 16) | (0x09 << 24);
    *(uint32_t *)(HidReport.bString + 4) = 0xA5 | (0xA1 << 8) | (0x01 << 16) | (0x09 << 24);
    *(uint32_t *)(HidReport.bString + 8) = 0xA6 | (0x09 << 8) | (0xA7 << 16) | (0x15 << 24);
    *(uint32_t *)(HidReport.bString + 12) = 0x80 | (0x25 << 8) | (0x7F << 16) | (0x75 << 24);
    *(uint32_t *)(HidReport.bString + 16) = 0x08 | (0x95 << 8) | (0x40 << 16) | (0x81 << 24);
    *(uint32_t *)(HidReport.bString + 20) = 0x02 | (0x09 << 8) | (0xA9 << 16) | (0x15 << 24);
    *(uint32_t *)(HidReport.bString + 24) = 0x80 | (0x25 << 8) | (0x7F << 16) | (0x75 << 24);
    *(uint32_t *)(HidReport.bString + 28) = 0x08 | (0x95 << 8) | (0x40 << 16) | (0x91 << 24);
    *(uint8_t *)(HidReport.bString + 32) = 0x02;
    *(uint8_t *)(HidReport.bString + 33) = 0xC0;
  }
}

/**
 * writeStringDescriptor
 *
 * String descriptor used to describe the Manufacturer, Product, SerialNumber
 * of the device. (used in Device Descriptor).
 */
void writeStringDescriptor()
{
  uint8_t i;
  /*FIXME magic number -JS */
  char *buf = (char *)malloc(80); /*requires special freeing in clearDescriptors()*/
  //atomic
  {
    for(i = 0; i < STRINGS_USED + 1; i++)
      Strings[i] = (USBstring)malloc(sizeof(__string_t));
     
    Strings[0]->bLength = 4;
    Strings[0]->uMisc.wLANGID = 0x0409;
     
    Strings[1]->uMisc.bString = "SNO";
    Strings[2]->uMisc.bString = "Intel Mote 2 Embedded Device";
    sprintf(buf, "%x", *((uint32_t *)0x01FE0000));
    //buf = *((uint32_t *)0x01FE0000);
    realloc(buf, strlen(buf) + 1);
    Strings[3]->uMisc.bString = buf; //serial number 

    for(i = 1; i < STRINGS_USED + 1; i++)
      Strings[i]->bLength = 2 + 2 * strlen(Strings[i]->uMisc.bString);
  }
}

/**
 * writeEndpointDescriptor
 *
 * Currently we are using EndPoint 0 for control transfer (default USB Protocol),
 * End Point A for transmission (IN) and End Point B for reception (OUT). 
 * Identifying the IN and OUT endpoints are a part of USB Enumeration.
 * 
 * End->bmAttributes = 0x3;     Indicates the type of transfer is INTERRUPT
 * End->wMaxPacketSize = 0x40;  The packet size is 64 bytes
 * End->bInterval = 0x01;       1ms interval for polling or NAK
 *
 * @param endpoints  The structure which holds the End Point Descriptor.
 * @param config     The current configuration.
 * @param inter      Current Interface (EP0 is Interface1, EP1 and EP2 are in Interface2).
 * @param i          Represents the EP in a particular interface.
 */
void writeEndpointDescriptor(USBendpoint *endpoints, uint8_t config, 
								uint8_t inter, uint8_t i)
{
  USBendpoint End;
  End = (USBendpoint)malloc(sizeof(__endpoint_t));
   
  endpoints[i] = End;
  End->bEndpointAddress = i + 1;
  switch(config)
  {
    case 1:
      switch(inter)
      {
        case 0:
          switch(i)
          {
            case 0:
              End->bEndpointAddress |= _UDC_bit(USB_ENDPOINT_IN);
              End->bmAttributes = 0x3;
              End->wMaxPacketSize = USB_MAX_PACKET_SIZE;
              End->bInterval = 0x01;

              UDCCRA |= (1 << 25) | 
               ((End->bEndpointAddress & 0xF) << 15) | 
               ((End->bmAttributes & 0x3) << 13) | 
               (((End->bEndpointAddress & _UDC_bit(USB_ENDPOINT_IN)) != 0) << 12) | 
               //(End->wMaxPacketSize << 2) | 1;
               (End->wMaxPacketSize << 2) | (1 << 1) | 1; /* Double Buffering Enabled*/
            break;
            case 1:
              End->bmAttributes = 0x3;
              End->wMaxPacketSize = USB_MAX_PACKET_SIZE;
              End->bInterval = 0x01;

              UDCCRB |= (1 << 25) | 
               ((End->bEndpointAddress & 0xF) << 15) | 
               ((End->bmAttributes & 0x3) << 13) | 
               (((End->bEndpointAddress & _UDC_bit(USB_ENDPOINT_IN)) != 0) << 12) | 
               //(End->wMaxPacketSize << 2) | 1;
               (End->wMaxPacketSize << 2) | (1 << 1) | 1; /* Double Buffering Enabled*/
            break;
          }
        break;
      }
    break;
  }
}

/**
 * writeInterfaceDescriptor
 *
 * The interface descriptor provides information about a function or feature 
 * that a device implements. The descriptor contains class, subclass, and 
 * protocol information and the number of EndPoints the interface uses.
 *
 * Inter->bAlternateSetting = 0;     If the config supports multipe intefaces.
 * Inter->bNumEndpoints = 2;         Number of end points in the interface.
 * Inter->bInterfaceClass = 0x03;    Value indicates that the device is HID.
 * Inter->bInterfaceSubclass = 0x00; There are not subclasses for HID
 * 
 * @param interfaces  The struct containing the details of the current interface.
 * @param config      The Current configuration.
 * @param i           Represents the interface in a particular configuration.
 */
uint16_t writeInterfaceDescriptor(USBinterface *interfaces, uint8_t config, uint8_t i)
{
  uint8_t j;
  uint16_t length;
  USBinterface Inter;
  Inter = (USBinterface)malloc(sizeof(__interface_t));

  interfaces[i] = Inter;
  length = 9;
  Inter->bInterfaceID = i;
  switch(config)
  {
    case 0:
      switch(i)
      {
        case 0:
          Inter->bAlternateSetting = 0;
          Inter->bNumEndpoints = 0;
          Inter->bInterfaceClass = 0;
          Inter->bInterfaceSubclass = 0;
          Inter->bInterfaceProtocol = 0;
          Inter->iInterface = 0;
        break;
      }
      break;
    case 1:
      switch(i)
      {
        case 0:
          Inter->bAlternateSetting = 0;
          Inter->bNumEndpoints = 2;
          Inter->bInterfaceClass = 0x03;  /* Denotes that the device is HID*/
          Inter->bInterfaceSubclass = 0x00;
          Inter->bInterfaceProtocol = 0x00;
          Inter->iInterface = 0;
          length += 0x09;
        break;
      }
      break;
  }
   
  if(Inter->bNumEndpoints > 0)
  {
    Inter->oEndpoints = (USBendpoint *)
               malloc(sizeof(__endpoint_t) * Inter->bNumEndpoints);
    length += Inter->bNumEndpoints * 7;
    for(j = 0; j < Inter->bNumEndpoints; j++)
      writeEndpointDescriptor(Inter->oEndpoints, config,i,j);
  }
  return length;
}
 
/**
 * writeConfigurationDescriptor
 *
 * Each device must have atleast one configuration that specifies the device's
 * feature and abilities. The configuration descriptor contains information
 * about the device's use of power and the number of interfaces.
 * This driver provides two configurations, one for control transfer (EP0) 
 * and the second for Rx (EndPoint B) and Tx (EndPoint A). Only one of the 
 * configurations could be active at any point of time. 
 * 
 * Config->bNumInterfaces = 1;  Number of interfaces.
 * Config->iConfiguration = 0;  Not Configured State.
 * Config->bmAttributes = 0x80; The device is BUS Powered
 * Config->MaxPower = USBPOWER; 
 * 
 * @param configs   Structure to hold configuration details.
 * @param i         Current configuration in the device.
 */
void writeConfigurationDescriptor(USBconfiguration *configs, uint8_t i)
{
  uint8_t j;
  USBconfiguration Config;
  Config = (USBconfiguration)malloc(sizeof(__configuration_t));
   
  configs[i] = Config;
  Config->wTotalLength = 9;
  Config->bConfigurationID = i;
   
  switch(i)
  {
    case 0: 
      Config->bNumInterfaces = 1;
      Config->iConfiguration = 0; /* Zero makes the device enter Not Configured state*/
      /*
       * Bit 7=1 Indicate that configuration is bus powered (in USB1.0).
       * Bit 6=0 Indicates that the device is bus powered (in USB1.1).
       * Bit 5=0 Device doesnt support remote wakeup feature.
       * Bit 4 to 0 set 0
       */
      Config->bmAttributes = 0x80;
      Config->MaxPower = USBPOWER; /*How much bus current the device requires*/
      break;
    case 1:
      Config->bNumInterfaces = 1;
      Config->iConfiguration = 0;
      Config->bmAttributes = 0x80;
      Config->MaxPower = USBPOWER; 
  }
   
  Config->oInterfaces = (USBinterface *)
              malloc(sizeof(__interface_t) * Config->bNumInterfaces);
   
  for(j = 0; j < Config->bNumInterfaces; j++)
    Config->wTotalLength += writeInterfaceDescriptor(Config->oInterfaces, i,j);   
}

/**
 * writeDeviceDescriptor
 *
 * Device descriptor contains basic information about the device. This is the 
 * first descriptor that the host reads after the attachment, and uses this to 
 * retrieve additional information.
 *
 * Device.bcdUSB = 0x0110;	USB Spec and Release number. version 1.1 = 0x0110 
 * Device.bMaxPacketSize0 = 16;	Max Packet size of EndPoint 0,
 * Device.idVendor = 0x042b;	Vendor Specific
 * Device.idProduct = 0x1337;	Vendor Specific
 * Device.bcdDevice = 0x0312;	Vendor Specific
 * Device.iManufacturer = 1;	Index of String Descriptor for Manufacturer 
 * Device.iProduct = 2;		Index of String Descriptor for Product
 * Device.iSerialNumber = 3;	Index of String Descriptor for SerialNumber
 * Device.bNumConfigurations = 2;	Number of Configurations.
 * 
 */
void writeDeviceDescriptor()
{
  uint8_t i;
  //atomic
  {
    Device.bcdUSB = 0x0110;
    Device.bDeviceClass = Device.bDeviceSubclass = Device.bDeviceProtocol = 0;
    Device.bMaxPacketSize0 = 16;
    Device.idVendor = 0x042b;
    Device.idProduct = 0x1337;
    Device.bcdDevice = 0x0312;
    Device.iManufacturer = 1;
    Device.iProduct = 2;
    Device.iSerialNumber = 3;
    Device.bNumConfigurations = 2;
    Device.oConfigurations = (USBconfiguration *) 
    malloc(sizeof(__configuration_t) * Device.bNumConfigurations);
  }
  for(i = 0; i < Device.bNumConfigurations; i++)
    writeConfigurationDescriptor(Device.oConfigurations, i);
}

/**
 * clearDescriptors
 *
 * Utility function for cleaning up the memory allocated for the Device,
 * Configuration, Interface, Endpoint descriptors. It is a good practice
 * to call this function either before leaving the bootloader as a part
 * of self cleaning process or before aborting USB Communication after
 * an error condition.
 *
 */
void clearDescriptors()
{
  uint8_t i, j, k;
  for(i = 0; i < Device.bNumConfigurations; i++)
  {
    for(j = 0; j < Device.oConfigurations[i]->bNumInterfaces; j++)
    {
      for(k = 0; k < Device.oConfigurations[i]->oInterfaces[j]->bNumEndpoints; k++)
        free(Device.oConfigurations[i]->oInterfaces[j]->oEndpoints[k]);
      free(Device.oConfigurations[i]->oInterfaces[j]->oEndpoints);
      free(Device.oConfigurations[i]->oInterfaces[j]);
    }
    free(Device.oConfigurations[i]->oInterfaces);
    free(Device.oConfigurations[i]);
  }
  free(Device.oConfigurations);
  for(i = 0; i < STRINGS_USED + 1; i++)
  {
    if(i == 3)//serial num, special freeing mentioned in writeStringDescriptor
      free(Strings[i]->uMisc.bString);
    free(Strings[i]);
  }
  free(HidReport.bString);
}

/**
 * clearIn
 *
 * Clear the output queue and free the USBdata stream. A good housekeeping
 * mechanism which could be called when ever the queue has to be cleaned.
 * 
 */
void clearIn()
{
  DynQueue QueueTemp;
  QueueTemp = InQueue;
  {
    while (DynQueue_getLength(QueueTemp) > 0)
    {
      uint8_t temp;
      InState = (USBdata)DynQueue_dequeue(QueueTemp);
      temp = ((uint32_t)InState->param == IMOTE_HID_REPORT);
      clearUSBdata(InState, temp);
    }
    InState = NULL;
    InTask = 0;
  }
}

/**
 * clearUSBdata
 *
 *
 */
void clearUSBdata (USBdata Stream, uint8_t isConst)
{
  if(isConst == 0)
    free(Stream->src);
  Stream->src = NULL;
  free(Stream);
  Stream = NULL;
}
 
/**
 * clearOut
 *
 * Clear Input Queue.
 */
void clearOut()
{
  uint8_t i;
  //atomic
  {
    for(i = 0; i < IMOTE_HID_TYPE_COUNT; i++)
    {
      free(OutStream[i].src);
      OutStream[i].endpointDR = NULL;
      OutStream[i].src = NULL;
      OutStream[i].status = 0;
      OutStream[i].type = 0;
      OutStream[i].index = 0;
      OutStream[i].n = 0;
      OutStream[i].len = 0;
    }
  }
}

void clearOutQueue()
{
  while(DynQueue_getLength(OutQueue) > 0)
    free((uint8_t *)DynQueue_dequeue(OutQueue));
} 
