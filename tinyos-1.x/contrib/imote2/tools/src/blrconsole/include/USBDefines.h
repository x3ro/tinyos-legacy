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

#ifndef USB_DEFINES_H
#define USB_DEFINES_H

#include <wtypes.h>

typedef struct USBdata{
	BYTE *data;
	DWORD i;
	DWORD n;
	BYTE type;
	DWORD len;
} USBdata;


#define isFlagged(_BITFIELD, _FLAG) (((_BITFIELD) & (_FLAG)) != 0)
#define _BIT(_bit) (1 << ((_bit) & 0x1f))

#define IMOTE_HID_TYPE_COUNT 4

//Imote2 HID report, byte positions
#define IMOTE_HID_TYPE 1
#define IMOTE_HID_NI 2

//Imote2 HID report, type byte,  bit positions
#define IMOTE_HID_TYPE_CL 0
#define IMOTE_HID_TYPE_L 2
#define IMOTE_HID_TYPE_H 4
#define IMOTE_HID_TYPE_MSC 5

//Imote2 HID report, type byte, L defintions
#define IMOTE_HID_TYPE_L_BYTE 0
#define IMOTE_HID_TYPE_L_SHORT 1
#define IMOTE_HID_TYPE_L_INT 2

//Imote2 HID report, L sizes
#define IMOTE_HID_TYPE_L_BYTE_SIZE 15871
#define IMOTE_HID_TYPE_L_SHORT_SIZE 3997695
#define IMOTE_HID_TYPE_L_INT_SIZE ULONG_MAX

//Imote2 HID report, type byte, CL defintions
#define IMOTE_HID_TYPE_CL_GENERAL 0
#define IMOTE_HID_TYPE_CL_BINARY 1
#define IMOTE_HID_TYPE_CL_RPACKET 2
#define IMOTE_HID_TYPE_CL_BLUSH 3

//Imote2 HID report, type byte, MSC definitions
#define IMOTE_HID_TYPE_MSC_DEFAULT 0
#define IMOTE_HID_TYPE_MSC_BLOADER 1

/**
 * The types used by the boot loader extending
 * JT Protocol messages.
 */
#define IMOTE_HID_TYPE_MSC_REBOOT 2
#define IMOTE_HID_TYPE_MSC_COMMAND 3
#define IMOTE_HID_TYPE_MSC_BINARY 4
#define IMOTE_HID_TYPE_MSC_ERROR 5

//Imote2 HID report, max packet data sizes
#define IMOTE_HID_BYTE_MAXPACKETDATA 62
#define IMOTE_HID_SHORT_MAXPACKETDATA 61
#define IMOTE_HID_INT_MAXPACKETDATA 59

#define WM_RECEIVE_SERIAL_DATA (WM_USER + 1)
#define WM_RECEIVE_USB_DATA (WM_USER + 2)
#define WM_CLOSE_PORT (WM_USER + 3)

#endif
