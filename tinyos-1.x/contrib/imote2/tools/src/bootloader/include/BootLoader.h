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
 * @file BootLoader.h
 * @author Junaith Ahemed Shahabdeen
 *
 * Boot loader state machine, recovery mechanism and
 * the application test mechanisms like SELF_TEST and
 * Image verify are implemented in this file. 
 */
#ifndef BOOT_LOADER_H
#define BOOT_LOADER_H

#include <HPLInit.h>

/**
 * Boot Loader State.
 */
typedef enum BootLoaderState
{
  NORMAL = 1,           /*default mode for the bootloader*/
  CODE_LOAD = 2,        /*Internal mode for the bootloader during code load*/
  VERIFY_IMAGE = 3,     /*App reqests to verify secondary image*/
  VERIFY_SELF_TEST = 4, /*SELF_TEST requested from the application*/
  BOOT_IMAGE = 5,       /*Internal mode for bootloader for booting the image*/
  CPY_TO_BOOT = 6,      /*Copy Secondary to boot location*/
  SET_LOADED_TO_GOLDEN = 7, /*Swap Secondary to primary attributes*/
  SET_BOOT_TO_GOLDEN = 8, /*Copy CRC and Size of Primary to Boot Attribute*/
  COMMAND_LINE = 9,       /*Internal mode, copy secondary to boot location*/
}BootLoaderState;

/**
 * CodeLoadState
 *
 * Internal states of the bootloader while it is
 * loading code through the USB. These states will
 * not be written to the attribute in FLASH.
 */
typedef enum CodeLoadState
{
  REQUEST_IMAGE_DETAIL = 1,
  REQUEST_USB_PACKETS = 2,
  VERIFY_CURRENT_BUFFER = 3,
  VERIFY_CURRENT_IMAGE = 4
} CodeLoadState;

/**
 * Set_Image_Details
 *
 * The details of the current downloaded image stored
 * in the secondary location is passed to the boot loader
 * state machine for moving the image to boot location
 * and marking the image as golden. Though the values
 * are stored in the flash as attributes, it is easier and
 * quicker to deal with ram variables.
 * This function is basically a utility to pass the image 
 * details from BinImageHandler module to the BootLoaderState
 * module.
 *
 * @param isize Size of the image.
 * @parma iaddr Starting address of the image location.
 * @parma icrc  Crc of the image.
 *
 */
void Set_Image_Details (uint32_t isize, uint32_t iaddr, uint32_t icrc);

//result_t Enable_Mem_Test ();
//result_t Post_BootLoader_State ();

/**
 * Reboot_Device
 *
 * Set the watch dog and the OSMR3 registers and wait till
 * the board reboots.
 */
inline void Reboot_Device ();

//void USB_Send_Done ();

/**
 * Change_BootLoader_State_Attribute
 *
 * Change the current boot loader state to the value of first parameter and
 * also synch it with the BootLoader State Attribute in flash.
 * The value of the parameter passed must be one of the values in
 * the BootLoaderState enumerated list.
 * 
 * @param state	The new state of the boot loader.
 * @return SUCCESS | FAIL
 */
uint8_t Change_BootLoader_State_Attribute (BootLoaderState state);


/**
 * Change_BootLoader_State
 *
 * Change the current boot loader state to the value of first parameter.
 * The value of the parameter passed must be one of the values in
 * the BootLoaderState enumerated list.
 *
 * @param state	The new state of the boot loader.
 * @return SUCCESS | FAIL
 */
uint8_t Change_BootLoader_State (BootLoaderState state);

/**
 * Get_BootLoader_State
 *
 * Get the current boot loader state, The function returns the current
 * state of the boot loader.
 *
 * @return CurrentState of the boot loader.
 */
BootLoaderState Get_BootLoader_State ();

/**
 * Change_Internal_CodeLoad_State
 *
 * The code load state is internally maintained by the bootloader after the
 * PC application places it in CodeLoad state. Currently there are
 * two states in which the boot loader requests the image details to be
 * loaded and requests the usb packets.
 *
 * @param cls	The new internal state of Code_Load.
 * @return SUCCESS | FAIL
 */
uint8_t Change_Internal_CodeLoad_State (CodeLoadState cls);

/**
 * Get_Internal_CodeLoad_State
 *
 * The funciton returns the CLoaderState variable, which is the
 * current internal state of Code_Loader.
 *
 * @return CLoaderState Current state of Code_Loader.
 */
CodeLoadState Get_Internal_CodeLoad_State ();

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
 * Self_Test_Failed
 *
 * If the self test fails then the boot loader has to recover the
 * previous golden image and replace the current boot image (self test image).
 *
 * @return SUCCESS | FAIL 
 */
result_t Self_Test_Failed ();

/**
 * Self_Test_Succeeded
 * 
 * Self test succeeded so make the current image as golden image
 * and set the right attributes.
 *
 * @return SUCCESS | ERROR
 */
result_t Self_Test_Succeeded ();

/**
 * Validate_Self_Test_Image
 *
 * Validate the CRC of the self test image and determine if the
 * self test passed or failed.
 *
 * @return SUCCESS | FAIL
 */
result_t Validate_Self_Test_Image ();

/**
 * Verify_Image_And_Make_Golden
 *
 * The application can download an image and store it in the 
 * secondary location and requests the boot loader to validate (CRC)
 * the make and convert it to bootable image.
 * If the CRC Check passed then the image is made bootable and
 * copied to the primary location.
 * 
 * @return SUCCESS | FAIL
 */
result_t Verify_Image_And_Make_Golden ();

/**
 * Move_Image_To_Boot_Loc
 *
 * Move the image at imgAddr to the boot location. This
 * function holds a copy of the vector table. If incase there is
 * a failure then it will try to replace the vector table to
 * save the boot loader.
 *
 * @param imgAddr Starting address of the image to be moved.
 * @param imgSiz  Size of the image at imgAddr.
 *
 * @return SUCCESS | FAIL
 */
result_t Move_Image_To_Boot_Loc (uint32_t imgAddr, uint32_t imgSiz);

/**
 * BootLoader_Recovery_State_Machine
 *
 * State machine that is invoked while we are recovering from
 * a crash. The actions that has to be taken after a crash differs
 * from the normal one, just to prevent an infinite loop.
 * Also there are only few states in which the boot loader
 * crash could crash.
 * NOTE:
 * if the function doesnt recognize the crash state or if there is a 
 * possibility of an infinite loop then stall.
 */
void BootLoader_Recovery_State_Machine ();


/**
 * BootLoader_State_Machine
 *
 * The state machine for the boot loader which performs certain tasks
 * based on the current state of the boot loader. The current state must
 * be changed appropriately before calling this fuction.
 *
 */
void BootLoader_State_Machine ();

#endif
