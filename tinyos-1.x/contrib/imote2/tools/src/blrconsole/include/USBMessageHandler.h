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
 * @file USBMessageHandler.h
 * @author Junaith Ahemed Shahabdeen
 *
 * This file provides a higher level USB Message
 * parser and assembler. The message from the
 * USB driver is identified by its message type
 * and the required modules are invoked based on
 * the type.
 */
#ifndef USB_MESSAGE_HANDLER_H
#define USB_MESSAGE_HANDLER_H

#include <MessageDefines.h>

/**
 * Command_Packet_Received
 *
 * The function is signalled when a command packet is received
 * from the device. The function parses the USB payload
 * to determine the command type and calls the required module
 * based on the type.
 * 
 * @param data USB Payload.
 *
 * @return SUCCESS | FAIL
 */
result_t Command_Packet_Received (char* data);

/**
 * Error_Packet_Received
 *
 * Received an error from the Device.
 *
 * @param data  Valid usb data.
 * @return SUCCESS | FAIL
 */
result_t Error_Packet_Received (uint8_t* data);


/**
 * Binary_Packet_Received
 *
 * Binary data received from the mote. Currently the mote sends
 * a binary packet only when the pc requests a flash dump or a
 * buffer dump.
 *
 * @param data Binary data from the mote.
 * @param length Length of the data.
 * @param seq Sequence number from the packet.
 */
result_t Binary_Packet_Received (char* data, uint8_t length, uint32_t seq);

/**
 * Dump_From_Flash
 *
 * Request a data chunk from the flash, the length of the
 * chunk and the flash address is passed as parameter to
 * the function. This function basically triggers a request
 * response cycle between the MOTE and the PC Application till
 * the entire chunk is downloaded.
 *
 * @param addr Start address of the chunk in flash.
 * @param length The size of the chunk.
 *
 * @return SUCCESS | FAIL
 */
result_t Dump_From_Flash (uint32_t addr, uint32_t length);

/**
 * Get_Buffer_Dump
 *
 * The function requests the next packet from the IMote during
 * flash dump mode. The process continues till the window size
 * and is trigerred by the <I>Dump_From_Flash</I> function
 * for the next buffer.
 *
 * @return SUCESS | FAIL
 */
result_t Get_Buffer_Dump ();

/**
 * Send_USB_Command
 *
 * Send a command message to the Mote.
 *
 * @param cmd Command struct with appropriate data defined in MessageDefines.h.
 * @param length Length of the command data.
 *
 * @return SUCCESS | FAIL
 */
result_t Send_USB_Command (USBCommand* cmd, uint32_t Length);


/**
 * Send_USB_Command_Packet
 *
 * Send a command message to the Mote.
 *
 * @param cmd Command type defined in the enum (see MessageDefines.h).
 * @param clen Length of the command data.
 * @param cdata Command data in array format.
 *
 * @return SUCCESS | FAIL
 */
result_t Send_USB_Command_Packet (Commands cmd, uint8_t clen, void* cdata);

/**
 * Send_Binary_Data
 *
 * Send a binary buffer to the device. Usually binary data is prepended
 * with the sequence number of the packet the final packet will
 * have a sequence number of 0. JT Protocol requires a header with the
 * valid bytes in the packet if the seqence number is 0, this allows
 * the pc host to send less than IMOTE_HID_TYPE_L_SHORT in the last
 * packet if required.
 *
 * @param buff Pointer to the binary buffer.
 * @param length Length of the buffer.
 * @param seq Current Sequence number of the buffer.
 *
 * @return SUCCESS | FAIL
 */
result_t Send_Binary_Data (uint8_t* buff, uint32_t Length, uint16_t seq);

/**
 * Send_USB_Binary_Data
 *
 * The function allows the user to send binary data packed in
 * a structure.
 *
 * @param img The struct which contains binary data.
 * @param length length of the struct with data.
 * 
 * @return SUCCESS | FAIL
 */
result_t Send_USB_Binary_Data (USBImagePck* img, uint32_t Length);

//#ifdef DEBUG
/**
 * Dbg_Binary_Code_Upload
 *
 * Function used in the -tp option to send the
 * image detail command to the device.
 *
 * @return SUCCESS | FAIL
 */
result_t Dbg_Binary_Code_Upload ();
//#endif
	
#endif
