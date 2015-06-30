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
 * @file main.c
 * @author Junaith Ahemed Shahabdeen
 *
 * Entry point for the USB Loader application. The file provides
 * an interface to the lower level windows drivers which is
 * required to recieve notifications about changes at the lower level.
 *
 * The file actually creates and intializes a window with out displaying
 * one. The reason is because the notification registration for the
 * devices is possible only if the app is either a window based or a
 * service based. It is a future requirement to enable window
 * based applications hence a window based approach.
 */
#include <USBComm.h>
#include <USBMessageHandler.h>
#include <CommandLine.h>
#include <BinImageFile.h>
#include <sys/time.h>
#include <sys/signal.h>

#define MAX_FILE_NAME_SIZE 1024
pthread_t thread_rx, thread_cmd;
struct sigaction actions;
BOOLEAN ProgramMode = FALSE;
BOOLEAN STImage = FALSE;
BOOLEAN TestProgramMode = FALSE;
BOOLEAN CmdLineMode = FALSE;
BOOLEAN DownloadDone = FALSE;

char FileName [MAX_FILE_NAME_SIZE] = "\0";

HWND hwnd;
MSG Msg;
HDEVNOTIFY DeviceNotificationHandle;

struct timeval start, end;
unsigned long timeelapsed = 0, sec = 0, usec = 0;

struct timeval  now;            /* time when we started waiting        */
struct timespec timeout;        /* timeout value for the wait function */
int             done;           /* are we done waiting?                */
pthread_cond_t got_request = PTHREAD_COND_INITIALIZER;
pthread_mutex_t req_mutex = PTHREAD_MUTEX_INITIALIZER;

const char g_szClassName[] = "myWindowClass";

/**
 * print_help
 *
 * This function prints the help menu for the main app.
 */
void print_help ()
{
  printf ("out.exe [Options] [FileName]\n");
  printf ("Options:\n");
  printf (" -p FileName:\t Upload a binary file to the Device.\n");
  printf (" -tp FileName:\t Upload a binary file to the Device in\n");
  printf ("\t\t a interactively. The display guides the user about\n");
  printf ("\t\t the next action required. If the user has to send\n");
  printf ("\t\t a command with parameter, then the value of the\n");
  printf ("\t\t parameters are diplayed in stdout.\n");
  printf (" -c\t\t Place the Device in command line mode.\n");
  printf (" -pst\t\t FileName: Upload selftest image to the device.\n");
}

/**
 * Register_For_Device_Notifications
 *
 * Register a particular Class of device with the lover level
 * driver interface to get notifications about any changes in
 * the device status (attached, detached etc.) 
 * 
 * @param HidGuid GUID of a particular class.
 */
void Register_For_Device_Notifications(GUID HidGuid)
{
  // Request to receive messages when a device is attached or removed.
  // Also see WM_DEVICECHANGE in BEGIN_MESSAGE_MAP(CUsbhidiocDlg, CDialog).

  DEV_BROADCAST_DEVICEINTERFACE DevBroadcastDeviceInterface;

  ZeroMemory (&DevBroadcastDeviceInterface, sizeof(DevBroadcastDeviceInterface));
  DevBroadcastDeviceInterface.dbcc_size = sizeof(DevBroadcastDeviceInterface);
  DevBroadcastDeviceInterface.dbcc_devicetype = DBT_DEVTYP_DEVICEINTERFACE;
  DevBroadcastDeviceInterface.dbcc_classguid = HidGuid;

  DeviceNotificationHandle = RegisterDeviceNotification (hwnd, 
			&DevBroadcastDeviceInterface, DEVICE_NOTIFY_WINDOW_HANDLE);

  if (!DeviceNotificationHandle)
  {
    printf ("Registration Failed = %lx\n", GetLastError());
  }
}

/**
 * WndProc
 *
 * Call back funciton registerd with the lower level driver which gets
 * invoked when there are any changes with the device attached or
 * events related to this process.
 *
 */
LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  switch(msg)
  {
    case WM_CREATE:
      //printf ("Window Created \n");
      break;
    case WM_CLOSE:
      DestroyWindow(hwnd);
      break;
    case WM_DESTROY:
      PostQuitMessage(0);
      break;
    case WM_DEVICECHANGE:
      switch (wParam)
      {
        case DBT_DEVICEARRIVAL:
          if (DownloadDone)
          {
            fprintf (stderr, "Booted New Application.\n");
            Exit_Application ();
          }
          if (DeviceNotificationHandle)
            UnregisterDeviceNotification (DeviceNotificationHandle);
          USB_Init ();
//#if DEBUG
         if (!TestProgramMode)
         {
//#endif
          if (ProgramMode)
          {
            uint8_t imgtyp = APPLICATION;
            if (STImage)
              imgtyp = SELFTEST;
            if (Send_USB_Command_Packet (RSP_USB_CODE_LOAD, 1, &imgtyp) == FAIL)
              fprintf (stderr, "Could not place the Device in upload mode\n");
          }
//#if DEBUG
         }
         else
           fprintf (stdout, "Start upload by sending the loadcode command\n");
//#endif
        // I dont have a very good way to set the correct BL State.
        if ((CmdLineMode) || (Is_Test_Program_Mode()))
	{
          uint8_t BLState = 8;
      	  Send_USB_Command_Packet (RSP_SET_BOOTLOADER_STATE, 1, &BLState);
	}
        break;
        case DBT_DEVICEREMOVECOMPLETE:
          break;
        default:
          break;
      }
      break;
    default:
      //printf ("Unkown event \n");
      return DefWindowProc(hwnd, msg, wParam, lParam);
  }
  return 0;
}

/**
 * WinMain
 *
 * Window Main function, The low level events from windows are 
 * directly passed to a program if it is a service or a window
 * based application. Since at some point a window application 
 * is required to be an extension of this applicaiton, it is
 * easier to create a window than a service based application.
 */
int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
    LPSTR lpCmdLine, int nCmdShow)
{
  WNDCLASSEX wc;
  bool detectUSB = TRUE;
  uint8_t NumTries = 0;
  
  //Step 1: Registering the Window Class
  wc.cbSize        = sizeof(WNDCLASSEX);
  wc.style         = 0;
  wc.lpfnWndProc   = WndProc;
  wc.cbClsExtra    = 0;
  wc.cbWndExtra    = 0;
  wc.hInstance     = hInstance;
  wc.hIcon         = LoadIcon(NULL, IDI_APPLICATION);
  wc.hCursor       = LoadCursor(NULL, IDC_ARROW);
  wc.hbrBackground = (HBRUSH)(COLOR_WINDOW+1);
  wc.lpszMenuName  = NULL;
  wc.lpszClassName = g_szClassName;
  wc.hIconSm       = LoadIcon(NULL, IDI_APPLICATION);

  if (!RegisterClassEx(&wc))
  {
    printf ("Window Registration Failed! %lx \n", GetLastError ());
    return 0;
  }

  hwnd = CreateWindowEx (WS_EX_CLIENTEDGE, g_szClassName, 
              "Code Loader", WS_OVERLAPPEDWINDOW, 
              CW_USEDEFAULT, CW_USEDEFAULT, 240, 120,
              NULL, NULL, hInstance, NULL);

  if(hwnd == NULL)
  {
    printf ("Window Creation Failed! %lx \n", GetLastError ());
    return 0;
  }

  //ShowWindow(hwnd, nCmdShow);
  //UpdateWindow(hwnd);
  if (lpCmdLine [0] != '\0')
    Parse_Arguments (lpCmdLine);
  else
  {
    print_help ();
    exit (1);
  }

  if (ProgramMode)
  {
    if (strcmp(FileName, "\0") != 0)
    {
      fprintf (stdout, "Program Mode, File name = %s\n", FileName);
      if (Load_Binary_File (FileName) == FAIL)
      {
        ProgramMode = FALSE;
        fprintf (stderr, "Problem loading Binary file, exiting program mode \n");
	exit (1);
      }
    }
    else
    {
      ProgramMode = FALSE;
      fprintf (stderr, "Cannot enter Program Mode, no File specified \n");
      exit (1);
    }
  }

  while (detectUSB)
  {
    if (USB_Init () == SUCCESS)
    {
      detectUSB = FALSE;    
      pthread_create (&thread_rx, NULL, (void*)Read_Input_Report, NULL);
//#if DEBUG
      //if (!Is_Test_Program_Mode ())
      //{
//#endif
        if (ProgramMode)
        {
          USBCommand cmdsend;
          cmdsend.type = RSP_REBOOT;
          Send_USB_Command (&cmdsend, sizeof (USBCommand));
        }
//#if DEBUG
      //}
//#endif
      if ((CmdLineMode) || (Is_Test_Program_Mode()))
      {
        uint8_t BLState = 8;
        Send_USB_Command_Packet (RSP_SET_BOOTLOADER_STATE, 1, &BLState);
        pthread_create (&thread_cmd, NULL, (void*)Command_Line, NULL);
      }
    }
    else
    {
      printf ("Device not connected to USB. Retry\n");
      if ((++ NumTries) < 3)
        Sleep (2000);
      else
      {
        detectUSB = FALSE;    
        printf ("USB Communication Failed. Device not connected to USB.\n");	      
        exit (0);
      }
    }
  }
  
  while(GetMessage(&Msg, NULL, 0, 0) > 0)
  {
    TranslateMessage(&Msg);
    DispatchMessage(&Msg);
  }

  return Msg.wParam;
}

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
void Parse_Arguments (LPSTR argv)
{
  if (argv [0] != '\0')
  {
    LPSTR p = argv;
    char* s = strtok (p, " ");
    CmdLine_Argument (s);
    while ((s = strtok (NULL, " ")) != '\0')
    {
      CmdLine_Argument (s);
    }
  }
}

/**
 * CmdLine_Argument
 *
 * This function identifies each argument from the argument list
 * passed through the command line and performs specific actions
 * based on the argument.
 *
 * @param par Parsed argument from Parse_Argument function.
 */
void CmdLine_Argument (char* par)
{
  if (strcmp (par, "-p") == 0)
    ProgramMode = TRUE;
  else if (strcmp (par, "-c") == 0)
    CmdLineMode = TRUE;
  else if (strcmp (par, "-pst") == 0)
  {
    ProgramMode = TRUE;
    STImage = TRUE;
  }
  else if (strcmp (par, "-help") == 0)
  {
    print_help ();
    exit (0);
  }
//#ifdef DEBUG  
  else if (strcmp (par, "-tp") == 0)
  {
    TestProgramMode = TRUE;
    ProgramMode = TRUE;
  }
//#endif
  else if (par[0] != '-')
  {
    strncpy (FileName, par, MAX_FILE_NAME_SIZE);
  }
  else
  {
    fprintf (stderr, "Ignoring unknown argument %s.", par);
  }
}

/**
 * Is_STImage
 *
 * Check if we are downloading SELF Test Image to the
 * device. The function returns boolean variable
 * STImage.
 *
 * @return STImage TRUE | FALSE
 */
BOOLEAN Is_STImage ()
{
  return STImage;
}

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
BOOLEAN Is_Test_Program_Mode ()
{
  return TestProgramMode;
}

/**
 * Binary_Upload_Completed
 * 
 * Reverts the programming mode. Checks if the application has to
 * stay in command line mode.
 */
void Binary_Upload_Completed ()
{
  ProgramMode = FALSE;
  DownloadDone = TRUE;
  //TestProgramMode = FALSE;
}

/**
 * Exit_Applicaiton
 *
 * This function provides a reliable way of exiting the application.
 * It makes sure that the threads are terminated before the exit
 * function is call. It is advisable to call this function for a
 * clean exit rather than using exit(0).
 */
void Exit_Application ()
{
  //pthread_kill (thread_rx, 0);
  //pthread_kill (thread_cmd, 0);
  pthread_cancel (thread_rx);
  pthread_cancel (thread_cmd);
  exit (0);
}

