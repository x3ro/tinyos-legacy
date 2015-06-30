/* 
  * Author:		Josh Herbach
  * Revision:	1.0
  * Date:		09/02/2005
  */
#ifndef __PXA27XUSBCLIENT_H__
#define __PXA27XUSBCLIENT_H__

#define USBPOWER 125 // 1/2 of the actually requested power, so 250 ma

#define _PXAREG8(_addr)	(*((volatile uint8_t *)(_addr)))
#define _PXAREG16(_addr)	(*((volatile uint16_t *)(_addr)))

#define _UDC_bit(_udc)  (1 << ((_udc) & 0x1f))


#define USB_ENDPOINT_IN 7

// These define offsets within certain register bitmaps

//States, defined as full numbers, not flags
//0 is nothing
#define POWERED 1 //means attached and powered by the USB host
#define DEFAULT 2 //finished resetting
#define CONFIGURED 3 //ready to be used for communication

#define isFlagged(_BITFIELD, _FLAG) (((_BITFIELD) & (_FLAG)) != 0)
#define getByte(_WORD, _BYTE) ((((_WORD) >> (((_BYTE) & 0x03) * 8))) & 0xFF)
#define getBit(_BITFIELD, _BIT) (((_BITFIELD) >> ((_BIT) & 0x1F)) & 0x01)

#define STRINGS_USED 3

//Interfaces used
#define SENDVARLENPACKET 0
#define SENDJTPACKET 1
#define SENDBAREMSG 2


/*JT protocol numbers; NOTE: some of the constants 
are different between the client (mote) and host (pc) software (namely, 
the byte positions)*/

#define IMOTE_HID_REPORT 1
#define IMOTE_HID_TYPE_COUNT 4

//Imote2 HID report, byte positions
#define IMOTE_HID_TYPE 0
#define IMOTE_HID_NI 1
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
#define IMOTE_HID_TYPE_L_INT_SIZE 0xFFFFFFFF
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
 * FIXME Currently the driver will not push the
 * MSC types to the right bits, so its easier to
 * set the right bits to start with. 
 * NOTE this value is not the same in PC App but the
 * result is the same.
 */
#define IMOTE_HID_TYPE_MSC_REBOOT 64
#define IMOTE_HID_TYPE_MSC_COMMAND 96
#define IMOTE_HID_TYPE_MSC_BINARY 128
#define IMOTE_HID_TYPE_MSC_ERROR 160

//Imote2 HID report, max packet data sizes
#define IMOTE_HID_BYTE_MAXPACKETDATA 62
#define IMOTE_HID_SHORT_MAXPACKETDATA 61
#define IMOTE_HID_INT_MAXPACKETDATA 59

#endif
