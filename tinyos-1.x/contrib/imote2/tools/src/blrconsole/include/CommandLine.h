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
 * @file CommandLine.h
 * @author Junaith Ahemed
 *
 * The file provides the command line interface for the
 * -c option. The command line is a seprate thread.
 */
#ifndef COMMAND_LINE_H
#define COMMAND_LINE_H

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <wtypes.h>
#include <windows.h>
#include <pthread.h>

#include <USBMessageHandler.h>

/**
 * Parse_Arguments
 *
 * Parse the arguments from the command line of the
 * terminal. The function passed each argument to CmdLine_Argument
 * function which will perform necessary action based
 * on the argument.
 * 
 * @param argv The argument list passed through the command line
 */
void Parse_Arguments (LPSTR argv);

/**
 * CmdLine_Argument
 *
 * This function identifies each argument from the argument list
 * passed through the command line and performs specific actions
 * based on the argument.
 *
 * @param par Parsed argument from Parse_Argument function.
 */
void CmdLine_Argument (char* par);

/**
 * Is_STImage
 *
 * Check if we are downloading SELF Test Image to the
 * device. The function returns boolean variable
 * STImage.
 *
 * @return STImage TRUE | FALSE
 */
BOOLEAN Is_STImage ();

/**
 * Is_Test_Program_Mode
 *
 * Returns the boolean variable TestProgramMode. If the application is 
 * compiled with DEBUG flag then it accepts an extra command 
 * line parameter '-tp' which provides step by step control to the user 
 * over the communication with the bootloader.
 * 
 * @return TestProgramMode = TRUE | FALSE
 */
BOOLEAN Is_Test_Program_Mode ();

/**
 * Binary_Upload_Completed
 * 
 * Reverts the programming mode. Checks if the application has to
 * stay in command line mode.
 */
void Binary_Upload_Completed ();

/**
 * Exit_Applicaiton
 *
 * This function provides a reliable way of exiting the application.
 * It makes sure that the threads are terminated before the exit
 * function is call. It is advisable to call this function for a
 * clean exit rather than using exit(0).
 */
void Exit_Application ();


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
void* Command_Line ();

/**
 * Handle_Get_Attribute
 *
 * Checks the arguments passed to the getattr command and 
 * sends a Get_Attribute command to the mote with appropriate
 * attribute type.
 * 
 */ 
result_t Handle_Get_Attribute (char* args);

/**
 * Handle_Set_Attribute
 *
 * Checks the arguments passed to the setattr command and 
 * sends a Set_Attribute command to the mote with appropriate
 * attribute type and value.
 * 
 */ 
result_t Handle_Set_Attribute (char* args1, char*args2);

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
result_t Handle_Send_Crc (char* arg1, char* arg2, char* arg3);


#endif
