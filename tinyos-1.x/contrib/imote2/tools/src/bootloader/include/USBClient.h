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
 * @file USBClient.h
 * @author
 *
 * ported from tinyos repository - junaith
 */
#ifndef USB_CLIENT_H
#define USB_CLIENT_H

#include <PXA27XUSBdata.h>
#include <PXA27XUSBClient.h>
#include <PXA27Xdynqueue.h>


/**
 * MAX bytes in a USB Hid report.
 */
#define USB_MAX_PACKET_SIZE 0x40

/*In and Out follow USB specifications.
  IN = Device->Host, OUT = Host->Device*/

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
result_t Prepare_Buffer_Download (uint32_t pckrcv, uint32_t pckexp);

void DMA_Done ();

/**
 * USBInit
 *
 * Initialize the USB Client in the processor for communication.
 * 
 * @return SUCCESS | FAIL
 */
result_t USB_Init();

/**
 * USB_Stop
 *
 * Stop the USB interface, disable the interrupts and
 * GPIO's.
 * 
 * @return SUCCESS | FAIL
 */
result_t USB_Stop ();

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
result_t USBMsg_Send (uint8_t* data, uint32_t numBytes, uint8_t type);

/*
 * The various write*Descriptor functions are used to initialize data for
 * USB enumeration and use
 */
void writeStringDescriptor();

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
void writeHidDescriptor();

/**
 * writeStringDescriptor
 *
 * String descriptor used to describe the Manufacturer, Product, SerialNumber
 * of the device. (used in Device Descriptor).
 */
void writeHidReportDescriptor();

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
void writeEndpointDescriptor(USBendpoint *endpoints, 
		uint8_t config, 
		uint8_t inter, 
		uint8_t i);

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
uint16_t writeInterfaceDescriptor(USBinterface *interfaces, 
		uint8_t config, 
		uint8_t i);

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
void writeConfigurationDescriptor(USBconfiguration *configs, uint8_t i);


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
void writeDeviceDescriptor();
  
/**
 * clearDescriptors
 * 
 * clearDescriptors is a function to clean up all the memory used in 
 * initializing the USB descriptors in the various write*Descriptor 
 * functions.
 */
void clearDescriptors();
  
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
void sendStringDescriptor(uint8_t id, uint16_t wLength);

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
void sendDeviceDescriptor(uint16_t wLength);

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
void sendConfigDescriptor(uint8_t id, uint16_t wLength);


void sendHidReportDescriptor(uint16_t wLength);
  
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
void sendReport(uint8_t *data, uint32_t datalen, uint8_t type, uint8_t source);
  
/**
 * sendIn
 * 
 * The sendIn() task prepends the necessary JT protocol information and
 * for a packet that has been queued and then handles sending it.
 */
void sendIn();
  
/**
 * sendControlIn
 * 
 * sendControlIn handles sending a queued control message.
 */  
void sendControlIn();
  
/*
 * clearIn() clears the queue of data to be sent to the host PC. 
 * clearUSBdata() is a helper function
 */ 
void clearIn();
void clearUSBdata(USBdata Stream, uint8_t isConst);

//result_t Post_Process_Out (DynQueue OutQ);
//result_t Post_Bin_Process_Out ();
//result_t Post_Send_In (DynQueue OutQ);


/**
 * processOut
 * 
 * The processOut() task handles converting data received from the host PC
 * in JT format into regular data.
 */
void processOut();


//void processOut_Binary ();
  
/**
 * retrieveOut
 * 
 * retrieveOut() queues JT data that has been received from the host PC
 * for translating into regular data.
 */
void retrieveOut();
  
/**
 * clearOut
 * 
 * clearOut() is a helper function that clears the data structure for the 
 * current packet of received data. 
 */ 
void clearOut();
  
/**
 * clearOutQueue
 * 
 * clearOutQueue wipes the queue of data received from the PC waiting to 
 * be processed
 */
void clearOutQueue();
  
/**
 * handleControlSetup
 *
 * handleControlSetup() processes setup requests from the host PC.
 */
void handleControlSetup();
  
/**
 * isAttached
 *
 * isAttached() checks if the mote is attached over USB to a power source
 * (assumed to be a host PC).
 */
void isAttached();

/**
 * USB_GPIO_Interrpt_Fired
 * 
 * Interrupt from the GPIO Pin.
 */
void USB_GPIO_Interrpt_Fired();

/**
 * HPLUSBClientGPIO_Init
 *
 * Initialize the required GPIO pins during USB initalization.
 *
 * @return SUCCESS 
 */
result_t HPLUSBClientGPIO_Init();

/**
 * HPLUSBClientGPIO_Stop
 *
 * Disable the USBC_GPIOX_EN GPIO pin.
 */
result_t HPLUSBClientGPIO_Stop();

/**
 * HPLUSBClientGPIO_CheckConnection
 *
 * The function checks to see if the USB GPIO pin
 * is enabled and returns a boolean result.
 * 
 * @return SUCCESS | FAIL
 */
result_t HPLUSBClientGPIO_CheckConnection();

/**
 * USBInterrupt_Fired
 *
 * This function is the interrupt handler for the USB Client interface.
 * It performs the required checks to see where the interrupt
 * originated and sinals the appropriate higher level modules based
 * on the current context.
 *
 */
void USBInterrupt_Fired ();

#endif
