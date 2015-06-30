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
 * @file CommandLine.c
 * @author Junaith Ahemed Shahabdeen
 *
 * The file provides the command line interface for the
 * -c option. The command line is a seprate thread.
 */
#include <CommandLine.h>
#include <AttrAccess.h>
#include <USBMessageHandler.h>
#include <BinImageUpload.h>

//#ifdef DEBUG
#include <BinImageFile.h>
//#endif

#define CMD_SIZE 256
#define MAX_ARGS 10

/**
 * print_command_help
 *
 * Displays help menu for the user with different commands
 * and its parameters. The second section provides the
 * name of the attributes and a short description about each
 * attribute.
 */
void print_command_help ()
{
  printf ("Command [Options]\n");
  printf ("Command and Options:\n");
  printf ("\tgetattr: Attribute_Name\n");
  printf ("\t\tRequest the value of an attribute from the attribute table.\n");
  printf ("\t\tThe command dumps the attribute to the stdout.\n");
  printf ("\tsetattr: Attribute_Name Attribute_Value\n");
  printf ("\t\tSet a new value to an attribute in the attribute table.\n");
  printf ("\t\tThe command returns SUCCESS or ERROR to stdout.\n");
  printf ("\tdumpflash:\n");
  printf ("\t\tReads the uploaded code from the Secondary location\n");
  printf ("\t\tin flash and dumps it to a file (flashdump.bin).\n");
  printf ("\t\tThe command is mostly used for upload verification\n");
  printf ("\t\tpurpose.\n");
  printf ("\tloadcode:\n");
  printf ("\t\tIf the application is started with (-tp) option,\n");
  printf ("\t\tthen this command will place the device in Code\n");
  printf ("\t\tLoad mode.\n");
  printf ("\timagedetail:\n");
  printf ("\t\tSend image details to the device while in test \n");
  printf ("\t\tprogram mode, that is if the application is started \n");
  printf ("\t\twith -tp option.\n");
  printf ("\tsendbindata:\n");
  printf ("\t\tSend the next binary chunk to the device. This command\n");
  printf ("\t\tis only valid during test program mode.\n");
  printf ("\tcrc:\n");
  printf ("\t\tSend crc of the current uploaded chunk. This Command\n");
  printf ("\t\tis only valid during test program mode.\n");
  printf ("\n");
  printf ("\n");
  printf ("Attribute List:\n");
  printf ("\tBLR_TABLE    - Address of BootLoader Table.\n");
  printf ("\tSHARED_TABLE - Address of Shared Table (app and boot loader).\n");
  printf ("\tSYNC_TOUT    - Initial PC Sync Timeout.\n");
  printf ("\tCMD_RETRY    - Number of retries for command failures.\n");
  printf ("\tCRC_RETRY    - Number of retries for CRC failues.\n");
  printf ("\tCMD_TOUT     - Timeout Value for Commands (retries).\n");
  printf ("\tBIN_TOUT     - Timeout Value for Binary Chunk (retries).\n");
  printf ("\tST_TOUT      - Timeout Value for Self Test (Watch Dog).\n");
  printf ("\tPIMG_LOC     - Primary or Golden Image Location.\n");
  printf ("\tPIMG_CRC     - Crc of the image loaded in primary location.\n");
  printf ("\tPIMG_SIZE    - Size of the image loaded in primary location.\n");
  printf ("\tSIMG_LOC     - Secondary Image Location.\n");
  printf ("\tSIMG_CRC     - Crc of the image loaded in secondary location.\n");
  printf ("\tSIMG_SIZE    - Size of the image loaded in secondary location.\n");
  printf ("\tBIMG_CRC     - Crc of the Image in boot location. Must be \n");
  printf ("\t\t\tequal to the crc of the primary image.\n");
  printf ("\tBIMG_SIZE    - Size of the image at boot location. Must be \n");
  printf ("\t\t\tequal to the size of the primary image.\n");
  printf ("\tVER_IMG      - TRUE or FALSE. When set to true the boot loader\n");
  printf ("\t\t\twill verify the secondary image and will make\n");
  printf ("\t\t\tit as the current golden image.\n");
  printf ("\tSELF_TEST    - TRUE or FALSE value. When set to true the\n");
  printf ("\t\t\tboot loader prepares the secondary image for self test\n");
  printf ("\t\t\tand load it to boot location. After the Self Test is\n");
  printf ("\t\t\tcompleted the boot loader validates it and decides if\n");
  printf ("\t\t\tthe new image should be marked as golden.\n");
  printf ("\tSTD_IMG_LOC  - Default Self_Test Image Location.\n");
  printf ("\tSTD_IMG_CRC  - Crc of the image loaded in default Self Test location.\n");
  printf ("\tSTD_IMG_SIZE - Size of the image loaded in default Self Test location.\n");
  printf ("\tST_IMG_LOC   - Self_Test Image Location for Application.\n");
  printf ("\tST_IMG_CRC  - Crc of the image loaded in App Self Test location.\n");
  printf ("\tST_IMG_SIZE - Size of the image loaded in App Self Test location.\n");

  printf ("\t\n");
  printf ("\t\t\n");
}

/**
 * Command_Line
 *
 * The Command line interface for the application. This
 * function will wait for a command from the user, once received
 * it will process the command and take the necessary steps.
 * It also provides a help menu which explains the available
 * commands and how to use those commands.
 * This function is invoked as a seperate thread.
 */ 
void* Command_Line ()
{
  unsigned char tmpbuff [CMD_SIZE];
  unsigned char buff [CMD_SIZE];
  unsigned char buff1;
  unsigned char cargs [MAX_ARGS][CMD_SIZE];
  unsigned char* arg;
  unsigned int argc = 1;
  unsigned int numbytes = 0;
  while (1)
  {
    numbytes = 0;
    memset (buff, 0, CMD_SIZE);
    printf ("Command > ");
    /**
     * The command line interface in cygwin is really bad.
     * Its easy to mess up the display. I had to go through all this
     * pain to prevent it as much as possible.
     */
    while (1)
    {
      buff1 = getc (stdin);
      if (buff1 == 27) /* Check if its an escape charecter*/
      { /* If so then dump the next 2 charecters*/
        getc (stdin);
        buff1 = getc (stdin);
        if ((buff1) == 65) printf ("\n"); /*UpArrow, compensate with end lines*/
      }
      else if (buff1 == 8) /*Back Space so delete a charecter*/
      {
        if (numbytes > 0) 
          --numbytes;
      }
      else if (buff1 == 10) /* End line break out of the while loop to process*/
        break;
      else
      {
        tmpbuff [numbytes] = buff1;
        ++numbytes;
      }
    }

    //if (skipLines > 0)
    //while (gets (buff) == NULL) {}
    pthread_testcancel ();

    //if (strcmp (buff, "\n") > 0)
    if (numbytes > 0)
    {
      memcpy (buff, tmpbuff, numbytes);
      arg = strtok (buff, " ");
      strcpy (cargs [0], arg);

      for (argc=1; argc < MAX_ARGS; argc++)
      {
        if ((arg = strtok (NULL, " ")) == NULL)
          break;
        else
          strcpy (cargs [argc], arg);
      }

      //printf ("\t %d %s \n ", argc, cargs [0]);
      if (strcmp (cargs [0], "exit") == 0)
      {
        exit (0);
      }
      else if (strcmp (cargs [0], "getattr") == 0)
      {
        if (argc >= 2)
          Handle_Get_Attribute (cargs [1]);
        else
        {
          fprintf (stderr, "getattr requires atlease 1 argument\n");
          print_command_help ();
        }
      }
      else if (strcmp (cargs [0], "setattr") == 0)
      {
        if (argc >= 3)
          Handle_Set_Attribute (cargs[1], cargs[2]);
        else
        {
          fprintf (stderr, "setattr requires atlease 2 argument\n");
          print_command_help ();
        }
      }
      else if (strcmp (cargs[0], "dumpflash") == 0)
      {
        Dump_From_Flash (0, 0);
      }
      else if (strcmp (cargs[0], "crc") == 0)
      {
        if (argc >= 2)
          Handle_Send_Crc ("0", "0", cargs[1]);
        else
        {
          fprintf (stderr,"The crc command requires atleast 3 arguments\n");
          print_command_help ();
        }
      }
      else if (strcmp (cargs[0], "loadcode") == 0)
      {
        uint8_t imgtyp = APPLICATION;
        if (Send_USB_Command_Packet (RSP_USB_CODE_LOAD, 1, &imgtyp) == FAIL)
          fprintf (stderr, "Could not place the Device in upload mode\n");
      }
      else if (strcmp (cargs[0], "imagedetail") == 0)
      {
        RspImageDetail imgdetail;
        uint8_t Length = sizeof(RspImageDetail);
        imgdetail.ImageSize = (uint32_t)Get_BinFile_Size ();
	imgdetail.NumUSBPck = (uint32_t)Get_Num_USB_Packets (0);
        Send_USB_Command_Packet (RSP_GET_IMAGE_DETAILS, Length, (void*)&imgdetail);
        fprintf (stdout, "GET_IMAGE_DETAILS Received.ImgSize=%ld\n", imgdetail.NumUSBPck);        
      }
      else if (strcmp (cargs[0], "sendbindata") == 0)
      {
        Dbg_Binary_Code_Upload ();
      }
      else if (strcmp (cargs[0], "reboot") == 0)
      {
      }
      else if (strcmp (cargs[0], "help") == 0)
        print_command_help ();
      else if (strcmp (cargs[0], "memtest") == 0)
      {
        Send_USB_Command_Packet (RSP_FLASH_MEM_TEST, 0, NULL);
      }
      else
      {
        fprintf (stderr, "Unknown Command: %s. Ignored.\n",cargs[0]);
      }
      memset (cargs [0], 0, CMD_SIZE);
    }
  }
}

/**
 * Handle_Get_Attribute
 *
 * Checks the arguments passed to the getattr command and 
 * sends a Get_Attribute command to the mote with appropriate
 * attribute type.
 * 
 */ 
result_t Handle_Get_Attribute (char* args)
{
  uint8_t buff [62];
  USBCommand* cmd;
  Attribute* attr;
  cmd = (USBCommand*) buff;
  cmd->type = RSP_GET_ATTRIBUTE;
  attr = (Attribute*) cmd->data;
  if (strcmp (args, "BLR_TABLE") == 0)
    attr->AttrType = BL_ATTR_TYP_BOOTLOADER;
  else if (strcmp (args, "SHARED_TABLE") == 0)
    attr->AttrType = BL_ATTR_TYP_SHARED;
  else if (strcmp (args, "SYNC_TOUT") == 0)
    attr->AttrType = BL_ATTR_TYP_SYNC_TIMEOUT;
  else if (strcmp (args, "CMD_RETRY") == 0)
    attr->AttrType = BL_ATTR_TYP_CMD_FAIL_RETRY;
  else if (strcmp (args, "CRC_RETRY") == 0)
    attr->AttrType = BL_ATTR_TYP_CRC_FAIL_RETRY;
  else if (strcmp (args, "CMD_TOUT") == 0)
    attr->AttrType = BL_ATTR_TYP_CMD_TIMEOUT;
  else if (strcmp (args, "BIN_TOUT") == 0)
    attr->AttrType = BL_ATTR_TYP_BIN_TIMEOUT;
  else if (strcmp (args, "ST_TOUT") == 0)
    attr->AttrType = BL_ATTR_TYP_SELF_TEST_TIMEOUT;
  else if (strcmp (args, "PIMG_LOC") == 0)
    attr->AttrType = BL_ATTR_TYP_PRIMARY_IMG_LOCATION;
  else if (strcmp (args, "PIMG_CRC") == 0)
    attr->AttrType = BL_ATTR_TYP_PRIMARY_IMG_CRC;
  else if (strcmp (args, "PIMG_SIZE") == 0)
    attr->AttrType = BL_ATTR_TYP_PRIMARY_IMG_SIZE;
  else if (strcmp (args, "SIMG_LOC") == 0)
    attr->AttrType = BL_ATTR_TYP_SECONDARY_IMG_LOCATION;
  else if (strcmp (args, "SIMG_CRC") == 0)
    attr->AttrType = BL_ATTR_TYP_SECONDARY_IMG_CRC;
  else if (strcmp (args, "SIMG_SIZE") == 0)
    attr->AttrType = BL_ATTR_TYP_SECONDARY_IMG_SIZE;
  else if (strcmp (args, "VER_IMG") == 0)
    attr->AttrType = ATTR_VERIFY_IMAGE;
  else if (strcmp (args, "SELF_TEST") == 0)
    attr->AttrType = ATTR_PERFORM_SELF_TEST;  
  else if (strcmp (args, "BIMG_CRC") == 0)
    attr->AttrType = BL_ATTR_TYP_BOOT_IMG_CRC;
  else if (strcmp (args, "BIMG_SIZE") == 0)
    attr->AttrType = BL_ATTR_TYP_BOOT_IMG_SIZE; 
  else if (strcmp (args, "STD_IMG_LOC") == 0)
    attr->AttrType = BL_ATTR_TYP_DEF_SELF_TEST_IMG_LOC;
  else if (strcmp (args, "STD_IMG_CRC") == 0)
    attr->AttrType = BL_ATTR_TYP_DEF_SELF_TEST_IMG_CRC;
  else if (strcmp (args, "STD_IMG_SIZE") == 0)
    attr->AttrType = BL_ATTR_TYP_DEF_SELF_TEST_IMG_SIZE; 
  else if (strcmp (args, "ST_IMG_LOC") == 0)
    attr->AttrType = ATTR_SELF_TEST_IMG_LOC;
  else if (strcmp (args, "ST_IMG_CRC") == 0)
    attr->AttrType = ATTR_SELF_TEST_IMG_CRC;
  else if (strcmp (args, "ST_IMG_SIZE") == 0)
    attr->AttrType = ATTR_SELF_TEST_IMG_SIZE;  
  else if (strcmp (args, "BSTATE") == 0)
    attr->AttrType = BL_ATTR_TYP_BOOTLOADER_STATE;  
  else
  {
    fprintf (stderr, "Requesting Unknown Attribute %s\n",args);
    return FAIL;
  }
  Send_USB_Command (cmd, sizeof(USBCommand) + sizeof (Attribute));
  return SUCCESS;
}

/**
 * Handle_Set_Attribute
 *
 * Checks the arguments passed to the setattr command and 
 * sends a Set_Attribute command to the mote with appropriate
 * attribute type and value.
 * 
 */ 
result_t Handle_Set_Attribute (char* args1, char* args2)
{
  uint8_t buff [62];
  Attribute* attr;
  //uint32_t val = (uint32_t) atoi (args2);
  uint32_t val = (uint32_t) strtoul (args2, (char**)NULL, 10);
  attr = (Attribute*) buff;
  //cmd->type = RSP_SET_ATTRIBUTE;
  if (strcmp (args1, "SYNC_TOUT") == 0)
    attr->AttrType = BL_ATTR_TYP_SYNC_TIMEOUT;
  else if (strcmp (args1, "CMD_RETRY") == 0)
    attr->AttrType = BL_ATTR_TYP_CMD_FAIL_RETRY;
  else if (strcmp (args1, "CRC_RETRY") == 0)
    attr->AttrType = BL_ATTR_TYP_CRC_FAIL_RETRY;
  else if (strcmp (args1, "CMD_TOUT") == 0)
    attr->AttrType = BL_ATTR_TYP_CMD_TIMEOUT;
  else if (strcmp (args1, "BIN_TOUT") == 0)
    attr->AttrType = BL_ATTR_TYP_BIN_TIMEOUT;
  else if (strcmp (args1, "ST_TOUT") == 0)
    attr->AttrType = BL_ATTR_TYP_SELF_TEST_TIMEOUT;
  //else if  (strcmp (args1, "PIMG_LOC") == 0)
  //  attr->AttrType = BL_ATTR_TYP_PRIMARY_IMG_LOCATION;
  else if (strcmp (args1, "VER_IMG") == 0)
    attr->AttrType = ATTR_VERIFY_IMAGE;
  else if (strcmp (args1, "SELF_TEST") == 0)
    attr->AttrType = ATTR_PERFORM_SELF_TEST;
  else if (strcmp (args1, "PIMG_CRC") == 0)
    attr->AttrType = BL_ATTR_TYP_PRIMARY_IMG_CRC;
  else if (strcmp (args1, "PIMG_SIZE") == 0)
    attr->AttrType = BL_ATTR_TYP_PRIMARY_IMG_SIZE;
  else if (strcmp (args1, "SIMG_CRC") == 0)
    attr->AttrType = BL_ATTR_TYP_SECONDARY_IMG_CRC;
  else if (strcmp (args1, "SIMG_SIZE") == 0)
    attr->AttrType = BL_ATTR_TYP_SECONDARY_IMG_SIZE;  
  else if (strcmp (args1, "BIMG_CRC") == 0)
    attr->AttrType = BL_ATTR_TYP_BOOT_IMG_CRC;  
  else if (strcmp (args1, "BIMG_SIZE") == 0)
    attr->AttrType = BL_ATTR_TYP_BOOT_IMG_SIZE;  
  //else if (strcmp (args1, "STD_IMG_LOC") == 0)
  //  attr->AttrType = BL_ATTR_TYP_DEF_SELF_TEST_IMG_LOC;
  else if (strcmp (args1, "STD_IMG_CRC") == 0)
    attr->AttrType = BL_ATTR_TYP_DEF_SELF_TEST_IMG_CRC;
  else if (strcmp (args1, "STD_IMG_SIZE") == 0)
    attr->AttrType = BL_ATTR_TYP_DEF_SELF_TEST_IMG_SIZE;   
  //else if (strcmp (args1, "ST_IMG_LOC") == 0)
  //  attr->AttrType = ATTR_SELF_TEST_IMG_LOC;
  else if (strcmp (args1, "ST_IMG_CRC") == 0)
    attr->AttrType = ATTR_SELF_TEST_IMG_CRC;
  else if (strcmp (args1, "ST_IMG_SIZE") == 0)
    attr->AttrType = ATTR_SELF_TEST_IMG_SIZE;  
  else
  {
    fprintf (stderr, "Cannot Set Attribute %s.\n",args1);
    return FAIL;
  }

  attr->AttrLength = 4;
  memcpy (&attr->AttrValue, &val, 4);
  Send_USB_Command_Packet (RSP_SET_ATTRIBUTE, 
                sizeof (Attribute) + attr->AttrLength, buff);
  //Send_USB_Command (cmd, sizeof(USBCommand) + sizeof (Attribute));
  return SUCCESS;
}

/**
 * Handle_Send_Crc
 *
 * Sends a crc command to the mote. The buffer starting and the
 * number of usb packets in the buffer must be passed as a
 * parameter to the function together with the CRC. 
 * NOTE:
 *    This command provides a way to see if the CRC check 
 *    works and also validate if the boot loader is re-requesting
 *    the same buffer when a failure occurs. If the application is
 *    invoked in TestProgram mode the the correct CRC will
 *    be printed to the screen after every chunk is uploaded.
 *
 * @param arg1
 * @param arg2
 * @param arg3   
 *
 * @return SUCCESS | FAIL
 */
result_t Handle_Send_Crc (char* arg1, char* arg2, char* arg3)
{
  uint32_t start = atoi(arg1);
  uint32_t numpck = atoi(arg2);
  uint32_t crc = atoi(arg3);

  fprintf (stdout, " %d  %d \n", atoi(arg1), atoi(arg2));
  Send_Test_CRC_Command (start, numpck, crc);
  return SUCCESS;
}
