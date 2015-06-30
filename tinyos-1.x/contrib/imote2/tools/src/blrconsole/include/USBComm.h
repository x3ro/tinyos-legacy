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
 * @file USBComm.c
 * @author Junaith Ahemed Shahabdeen
 *
 * This modules communicates with the USB driver to send and
 * receive packets. It also provides functions to search
 * through a list of USB devices of a specific class and
 * set up an overlapped I/O communication with those devices.
 * The file uses lot of inbuilt function of the HID class defined
 * in the windowsDDK, the usage of each function is explained when
 * required.
 */
#ifndef USB_COMM_H
#define USB_COMM_H

#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0501
#endif

#ifndef WINVER
#define WINVER 0x0501
#endif


#ifndef WM_INPUT
#define WM_INPUT 0x00FF
#endif

#include <stdio.h>
#include <assert.h>
#include <wtypes.h>
#include <hidsdi.h>
#include <setupapi.h>

#include <windows.h>
#include <dbt.h>
#include <winuser.h>

#include <pthread.h>
#include <USBDefines.h>
#include <types.h>

/**
 * USB_Init
 *
 * Intialize the USB Handle and clear the events and open the USB
 * handle for communication by calling the <B>Open_Imote_HID</B> function.
 *
 * @return SUCCESS | FAIL
 */
result_t USB_Init ();

/**
 * Open_Imote_HID
 *
 * The function opens the USB communication handle to the IMote. I browses 
 * through the list of members in the HID class from windows and identifies 
 * the deivces of interest using the PID and the VID.
 *
 * <B>HidD_GetHidGuid</B> gets the GUID for all system HIDs and returns the 
 * GUID in HidGuid.
 *
 * <B>SetupDiGetClassDevs</B> returns a handle to a device information set for 
 * all installed devices. It requires the GUID returned by GetHidGuid.
 *
 * <B>SetupDiEnumDeviceInterfaces</B>, On return, MyDeviceInterfaceData contains 
 * the handle to SP_DEVICE_INTERFACE_DATA structure for a detected device. The 
 * function requires the DeviceInfoSet returned in SetupDiGetClassDevs, the 
 * HidGuid returned in GetHidGuid and an index to specify a device.
 *
 * <B>SetupDiGetDeviceInterfaceDetail</B> returns a SP_DEVICE_INTERFACE_DETAIL_DATA
 * structure containing information about a device. To retrieve the information, 
 * call this function twice. The first time returns the size of the structure in 
 * Length. The second time returns a pointer to the data in DeviceInfoSet. It 
 * requires a DeviceInfoSet returned by SetupDiGetClassDevs the 
 * SP_DEVICE_INTERFACE_DATA structure returned by SetupDiEnumDeviceInterfaces. 
 * The final parameter is an optional pointer to an SP_DEV_INFO_DATA structure.
 * This application doesn't retrieve or use the structure. If retrieving the 
 * structure, set MyDeviceInfoData.cbSize = length of MyDeviceInfoData. and pass 
 * the structure's address.
 *
 * <B>CreateFile</B> returns a handle that enables reading and writing to the 
 * device. It requires the DevicePath in the detailData structure returned by 
 * SetupDiGetDeviceInterfaceDetail.
 *
 * <B>HidD_GetAttributes</B> requests information from the device. It requires
 * the handle returned by CreateFile and returns a HIDD_ATTRIBUTES structure 
 * containing the Vendor ID, Product ID, and Product Version Number. Use this 
 * information to decide if the detected device is the one we're looking for.
 *
 * @return SUCCESS | FAIL
 */
result_t Open_Imote_HID();

/**
 * Get_Device_Capabilities
 * 
 * <B>HidD_GetPreparsedData</B> returns a pointer to a buffer containing
 * the information about the device's capabilities. It requires a handle 
 * returned by CreateFile. There's no need to access the buffer directly, but 
 * HidP_GetCaps and other API functions require a pointer to the buffer.
 *
 * <B>HidP_GetCaps</B> Learn the device's capabilities.For standard devices 
 * such as joysticks, you can find out the specific capabilities of the device.
 * For a custom device, the software will probably know what the device is 
 * capable of, and the call only verifies the information. It requires the 
 * pointer to the buffer returned by HidD_GetPreparsedData and returns a 
 * Capabilities structure containing the information.
 */
void Get_Device_Capabilities();


void Prepare_For_Overlapped_Transfer();

/**
 * Write_Output_Report
 * 
 * The function writes a byte array to the USB using WriteFile function. The
 * api functions used are explained below. 
 * 
 * <B>WriteFile</B> Sends a report to the device. It returns success or failure.
 * The function requires, a device handle returned by CreateFile, a buffer that 
 * holds the report, the Output Report length returned by HidP_GetCaps, a 
 * variable to hold the number of bytes written.
 *
 */
void Write_Output_Report(char* data, int length);

/**
 * Close_Handles
 *
 * Close all the device handles.
 */
void Close_Handles();

/**
 * Read_Input_Report
 * 
 * Function loops around till the handle is valid and tries to read packets from the USB. The
 * main programs forks a seperate thread for this function to constantly monitory the
 * incomming traffic.
 *
 * Few of the API calls used in this function are explained below.
 * 
 * <B>ReadFile</B> returns the report in InputReport. It requires a device 
 * handle returned by CreateFile (for overlapped I/O, CreateFile must be called 
 * with FILE_FLAG_OVERLAPPED),the Input report length in bytes returned by 
 * HidP_GetCaps, and an overlapped structure whose hEvent member is set to 
 * an event object.	
 *
 * <B>WaitForSingleObject</B> is used with overlapped ReadFile. It returns 
 * when ReadFile has received the requested data or on timeout. Requires 
 * an event object created with CreateEvent and a timeout value in milliseconds.
 * 
 * <B>CancelIo</B> Cancels the ReadFile and returns non-zero on success.
 *
 * <B>ResetEvent</B> sets the event object to non-signaled. Requires a handle to 
 * the event object. Returns non-zero on success.
 * 
 */
void Read_Input_Report();

/**
 * Register_For_Device_Notifications
 *
 * Register a particular Class of device with the lover level
 * driver interface to get notifications about any changes in
 * the device status (attached, detached etc.) 
 * 
 * @param HidGuid GUID of a particular class.
 */
void Register_For_Device_Notifications (GUID hidG);

/**
 * Get_OutputReportByteLength
 *
 * Returns the output report length of the
 * current device.
 * 
 * @return Report Length.
 */
int Get_OutputReportByteLength ();
#endif
