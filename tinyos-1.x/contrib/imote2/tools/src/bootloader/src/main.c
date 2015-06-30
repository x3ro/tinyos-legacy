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
 * @author Junaith Ahemed Shahabdeen
 * @file main.c
 *
 * The main acts an entry point for the bootloader after initialization
 * of the processor is completed. The file provides <B>main</B> and the
 * sup loop for the boot loader. Overview of functionalities in the file
 *
 * 1. Initalize the hardware.
 * 2. Perform the required checks before booting up the OS. (see main).
 * 3. Try to boot the OS, if it fails then wait for a new load by
 *    enabling USB.
 * 4. Validate the existing OS before booting to the OS.   
 */
#include <hardware.h>
#include <USBClient.h>
#include <HPLInit.h>
#include <PXA27XGPIOInt.h>
#include <FlashAccess.h>
#include <BootLoader.h>
#include <MessageDefines.h>
#include <stdlib.h>
#include <string.h>
#include <leds.h>
#include <PMIC.h>
#include <AttrAccess.h>
#include <BinImageHandler.h>
#include <PXA27XClock.h>
#include <PXA27Xdynqueue.h>
#include <TOSSched.h>


extern void handle_jump (); /* defined in barcert.s*/
uint32_t jmp_addr = 0x20;   /* Address of the OS reset_vector*/ 
uint32_t waitTime = 0;      /* Sync Timeout (populated from attr table)*/
uint32_t OpCode = 0;        /* Opcode of the jmp_addr*/

void Sync_Timed_Out (uint8_t MsgId, uint8_t Typ, uint8_t retries);
result_t Set_Sync_Timout ();
result_t Check_OS_Validity_And_Jump ();

bool USBInited = FALSE;     /*Start and Stop of USB before jumping to the OS*/
TimeoutDetail toutdetail; /*Time out details for PC SYNC TIMEOUT*/
#if 0
bool POST_BOOT_STATE = FALSE;   /*bootloader_state_machine called from sup*/
bool POST_SYNC_TIMEOUT = FALSE; /*Post_Sync_Timed_Out called from sup*/
bool POST_USB_PROCESS_OUT = FALSE; /*processOut from sup*/
bool POST_USB_BIN_PROCESS_OUT = FALSE; /*Bin_processOut called from sup*/

DynQueue TxQueue, RxQueue; /* Points to the InQueue and OutQueue of USB Driver*/

/**
 * Post_BootLoader_State
 *
 * Set to call the boot loader state machine from the sup loop.
 * This is mainly useful if the boot loader has to be called from
 * any state other than SVC and has to execute in SVC.
 *
 * @return SUCCESS
 */
result_t Post_BootLoader_State ()
{
  POST_BOOT_STATE  = TRUE;
  return SUCCESS;
}

#if 0
result_t Post_Bin_Process_Out ()
{
  POST_USB_BIN_PROCESS_OUT = TRUE;
  return SUCCESS;
}
#endif

/**
 * Post_Process_Out
 *
 * Delayed processing of the USB received packets. The 
 * USB driver adds the received messages to the a queue
 * and passes the head of the queue to this function.
 * The main purpose of the delayed execution is to change
 * the state from IRQ to SVC.
 * The received packets in queue is processed when the
 * control returns to the SUP LOOP.
 * 
 * @return SUCCESS | FAIL
 */
result_t Post_Process_Out (DynQueue OutQ)
{
  RxQueue = OutQ;
  POST_USB_PROCESS_OUT = TRUE;
  return SUCCESS;
}
#endif

/**
 * Set_Sync_Timout
 *
 * Setup the Timer for SYNC TIMEOUT. The boot loader tries to synchronize
 * with the PC in this window. 
 *
 * @return SUCCESS | FAIL
 */
result_t Set_Sync_Timout ()
{
  TOGGLE_LED (YELLOW);
  //toutdetail.TimeoutMS = waitTime;
  toutdetail.TimeoutMS = 2000; /*we need to finish the enumeration*/
  toutdetail.MsgId = SYNC_TIMEOUT;
  toutdetail.Type = 0;
  toutdetail.ExpectedType = 0;
  toutdetail.NumRetries = 0;
  toutdetail.NotifyFunc = &Sync_Timed_Out;
  Enable_Timeout (&toutdetail);
  return SUCCESS;
}

/**
 * Check_OS_Validity_And_Jump
 *
 * The function checks the validity of the current OS in the
 * boot location by comparing the crc of the boot location
 * and the primary location before jumping to the location.
 * 
 * @return SUCCESS | FAIL
 */
result_t Check_OS_Validity_And_Jump ()
{
  result_t ret = FAIL;
  uint32_t BootImgCrc;
  uint32_t PrimImgCrc;
  
  /*Lets try to boot the existing Image*/
  if ((ret = Read_Attribute_Value (BL_ATTR_TYP_BOOT_IMG_CRC, 
                           (void*)&BootImgCrc)) == SUCCESS)
  {
    if (BootImgCrc > 0) /*The assumption is that no valid image will have CRC=0*/
    {
      if ((ret = Read_Attribute_Value (BL_ATTR_TYP_PRIMARY_IMG_CRC, 
                              (void*)&PrimImgCrc)) == SUCCESS)
      {
        if (BootImgCrc == PrimImgCrc)
        {
          /*What if the Attribute is out of Sync and there is no
           *valid os in that location
           */
          OpCode = (*((uint32_t *)jmp_addr));
          if (OpCode != 0xFFFFFFFF)
          {
            if (USBInited) 
              USB_Stop ();
            TOSH_SET_GREEN_LED_PIN ();
            TOSH_SET_YELLOW_LED_PIN ();
            TOSH_SET_RED_LED_PIN ();
	    /*Lock down attribute tables*/
            Flash_Lockdown(BL_ATTR_ADDRESS_TABLE);
            Flash_Lockdown(BL_ATTR_DEF_BOOTLOADER);
            Flash_Lockdown(BL_ATTR_BOOTLOADER);
            /*Lock down the bootloader location*/
	    Flash_Lockdown(0x200000);
            handle_jump ();
          }
        }
        else
          ret = FAIL;
      }
    }
    else
      ret = FAIL;
  }
  return ret;
}

/**
 * Post_Sync_Timed_Out
 *
 * Delayed execution of Sync_Timed_Out function. The function
 * checks if the boot loader state has changed while it was
 * waiting for a PC Sync. If the state remains NORMAL then
 * PC Sync has failed so it tries to boot the existing OS. If there
 * is not valid OS in the Boot Location then the boot loader
 * waits for a PC download.
 * 
 */
void Post_Sync_Timed_Out ()
{
  TOGGLE_LED (YELLOW);
  if (Get_BootLoader_State () == NORMAL)
  {
    if (Check_OS_Validity_And_Jump () == FAIL)
      return;
  }
}

/**
 * Sync_Timed_Out
 *
 * Event that is called from the timer interrupt when a sync timeout
 * is requested. The function posts the Sync time out and returns.
 * The parameters are mainly to be compatible with the timer
 * call back function defined in <I>PXA27XClock.h</I>.
 *
 * @param MsgId Message Id.
 * @param Typ   Identifies the Message Type.
 * @param retries Number of retries left.  
 */
void Sync_Timed_Out (uint8_t MsgId, uint8_t Typ, uint8_t retries)
{
  //POST_SYNC_TIMEOUT = TRUE;
  TOS_post (&Post_Sync_Timed_Out);
  return;
}

/**
 * Main_Loop
 * 
 * SUP Loop for the application. The function provides an additional
 * delayed execution mechanism which is required especially if the
 * code is in <I>CPSR_IRQ</I> state.
 */
void Main_Loop ()
{
  TOSH_CLR_GREEN_LED_PIN ();
  while (1) 
  {
#if 0	  
    if (POST_USB_PROCESS_OUT)
    {
      if(DynQueue_getLength(RxQueue) >= 1)
        processOut ();
      else
        POST_USB_PROCESS_OUT = FALSE;
    }
    else if (POST_USB_BIN_PROCESS_OUT)
    {
      POST_USB_BIN_PROCESS_OUT = FALSE;
      processOut_Binary ();
    }
    else if (POST_BOOT_STATE)
    {
      POST_BOOT_STATE = FALSE;
      BootLoader_State_Machine ();
    }
    else if (POST_SYNC_TIMEOUT)
    {
      POST_SYNC_TIMEOUT = FALSE;
      Post_Sync_Timed_Out ();
    }
#endif
    TOSH_run_task();
  }
}

/**
 * main
 *
 * Entry point for Boot Loader Application. The main does the following
 * checks before trying to boot an existing OS.
 *
 * 1. Check the current BootLoader state and confirm that it is NORMAL, if
 *    the current state is not normal then it means that the system requires
 *    <B>recovry</B>. The boot loader recovery state machine is called to
 *    handle the current state.
 * 2. If the current boot state is unknown then the boot loader attribute
 *    table is corrupted so the attribute table is recovered from the 
 *    default location.
 * 3. Secondly the boot loaders checks to see if the OS has requested
 *    a verify image or self test. If either of them is selected then it
 *    performs the required functions. SELF_TEST includes verification
 *    of the image in the secondary location so setting both of the
 *    attributes (SELF_TEST and VERIFY_IMAGE) will only not have any
 *    effect on VERIFY_IMAGE, only SELF_TEST will be performed.
 * 4. Before jumping to the current OS the bootloader checks to see
 *    if the USB cable is connected if so then it tries to sync with
 *    the PC to see if the user wants to download a new image. If the
 *    SYNC fails then its boots up the current image.
 * 5. <I>DEEP SLEEP</I> reboot is treated as a special case, the bootloader
 *    directly loads the current valid image without performing any
 *    of the above tests.
 */
int main ()
{
  uint32_t bstate;
  uint32_t verifyImg = 0;
  uint32_t selftest = 0;
  
  HPLInit ();
  Leds_Init ();
  FlashAccess_Init();

  /* FIXME this should be done at the start of the reset
   * vector. We dont have to reach till here.
   */
  if (RCSR & RCSR_SMR)
    Check_OS_Validity_And_Jump ();
  

  /*Check if we have to recover from any crash.*/
  if (Read_Attribute_Value (BL_ATTR_TYP_BOOTLOADER_STATE, (void*)&bstate) == SUCCESS)
  {
    if (bstate != NORMAL)
    {
      SetCoreFreq (104, 104);
      TOGGLE_LED (YELLOW);
      /*Invoke the recovery phase*/
      Change_BootLoader_State (bstate);
      /*We will either reboot or stall*/
      BootLoader_Recovery_State_Machine ();
    }
  }
  else
  {
    TOGGLE_LED (YELLOW);
    /* This might be being too paranoid but, We can recover by reloading*/
    Recover_Default_Table (BL_ATTR_TYP_BOOTLOADER);
  }

  Read_Attribute_Value (ATTR_PERFORM_SELF_TEST, (void*)&selftest); 
  Read_Attribute_Value (ATTR_VERIFY_IMAGE, (void*)&verifyImg); 
  /* The next stage is to check if there is an request from the application for
   * verifying image or self test.
   */
  if (selftest)
  {
    //SetCoreFreq (104, 104);
    TOGGLE_LED (YELLOW);
    if (Write_Attribute_Value (ATTR_PERFORM_SELF_TEST, 0) == SUCCESS)
    {
      /* Just a sanity check, we dont need to run both at the same time
       * because self test includes verification of the image.
       */
      if (verifyImg)
        Write_Attribute_Value (ATTR_VERIFY_IMAGE, 0);
      if (Prepare_Self_Test () == FAIL)
        Reboot_Device ();
    }
  }
  /** 
   * Selftest involves Image Validataion so we dont have to repeat it.
   */
  else if ((!selftest) && (verifyImg))
  {
    SetCoreFreq (104, 104);
    TOGGLE_LED (YELLOW);
    if (Write_Attribute_Value (ATTR_VERIFY_IMAGE, 0) == SUCCESS)
    { 
      if (Verify_Image_And_Make_Golden () == SUCCESS)
      {
        //POST_BOOT_STATE = TRUE;
        /**
         * Lets start the main loop right here and enable the
         * USB messages if there is a USB Connection,
         */
        HPLUSBClientGPIO_Init ();
        if ((HPLUSBClientGPIO_CheckConnection ()) == SUCCESS)
          USB_Init ();
      }
      else
      {
        /*FIXME Set the Error Attribute with the proper value.*/
        Reboot_Device ();
      }
    }
  }
  else
  {
    PXA27XGPIOInt_Init ();
    HPLUSBClientGPIO_Init ();
    PMIC_Init();
    TOSH_sched_init();    
    if ((HPLUSBClientGPIO_CheckConnection ()) == SUCCESS)
    {
      USB_Init ();
      USBInited = TRUE;
      if (Read_Attribute_Value (BL_ATTR_TYP_SYNC_TIMEOUT, (void*)&waitTime) == FAIL)
        waitTime = 500; /* Dont make a big deal. Just a time out failure*/
      Set_Sync_Timout ();
    }
    else
    {
      HPLUSBClientGPIO_Stop ();
      PXA27XGPIOInt_Stop ();
      Check_OS_Validity_And_Jump ();
    }
  }
  Main_Loop ();
  return 0;
}
