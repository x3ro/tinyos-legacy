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
 * @file BinImageFile.h
 * @author Junaith Ahemed Shahabdeen
 *
 * The functions required for handling the binary image
 * data are provided by this file. Some of the functions
 * are opening the binary file and noting down the size
 * of the image, reading the content of the image in to
 * a buffer and providing utility functions to load code
 * through USB.
 */
#ifndef BIN_IMAGE_FILE_H
#define BIN_IMAGE_FILE_H

#include <stdio.h>
#include <stdlib.h>
#include <types.h>

/*Represent the file size in KBytes*/
#define FILE_SIZE_DIVIDER 1000

/**
 * Load_Binary_File
 *
 * This function loads the binary file which has
 * to be transfered through USB in to memory.
 *
 * @param fname Name of the file that has to be loaded
 *
 * @return SUCCESS | FAIL
 */
result_t Load_Binary_File (char* fname);

/**
 * Get_BinFile_KBSize
 *
 * Return the file size in KB.
 * 
 * @return file size
 * 
 */
long Get_BinFile_KBSize ();

/**
 * Get_BinFile_Size
 * 
 * Return the actual file size.
 *
 * @return file size.
 */
long Get_BinFile_Size ();

/**
 * Get_Bin_Buffer_Data
 *
 * The function copies a fixed length from the starting index
 * to the data pointer. The source of the data is the
 * buffer in which the file is copied to.
 *
 * @param data Desitnation data pointer.
 * @parma length Size to be copied from the main buffer.
 * @param startindex Starting index in the main buffer.
 *
 * @return Size copied | 0 on error
 */
uint32_t Get_Bin_Buffer_Data (uint8_t* data, uint32_t length, uint32_t startindex);

/**
 * Get_Num_USB_Packets
 *
 * Returns the number of USB packets of size IMOTE_HID_SHORT_MAXPACKETDATA
 * required to transfer the whole image.
 *
 * FIXME:
 *    If there are multiple motes and if there is a scenario where
 *    different files must be uploaded to each mote then this file
 *    has to keep track of the file name for each mote.
 *
 * @param nodeid The mote which is requesting the information. (Future Use)
 *
 * @return number of usb packets in the file.
 */ 
uint32_t Get_Num_USB_Packets (uint32_t nodeid);

#endif
