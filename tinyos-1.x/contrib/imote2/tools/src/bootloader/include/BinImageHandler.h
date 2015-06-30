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
 * @file BinImageHandler.h
 * @author Junaith Ahemed Shahabdeen
 *
 * This file serves as a layer above the <I>USB driver</I> which 
 * receives a the USB Packet and parses the data part to
 * identify a command or binary data. The <B>boot loader state
 * machine</B> is directly controlled by this file based on the
 * current download context or error conditions.
 * 
 */
#ifndef BIN_IMAGE_HANDLER_H
#define BIN_IMAGE_HANDLER_H
#include <FlashAccess.h>
#include <USBClient.h>
#include <MessageDefines.h>

/**
 * Binary_Image_Packet_Received
 *
 * The function is a signal from the USB Driver when a binary 
 * data packet is received. The function stores the binary data in 
 * the RAM Buffer till the BIN_DATA_WINDOW_SIZE is reached. If the 
 * sequence number matches with the windown size then the function 
 * changes the <B>boot loader internal state</B> to <B>VERIFY_CURRENT_BUFFER</B>.
 * The state change indicates that the current buffer is completely
 * downloaded and the next command from the PC app (CRC Check) can 
 * be executed on the RAM Buffer.
 *
 * @param data   Data Payload of the USB Packet.
 * @parma length Length of the Payload.
 * @param seq    Sequence number of the packet.
 */
void Binary_Image_Packet_Received (uint8_t* data, uint8_t length, uint32_t seq);

/**
 * Request_Next_Binary_Chunk
 *
 * The function requests the next binary chunk of size 
 * <I>BIN_DATA_WINDOW_SIZE</I> from the PC app. This function is 
 * invoked from the boot loader state machine when the current state 
 * is <I>REQUEST_USB_PACKETS</I>.
 * It also sets the time out value for the buffer download.
 *
 * @return SUCCESS | FAIL
 */
result_t Request_Next_Binary_Chunk ();

/**
 * Command_Packet_Received
 * 
 * Signal from the USB Driver when a command packet is received.
 * The payload is parsed to identify the command type and based
 * on the command type the rest of the data is handled.
 * The commands and the data structure for each command is
 * defined in <B>MessageDefines.h</B>.
 *
 * @param data Data Payload of the USB Packet.
 * @param length Length of the payload.
 *
 * @return SUCCESS | FAIL
 */
result_t Command_Packet_Received (uint8_t* data, uint8_t length);

/**
 * Command_Timeout
 * 
 * The function is a signal from the timer module to indicate
 * that timeout value has reached for a particular operation.
 * The action required for the signal is determined by the
 * message type and the number of retires.
 * 
 * NOTE:
 *   If the number of retries expired then it usually indicates
 * a fatal comminucation error in the current code, the board 
 * will send a fata error message and will reboot.
 *
 * @param MsgId Message Type (command, or binary etc)
 * @parma Typ Type of command or any other message.
 * @param retries Number of retries left. (usually reducing).
 *
 */
void Command_Timeout (uint8_t MsgId, uint8_t Typ, uint8_t retries);

/**
 * Request_Next_Binary_Packet
 *
 * While in the MMU Disabled mode it is impossible to receive chunks
 * of data from the PC app, because the processing is not fast enough to
 * keep up with the data rate. It is easier to switch to request
 * each packet.
 *
 * @return SUCCESS | FAIL
 * 
 */
result_t Request_Next_Binary_Packet ();

/**
 * Check_Buffer_Crc 
 *
 * Check the CRC of the current RAM buffer and return the
 * result.
 * 
 * @param start  Current Start packet.
 * @param numpck number of packets downloaded in to the current buffer.
 * @param crc    CRC of the current buffer.
 *
 * @return SUCCESS| FAIL
 */
result_t Check_Buffer_Crc (uint32_t start, uint32_t numpck, uint16_t crc);

/**
 * Prepare_Self_Test
 *
 * If the application requests a self test for the newly
 * downloaded image, then the new image will be copied to
 * the boot location temporarily. The watch dog timer is
 * set to ensure that the app will reboot for the second
 * verification phase.
 * After the reboot the boot loader verifies the test result
 * and decides if the image has to be made golden or not.
 *
 * @return SUCCESS | ERROR
 */
result_t Prepare_Self_Test ();


/**
 * Handle_Cmd_Verify_Buffer_Crc
 * 
 * The function caluculates the crc of a given buffer
 * and compares it with the crc passed. If the data in
 * the buffer is determined valid through the crc check the
 * buffer data is transfered to the current load location.
 *
 * @parma chkcrc Data structure contaning number of packets 
 *               and the crc of the current buffer.
 *
 * @return SUCCESS | FAIL
 */
result_t Handle_Cmd_Verify_Buffer_Crc (CmdCrcData* chkcrc);

/**
 * Handle_Cmd_Verify_Image_Crc
 *
 * After the download is completed the bootloader verifies
 * the CRC of the image by reading the Image from the
 * flash. The current load location has to be specified
 * to the boot loader through CURRENT_LOAD_LOCATION attribute.
 * This function starts reading chunks of size DATA_WINDOW_SIZE
 * from the address passed as the first parameter from the flash and
 * calculates a cumulative crc of the chunks up to the
 * specified size (numpck number of ).
 *
 * @param StartAddr Starting address of the image.
 * @param Size The total size of the image.
 * @param rcvCRC The crc received or to be verified.
 *
 * @return SUCCESS | FAIL
 */
result_t Handle_Cmd_Verify_Image_Crc (uint32_t StartAddr, uint32_t Size, 
                                                        uint16_t rcvCrc);

/**
 * Handle_Cmd_Get_Buffer_Data
 *
 * This command enables the PC application to request the data from
 * the current internal buffer (rcvBuffer). This command is usally preceded by a
 * DUMP_FLASH_DATA command.
 *
 * @param sequence Sequence number of the packet requested.
 */
void Handle_Cmd_Get_Buffer_Data (uint16_t sequence);

/**
 * Handle_Cmd_Flash_Dump
 *
 * The verification mechanism of flash programming requires a flash dump of the
 * currently programmed location. The PC application can request a flash
 * dump of either the primary or the secondary flash image. 
 * The function expects the CurrentAddress to be set to the address where
 * the chunk has to be read. The chunk size is same as the download 
 * (BIN_DATA_WINDOW_SIZE).
 * 
 */ 
void Handle_Cmd_Flash_Dump ();

/**
 * Send_Command_Packet
 *
 * The abstraction function which takes a command and converts it in to
 * byte array and calls the lower level send function in USBClient.
 *
 * @param cmd Command to be send.
 * @param length Size of the struct pointed by cmd.
 *
 * @return SUCCESS | FAIL
 */
result_t Send_Command_Packet (USBCommand* cmd, int len);

/**
 * Send_USB_Command_Packet
 *
 * Send an command message to the PC.
 *
 * @param err Error codes defined in the enum (see MessageDefines.h).
 * @param clen Length of the command data.
 * @param cdata Command data in array format.
 */
result_t Send_USB_Command_Packet (Commands cmd, uint8_t clen, void* cdata);

/**
 * Send_USB_Error_Packet
 *
 * Send an error message and a description about the error to the
 * PC application.
 *
 * @param err Error codes defined in the enum (see MessageDefines.h).
 * @param dlen Length of the descriptor string.
 * @param desc A description about the error.
 */
result_t Send_USB_Error_Packet (Errors err, uint8_t dlen, void* desc);


/**
 * Send_USB_Binary_Packet
 *
 * Send Binary data to the pc application. This function is used mainly
 * to dump data from flash or the internal buffer to the pc applicaiton for
 * image verification purposes.
 *
 * The function currently follows the JTPacket format which means that
 * every packet can transmit a length of IMOTE_HID_SHORT_MAXPACKETDATA and
 * packet will contain the sequence number.
 *
 * @param data Data to be transmitted.
 * @return SUCCESS | FAIL
 */
result_t Send_USB_Binary_Packet (uint8_t* data, uint32_t length);
#endif
