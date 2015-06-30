#include "usb.h"
#include "usbhid.h"
#include "trace.h"
#include "stdlib.h"
#include "assert.h"
#include "string.h"

/*
 * The send*Descriptor functions convert the data initialized in the 
 * write*Descriptor functions into the data streams that are to be sent, and
 * then queues those data streams.
 */
void sendStringDescriptor(uint8_t id, uint16_t wLength);
void sendDeviceDescriptor(uint16_t wLength);
void sendConfigDescriptor(uint8_t id, uint16_t wLength);


extern USBConfiguration_t USBHIDConfiguration;

//an array of pointers to configration structures.  Currently our only support configuration is the HIDConfiguration
USBConfiguration_t *USBConfigurations[] = {&USBHIDConfiguration}; 

//USBDevice structure...the first entry is the device descriptor itself followed by an array of pointers to configurations
USBDevice_t USBDevice = {{ 18,                      //blength,
			   USB_DESCRIPTOR_DEVICE,   //bDescriptorType DEVICE
			   0x0110,                  //bcdUSB
			   0,                       //bDeviceClass
			   0,                       //bDeviceSubclass
			   0,                       //bDeviceProtocol
			   16,                      //bMaxPacketSize0
			   0x042b,                  //idVendor
			   0x1337,                  //idProduct
			   0x0312,                  //bcdDevice
			   1,                       //iManufacturer
			   2,                       //iProduct
			   3,                       //iSerialNumber
			   1},                      //bNumConfigurations
			 USBConfigurations};
  
//our strings
static const char string1[] = "SNO";  
static const char string2[] = "Intel Mote 2 Embedded Device";
static char string3[9]; 

//our string descriptors.
static const USBStringDescriptor_t stringDescriptor0 = {0x4,                       //bLength
							USB_DESCRIPTOR_STRING,     //bDescriptorType
							{.wLANGID = 0x0409}};      //wLANGID

static const USBStringDescriptor_t stringDescriptor1 = {0x4 + sizeof(string1),     //bLength
							USB_DESCRIPTOR_STRING,     //bDescriptorType
							{.bString = string1}};                  //bString

static const USBStringDescriptor_t stringDescriptor2 = {0x4 + sizeof(string2),     //bLength
							USB_DESCRIPTOR_STRING,     //bDescriptorType
							{.bString = string2}};                  //bString

static const USBStringDescriptor_t stringDescriptor3 = {0x4 + sizeof(string3),     //bLength
							USB_DESCRIPTOR_STRING,     //bDescriptorType
							{.bString = string3}};                  //bString
  
static const USBStringDescriptor_t *USBStringDescriptors[] = {&stringDescriptor0,
							      &stringDescriptor1,
							      &stringDescriptor2,
							      &stringDescriptor3};

void initializeUSBStack(){
  sprintf(string3, "%x", *((uint32_t *)0x01FE0000));
#ifdef ENABLE_USBHID
  initializeUSBHIDStack();
#endif
}

					       
USBDevice_t *getUSBDevice(){
  return &USBDevice;
}

static const USBStringDescriptor_t *getUSBStringDescriptor(uint8_t id){
  
  if(id < 4){
    return USBStringDescriptors[id];
  }
  return NULL;
}

void handleControlSetupStage(USBSetupData_t *pUSBSetupData){
      
  switch((pUSBSetupData->bmRequestType >> 5) & 0x3){
  case 0x00:
    //USB Standard requests
    switch(pUSBSetupData->bRequest){
    case USB_GETDESCRIPTOR:
      //the upper byte of wValue defines the type of descriptor being requested
      //bit decoding
      //  7 = 0
      //6-5 = type :  0 = standard, 1 = class, 2 = Vendor, 3 = Reserved
      //4-0 = descriptor index.  This is either an index for the standard descriptor or a vendor/class specific one
      switch((pUSBSetupData->wValue)>>8){
      case USB_DESCRIPTOR_DEVICE:
	sendDeviceDescriptor(pUSBSetupData->wLength);
	break;
      case USB_DESCRIPTOR_CONFIGURATION:
	sendConfigDescriptor(pUSBSetupData->wValue & 0xFF,pUSBSetupData->wLength);
	break;
      case USB_DESCRIPTOR_STRING:
	sendStringDescriptor(pUSBSetupData->wValue & 0xFF,pUSBSetupData->wLength);
	break;
#ifdef ENABLE_USBHID
      case USB_DESCRIPTOR_HID_REPORT:
	sendHidReportDescriptor(pUSBSetupData->wLength);
	break;
#endif
      default:
	//trace(DBG_USR1,"Unrecognized Descriptor request\r\n");
	//	 /*atomic*/ UDCCSR0 |= _UDC_bit(UDCCSR0_FST);
	break;
      }
      break;
    case USB_SETCONFIGURATION:
#if DEBUG
      trace(DBG_USR1,"USB_SETCONFIGURATION\r\n");
#endif
      USBHAL_enableConfiguration(pUSBSetupData->wValue);
      break;
    default:
      trace(DBG_USR1,"ERROR:  USBClient received an unknown bmRequestType = %#x bRequest = %#x\r\n",
	    pUSBSetupData->bmRequestType,
	    pUSBSetupData->bRequest);
      //UDCCSR0 = UDCCSR0_FST;
	
      break;
    }
    break;
#ifdef ENABLE_USBHID  //NOTE..the location of this #ifdef will depend on the number of interfaces defined!!!
  case 0x01:
    if(USBHIDhandleGetDescriptor(pUSBSetupData) == 0){
      trace(DBG_USR1,"ERROR:  USBClient received an unknown bmRequestType = %#x bRequest = %#x\r\n",
	    pUSBSetupData->bmRequestType,
	    pUSBSetupData->bRequest);
      USBHAL_sendStall();
    }
    break;
#endif
  default:
    trace(DBG_USR1,"ERROR:  USBClient received an unknown bmRequestType = %#x bRequest = %#x\r\n",
	  pUSBSetupData->bmRequestType,
	  pUSBSetupData->bRequest);
    USBHAL_sendStall();
	
  }
}


void sendDeviceDescriptor(uint16_t wLength){
  USBData_t *pUSBData;
  USBDevice_t *pUSBDevice = getUSBDevice();
    
#if DEBUG_DESCRIPTOR
  trace(DBG_USR1,"Sending device descriptor;\r\n");
#endif
  if(wLength == 0)
    return;

  pUSBData = malloc(sizeof(*pUSBData));
  if(pUSBData == NULL){
    trace(DBG_USR1,"ERROR:  USBClient.SendDeviceDescriptor unable to allocate memory\r\n");
    return;
  }
   
  pUSBData->endpointDR = 0;
  pUSBData->fifosize = 16;
  pUSBData->src = malloc(pUSBDevice->deviceDescriptor.bLength);
    
  if(pUSBData->src == NULL){
    trace(DBG_USR1,"ERROR:  USBClient.sendDeviceDescriptor unable to allocate memory for data\r\n");
    free(pUSBData);
    return;
  }
    
  memcpy(pUSBData->src, (uint8_t*)&(pUSBDevice->deviceDescriptor), pUSBDevice->deviceDescriptor.bLength);
  pUSBData->len = (wLength < pUSBDevice->deviceDescriptor.bLength) ? wLength:pUSBDevice->deviceDescriptor.bLength;
  pUSBData->index = 0;
  pUSBData->param = 0;

  USBHAL_sendControlDataToHost(pUSBData);
}

void sendConfigDescriptor(uint8_t id, uint16_t wLength){
    
  USBData_t *pUSBData;
  USBConfiguration_t *pConfig;
  USBInterface_t *pInterface;
  uint32_t offset = 0;
  int interfaces, endpoints;
  USBDevice_t *pUSBDevice = getUSBDevice();
#if DEBUG_DESCRIPTOR   
  trace(DBG_USR1,"SendConfigDescriptor w/ID=%#x\r\n", id);
#endif
   
  if(wLength == 0){
    return;
  }
    
  pUSBData = malloc(sizeof(*pUSBData));
  if(pUSBData == NULL){
    trace(DBG_USR1,"ERROR:  USBClient.sendConfigDescriptor unable to allocate memory\r\n");
    return;
  }
    
  pConfig = (pUSBDevice->pUSBConfigurations[id]);
    
  pUSBData->endpointDR = 0;
  pUSBData->fifosize = 16;
  pUSBData->src = (uint8_t*)malloc(pConfig->configurationDescriptor.wTotalLength);  //allocate memory for the total size of this configuration
  //length is the amount of data that we'll be sending now
  if(pUSBData->src == NULL){
    trace(DBG_USR1,"ERROR:  USBClient.sendConfigDescriptor unable to allocate memory for data\r\n");
    free(pUSBData);
    return;
  }
  pUSBData->len = (wLength < pConfig->configurationDescriptor.wTotalLength) ? wLength:pConfig->configurationDescriptor.wTotalLength;
  pUSBData->index = 0;
  pUSBData->param = 0;
       
  memcpy(pUSBData->src, &(pConfig->configurationDescriptor), pConfig->configurationDescriptor.bLength);
  offset = pConfig->configurationDescriptor.bLength;
  //copy the configuration's interfaces into place
  for(interfaces = 0; interfaces < pConfig->configurationDescriptor.bNumInterfaces; interfaces++){
    //make sure that we don't corrupt memory
    pInterface = pConfig->pUSBInterfaces[interfaces];
      
    //make sure that we don't corrupt memory
    assert( (offset + pInterface->interfaceDescriptor.bLength) <= pConfig->configurationDescriptor.wTotalLength);
    memcpy((pUSBData->src)+offset, &(pInterface->interfaceDescriptor), pInterface->interfaceDescriptor.bLength);
    offset += pInterface->interfaceDescriptor.bLength;
      
    if(pInterface->pClassDescriptor != NULL){
      //an option additional class desccriptor is present...copy it in
      assert( (offset + pInterface->pClassDescriptor[0]) <= pConfig->configurationDescriptor.wTotalLength);
      memcpy((pUSBData->src)+offset, &(pInterface->pClassDescriptor[0]), pInterface->pClassDescriptor[0]);
      offset += pInterface->pClassDescriptor[0];
    }
      
    //copy the interface's endpoints into place
    for(endpoints = 0; endpoints < pInterface->interfaceDescriptor.bNumEndpoints; endpoints++){
	
      assert( (offset + pInterface->pEndpointDescriptors[endpoints].bLength) <= pConfig->configurationDescriptor.wTotalLength);
      memcpy((pUSBData->src)+offset, &(pInterface->pEndpointDescriptors[endpoints]), pInterface->pEndpointDescriptors[endpoints].bLength);
      offset += pInterface->pEndpointDescriptors[endpoints].bLength;
    }
  }
  
  USBHAL_sendControlDataToHost(pUSBData);
}
void sendStringDescriptor(uint8_t id, uint16_t wLength){
       
  USBData_t *pUSBData;
  const USBStringDescriptor_t *pString;

#if DEBUG_DESCRIPTOR
  trace(DBG_USR1,"Sending string descriptor; ID: %x\r\n", id);
#endif
    
  pString = getUSBStringDescriptor(id);
    
  if(pString==NULL){
    trace(DBG_USR1,"ERROR:  USBClient.sendStringDescriptor could not find descriptor for id = %#x\r\n",id);
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
        
  //NOTE:  all of this is necessary due to wchar_t being defined as 32 bits on this platform instead of 16
  // since this might be the case in general, we will do this brute force since this happens only a couple
  // of times when the device is enumerated (which is extremely infrequent)
  if(id == 0){
    pUSBData->src = malloc(pString->bLength);
    if(pUSBData->src == NULL){
      trace(DBG_USR1,"ERROR:  USBClient.sendStringDescriptor unable to allocate memory for data\r\n");
      free(pUSBData);
      return;
    }
      
    pUSBData->len = (wLength < (pString->bLength)) ? wLength:(pString->bLength);
    memcpy(pUSBData->src, (uint8_t*)(pString), 2);
    memcpy(pUSBData->src + 2, (uint8_t*)&(pString->uMisc.wLANGID), 2);
  }
  else{
    int i, len;
    uint8_t *pData;
    len = strlen(pString->uMisc.bString);
      
    pUSBData->len = (wLength < (2*len + 2)) ? wLength:(2*len + 2);
      
    pUSBData->src = malloc(2*len + 2);
    if(pUSBData->src == NULL){
      trace(DBG_USR1,"ERROR:  USBClient.sendStringDescriptor unable to allocate memory for data\r\n");
      free(pUSBData);
      return;
    }
    pData = pUSBData->src + 2;
    pUSBData->src[0] = 2*len + 2;
    pUSBData->src[1] = pString->bDescriptorType; 
    for(i=0; i<len; i++){
      pData[2*i] = pString->uMisc.bString[i];
      pData[2*i + 1] = 0;
    }
  }
    
  pUSBData->index = 0;
  pUSBData->param = 0;
    
  USBHAL_sendControlDataToHost(pUSBData);
}
