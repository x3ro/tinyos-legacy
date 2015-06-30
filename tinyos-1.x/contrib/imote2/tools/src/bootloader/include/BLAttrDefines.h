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
 * @file BLAttrDefines.h
 * @author Junaith Ahemed Shahabdeen
 *
 * The file defines the attribute details like location
 * name, default value etc.
 *
 * CAUTION: This file is used by the boot loader for
 *  the attribute location etc. You cannot change this
 *  parameters in the file unless all of the failure
 *  cases are considered carefully. Also chaning or
 *  repositioning the attributes or attribute table will
 *  make it incompatible with the existing version.
 */
#ifndef BL_ATTR_DEFINES_H
#define BL_ATTR_DEFINES_H

#include <BootLoaderInc.h>

/* 32k for each table */
//#define BL_TABLE_SIZE 0x8000
#define BL_TABLE_SIZE             0x20000

#define BL_ATTR_ADDRESS_TABLE     0x1E00000
#define BL_ATTR_DEF_BOOTLOADER    0x1E20000
#define BL_ATTR_BOOTLOADER        0x1E40000
/* Default and the updatable shared location */
#define BL_ATTR_DEF_SHARED        0x1E80000
#define BL_ATTR_SHARED            0x1EA0000

/**
 * Image Locations
 */
#define BL_PRIMARY_IMAGE_LOCATION     0x01C00000
#define BL_SECONDARY_IMAGE_LOCATION   0x01D00000
#define BL_DEF_SELF_TEST_IMG_LOC 0x1F00000
#define BL_ATTR_BOOT_LOC              0x20 /* Ignore the Vector table*/
#define BL_SELF_TEST_SIZE        0x8000 /* FIXME may be we should fix me*/

/*WD Timeout value for Self Test*/
#define BL_SELF_TEST_TIMEOUT 0x40000000

#define CMD_TIMEOUT_VAL 2000	/* 2 Seconds by default*/
#define BIN_TIMEOUT_VAL 10000	/* 10 Seconds by default*/

typedef enum ATTR_VALIDITY_DEF
{
  BL_VALID_ATTR = 0x1F,
  BL_INVALID_ATTR = 0x01
} ATTR_VALIDITY_DEF;

#define ATTR_ADDRESS_TABLE_START_VALUE 1
#define ATTR_ADDRESS_TABLE_END_VALUE 49
/**
 * The enum basically defines the Attribute type of the
 * parameters in the BL_ATTR_ADDRESS_TABLE.
 */
typedef enum ATTR_Address_Table
{
  BL_ATTR_TYP_ADDRESS_TABLE = 1,  /* Address location of all tables */
  BL_ATTR_TYP_DEF_BOOTLOADER = 2, /* Default BootLoader Table */
  BL_ATTR_TYP_BOOTLOADER = 3,     /* BootLoader Updatable region */
  BL_ATTR_TYP_DEF_SHARED = 4,     /* Shared attributes for communicaiton with app*/
  BL_ATTR_TYP_SHARED = 5,         /* Shared attributes for communicaiton with app*/
  BL_ATTR_TYP_BOOT_LOCATION = 6,  /* Current Boot Location*/
} ATTR_Address_Table;

/**
 * Number of attributes that are currently defined in the 
 * BL_ATTR_ADDRESS_TABLE. If you add a new attribute in the
 * ATTR_Address_Table, then it is essential to increment this
 * number.
 */
#define BL_ATTR_ADDRESS_TABLE_NUM 6

/***********************************************************************************
 *                              BOOT LOADER TABLE                                  *
 ***********************************************************************************/
#define ATTR_BOOTLOADER_START_VALUE 50
#define ATTR_BOOTLOADER_END_VALUE 350
/**
 * This enum defines the attribute types of the parameters in
 * the BL_ATTR_TYP_BOOTLOADER (the bootloader table).
 */
typedef enum ATTR_Bootloader_Table
{
  BL_ATTR_TYP_SYNC_TIMEOUT = 50,        /*Time out in ms for PC App sync mechanism */
  BL_ATTR_TYP_BOOTLOADER_STATE = 51,    /*Boot Loader State*/
  BL_ATTR_TYP_CMD_FAIL_RETRY = 52,      /*Number of retries for command failures */
  BL_ATTR_TYP_CRC_FAIL_RETRY = 53,      /*Number of retries for CRC failures */
  BL_ATTR_TYP_DATA_WINDOW = 54,         /*Number of retries for CRC failures */
  BL_ATTR_TYP_SELF_TEST_TIMEOUT = 55,   /*Time out value for self test mode*/
  BL_ATTR_TYP_CMD_TIMEOUT = 56,         /*Time out value for Commands*/
  BL_ATTR_TYP_BIN_TIMEOUT = 57,         /*Time out value for Binary data*/
  BL_ATTR_TYP_PRIMARY_IMG_LOCATION = 150,   /*Primary Image Location*/
  BL_ATTR_TYP_PRIMARY_IMG_CRC = 151,        /*CRC of Primary Image*/
  BL_ATTR_TYP_PRIMARY_IMG_SIZE = 152,       /*Size of Primary Image*/
  BL_ATTR_TYP_PRIMARY_IMG_VALIDITY = 153,   /*Is Primary Image Valid*/
  BL_ATTR_TYP_SECONDARY_IMG_LOCATION = 154, /*Secondary Image Location*/
  BL_ATTR_TYP_SECONDARY_IMG_CRC = 155,      /*CRC of Secondary Image*/
  BL_ATTR_TYP_SECONDARY_IMG_SIZE = 156,     /*Size of Secondary Image*/
  BL_ATTR_TYP_SECONDARY_IMG_VALIDITY = 157, /*Is Secondary Image Valid*/
  BL_ATTR_TYP_BOOT_IMG_CRC = 158,           /*CRC of Boot Image*/
  BL_ATTR_TYP_BOOT_IMG_SIZE = 159,          /*Size of Boot Image*/
  BL_ATTR_TYP_BOOT_IMG_VALIDITY = 160,      /*Is Boot Image Valid*/
  BL_ATTR_TYP_DEF_SELF_TEST_IMG_LOC = 161,  /*Self Test Image Location*/
  BL_ATTR_TYP_DEF_SELF_TEST_IMG_CRC = 162,  /*Self Test Image Crc*/
  BL_ATTR_TYP_DEF_SELF_TEST_IMG_SIZE = 163, /*Self Test Image Size*/
} ATTR_Bootloader;

/**
 * Number of attributes that are currently defined in the 
 * Boot Loader table.<B> If you add a new attribute in the
 * ATTR_Bootloader_Table, then it is essential to increment this
 * number.</B>
 */
#define BL_ATTR_BOOTLOADER_TABLE_NUM 22


#endif
