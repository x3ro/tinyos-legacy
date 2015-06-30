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

/* 
 * @file:	PXA27XUSBdata.h
 * @author:		Josh Herbach
 * Revision:	1.0
 * Date:		09/02/2005
 */

#ifndef __PXA27XUSBDATA_H
#define __PXA27XUSBDATA_H

#include <types.h>

typedef struct __USBdata
{
  volatile unsigned long *endpointDR;
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
} USBdata_t;
typedef USBdata_t * USBdata;

union string_or_langid
{
  uint16_t wLANGID;
  char *bString;
};

typedef struct __hid
{
  uint16_t bcdHID;
  uint16_t wDescriptorLength;  
  uint8_t bCountryCode;
  uint8_t bNumDescriptors;
  uint8_t bDescriptorType;
} USBhid;

typedef struct __hidreport
{
	uint16_t wLength;
	uint8_t *bString;
} USBhidReport;

typedef struct __string
{
  uint8_t bLength;
  union string_or_langid uMisc;
} __string_t;

typedef __string_t *USBstring;


typedef struct __endpoint
{
  uint8_t bEndpointAddress;
  uint8_t bmAttributes;
  uint16_t wMaxPacketSize;
  uint8_t bInterval;
} __endpoint_t;
typedef __endpoint_t *USBendpoint;


typedef struct __interface
{
  uint8_t bInterfaceID;
  uint8_t bAlternateSetting;
  uint8_t bNumEndpoints;
  uint8_t bInterfaceClass;
  uint8_t bInterfaceSubclass;
  uint8_t bInterfaceProtocol;
  uint8_t iInterface;
  USBendpoint *oEndpoints;
} __interface_t;
typedef __interface_t *USBinterface;

typedef struct __configuration
{
  uint16_t wTotalLength;
  uint8_t bNumInterfaces;
  uint8_t bConfigurationID;
  uint8_t iConfiguration;
  uint8_t bmAttributes;
  uint8_t MaxPower;
  USBinterface *oInterfaces;
} __configuration_t;
typedef __configuration_t *USBconfiguration;

typedef struct __device
{
  uint16_t bcdUSB;
  uint8_t bDeviceClass;
  uint8_t bDeviceSubclass;
  uint8_t bDeviceProtocol;
  uint8_t bMaxPacketSize0;
  uint16_t idVendor;
  uint16_t idProduct;
  uint16_t bcdDevice;
  uint8_t iManufacturer;
  uint8_t iProduct;
  uint8_t iSerialNumber;
  uint8_t bNumConfigurations;
  USBconfiguration *oConfigurations;
} USBdevice;

#endif
