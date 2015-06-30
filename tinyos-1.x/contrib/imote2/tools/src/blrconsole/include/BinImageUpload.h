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
 * @file BinImageUpload.h
 * @author Junaith Ahemed Shahabdeen
 *
 * Provides the function required to upload code to IMote2.
 */
#ifndef BIN_IMAGE_UPLOAD_H
#define BIN_IMAGE_UPLOAD_H

#include <BinImageFile.h>
#include <USBMessageHandler.h>

/**
 * Binary_Code_Upload
 *
 * The binary chunk request from the Imote device is
 * handled by this function. The reqest from the
 * device provides the start index and the size
 * of the chunk in of a given file that is being
 * trasfered. The function breaks the buffer in to
 * USB trasferable sizes and passes it to the USBComm
 * module to be trasfered to the IMote.
 *
 * @param startpck Starting index denoted in number of USB Packets.
 * @param numpck Number of packets to be transfered from start index.
 *
 * @return SUCCESS | FAIL 
 */
result_t Binary_Code_Upload (uint32_t startpck, uint32_t numpck);

/**
 * Send_Binary_Packet
 *
 * When the Mote request for one binary packet during the MMU Disabled mode,
 * this function will send the right data from the file. The chunk size
 * passed as parameter will identify the position in the file from which
 * the data has to be copied.
 * 
 * @param nseq Sequence number (Received from Device and has to be echoed)
 * @param numpck Number of packets requested.
 * @param ftpr The position in the file.
 *
 * @return SUCCESS | FAIL
 */
result_t Send_Binary_Packet (uint32_t nseq, uint32_t numpck, uint32_t fptr);


/**
 * Send_CRC_Command
 *
 * The function calculates the CRC of a chunk of given length
 * and sends the result to the mote over USB.
 *
 * @param buff The buffer for which crc must be computed.
 * @param length Length of the buffer.
 * @param startpck Start packet number of the chunk.
 * @param numt   Number of USB packets in the chunk.
 * 
 * @return SUCCESS | FAIL
 */
result_t Send_CRC_Command (uint8_t* buff, uint32_t length, 
                  uint32_t startpck, uint32_t numt);


/**
 * Send_Image_Crc_Command
 *
 * After the whole image is downloaded the crc of the
 * cumulative crc of the file in chunk size should be
 * sent as a part of verify image.
 *
 * @return SUCCESS | FAIL
 */
result_t Send_Image_Crc_Command ();

/**
 * Send_Test_CRC_Command
 *
 * This function is used in the debug mode to send
 * crc command to the mote. (allows to fake crc)
 *
 * @param startpck 
 * @param numt 
 * @param crc 
 * 
 * @return SUCCESS | FAIL
 */
result_t Send_Test_CRC_Command (uint32_t startpck, uint32_t numt, uint16_t crc);
#endif
