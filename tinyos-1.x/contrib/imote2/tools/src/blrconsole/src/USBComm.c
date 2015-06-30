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

#include <USBComm.h>
#include <USBMessageHandler.h>

#define vID 0x042b
#define pID 0x1337

GUID HidGuid;
HDEVINFO hDevInfo;
unsigned long Required;
BOOLEAN MyDeviceDetected = FALSE;

HANDLE DeviceHandle;
OVERLAPPED hRxEventObj;
OVERLAPPED hTxEventObj;
OVERLAPPED HIDOverlapped;

char OutputReport[256];
char InputReport[256];
DWORD NumberOfBytesRead;

DWORD Length = 0;
PSP_DEVICE_INTERFACE_DETAIL_DATA detailData = NULL;
HIDP_CAPS Capabilities;

/**
 * USB_Init
 *
 * Intialize the USB Handle and clear the events and open the USB
 * handle for communication by calling the <B>Open_Imote_HID</B> function.
 *
 * @return SUCCESS | FAIL
 */
result_t USB_Init ()
{
  int ret = FAIL;
  DeviceHandle = INVALID_HANDLE_VALUE;
  hRxEventObj.hEvent = INVALID_HANDLE_VALUE;
  hTxEventObj.hEvent = INVALID_HANDLE_VALUE;

  hRxEventObj.hEvent = CreateEvent (NULL, FALSE, FALSE, NULL);
  hTxEventObj.hEvent = CreateEvent (NULL, FALSE, FALSE, NULL);
  if (Open_Imote_HID ())
    ret = SUCCESS;
  return ret;
}

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
result_t Open_Imote_HID()
{
  //Use a series of API calls to find a HID with a specified Vendor IF and 
  //Product ID.
  HIDD_ATTRIBUTES  Attributes;
  SP_DEVICE_INTERFACE_DATA  devInfoData;
  BOOLEAN LastDevice = FALSE;
  int MemberIndex = 0;
  LONG Result;	

  Length = 0;
  detailData = NULL;
  DeviceHandle=NULL;

  HidD_GetHidGuid(&HidGuid);
  hDevInfo=SetupDiGetClassDevs (&HidGuid, NULL, NULL, 
		  DIGCF_PRESENT|DIGCF_INTERFACEDEVICE);
  devInfoData.cbSize = sizeof(devInfoData);

  //Step through the available devices looking for the one we want. Quit on
  //detecting the desired device or checking all available devices without 
  //success.
  MemberIndex = 0;
  LastDevice = FALSE;
  do
  {
    Result=SetupDiEnumDeviceInterfaces (hDevInfo, 0, &HidGuid, 
                                        MemberIndex, &devInfoData);
    if (Result != 0)
    {
      //A device has been detected, so get more information about it.
      //Get the Length value.
      //The call will return with a "buffer too small" error which can be ignored.
      Result = SetupDiGetDeviceInterfaceDetail (hDevInfo, &devInfoData, 
                                                NULL, 0, &Length, NULL);

      //Allocate memory for the hDevInfo structure, using the returned Length.
      detailData = (PSP_DEVICE_INTERFACE_DETAIL_DATA)malloc(Length);

      //Set cbSize in the detailData structure.
      detailData -> cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA);

      //Call the function again, this time passing it the returned buffer size.
      Result = SetupDiGetDeviceInterfaceDetail (hDevInfo, &devInfoData, 
                                           detailData, Length, &Required, NULL);

      // Open a handle to the device.
      // To enable retrieving information about a system mouse or keyboard,
      // don't request Read or Write access for this handle.
      DeviceHandle=CreateFile (detailData->DevicePath, 
             GENERIC_WRITE | GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, 
             (LPSECURITY_ATTRIBUTES)NULL, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, NULL);

      //printf ("The Last Error = %lx\n", GetLastError());

      //Set the Size to the number of bytes in the structure.
      Attributes.Size = sizeof(Attributes);
      Result = HidD_GetAttributes (DeviceHandle, &Attributes);
      //printf("The Last Error = %ld\n", GetLastError());
      //Is it the desired device?
      MyDeviceDetected = FALSE;

      if (Attributes.VendorID == vID)
      {
        if (Attributes.ProductID == pID)
        {
          MyDeviceDetected = TRUE;
          Get_Device_Capabilities();
          //Register the Device to detect if the device is attached or removed.
          Register_For_Device_Notifications (HidGuid);
        }
        else
          //The Product ID doesn't match.
          CloseHandle(DeviceHandle);
      }
      else
        //The Vendor ID doesn't match.
        CloseHandle(DeviceHandle);
      free(detailData);
    }
    else
      LastDevice=TRUE;
    MemberIndex = MemberIndex + 1;
  } while ((LastDevice == FALSE) && (MyDeviceDetected == FALSE));

  if (MyDeviceDetected == FALSE)
    printf ("Device not detected\n");
  else
    printf ("Device detected\n");

  SetupDiDestroyDeviceInfoList (hDevInfo);
  //printf("The Last Error = %s\n", GetLastError());
  return MyDeviceDetected;
}

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
void Get_Device_Capabilities()
{
  //Get the Capabilities structure for the device.
  PHIDP_PREPARSED_DATA PreparsedData;

  HidD_GetPreparsedData (DeviceHandle, &PreparsedData);
  HidP_GetCaps (PreparsedData, &Capabilities);
  HidD_FreePreparsedData(PreparsedData);
}

/**
 * Get_OutputReportByteLength
 *
 * Returns the output report length of the
 * current device.
 * 
 * @return Report Length.
 */
int Get_OutputReportByteLength ()
{
  return Capabilities.OutputReportByteLength;
}

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
void Write_Output_Report (char* data, int length)
{
  //Send a report to the device.
  DWORD BytesWritten = 0;
  ULONG Result;
  memcpy (OutputReport, data, length);
  ResetEvent (hTxEventObj.hEvent);
  if (DeviceHandle != INVALID_HANDLE_VALUE)
  {
    Result = WriteFile (DeviceHandle, OutputReport,
        Capabilities.OutputReportByteLength, 
        &BytesWritten, &hTxEventObj);
    while (!(HasOverlappedIoCompleted(&hTxEventObj)));
  }
  else
  {
    printf ("Invalid Write handle\n");
  }

  if (Result)
    printf ("Can't write to device %ld, Bytes Written %ld\n", GetLastError(), BytesWritten);
  else
    GetLastError();
}

/**
 * Close_Handles
 *
 * Close all the device handles.
 */
void Close_Handles()
{
  //Close open handles.
  //if (DeviceHandle == INVALID_HANDLE_VALUE)
  //{
    CloseHandle(DeviceHandle);
    fprintf (stderr, "Device Handle closed \n");
  //}
}

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
void Read_Input_Report()
{
  // Retrieve an Input report from the device.
  short	Result;
  //OVERLAPPED overlapped;
	
  while (DeviceHandle != INVALID_HANDLE_VALUE)
  {
    //The first byte is the report number.
    InputReport[0]=0;
    pthread_testcancel ();
    if (DeviceHandle != INVALID_HANDLE_VALUE)
    {
      Result = ReadFile (DeviceHandle, InputReport, 
		      Capabilities.InputReportByteLength, &NumberOfBytesRead, 
		      (LPOVERLAPPED) &hRxEventObj); 
    }
    //printf("The Last Error = %lx\n", GetLastError());
    Result = WaitForSingleObject (hRxEventObj.hEvent, 1000);
    pthread_testcancel ();
    switch (Result)
    {
      case WAIT_OBJECT_0:
        {
          uint8_t type;
          uint8_t valid;
          USBdata *USBin;
          USBdata USBData;
          type = *(InputReport + IMOTE_HID_TYPE);
          USBin = &USBData;
          if(isFlagged(type, _BIT(IMOTE_HID_TYPE_H)))
          {
            USBin->i = 0;
            USBin->type = type;
            switch((USBin->type >> IMOTE_HID_TYPE_L) & 3)
            {
              case IMOTE_HID_TYPE_L_BYTE:
                USBin->n = *(InputReport + IMOTE_HID_NI);
                if (USBin->n == 0)
                  valid = *(InputReport + IMOTE_HID_NI + 1);
                else
                  valid = IMOTE_HID_BYTE_MAXPACKETDATA;
                USBin->data = (BYTE *)malloc(valid);
                memcpy (USBin->data, InputReport + IMOTE_HID_NI + 1 + 
				(USBin->n == 0?1:0), valid);
              break;
              case IMOTE_HID_TYPE_L_SHORT:
                USBin->n = (*(InputReport + IMOTE_HID_NI) << 8) | 
			*(InputReport + IMOTE_HID_NI + 1);
                if(USBin->n == 0)
                  valid = *(InputReport + IMOTE_HID_NI + 2);
                else
                  valid = IMOTE_HID_SHORT_MAXPACKETDATA;
                USBin->data = (BYTE *)malloc(valid);
                memcpy(USBin->data, InputReport + IMOTE_HID_NI + 2 + 
                                           (USBin->n == 0?1:0), valid);
              break;
              case IMOTE_HID_TYPE_L_INT:
                USBin->n = (*(InputReport + IMOTE_HID_NI) << 24) | 
                        (*(InputReport + IMOTE_HID_NI + 1) << 16) | 
                        (*(InputReport + IMOTE_HID_NI + 2) << 8) | 
			*(InputReport + IMOTE_HID_NI + 3);
                if(USBin->n == 0)
                  valid = *(InputReport + IMOTE_HID_NI + 4);
                else
                  valid = IMOTE_HID_INT_MAXPACKETDATA;
                USBin->data = (BYTE *)malloc(valid);
                memcpy(USBin->data, InputReport + IMOTE_HID_NI + 4 +
			       	(USBin->n == 0?1:0), valid);
              break;
              default:
                //printf ("Not a valid case\n");
              break;
            }

            if (((USBin->type >> 5) & 0x7) == IMOTE_HID_TYPE_MSC_BINARY)
            {
              Binary_Packet_Received (USBin->data, valid, USBin->n);
            }
            else if (((USBin->type >> 5) & 0x7) == IMOTE_HID_TYPE_MSC_COMMAND)
            {
              Command_Packet_Received (USBin->data);
            }
            else if (((USBin->type >> 5) & 0x7) == IMOTE_HID_TYPE_MSC_ERROR)
            {
              Error_Packet_Received (USBin->data);
            }
            else
            {
               fprintf (stderr, "Unknown USB Packet %d\n",USBin->type);
            }	    
          }
          break;
        }
      case WAIT_TIMEOUT:
        //printf ("ReadFile timeout.\n");
        //Cancel the Read operation.
        Result = CancelIo(DeviceHandle);

        //A timeout may mean that the device has been removed. 
        //Close the device handles and set MyDeviceDetected = False 
        //so the next access attempt will search for the device.
        //Close_Handles();
        //printf ("Can't read from device\n");
        //MyDeviceDetected = FALSE;
      break;
      default:
        fprintf (stderr, "Undefined error\n");

        //Close the device handles and set MyDeviceDetected = False 
        //so the next access attempt will search for the device.
        Close_Handles();
        fprintf (stderr, "Can't read from device \n");
        MyDeviceDetected = FALSE;
        break;
    }
    memset (InputReport, 0, 65);
    ResetEvent(hRxEventObj.hEvent);
  }
  //Display the report data.
  //DisplayInputReport();
}
