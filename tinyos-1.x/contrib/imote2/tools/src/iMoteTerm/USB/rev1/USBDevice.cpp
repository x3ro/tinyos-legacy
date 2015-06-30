// USBDevice.cpp: implementation of the CUSBDevice class.
//
//////////////////////////////////////////////////////////////////////

#include "stdafx.h"
#include "iMoteConsole.h"
#include "USBDevice.h"
#include "IMoteConsoleDlg.h"
#include <cassert>
#include ".\usbdevice.h"
#include "IMoteTerminal.h"

#ifdef _DEBUG
#undef THIS_FILE
static char THIS_FILE[]=__FILE__;
#define new DEBUG_NEW
#endif

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CUSBDevice::CUSBDevice() : m_rxThread(NULL), m_txThread(NULL), m_sendQueue(){
	m_hDevice = INVALID_HANDLE_VALUE;
	m_hTxUpdateEvent = INVALID_HANDLE_VALUE;
	m_txOv.hEvent = m_rxOv.hEvent = INVALID_HANDLE_VALUE;
	m_txOv.Offset = m_rxOv.Offset = 0;
	m_txOv.OffsetHigh = m_rxOv.OffsetHigh = 0;
	
	m_bConnected = false;

	m_rxOv.hEvent = CreateEvent(NULL, FALSE, FALSE, NULL);
	m_txOv.hEvent = CreateEvent(NULL, FALSE, FALSE, NULL);
	m_hTxUpdateEvent = CreateEvent(NULL, FALSE, FALSE, NULL);
	

	assert(m_rxOv.hEvent);
	assert(m_txOv.hEvent);
	assert(m_hTxUpdateEvent);

	m_serialNumString = new char[0];
	m_parent = NULL;
	m_pPath = NULL;
}

CUSBDevice::CUSBDevice(CString serial) : m_rxThread(NULL), m_txThread(NULL), m_sendQueue(){
	m_hDevice = INVALID_HANDLE_VALUE;
	m_hTxUpdateEvent = INVALID_HANDLE_VALUE;
	m_txOv.hEvent = m_rxOv.hEvent = INVALID_HANDLE_VALUE;

	m_txOv.Offset = m_rxOv.Offset = 0;
	m_txOv.OffsetHigh = m_rxOv.OffsetHigh = 0;
	m_bConnected = false;

	m_rxOv.hEvent = CreateEvent(NULL, FALSE, FALSE, NULL);
	m_txOv.hEvent = CreateEvent(NULL, FALSE, FALSE, NULL);
	m_hTxUpdateEvent = CreateEvent(NULL, FALSE, FALSE, NULL);

	assert(m_rxOv.hEvent);
	assert(m_txOv.hEvent);
	assert(m_hTxUpdateEvent);

	m_serialNumString = new char[strlen(serial) + 1];
	strcpy(m_serialNumString, (LPCTSTR)serial);
	m_parent = NULL;
	m_pPath = NULL;
}

void CUSBDevice::SetParent(CWnd* parent){
	m_parent = parent;
}
CUSBDevice::~CUSBDevice()
{
	ClearQueue();
	delete[] m_serialNumString;
	delete[] m_pPath;
}

void CUSBDevice::setDetail(TCHAR *path){
	HANDLE temp;
	PHIDP_PREPARSED_DATA PreparsedData;
	delete[] m_pPath;
	m_pPath = new TCHAR[strlen(path) * sizeof(TCHAR) + 1];
	strcpy(m_pPath, path);
	TRACE("received at addr %x %s\r\n", m_pPath, m_pPath);
	temp = CreateFile(m_pPath,
		0,
		FILE_SHARE_READ | FILE_SHARE_WRITE,
		NULL, 
		OPEN_EXISTING,
		0,
		NULL);
	HidD_GetPreparsedData(temp, &PreparsedData);
	HidP_GetCaps(PreparsedData, &m_Capabilities);
}
bool CUSBDevice::ConnectDevice()//, HIDP_CAPS Capabilities)
{

	if(m_hDevice != INVALID_HANDLE_VALUE)
	{
		//port is apparently already openned, abort this operation
		TRACE("openPort called with non INVALID_HANDLE_VALUE value for USB port handle\n");
		return false;
	}
	ResetEvent(m_rxOv.hEvent);
	ResetEvent(m_txOv.hEvent);
	ResetEvent(m_hTxUpdateEvent);

	m_hDevice = CreateFile(m_pPath,
					GENERIC_WRITE | GENERIC_READ, 
					FILE_SHARE_READ | FILE_SHARE_WRITE,
					NULL, 
					OPEN_EXISTING,
					FILE_FLAG_OVERLAPPED,
					NULL);

	if (m_hDevice == INVALID_HANDLE_VALUE)
   	{
		// error opening port; abort
		
		OutputError("Error connecting to USB device, ",GetLastError());
		return false;
	}
	else
	{
		TRACE("Successfully opened port %s\n",m_pPath);
	}
	m_bConnected = true;
	if(!(m_rxThread = AfxBeginThread(USBThreadRxFunc, new USBmessage(this, 0, m_serialNumString))))
	{
		TRACE("Unable to start helper rx thread\n");
		CloseDevice();
		//PrivateClosePort();
		return FALSE;
	}
	m_rxThread->m_bAutoDelete=false;
	TRACE("Rx Thread started\n");
	if(!(m_txThread = AfxBeginThread(USBThreadTxFunc, new USBmessage(this, 0, m_serialNumString))))
	{
		TRACE("Unable to start helper tx thread\n");
		CloseDevice();
		return FALSE;
	}
	m_txThread->m_bAutoDelete=false;
	TRACE("Tx Thread started\n");
	
	return TRUE;
}

bool CUSBDevice::WriteData(BYTE *data, DWORD datalen, BYTE type){
	BYTE valid;
	BYTE *OutputReport;

	if(!IsConnected())
		return false;

	if(datalen == 0){
		OutputReport = new BYTE[m_Capabilities.OutputReportByteLength];
		OutputReport[0] = 0;
		OutputReport[IMOTE_HID_TYPE] = (type & 0xE3) | _BIT(IMOTE_HID_TYPE_H) | (IMOTE_HID_TYPE_L_BYTE << IMOTE_HID_TYPE_L);
		OutputReport[IMOTE_HID_NI] = 0;
		OutputReport[IMOTE_HID_NI + 1] = 0;
		//Result = SendData(OutputReport, m_Capabilities.OutputReportByteLength);
		QueueData(OutputReport);
		//assert(Result);
	}
	else if(datalen <= IMOTE_HID_TYPE_L_BYTE_SIZE){
		BYTE n = (BYTE)(datalen / IMOTE_HID_BYTE_MAXPACKETDATA);

		for(BYTE i = 0; i <= n && IsConnected(); i++){
			OutputReport = new BYTE[m_Capabilities.OutputReportByteLength];
			OutputReport[0] = 0;
			
			if(i == 0){
				OutputReport[IMOTE_HID_NI] = n;
				OutputReport[IMOTE_HID_TYPE] = (type & 0xE3) | _BIT(IMOTE_HID_TYPE_H) | (IMOTE_HID_TYPE_L_BYTE << IMOTE_HID_TYPE_L);
			}
			else{
				OutputReport[IMOTE_HID_NI] = i;
				OutputReport[IMOTE_HID_TYPE] = (type & 0xE3) | (IMOTE_HID_TYPE_L_BYTE << IMOTE_HID_TYPE_L);
			}
			if(i==n){
				valid = (BYTE)(datalen % IMOTE_HID_BYTE_MAXPACKETDATA);
				OutputReport[IMOTE_HID_NI + 1] = valid;
			}
			else
				valid = (BYTE)IMOTE_HID_BYTE_MAXPACKETDATA;
			memcpy(OutputReport + IMOTE_HID_NI + 1 + (i==n?1:0), data + i * IMOTE_HID_BYTE_MAXPACKETDATA, valid);
			//Result = SendData(OutputReport, m_Capabilities.OutputReportByteLength);
			QueueData(OutputReport);
			//assert(Result);
			if(i == n)
				break;// because of loop around
		}
	}
	else if(datalen <= IMOTE_HID_TYPE_L_SHORT_SIZE){
		USHORT n = (USHORT)(datalen / IMOTE_HID_SHORT_MAXPACKETDATA);
		for(USHORT i = 0; i <= n && IsConnected(); i++){
			OutputReport = new BYTE[m_Capabilities.OutputReportByteLength];
			OutputReport[0] = 0;
			if(i == 0){
				OutputReport[IMOTE_HID_TYPE] = (type & 0xE3) | _BIT(IMOTE_HID_TYPE_H) | (IMOTE_HID_TYPE_L_SHORT << IMOTE_HID_TYPE_L);
				OutputReport[IMOTE_HID_NI] = (BYTE)(n >> 8);
				OutputReport[IMOTE_HID_NI + 1] = (BYTE)n;
			}
			else{
				OutputReport[IMOTE_HID_TYPE] = (type & 0xE3) | (IMOTE_HID_TYPE_L_SHORT << IMOTE_HID_TYPE_L);
				OutputReport[IMOTE_HID_NI] = (BYTE)(i >> 8);
				OutputReport[IMOTE_HID_NI + 1] = (BYTE)i;
			}
			if(i==n){
				valid = (BYTE)(datalen % IMOTE_HID_SHORT_MAXPACKETDATA);
				OutputReport[IMOTE_HID_NI + 2] = valid;
			}
			else
				valid = (BYTE)IMOTE_HID_SHORT_MAXPACKETDATA;
			memcpy(OutputReport + IMOTE_HID_NI + 2 + (i==n?1:0), data + i * IMOTE_HID_SHORT_MAXPACKETDATA, valid);
			//Result = SendData(OutputReport, m_Capabilities.OutputReportByteLength);
			QueueData(OutputReport);
			//assert(Result);

			if(i == n)
				break;// because of loop around
		}
	}
	else if(datalen <= IMOTE_HID_TYPE_L_INT_SIZE){
		DWORD n = datalen / IMOTE_HID_SHORT_MAXPACKETDATA;
		for(DWORD i = 0; i <= n && IsConnected(); i++){
			OutputReport = new BYTE[m_Capabilities.OutputReportByteLength];
			OutputReport[0] = 0;
			if(i == 0){
				OutputReport[IMOTE_HID_TYPE] = (type & 0xE3) | _BIT(IMOTE_HID_TYPE_H) | (IMOTE_HID_TYPE_L_INT << IMOTE_HID_TYPE_L);
				OutputReport[IMOTE_HID_NI] = (BYTE)(n >> 24);
				OutputReport[IMOTE_HID_NI + 1] = (BYTE)(n >> 16);
				OutputReport[IMOTE_HID_NI + 2] = (BYTE)(n >> 8);
				OutputReport[IMOTE_HID_NI + 3] = (BYTE)n;
			}
			else{
				OutputReport[IMOTE_HID_TYPE] = (type & 0xE3) | (IMOTE_HID_TYPE_L_INT << IMOTE_HID_TYPE_L);
				OutputReport[IMOTE_HID_NI] = (BYTE)(i >> 24);
				OutputReport[IMOTE_HID_NI + 1] = (BYTE)(i >> 16);
				OutputReport[IMOTE_HID_NI + 2] = (BYTE)(i >> 8);
				OutputReport[IMOTE_HID_NI + 3] = (BYTE)i;
			}
			
			if(i==n){
				valid = (BYTE)(datalen % IMOTE_HID_INT_MAXPACKETDATA);
				OutputReport[IMOTE_HID_NI + 4] = valid;
			}
			else
				valid = (BYTE)IMOTE_HID_INT_MAXPACKETDATA;
			memcpy(OutputReport + IMOTE_HID_NI + 4 + (i==n?1:0), data + i * IMOTE_HID_INT_MAXPACKETDATA, valid);
			//Result = SendData(OutputReport, m_Capabilities.OutputReportByteLength);
			QueueData(OutputReport);
			//assert(Result);

			if(i == n)
				break;// because of loop around
		}
	}
	else{
		return FALSE;
	}
	//free(OutputReport);
	return TRUE;
}

void CUSBDevice::QueueData(BYTE *data){
	m_sendQueue.enqueue(data);
	SetEvent(m_hTxUpdateEvent);
}

void CUSBDevice::ClearQueue(){
	while(m_sendQueue.getLength() > 0)
		delete[] (BYTE *)m_sendQueue.dequeue();
}

UINT CUSBDevice::USBThreadTxFunc(LPVOID pParam){
	CUSBDevice *pPort = ((USBmessage *)pParam)->usb;
	BYTE *buffer = NULL;
	DWORD actualBytesWrote;
	DWORD dwError, dwEvent;
	while(pPort->IsConnected()){
		if(pPort->m_sendQueue.getLength() < 1)
			WaitForSingleObject(pPort->m_hTxUpdateEvent, INFINITE);
		ResetEvent(pPort->m_hTxUpdateEvent);
		if(!pPort->IsConnected())
			break;

		
		buffer = (BYTE *)pPort->m_sendQueue.dequeue();

		/*if((buffer[1] & 0x3) == IMOTE_HID_TYPE_CL_BINARY && ((buffer[1] >> IMOTE_HID_TYPE_L) & 3) == IMOTE_HID_TYPE_L_SHORT)
			if((buffer[2] << 8) + buffer[3] == 0x9F1)
				TRACE(/*pPort->m_parent->MessageBox(*//*"Final packet sending\r\r");*/

		if(WriteFile(pPort->m_hDevice, buffer, pPort->m_Capabilities.OutputReportByteLength,&actualBytesWrote, &(pPort->m_txOv))){
			/***************************************************************************
			if for some reason the WriteFile call returns immediately, everyone's happy.
			However, since we are using overlapped IO, this will most likely not happen
			***************************************************************************/
			if(actualBytesWrote == pPort->m_Capabilities.OutputReportByteLength){
				TRACE("String sent immediately by WriteFile\n");
				delete[] buffer;
				buffer = NULL;
			}
			else if(actualBytesWrote > pPort->m_Capabilities.OutputReportByteLength){
				TRACE("Error: WriteFile returned but wrote more bytes than requested\n");
				pPort->m_sendQueue.push((void *)buffer);
				buffer = NULL;
			}
			else if(actualBytesWrote < pPort->m_Capabilities.OutputReportByteLength){
				TRACE("Error:WriteFile returned but wrote fewer bytes than requested\n");
				pPort->m_sendQueue.push((void *)buffer);
				buffer = NULL;
			}
		}
		else{
			bool error = false;
			switch(dwError = GetLastError()){
			case ERROR_IO_PENDING:
				//TRACE("Write queued\n");
				break;
			default:
				OutputError("Error writing USB device, ",dwError);	
				TRACE("Aborting write and disconnecting\n");
				delete[] buffer;
				buffer = NULL;
				error = true;
				if(pPort->IsConnected())
					pPort->m_parent->PostMessage(WM_CLOSE_PORT);
			}
			if(error)break;
			
			while((dwEvent = WaitForSingleObject(pPort->m_txOv.hEvent,200)) == WAIT_TIMEOUT)
				if(!pPort->IsConnected()){
					delete[] buffer;
					break;
				}

			switch(dwEvent){
			case WAIT_OBJECT_0:
				//our overlapped structure was signaled
				if(GetOverlappedResult(pPort->m_hDevice,&(pPort->m_txOv),&actualBytesWrote,TRUE)){
					if(actualBytesWrote == pPort->m_Capabilities.OutputReportByteLength){
						if((buffer[1] & 0x3) == IMOTE_HID_TYPE_CL_BINARY && ((buffer[1] >> IMOTE_HID_TYPE_L) & 3) == IMOTE_HID_TYPE_L_SHORT)
							if((buffer[2] << 8) + buffer[3] >= 0x9F1)
								TRACE("Sending packet %x %x\r\n",(buffer[2] << 8) + buffer[3], buffer);
						//TRACE("Write completed\n");
						delete[] buffer;
						buffer = NULL;
					}
					else if(actualBytesWrote > pPort->m_Capabilities.OutputReportByteLength){
						TRACE("Error: WriteFile returned but wrote more bytes than requested\n");
						pPort->m_sendQueue.push((void *)buffer);
						buffer = NULL;
					}
					else if(actualBytesWrote < pPort->m_Capabilities.OutputReportByteLength){
						TRACE("Error:WriteFile returned but wrote fewer bytes than requested\n");
						pPort->m_sendQueue.push((void *)buffer);
						buffer = NULL;
					}
				}
				else{
					OutputError("GetOverlappedResult failed, ",GetLastError());
					pPort->m_sendQueue.push((void *)buffer);
					buffer = NULL;
				}
				break;
			}
		}
	}

	delete (USBmessage *)pParam;
	TRACE("Tx Thread Exiting...\n");
	return 0;
}

UINT CUSBDevice::USBThreadRxFunc(LPVOID pParam)
{
	DWORD dwEvent,dwError;
	CUSBDevice *pPort = ((USBmessage *)pParam)->usb;
	
	OVERLAPPED overlapped;
	DWORD actualBytesRead,requestedBytesRead = pPort->m_Capabilities.InputReportByteLength;
	BYTE *buffer;

	overlapped.hEvent = CreateEvent(NULL,FALSE,FALSE,"WaitEvent");

	/*************************************************************************
	Basic idea is to simply continously read from the usb device.  If there's
	nothing to read, the thread will simply go to sleep until any actual data
	exists
	*************************************************************************/

	while(pPort->IsConnected())
	{			
		buffer = new BYTE[requestedBytesRead];
		//buffer = (BYTE *)malloc(requestedBytesRead);
		if(ReadFile(pPort->m_hDevice,buffer,requestedBytesRead,&actualBytesRead,&(pPort->m_rxOv)))
		{
			if(actualBytesRead == requestedBytesRead){
				//("Received %d bytes immediately\n", actualBytesRead);
				//SendMessage(*pPort->m_parent,WM_RECEIVE_USB_DATA, (WPARAM)actualBytesRead, (LPARAM)buffer);
				//pParent->OnReceiveData((WPARAM)actualBytesRead, (LPARAM)buffer);
				//TRACE("Tx...Buffer = %#X\tNumBytesReceived = %d\n",buffer,actualBytesRead);
				pPort->m_parent->PostMessage(WM_RECEIVE_USB_DATA, (WPARAM)new USBmessage(NULL, actualBytesRead, ((USBmessage *)pParam)->serialNum), (LPARAM)buffer);
				buffer = NULL;
			}
			else if(actualBytesRead > requestedBytesRead)
			{
				TRACE("Error: ReadFile returned but read more bytes than requested\n");
				delete[] buffer;
				/*free(buffer);
				buffer = NULL;*/
			}
			else if(actualBytesRead < requestedBytesRead)
			{
				TRACE("Error: ReadFile returned but read fewer bytes than requested\n");
				delete[] buffer;
				/*free(buffer);
				buffer = NULL;*/
			}
		}
		else
		{
			bool error = false;
			switch(dwError = GetLastError())
			{
			case ERROR_IO_PENDING:
				break;
			default:
				OutputError("Error reading from USB device ",dwError);
				TRACE("Aborting read and disconnecting\r\n");
				delete[] buffer;
				/*free(buffer);
				buffer = NULL;*/
				error = true;
			}
			if(error)break;

			while((dwEvent = WaitForSingleObject(pPort->m_rxOv.hEvent,200)) == WAIT_TIMEOUT)
				if(!pPort->IsConnected())
					break;
			if(!pPort->IsConnected()){
				delete[] buffer;
				break;
			}

			switch(dwEvent)
			{
			case WAIT_OBJECT_0:
				
				//our overlapped structure was signaled
				if(GetOverlappedResult(pPort->m_hDevice,&pPort->m_rxOv,&actualBytesRead,TRUE))
				{
					if(actualBytesRead == requestedBytesRead)
					{
						//TRACE("Received %d bytes asynchronously\n", actualBytesRead);
						//SendMessage(*pPort->m_parent,WM_RECEIVE_USB_DATA, (WPARAM)actualBytesRead, (LPARAM)buffer);		
						//pParent->OnReceiveData((WPARAM)actualBytesRead, (LPARAM)buffer);
						//TRACE("Tx...Buffer = %#X\tNumBytesReceived = %d\n",buffer,actualBytesRead);
						pPort->m_parent->PostMessage(WM_RECEIVE_USB_DATA, (WPARAM)new USBmessage(NULL, actualBytesRead, ((USBmessage *)pParam)->serialNum), (LPARAM)buffer);
						buffer = NULL;
					}
					else if(actualBytesRead > requestedBytesRead)
					{
						TRACE("Error: Overlapped ReadFile returned but read more bytes than requested\n");
						delete[] buffer;
						/*free(buffer);
						buffer = NULL;*/
					}
					else if(actualBytesRead < requestedBytesRead && actualBytesRead != 0)
					{
						TRACE("Error: Overlapped ReadFile returned but read fewer bytes than requested\n");
						delete[] buffer;
						/*free(buffer);
						buffer = NULL;*/
					}
				}
				else
				{
					OutputError("GetOverlappedResult failed, ",GetLastError());
					delete[] buffer;
					/*free(buffer);
					buffer = NULL;*/
				}	
				break;
			}
		}
	}
	TRACE("Rx Thread Exiting...\n");
	//delete[] buffer;
	//free(buffer);
	delete (USBmessage *)pParam;
	return 1;
}

bool CUSBDevice::IsConnected()
{
	return m_bConnected;
}

bool CUSBDevice::CloseDevice(void){
	if(IsConnected()){
		TRACE("Requesting USB device disconnect\n");
		m_bConnected = false;
		if(m_rxThread != NULL){
			WaitForSingleObject(m_rxThread->m_hThread,INFINITE);
			if(m_rxThread){
				delete m_rxThread;
				m_rxThread=NULL;
			}
		}
		if(m_txThread != NULL){
			SetEvent(m_hTxUpdateEvent);
			WaitForSingleObject(m_txThread->m_hThread,INFINITE);
			if(m_txThread){
				delete m_txThread;
				m_txThread=NULL;
			}
		}
		CloseHandle(m_hDevice);
		m_hDevice = INVALID_HANDLE_VALUE;
	}
	ClearQueue();
	((CIMoteTerminal *)m_parent)->DisplayChange();
	return true;
}

void CUSBDevice::OutputError(char *string, DWORD error)
{
	LPVOID lpMsgBuf;

	FormatMessage( 
				FORMAT_MESSAGE_ALLOCATE_BUFFER | 
				FORMAT_MESSAGE_FROM_SYSTEM | 
				FORMAT_MESSAGE_IGNORE_INSERTS,
				NULL,
				error,
				MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
				(LPTSTR) &lpMsgBuf,
				0,
				NULL 
			);

	TRACE(string);
	TRACE((char*)lpMsgBuf);
	LocalFree( lpMsgBuf );
}
