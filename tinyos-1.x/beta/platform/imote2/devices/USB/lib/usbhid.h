/* 
  * Authors:		Robbie Adler
  *                     Josh Herbach
  * Revision:	1.1
  * Last update:	05/02/2005
  * 
  */

#ifndef __USBHID_H__
#define __USBHID_H__

#include "inttypes.h"

// USB control Setup request, Hid

#define USB_HID_GETREPORT 0x01
#define USB_HID_GETIDLE 0x02
#define USB_HID_GETPROTOCOL 0x03
#define USB_HID_SETREPORT 0x09
#define USB_HID_SETIDLE 0x0A
#define USB_HID_SETPROTOCOL 0x0B


// USB Descriptors
#define USB_DESCRIPTOR_HID 0x21
#define USB_DESCRIPTOR_HID_REPORT 0x22


typedef struct USBHIDDescriptor{
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint16_t bcdHID;
  uint8_t bCountryCode;
  uint8_t bNumDescriptors;
  uint8_t bDescriptorTypeClass;
  uint16_t wDescriptorLength;  
} USBHIDDescriptor_t;

typedef struct USBHIDReportDescriptor{
  uint8_t bLength;
  uint8_t bString[];
} USBHIDReportDescriptor_t;


/******************
FUNCTION PROTOTYPES
******************/
void initializeUSBHIDStack();

/*
 * During enumeration, this function handles the hid specific get descriptor requests
 * that can potentially be received from the host.  It return 1 if it handles the request
 * and 0 otherwise.  It is passed a pointer to the 8 byte USBSetupData_t structure that
 * is received from the host
 */
int USBHIDhandleGetDescriptor(USBSetupData_t *pUSBSetupData);

/*
 * Once the device has been enumerated, sendReport is used to take data and
 * convert it into a queuable structure for sending. data is a pointer to the
 * buffer to be sent; datalen is the length of that buffer in bytes, type
 * is the type as specified in the JT protocol, and source is either 
 * SENDVARLENPACKET, SENDJTPACKET or SENDBAREMSG, depending on the 
 * interface used to send the data.
 */
int sendReport(uint8_t *data, uint32_t datalen, uint8_t type, uint8_t source, uint8_t channel);

/*
 * The send*Descriptor functions convert the descriptor in question into a data packet
 * that can be sent to the host.  
 */

void sendHidReportDescriptor(uint16_t wLength);


/*********************
 *CALLBACK FUNCTIONS
 * these functions must be implemented by the upper layer application or module that
 * is using the HID library.
 *********************/

//function that is called when data is received through the HID interface.
//this function is called synchronously
void USBHIDReceive(USBData_t *pUSBData, uint8_t numBytes);

//function that is called when send to the host using SendReport has finished being sent
//this function is called synchronously
void USBHIDSendReportDone(USBData_t *pUSBData);



#endif //__USBHID_H__
