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
 * MessageDefines.h
 *
 * The file contains the definitions of the commands, errors
 * and the data structure used to form a command information.
 * 
 * CAUTION;
 *   This file is shared between the boot loader and the
 *   pc application. <B> DO NOT CHANGE THIS FILE without
 *   considering the failure cases on both the sides.</B>
 *
 */
#ifndef MESSAGE_DEFINES_H
#define MESSAGE_DEFINES_H

#include <types.h>

/**
 * The window size is reperesented in number of USB packets
 * required to for 32k chunk of data (excluding the headers). The 
 * down side of this definitions is that it ASSUMES that the USB
 * communicates with the PC as a HID Client and the maximum packet
 * size is 64 bytes. 
 * If the USB Communication changes, then this value has to be
 * changed.
 */
#define BIN_DATA_WINDOW_SIZE 546 /* Close to 32k*/

/**
 * CodeLoadType
 * 
 * The type of image being loaded. It could be
 * the binary image of an application or a
 * self test image.
 */
typedef enum CodeLoadType
{
  APPLICATION = 1,
  SELFTEST = 2
}CodeLoadType;

typedef struct USBImagePck
{
  uint16_t seq;    /* Sequence Number of the packet*/
  uint8_t data []; /* The binary data of the packet*/
}USBImagePck;

typedef struct USBCommand
{
  uint8_t type;    /*Command Type (enum Commands)*/
  uint8_t data []; /*Idea is to plug in and data possible*/
} USBCommand;

/**
 * struct USBError
 *
 * The data structure which communicates the error between the
 * boot loader and the PC application
 */
typedef struct USBError
{
  uint8_t type;           /* Error Type (see enum Errors)*/
  uint8_t desclen;        /* Description Length*/
  uint8_t description []; /* Description or required data related to the error*/
} USBError;



/**
 * struct CmdImageDetail
 *
 * Defines the details that are passed from the PC to the
 * IMote in response to GET_IMAGE_DETAILS
 */
typedef struct RspImageDetail
{
  uint32_t ImageSize;  /* Size of the Image being uploaded*/
  uint32_t NumUSBPck;  /* Number of USB Packets*/
} RspImageDetail;

/**
 * struct CmdReqBinData
 *
 * Command Structure for requesting binary image data from
 * the PC. The image is requested as chuncks of USB packets.
 */
typedef struct CmdReqBinData
{
  uint32_t PckStart;  /* Packet number to start from*/
  uint32_t NumUSBPck; /* Number of USB Packets to form the chunk*/
  uint32_t ChunkSize; /* Size of the Chunk*/
}CmdReqBinData;


/**
 * struct CmdCrcData
 *
 * This stucture is used if the boot loader has to request crc for a chunk of 
 * data from the PC application or if the pc application sends the crc
 * after uploading a chunk. 
 */
typedef struct CmdCrcData
{
  uint32_t chunkStart; /* Starting point of the chunk (in usb packets)*/
  uint32_t NumUSBPck;  /* Number of USB Packets. Mostly for size*/
  uint16_t ChunkCRC;   /* CRC of the chunk between pckstart and size*/
}CmdCrcData;

/**
 * Defines the commands to the PC applicaiton (CMD_*) and response
 * from the PC application (RSP_*)
 * Note the implementation the embedded side only implements the
 * RSP_* because it has to understand only those and the PC side
 * implements all the CMD_*.
 * This is to make the code less ambiguous.
 */
typedef enum Commands
{
  /* Usually commands that originate from the bootloader*/
  RSP_REBOOT = 1,            /*Reboot the Device*/
  CMD_BOOT_ANNOUNCE = 2,     /*Announce the reboot to PC*/
  RSP_USB_CODE_LOAD = 3,     /*Place the boot loader in Code Load*/
  CMD_GET_IMAGE_DETAILS = 4, /*Request Image detail from PC app*/
  RSP_GET_IMAGE_DETAILS = 5, /*Response from PC app about the image*/
  CMD_REQUEST_BIN_DATA = 6,  /*Request binary chunk from PC*/
  CMD_CRC_CHECK = 7,         /*Request CRC for the current chunk*/
  RSP_CRC_CHECK = 8,         /*CRC for the current chunk from PC app*/
  CMD_IMG_UPLOAD_COMPLETE = 9, /*Inform PC app that Image download is complete*/
  CMD_IMG_VERIFY_COMPLETE = 10, /*Image passed the CRC test*/
  CMD_REQUEST_BIN_PCK = 11,     
  CMD_CREATED_GOLDEN_IMG = 12,  /*Image download is complete*/
  
  /* Commands that originate from the PC and expects a response*/
  RSP_GET_ATTRIBUTE = 100,        /*PC asks for the attribute value*/
  CMD_RSP_GET_ATTRIBUTE = 101,    /*The boot loader responds with Attr Value*/
  RSP_DUMP_FLASH_DATA = 102,      /*PC app is requesting data from flash */ 
  RSP_SET_ATTRIBUTE = 103,        /*Response for setattr request from PC app*/
  CMD_RSP_SET_ATTRIBUTE = 104,    /*setattr Request from PC app*/
  RSP_SET_BOOTLOADER_STATE = 105, /*Set boot loader state*/
  
  CMD_TEST_IMG_DUMP= 200,         /*Dump an image from the secondary location*/
  RSP_TEST_GET_BUFFER_DATA = 201, /*Dump the current buffer*/
  RSP_FLASH_MEM_TEST = 202,       /**/
  CMD_BOOTLOADER_MSG = 203        /*Send a string to the PC app (dbg message)*/
} Commands;


/**
 * The enumerated values are the possible errors that are communicated
 * between the bootloader and the PC application.
 */
typedef enum Errors
{
  ERR_FLASH_WRITE = 1,     /*Error writing to flash memory*/
  ERR_FLASH_ERASE = 27,    /*Error erasing flash block*/
  ERR_FLASH_READ = 28,     /*Error reading from Flash*/
  ERR_COMMAND_FAILED = 29, /*The command sent by pc app failed*/
  
  ERR_NO_MORE_BINARY_DATA = 100,
  TEST_CRC_FAILURE = 201,  /*CRC does not match for the current buffer or Image*/
  ERR_FATAL_ERROR_ABORT = 250 /*Error that prevent execution impossible*/
} Errors;

#endif
