/* 
  * Authors:		Robbie Adler
  *                     Josh Herbach
  * Revision:	1.0
  * Last Update:	05/03/2007
  */

#ifndef __USB_H__
#define __USB_H__

#include "inttypes.h"
#include "bufferManagement.h"

// USB control Setup request, Standard
#define DEBUG_CONTROL_ENDPOINT (0)
#define DEBUG_DESCRIPTOR (0)
#define DEBUG_INTERRUPT (0)
#define DEBUG (0)

#define USB_GETSTATUS           (0x00)
#define USB_CLEARFEATURE        (0x01)
#define USB_RESERVEDREQUEST2    (0x02)
#define USB_SETFEATURE          (0x03)
#define USB_RESERVEDREQUEST4    (0x04)
#define USB_SETADDRESS          (0x05)
#define USB_GETDESCRIPTOR       (0x06)
#define USB_SETDESCRIPTOR       (0x07)
#define USB_GETCONFIGURATION    (0x08)
#define USB_SETCONFIGURATION    (0x09)
#define USB_GETINTERFACE        (0x0A)
#define USB_SETINTERFACE        (0x0B)
#define USB_SYNCHFRAME          (0x0C)

// USB Descriptors
#define USB_DESCRIPTOR_DEVICE             (0x01)
#define USB_DESCRIPTOR_CONFIGURATION      (0x02)
#define USB_DESCRIPTOR_STRING             (0x03)
#define USB_DESCRIPTOR_INTERFACE          (0x04)
#define USB_DESCRIPTOR_ENDPOINT           (0x05)
#define USB_DESCRIPTOR_DEVICE_QUALIFIER   (0x06)
#define USB_DESCRIPTOR_OTHER_SPEED_CONFIG (0x07)
#define USB_DESCRIPTOR_INTERFACE_POWER    (0x08)


typedef struct __USBData{
  uint32_t endpointDR;
  uint32_t fifosize;
  uint8_t *src;
  uint32_t len;
  uint32_t tlen;
  uint32_t index;
  uint32_t pindex;
  uint32_t n;
  uint16_t status;
  uint8_t type;
  uint8_t source;
  uint8_t *param;
  uint8_t **packets;
  uint8_t channel;
} USBData_t;

union string_or_langid{
  uint16_t wLANGID;
  const char *bString;
};

typedef struct USBSetupData{
  uint8_t  bmRequestType;
  uint8_t  bRequest;
  uint16_t wValue;
  uint16_t wIndex;
  uint16_t wLength;
} __attribute__ ((packed)) USBSetupData_t;

typedef union USBSetupDataUnion{
  USBSetupData_t USBSetupData;
  uint32_t rawData[2];
} USBSetupDataUnion_t;

/*********************************
USB Standard Structure definitions
*********************************/

typedef struct USBStringDescriptor{
  uint8_t bLength;
  uint8_t bDescriptorType;
  union string_or_langid uMisc;
 } USBStringDescriptor_t;

typedef struct USBEndpointDescriptor{
  uint8_t  bLength;
  uint8_t  bDescriptorType;
  uint8_t  bEndpointAddress;
  uint8_t  bmAttributes;
  uint16_t wMaxPacketSize;
  uint8_t  bInterval;
} __attribute__ ((packed)) USBEndpointDescriptor_t; 

typedef struct USBInterfaceDescriptor{
  uint8_t  bLength;
  uint8_t  bDescriptorType;
  uint8_t  bInterfaceID;
  uint8_t  bAlternateSetting;
  uint8_t  bNumEndpoints;
  uint8_t  bInterfaceClass;
  uint8_t  bInterfaceSubclass;
  uint8_t  bInterfaceProtocol;
  uint8_t  iInterface;
} __attribute__ ((packed)) USBInterfaceDescriptor_t; 

typedef struct USBConfigurationDescriptor{
  uint8_t  bLength;
  uint8_t  bDescriptorType;
  uint16_t wTotalLength;
  uint8_t  bNumInterfaces;
  uint8_t  bConfigurationValue;
  uint8_t  iConfiguration;
  uint8_t  bmAttributes;
  uint8_t  MaxPower;
} __attribute__ ((packed)) USBConfigurationDescriptor_t; 

typedef struct USBDeviceDescriptor{
  uint8_t  bLength;
  uint8_t  bDescriptorType;
  uint16_t bcdUSB;
  uint8_t  bDeviceClass;
  uint8_t  bDeviceSubclass;
  uint8_t  bDeviceProtocol;
  uint8_t  bMaxPacketSize0;
  uint16_t idVendor;
  uint16_t idProduct;
  uint16_t bcdDevice;
  uint8_t  iManufacturer;
  uint8_t  iProduct;
  uint8_t  iSerialNumber;
  uint8_t  bNumConfigurations;
}  __attribute__ ((packed)) USBDeviceDescriptor_t;

/*******************************
USB Helper Structure definitions
*******************************/

//An interface consists of an interface descriptor and a pointer to an array of
//endpointDescriptor_t structures.  The number of entries in the pEndpointDescriptors
//array is equal to the bNumEndpoints field in the interfaceDescriptor

typedef struct USBInterface{
  USBInterfaceDescriptor_t interfaceDescriptor;
  uint8_t *pClassDescriptor;
  USBEndpointDescriptor_t *pEndpointDescriptors;
} __attribute__ ((packed)) USBInterface_t;

//A configuration consists of an configuration descriptor and a pointer to an array of
//USBInterface_t structures.  The number of entries in the pUSBInterfaces
//array is equal to the bNumInterfaces field in the configuration descriptor

typedef struct USBConfiguration{
  USBConfigurationDescriptor_t configurationDescriptor;
  USBInterface_t **pUSBInterfaces;
} __attribute__ ((packed)) USBConfiguration_t;

//A USBDevice consists of a USBDeviceDescriptor_t and a pointer to an array of
//USBConfiguration_t structures.  The number of entries in the pUSBConfigurations
//array is equal to the bNumConfigurations field in the device descriptor

typedef struct USBDevice{
  const USBDeviceDescriptor_t deviceDescriptor;
  USBConfiguration_t **pUSBConfigurations;
} USBDevice_t;

/******************
FUNCTION PROTOTYPES
******************/

/***************************************************************
 * Hardware Abstraction Layer callbacks
 *
 * the following function can be and are expected to be called by 
 * the HAL on the USB library
 ***************************************************************/

/*
 * getUSBDevice: return a pointer to the USBDevice.  
 *
 *
 * The USBDevice is basically a structurethat contains all of the device's descriptors
 *
 */
USBDevice_t *getUSBDevice();

/*
 * initializeUSBStack: initialize internal USB stack state and variables
 *
 *
 * This function must be called before the usb stack is used
 *
 */
void initializeUSBStack();

/*
 * SendDataToEndpointDone:  callback that indicates that the last data sent to the 
 * endpoint has been sent. 
 *
 * this function must be called synchronously and NOT in interrupt context by the HAL
 *
 */
void sendDataToEndpointDone(uint8_t endpoint);

/*
 * getNewBufferForEndpoint:  callback  tha retrieves a new buffer for use by the HAL
 *
 * The function can be called in Interrupt context. The pointer to the bufferInfo structure will 
 * be implicitly returned by the HAL in the receiveDataFromEndpoint function
 */
uint8_t* getNewBufferForEndpoint(uint8_t endpoint);

/*
 * getNewBufferInfoForEndpoint:  callback  tha retrieves a new buffer Info for use by the HAL
 *
 * The function can be called in Interrupt context.  The pointer to the bufferInfo structure will 
 * be implicitly returned by the HAL in the receiveDataFromEndpoint function
 */

bufferInfo_t *getNewBufferInfoForEndpoint(uint8_t endpoint);

/*
 * receiveDataFromEndpoint:  callback that indicates that new data has been received from the indicated
 * endpoint
 *
 * This function must be called synchronously and NOT in interrupt context by the HAL.
 */

void receiveDataFromEndpoint(uint8_t endpoint, bufferInfo_t *pBI);

/*
 * handleControlSetupStage:  callback that indicates that new control data has been received from
 * the host on the control endpoint
 *
 * This function must be called synchronously and NOT in interrupt context by the HAL.
 */
void handleControlSetupStage(USBSetupData_t *pUSBSetupData);

/*************************************************
 *  Hardware Abstraction Layer function prototypes
 ************************************************/

/*
 * USBHAL_enableConfiguration:  function that is called to enable a specific
 * configuration in response to a SETCONFIGURATION request from the host
 * 
 * The implementation of this function is device/hardware specific, but it is
 * intended to allow hardware that requires specific reconfiguration in response
 * to a SETCONFIGURATION request (such as the PXA27X usb client controller)
 *
 */
void USBHAL_enableConfiguration(uint8_t config);

/*
 * USBHAL_sendStall:  function that is called to send a stall on the USB
 * 
 * This function abstacts away the underlying hardwares ability to send a stall on the bus
 *
 */

void USBHAL_sendStall();

/*
 * USBHAL_isUSBConfigured:  function that is called to check the configured state of the 
 * usb client hardware
 * 
 * This function abstacts away the underlying hardware's configuration state
 * It is expected that the HAL take care of state tracking if the hardware can't
 * return information about the configured state
 */

int USBHAL_isUSBConfigured();

/*
 * USBHAL_sendDataToEndpoint:  function that is called to send data to specfic endpoint
 * 
 * This function abstacts away the underlying hardwares ability to send data to a given endpoint
 * It is up to the HAL layer to implement this function as necessary.  When this function completes
 * its job, it should call the sendDataToEndpointDone callback function.  It is recommended that
 * sendDataToEndpointDone not be called from sendDataToEndpoint
 *
 */

int USBHAL_sendDataToEndpoint(uint8_t endpoint, uint8_t *pData, uint32_t numBytes);

/*
 * USBHAL_sendControlDataToHost:  function that is called to send control packets/data to the Host
 * 
 * This function abstacts away the underlying hardwares ability to send data to endpoint 0(the dedicated 
 * control endpoint It is up to the HAL layer to implement this function as necessary.
 *
 */
void USBHAL_sendControlDataToHost(USBData_t *pUSBData);


#endif //__USB_H__
