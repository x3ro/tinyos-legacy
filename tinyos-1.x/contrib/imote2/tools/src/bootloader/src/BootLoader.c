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
 * @file BootLoader.c
 * @author Junaith Ahemed Shahabdeen
 *
 * Boot loader state machine, recovery mechanism and
 * the application test mechanisms like SELF_TEST and
 * Image verify are implemented in this file.
 */

#include <BootLoader.h>
#include <USBClient.h>
#include <Leds.h>
#include <BinImageHandler.h>
#include <AttrAccess.h>
#include <stdlib.h>
#include <Flash.h>
#include <stdio.h>
#include <TOSSched.h>

extern void handle_jump ();
extern int __Binary_Mover (uint32_t, uint32_t, void*);
extern int __Binary_Erase (uint32_t, uint32_t, void*);

/* Default boot loader state is normal */
BootLoaderState CurrentState = NORMAL;
CodeLoadState CLoaderState = REQUEST_IMAGE_DETAIL;
bool REBOOT_DEVICE = FALSE;
bool MMU_ENABLED = FALSE;

static uint8_t vecbuffer [32];
static uint8_t cpybuffer [0x8000];

/*Attributes of the Golden Image used if we have to recover*/
uint32_t GImgSize = 0;
uint32_t GImgAddr = 0;
uint32_t GImgCrc = 0;

/*Attributes of the newly loaded image*/
uint32_t CurrImageSize = 0;
uint32_t CurrImageAddr = 0;
uint32_t CurrImageCrc = 0;

void Set_Image_Details (uint32_t isize, uint32_t iaddr, uint32_t icrc)
{
  CurrImageSize = isize;
  CurrImageAddr = iaddr;
  CurrImageCrc = icrc;
}

/**
 * Change_BootLoader_State_Attribute
 *
 * Change the current boot loader state attribute to the value of first parameter,
 * together with the local variable. The value of the parameter passed must be 
 * one of the values in the BootLoaderState enumerated list.
 *
 * @param state	The new state of the boot loader.
 * @return SUCCESS | FAIL
 */
uint8_t Change_BootLoader_State_Attribute (BootLoaderState state)
{
  result_t ret = FAIL;
  ret = Write_Attribute_Value (BL_ATTR_TYP_BOOTLOADER_STATE, (uint32_t)state);
  CurrentState = state;
  return SUCCESS;
}

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
uint8_t Change_BootLoader_State (BootLoaderState state)
{
  CurrentState = state;
  return SUCCESS;
}

/**
 * Get_BootLoader_State
 *
 * Get the current boot loader state, The function returns the current
 * state of the boot loader.
 *
 * @return CurrentState of the boot loader.
 */
BootLoaderState Get_BootLoader_State ()
{
  return CurrentState;
}


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
uint8_t Change_Internal_CodeLoad_State (CodeLoadState cls)
{
  CLoaderState = cls;
  return SUCCESS;
}

/**
 * Get_Internal_CodeLoad_State
 *
 * The funciton returns the CLoaderState variable, which is the
 * current internal state of Code_Loader.
 *
 * @return CLoaderState Current state of Code_Loader.
 */
CodeLoadState Get_Internal_CodeLoad_State ()
{
  return CLoaderState;
}

/**
 * Reboot_Device
 *
 * Set the watch dog and the OSMR3 registers and wait till
 * the board reboots.
 */
inline void Reboot_Device ()
{
  OSMR3 = OSCR0 + 0x2000;
  OWER = 1;
  while(1);
}

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
result_t Prepare_Self_Test ()
{
  //uint8_t buffer [61];
  /**
   * first change the state so that in case if we crash then we 
   * can recover.
   */
  Flash_Read (0x0, 32, vecbuffer);

  /* Load the Image details so that we can move the contents to
   * boot location
   */
  if (Read_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_LOCATION, &GImgAddr) 
                                                              == SUCCESS)
  {
    if (Read_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_SIZE, &GImgSize)
                                                            == SUCCESS)
    {
      /**
       * First check if the image is worth performing selftest on. Calculate
       * the crc and try to match it with the crc attribute.
       */
      if (Read_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_CRC, &GImgCrc)
                                                                == SUCCESS)
      {
        if ((GImgSize == 0) || (GImgCrc == 0))
          return FAIL;
        if (Handle_Cmd_Verify_Image_Crc (GImgAddr, GImgSize, 
                             GImgCrc) == SUCCESS)
        {
          uint32_t WDTimeout;
          if (Change_BootLoader_State_Attribute (VERIFY_SELF_TEST) == FAIL)
            return FAIL;
          if (Read_Attribute_Value(BL_ATTR_TYP_SELF_TEST_TIMEOUT, &WDTimeout)
                                                              == SUCCESS)
            WDTimeout = BL_SELF_TEST_TIMEOUT; /*Not a biggie if we fail set it default*/
          __Binary_Mover (GImgAddr, GImgSize, vecbuffer);
	  //Move_Image_To_Boot_Loc (GImgAddr, GImgSize);
          /* set the watchdog to wait for long time to allow the
           * app to finish the self test
           */
          OSMR3 = OSCR0 + WDTimeout;
          OWER = 1;
          handle_jump ();
        }
      }
    }
  }
  return FAIL;
}

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
result_t Verify_Image_And_Make_Golden ()
{
  /* Load the Image details so that we can move the contents to
   * boot location
   */
  if (Read_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_LOCATION, &CurrImageAddr) 
                                                               == SUCCESS)
  {
    if (Read_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_SIZE, &CurrImageSize)
                                                              == SUCCESS)
    {
      /*Verify the crc of the image.*/
      if (Read_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_CRC, &CurrImageCrc)
                                                              == SUCCESS)
      {
        if ((CurrImageSize == 0) || (CurrImageCrc == 0))
          return FAIL;
        if (Handle_Cmd_Verify_Image_Crc(CurrImageAddr, CurrImageSize, CurrImageCrc)
                                                              == SUCCESS)
        {
          //__Binary_Mover (GImgAddr, GImgSize, vecbuffer);
          if(Change_BootLoader_State_Attribute (CPY_TO_BOOT) == SUCCESS)
	  {
            BootLoader_State_Machine ();
            return SUCCESS;
          }
        }
      }
    }
  }
  return FAIL;
}


/**
 * Self_Test_Failed
 *
 * If the self test fails then the boot loader has to recover the
 * previous golden image and replace the current boot image (self test image).
 *
 * @return SUCCESS | FAIL 
 */
result_t Self_Test_Failed ()
{
  /**
   * first change the state so that in case if we crash then we 
   * can recover.
   */
  Flash_Read (0x0, 32, vecbuffer);

  /* Load the Image details so that we can move the contents to
   * boot location
   */
  if (Read_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_LOCATION, &GImgAddr) 
                                                             == SUCCESS)
  {
    if (Read_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_SIZE, &GImgSize) 
                                                             == SUCCESS)
    {
      if (Read_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_CRC, &GImgCrc) 
                                                             == SUCCESS)
      {
        /* Just in case, make sure that CRC matches before loading it*/
        if (Handle_Cmd_Verify_Image_Crc(GImgAddr, GImgSize, GImgCrc)
                                                             == SUCCESS)
        {
          __Binary_Mover (GImgAddr, GImgSize, vecbuffer);
          //Move_Image_To_Boot_Loc (GImgAddr, GImgSize);
          /*Reset the Crc boot address.*/
          //Write_Attribute_Value(BL_ATTR_TYP_BOOT_IMG_CRC, GImgCrc);
          //handle_jump ();
          return SUCCESS;
	}
      }
    }
  }
  return FAIL;
}

/**
 * Self_Test_Succeeded
 * 
 * Self test succeeded so make the current image as golden image
 * and set the right attributes.
 *
 * @return SUCCESS | ERROR
 */
result_t Self_Test_Succeeded ()
{
  result_t ret; 
  /* Load the Image details and prepare to make the secondary 
   * image as golden
   */
  /* FIXME the assumption is that non of these values could be changed by the
   * app. Not sure if its good enough.
   */
  ret = Read_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_LOCATION, &CurrImageAddr);
  ret = Read_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_SIZE, &CurrImageSize);
  ret = Read_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_CRC, &CurrImageCrc);
  ret = Read_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_LOCATION, &GImgAddr);
  ret = Read_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_CRC, &GImgCrc);
  ret = Read_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_SIZE, &GImgSize);

  if (ret == SUCCESS)
  {
    if(Change_BootLoader_State_Attribute (SET_LOADED_TO_GOLDEN) == SUCCESS)
    {
      BootLoader_State_Machine ();
      return SUCCESS;
    }
  }
  return FAIL;
}

/**
 * Validate_Self_Test_Image
 *
 * Validate the CRC of the self test image and determine if the
 * self test passed or failed.
 *
 * @return SUCCESS | FAIL
 */
result_t Validate_Self_Test_Image ()
{
  uint32_t AttrLoc = 0;
  uint32_t AttrSize = 0;
  uint32_t DefAttrCrc = 0;
  
  if(Change_BootLoader_State_Attribute (NORMAL) == SUCCESS)
  {
    if (Read_Attribute_Value(BL_ATTR_TYP_DEF_SELF_TEST_IMG_CRC, &DefAttrCrc)
                                                               == SUCCESS)
    {
      if (DefAttrCrc == 0)
      {
        return FAIL;
      }
    }

    if (Read_Attribute_Value(ATTR_SELF_TEST_IMG_LOC, &AttrLoc) 
                                                      == SUCCESS)
    {
      if (Read_Attribute_Value(ATTR_SELF_TEST_IMG_SIZE, &AttrSize) 
                                                        == SUCCESS)
      {
        if (Handle_Cmd_Verify_Image_Crc(AttrLoc, AttrSize, DefAttrCrc)
                                                            == SUCCESS)
        {
          return SUCCESS;
        }
      }
    }
  }
  else
  {
    ; /* Fatal, We cant revert back to the old image*/
  }
  return FAIL;
}


/**
 * Map_Loaded_To_Golden
 *
 * This function swaps the attribute values of the current golden image
 * with the secondary image attribute. The assumption is that the 
 * secondary image is already validated and copied to the boot location,
 * as a final step this function is called to mark the secondary as
 * golden so that the successive reboots can boot the newly loaded image.
 *
 * @return SUCCESS | FAIL
 */
result_t Map_Loaded_To_Golden ()
{
  result_t ret = FAIL;
  AttrSet attset;
  
  attset.NumAttributes = 9;
  attset.AttrId [0] = BL_ATTR_TYP_BOOTLOADER_STATE;
  attset.AttrVal [0] = NORMAL;
  attset.AttrId [1] = BL_ATTR_TYP_PRIMARY_IMG_LOCATION;
  attset.AttrVal [1] = CurrImageAddr;
  attset.AttrId [2] = BL_ATTR_TYP_PRIMARY_IMG_CRC;
  attset.AttrVal [2] = CurrImageCrc;
  attset.AttrId [3] = BL_ATTR_TYP_PRIMARY_IMG_SIZE;
  attset.AttrVal [3] = CurrImageSize;
  attset.AttrId [4] = BL_ATTR_TYP_SECONDARY_IMG_LOCATION;
  attset.AttrVal [4] = GImgAddr;
  attset.AttrId [5] = BL_ATTR_TYP_SECONDARY_IMG_CRC;
  attset.AttrVal [5] = GImgCrc;
  attset.AttrId [6] = BL_ATTR_TYP_SECONDARY_IMG_SIZE;
  attset.AttrVal [6] = GImgSize;
  attset.AttrId [7] = BL_ATTR_TYP_BOOT_IMG_CRC;
  attset.AttrVal [7] = CurrImageCrc;
  attset.AttrId [8] = BL_ATTR_TYP_BOOT_IMG_SIZE;
  attset.AttrVal [8] = CurrImageSize;

  ret = Write_Attribute_Set (BL_ATTR_TYP_BOOTLOADER, &attset);
  return ret;
}


result_t ReMap_Golden ()
{
  result_t ret = FAIL;

  ret = Write_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_LOCATION, GImgAddr);
  ret = Write_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_CRC, GImgCrc);
  ret = Write_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_SIZE, GImgSize);
  //ret = Write_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_VALIDITY, &PrimaryVal);
  ret = Write_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_LOCATION, CurrImageAddr);
  ret = Write_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_CRC, CurrImageCrc);
  ret = Write_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_SIZE, CurrImageSize);
  //ret = Write_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_VALIDITY, &PrimaryVal);

  return ret;
}


/*result_t Map_Boot_To_Golden ()
{
  return SUCCESS;
}*/


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
void BootLoader_Recovery_State_Machine ()
{
  result_t ret = FAIL;
  switch (CurrentState)
  {
    case CPY_TO_BOOT:
      ret = Read_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_LOCATION, &GImgAddr);
      ret = Read_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_CRC, &GImgCrc);
      ret = Read_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_SIZE, &GImgSize);
      ret = Read_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_LOCATION, &CurrImageAddr);
      ret = Read_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_CRC, &CurrImageCrc);
      ret = Read_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_SIZE, &CurrImageSize);
      if (ret == SUCCESS)
      {
        if (Move_Image_To_Boot_Loc (CurrImageAddr, CurrImageSize) == SUCCESS)
        {
          if (Map_Loaded_To_Golden () == FAIL)
          {
            /*Prepare for the second pass*/
            if (Change_BootLoader_State_Attribute (SET_LOADED_TO_GOLDEN) == FAIL)
            {
              TOGGLE_LED (RED);
              while (1); /* Thats a stall case, dont go back*/
            }
          }
        }
      }

      if (Change_BootLoader_State_Attribute (NORMAL) == FAIL)
      {
        TOGGLE_LED (RED);
        while (1); /* Thats a stall case, dont go back*/
      }
      Reboot_Device ();
    break;
    case SET_LOADED_TO_GOLDEN:
    {
      ret = Read_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_LOCATION, &GImgAddr);
      ret = Read_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_CRC, &GImgCrc);
      ret = Read_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_SIZE, &GImgSize);
      if (ret == SUCCESS)
      {
        ret = Read_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_LOCATION, &CurrImageAddr);
        ret = Read_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_CRC, &CurrImageCrc);
        ret = Read_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_SIZE, &CurrImageSize);

        if (ret == SUCCESS)
        {
          Map_Loaded_To_Golden ();
        }
        else
        {
          /* We know that we have a good PIMG. so lets replace it and boot the old app
	   */
          Move_Image_To_Boot_Loc (GImgAddr, GImgSize);
          if ((CurrImageAddr != BL_PRIMARY_IMAGE_LOCATION) && 
                       (CurrImageAddr != BL_SECONDARY_IMAGE_LOCATION))
          {
            /* Find where the current primary location is to determine
             * the secondary location.
             */
            if ((GImgAddr - BL_PRIMARY_IMAGE_LOCATION) > 0)
              ret = Write_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_LOCATION, 
                                              BL_PRIMARY_IMAGE_LOCATION);
            else
              ret = Write_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_LOCATION, 
                                              BL_SECONDARY_IMAGE_LOCATION);

            ret = Write_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_LOCATION, 0);
            ret = Write_Attribute_Value(BL_ATTR_TYP_SECONDARY_IMG_LOCATION, 0);
          }
        }
      }
      else
      {
        /* We might have busted the whole table, just replace the default*/
        Recover_Default_Table (BL_ATTR_TYP_BOOTLOADER);
      }
      if (Change_BootLoader_State_Attribute (NORMAL) == FAIL)
      {
        TOGGLE_LED (RED);
        while (1); /* Thats a stall case, dont go back, Will lead to a loop*/
      }
      Reboot_Device ();
    }
    break;
    case SET_BOOT_TO_GOLDEN:
      if (Change_BootLoader_State_Attribute (NORMAL) == FAIL)
      {
        TOGGLE_LED (RED);
        while (1); /* Thats a stall case, dont go back*/
      }
      Reboot_Device ();
    break;
    case VERIFY_SELF_TEST:
      if (Validate_Self_Test_Image () == SUCCESS)
      {
        if (Self_Test_Succeeded () == FAIL)
          ; /* Serious, we need to some how save the vector table*/ 
      }
      else
      {
        Self_Test_Failed ();
        Reboot_Device ();      
      }
    break;
    default:
      Recover_Default_Table (BL_ATTR_TYP_BOOTLOADER);
      Reboot_Device ();
    break;
  }
}

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
result_t Move_Image_To_Boot_Loc (uint32_t imgAddr, uint32_t imgSiz)
{
  result_t ret;
  uint32_t ImgFlashAddr = imgAddr + 32; /*Drop the vec table*/
  uint32_t CSize= 0x8000;
  uint32_t RSize = 0;
  uint32_t CurSize = 0x20;
  uint32_t BootAddr = 0x0;
  uint32_t AddVec = 0x0;
  
  Flash_Read (0x0, 32, vecbuffer); /* Keep this for recovery purpose*/
  if (Flash_Param_Partition_Erase (BootAddr) == SUCCESS)
  {
    if (Flash_Write (BootAddr, vecbuffer, 0x20) == FAIL)
    {
      memcpy (cpybuffer, vecbuffer, 0x20);
      AddVec = 0x20;
    }
    else
      BootAddr = 0x20;
  }
  
  ret = __Binary_Erase (CurrImageAddr, CurrImageSize, vecbuffer);

  if (Flash_Read (ImgFlashAddr, (CSize - CurSize), (cpybuffer + AddVec)) == SUCCESS)
  {
    if (Flash_Write (BootAddr, cpybuffer, (0x7FE0 + AddVec)) == SUCCESS)
    {
      CurSize += (0x8000 - 0x20);
      ImgFlashAddr += (0x8000 - 0x20);
      BootAddr += (0x8000 - 0x20);
    }
    else
    {
      if (Flash_Write (BootAddr, vecbuffer, 0x20) == FAIL)
      {
        TOGGLE_LED (RED);
        while (1);
      }
      else
        return FAIL;
    }
  }
      
  while (CurSize < imgSiz)
  {
    RSize = ((imgSiz - CurSize) > CSize)? CSize : (imgSiz - CurSize);
    if (Flash_Read (ImgFlashAddr, RSize, cpybuffer) == SUCCESS)
    {
      if (Flash_Write (BootAddr, cpybuffer, 0x8000) == SUCCESS)
      {
        CurSize += RSize;
        ImgFlashAddr += RSize;
        BootAddr += RSize;
      }
      else
        return FAIL;
    }
  }
  return SUCCESS;
}



/**
 * BootLoader_State_Machine
 *
 * The state machine for the boot loader which performs certain tasks
 * based on the current state of the boot loader. The current state must
 * be changed appropriately before calling this fuction.
 *
 */
void BootLoader_State_Machine ()
{
  switch (CurrentState)
  {
    case NORMAL:
      /*FIXME Move the code from main and post the state machine*/
    break;
    case CPY_TO_BOOT:
    {
      uint8_t buffer [61];
      Read_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_LOCATION, &GImgAddr);
      Read_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_CRC, &GImgCrc);
      Read_Attribute_Value(BL_ATTR_TYP_PRIMARY_IMG_SIZE, &GImgSize);
      __nesc_atomic_t atomic = __nesc_atomic_start();
      if (Move_Image_To_Boot_Loc (CurrImageAddr, CurrImageSize) == FAIL)
        Reboot_Device (); 
      __nesc_atomic_end (atomic);

      TOGGLE_LED (YELLOW);

      if(Change_BootLoader_State_Attribute (SET_LOADED_TO_GOLDEN) == SUCCESS)
      {
        sprintf (buffer, "Successfully copied image to boot location.\n");
        Send_USB_Command_Packet (CMD_BOOTLOADER_MSG, 61, buffer);
        TOS_post (&BootLoader_State_Machine);
      }
      else
      {
        /**
         * If we cant switch state then its hard to determine the problem
         * So let reboot and try to recover.
         */
        sprintf (buffer, "Could not switch to SET_LOADED_TO_GOLDEN. Rebooting\n");
        Send_USB_Error_Packet (ERR_FATAL_ERROR_ABORT, 60, buffer);	   
        Reboot_Device ();
      }
    }
    break;
    case SET_LOADED_TO_GOLDEN:
    {
      uint8_t buffer [61];
      result_t ret = SUCCESS;
      /*It may not be required, but still we dont want an interrupt to stop us*/
      TOGGLE_LED (GREEN);
      __nesc_atomic_t atomic = __nesc_atomic_start();
        ret = Map_Loaded_To_Golden ();
      __nesc_atomic_end (atomic);
      TOGGLE_LED (GREEN);
      if (ret == SUCCESS)
      {
        sprintf (buffer, "Mapped Boot Image to golden. Booting New Image.\n");
        Send_USB_Command_Packet (CMD_CREATED_GOLDEN_IMG, 61, buffer);
        Reboot_Device ();
      }
      else
      {
        /* Very Bad, We dont know exactly where we failed. I Guess the
         * best way is reset the whole primary to secondary switch and
         * reboot.
         */
        sprintf (buffer, "Mark loaded to golden failed. Trying to recover\n");
        Send_USB_Error_Packet (ERR_FATAL_ERROR_ABORT, 60, buffer);
        Reboot_Device ();
      }
    }
    break;
    case SET_BOOT_TO_GOLDEN:
    {
      Change_BootLoader_State_Attribute (NORMAL);
      Reboot_Device ();
    }
    break;
    case BOOT_IMAGE:
    break;
    case CODE_LOAD:
      switch (CLoaderState)
      {
        case REQUEST_IMAGE_DETAIL:
        {
          USBCommand cmd;
          if (!MMU_ENABLED)
          {
            MMU_ENABLED = TRUE;
      	    Enable_MMU ();
          }
          cmd.type = CMD_GET_IMAGE_DETAILS;
          Send_Command_Packet (&cmd, sizeof (USBCommand));
        }
        break;
        case REQUEST_USB_PACKETS:
#ifdef MMU_ENABLE
          Request_Next_Binary_Chunk ();
#else
          Request_Next_Binary_Packet ();
#endif
          break;
        case VERIFY_CURRENT_BUFFER:
          break;
        case VERIFY_CURRENT_IMAGE:
          Send_USB_Command_Packet (CMD_IMG_UPLOAD_COMPLETE, 0, NULL);
          break;
        default:
          break;
      }
    break;
    case VERIFY_IMAGE:
    break;
    case VERIFY_SELF_TEST:
      /*Implemented in Recovery State Machine*/
    break;
    default:
      /* This is fatal, It is very essential to investigate why
       * this might have happened but at the same time we dont
       * want to panic. The best is to go back and try normal
       * operation.
       */
      CurrentState = NORMAL;
    break;
  }
}
