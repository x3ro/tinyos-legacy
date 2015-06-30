// SerialPort.cpp: implementation of the CSerialPort class.
//
//////////////////////////////////////////////////////////////////////

#include "stdafx.h"
#include "SerialPort.h"
#include <cassert>
#include ".\serialport.h"
#ifdef _DEBUG
#undef THIS_FILE
static char THIS_FILE[]=__FILE__;
#define new DEBUG_NEW
#endif

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CSerialPort::CSerialPort() : m_rxThread(NULL)
{
	m_hComm = INVALID_HANDLE_VALUE;
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
}

CSerialPort::~CSerialPort()
{
	ClearQueue();
}

bool CSerialPort::OpenPort(const wchar_t *lpcstrPort, DCB *pDCB)
{
	if(m_hComm != INVALID_HANDLE_VALUE)
	{
		//port is apparently already openned, abort this operation
		TRACE(_T("OpenPort called with non INVALID_HANDLE_VALUE value for COM port handle\n"));
		return false;
	}

	ResetEvent(m_rxOv.hEvent);
	ResetEvent(m_txOv.hEvent);
	ResetEvent(m_hTxUpdateEvent);

	m_hComm = CreateFile(lpcstrPort,  
					GENERIC_READ | GENERIC_WRITE, 
					0, 
					0, 
					OPEN_EXISTING,
					FILE_FLAG_OVERLAPPED,
					0);
	
	if (m_hComm == INVALID_HANDLE_VALUE)
   	{
		// error opening port; abort
		
		OutputError("Error Opening COM port, ",GetLastError());
		return false;
	}
	else
	{
		TRACE(_T("Successfully opened port %s\n"),lpcstrPort);
	}

	// Set new state.
	if (!SetCommState(m_hComm, pDCB))
	{   
		 // Error in SetCommState. Possibly a problem with the communications 
		 // port handle or a problem with the DCB structure itself.	
		OutputError("Error Setting Commstate, ",GetLastError());
		PrivateClosePort();
		return false;
	}
	TRACE(_T("Successfully set Comstate\n"));

	//setup the comm mask for the notification event
	DWORD temp;
	GetCommMask(m_hComm,&temp);
	
	if(!SetCommMask(m_hComm,EV_RXCHAR))
	{
		OutputError("Error Setting CommMask, ",GetLastError());
	}

	TRACE(_T("Successfully set CommMask\n"));
	
	m_commtimeouts.ReadIntervalTimeout          = 200;
	m_commtimeouts.ReadTotalTimeoutMultiplier   = 300;
	m_commtimeouts.ReadTotalTimeoutConstant     = 16;
	m_commtimeouts.WriteTotalTimeoutMultiplier  = 0;
	m_commtimeouts.WriteTotalTimeoutConstant    = 0;

	if (!SetCommTimeouts(m_hComm, &m_commtimeouts))
	{
		TRACE(_T("Error Setting CommTimeouts.  GetLastError returned %d"),GetLastError());
		PrivateClosePort();
		return false;
	}
	TRACE(_T("Successfully set CommTimeouts\n"));
	TRACE(_T("Succesfully initialized port %s\n"),lpcstrPort);

	m_bConnected = true;
	if(!(m_rxThread = AfxBeginThread(CommThreadRxFunc, this)))
	{
		TRACE(_T("Unable to start helper rx thread\n"));
		ClosePort();
		//PrivateClosePort();
		return FALSE;
	}
	m_rxThread->m_bAutoDelete=false;
	TRACE(_T("Rx Thread started\n"));
#if 0
	if(!(m_txThread = AfxBeginThread(CommThreadTxFunc, this)))
	{
		TRACE(_T("Unable to start helper tx thread\n"));
		ClosePort();
		return FALSE;
	}
	m_txThread->m_bAutoDelete=false;
#endif
	TRACE(_T("Tx Thread started\n"));
	
	DWORD modemstatus;
	GetCommModemStatus(m_hComm, &modemstatus);
	TRACE(_T("ModemStatus value = %d\n"),modemstatus);
	TRACE(_T("CTS_ON = %d, DSR_ON = %d, RING_ON = %d, RLSD_ON = %d\n"),MS_CTS_ON, MS_DSR_ON, MS_RING_ON, MS_RLSD_ON);
	
		
	return true;
}

bool CSerialPort::WriteData(BYTE *data, DWORD datalen){
	DWORD dwError;
	COMSTAT comstat;

	if(!m_bConnected)
		return false;
#if 0
	BYTE *tempdata = (BYTE *)malloc(datalen);
	PCommdata temp = (PCommdata)malloc(sizeof(Commdata));
	memcpy(tempdata, data, datalen);
	temp->data = tempdata;
	temp->datalen = datalen;
	QueueData(temp);
	return true;
#endif
#if 0
	//set to 1 to force datasize to 32 bytes
	DWORD actualBytesWrote,requestedBytesWrote = 32;
	char tempData[32];
	int length=( datalen > 32) ? 32: datalen;
	memset(tempData,0,32);
	for(int i=0; i<length; i++)
		tempData[i]= data[i];
#else
	//original code
	DWORD actualBytesWrote,requestedBytesWrote = datalen;
	BYTE *tempData = new BYTE[datalen];
	memcpy(tempData,data,datalen);
#endif

	OVERLAPPED ovWrite;
	ovWrite.Offset = 0;
	ovWrite.OffsetHigh = 0;
	ovWrite.hEvent = CreateEvent(NULL,TRUE,FALSE, NULL);
	
	ClearCommError(m_hComm,&dwError,&comstat);
	
	TRACE(_T("Attempting to send command \"%s\"\n"),tempData);
	if(WriteFile(m_hComm,tempData, requestedBytesWrote,&actualBytesWrote,&ovWrite))
	{
		/***************************************************************************
		if for some reason the WriteFile call returns immediately, everyone's happy.  
		However, since we are using overlapped IO, this will most likely not happen
		***************************************************************************/
		
		if(actualBytesWrote == requestedBytesWrote)
		{
			TRACE(_T("String sent immediately by WriteFile\n"));
		}
		else if(actualBytesWrote > requestedBytesWrote)
		{
			TRACE(_T("Error: WriteFile returned but wrote more bytes than requested\n"));
		}
		else if(actualBytesWrote < requestedBytesWrote)
		{
			TRACE(_T("Error:WriteFile returned but wrote fewer bytes than requested\n"));
		}
	}
	else
	{
		switch(dwError = GetLastError())
		{
		case ERROR_IO_PENDING:
			TRACE(_T("Write queued\n"));
			break;
		default:
			OutputError("Error writing COM port, ",dwError);	
			TRACE(_T("Aborting write\n"));
			delete tempData;
			return false;
		}

		//wait for the write to complete
		WaitForSingleObject(ovWrite.hEvent, INFINITE);

		if(GetOverlappedResult(m_hComm,&ovWrite,&actualBytesWrote,TRUE))
		{
			if(actualBytesWrote == requestedBytesWrote)
			{
				TRACE(_T("Write completed\n"));
			}
			else if(actualBytesWrote > requestedBytesWrote)
			{
				TRACE(_T("Error: WriteFile returned but wrote more bytes than requested\n"));
			}
			else if(actualBytesWrote < requestedBytesWrote)
			{
				TRACE(_T("Error:WriteFile returned but wrote fewer bytes than requested\n"));
			}		
		}
		else
		{
			OutputError("GetOverlappedResult failed, ",GetLastError());
		}
	}
	delete tempData;
	return true;
}


void CSerialPort::QueueData(PCommdata data){
	//m_sendQueue.enqueue(data);
	SetEvent(m_hTxUpdateEvent);
}

void CSerialPort::ClearQueue(){
#if 0
	while(m_sendQueue.getLength() > 0){
		PCommdata temp = (PCommdata)m_sendQueue.dequeue();
		free(temp->data);
		free(temp);
	}
#endif
}

UINT CSerialPort::CommThreadTxFunc(LPVOID pParam){
	CSerialPort *pPort = (CSerialPort *)pParam;
	BYTE *buffer = NULL;
	DWORD actualBytesWrote, requestedBytesWrote;
	DWORD dwError, dwEvent;
	COMSTAT comstat;

	while(pPort->IsConnected()){
		//if(pPort->m_sendQueue.getLength() < 1)
		//	WaitForSingleObject(pPort->m_hTxUpdateEvent, INFINITE);
		ResetEvent(pPort->m_hTxUpdateEvent);
		if(!pPort->IsConnected())
			break;
		PCommdata temp; //(PCommdata)pPort->m_sendQueue.dequeue();
		buffer = temp->data;
		requestedBytesWrote = temp->datalen;
		free(temp);
		temp = NULL;
			
		ClearCommError(pPort->m_hComm,&dwError,&comstat);
		if(WriteFile(pPort->m_hComm, buffer, requestedBytesWrote, &actualBytesWrote,&(pPort->m_txOv))){
			/***************************************************************************
			if for some reason the WriteFile call returns immediately, everyone's happy.
			However, since we are using overlapped IO, this will most likely not happen
			***************************************************************************/
			if(actualBytesWrote == requestedBytesWrote){
				TRACE(_T("String sent immediately by WriteFile\n"));
				free(buffer);
				buffer = NULL;
			}
			else if(actualBytesWrote > requestedBytesWrote){
				TRACE(_T("Error: WriteFile returned but wrote more bytes than requested\n"));
				temp = (PCommdata)malloc(sizeof(Commdata));
				temp->data = buffer;
				temp->datalen = requestedBytesWrote;
				//pPort->m_sendQueue.push((void *)temp);
				buffer = NULL;
				temp = NULL;
			}
			else if(actualBytesWrote < requestedBytesWrote){
				TRACE(_T("Error:WriteFile returned but wrote fewer bytes than requested\n"));
				temp = (PCommdata)malloc(sizeof(Commdata));
				temp->data = buffer;
				temp->datalen = requestedBytesWrote;
				//pPort->m_sendQueue.push((void *)temp);
				buffer = NULL;
				temp = NULL;
			}
		}
		else{
			bool error = false;
			switch(dwError = GetLastError())
			{
			case ERROR_IO_PENDING:
				//TRACE("Write queued\n");
				break;
			default:
				OutputError("Error writing COM port, ",dwError);	
				TRACE(_T("Aborting write and disconnecting\n"));
				free(buffer);
				buffer = NULL;
				error = true;
				if(pPort->IsConnected())
					pPort->m_parent->PostMessage(WM_CLOSE_PORT);
			}
			if(error)break;


			//wait for the write to complete
			while((dwEvent = WaitForSingleObject(pPort->m_txOv.hEvent,200)) == WAIT_TIMEOUT)
				if(!pPort->IsConnected()){
					free(buffer);
					break;
				}
			
			switch(dwEvent){
			case WAIT_OBJECT_0:
				//our overlapped structure was signaled
				if(GetOverlappedResult(pPort->m_hComm,&(pPort->m_txOv),&actualBytesWrote,TRUE)){
					if(actualBytesWrote == requestedBytesWrote){
						//TRACE("Write completed\n");
						free(buffer);
						buffer = NULL;
					}
					else if(actualBytesWrote > requestedBytesWrote){
						TRACE(_T("Error: WriteFile returned but wrote more bytes than requested\n"));
						temp = (PCommdata)malloc(sizeof(Commdata));
						temp->data = buffer;
						temp->datalen = requestedBytesWrote;
						//pPort->m_sendQueue.push((void *)temp);
						buffer = NULL;
						temp = NULL;
					}
					else if(actualBytesWrote < requestedBytesWrote){
						TRACE(_T("Error:WriteFile returned but wrote fewer bytes than requested\n"));
						temp = (PCommdata)malloc(sizeof(Commdata));
						temp->data = buffer;
						temp->datalen = requestedBytesWrote;
						//pPort->m_sendQueue.push((void *)temp);
						buffer = NULL;
						temp = NULL;
					}
				}
				else{
					OutputError("GetOverlappedResult failed, ",GetLastError());
					temp = (PCommdata)malloc(sizeof(Commdata));
					temp->data = buffer;
					temp->datalen = requestedBytesWrote;
					//pPort->m_sendQueue.push((void *)temp);
					buffer = NULL;
					temp = NULL;
					buffer = NULL;
				}
				break;
			}
		}
	}
	TRACE(_T("Tx Thread Exiting...\n"));
	return true;
}

UINT CSerialPort::CommThreadRxFunc(LPVOID pParam)
{
	DWORD dwEvent,dwError, dwEventMask;
	CSerialPort *pPort = (CSerialPort *)pParam;

	OVERLAPPED overlapped;
	COMSTAT comstat;
	DWORD actualBytesRead,requestedBytesRead;
	unsigned char *buffer;

	overlapped.hEvent = CreateEvent(NULL,FALSE,FALSE,_T("WaitEvent"));
	/*************************************************************************
	Basic idea is to simply continously read from the serial port.  If there's
	nothing to read, the thread will simply go to sleep until any actual data
	exists
	*************************************************************************/

	while(pPort->IsConnected())
	{
		if(WaitCommEvent(pPort->m_hComm,&dwEventMask,&overlapped))
		{
			//we succeeded, don't do anything
		}
		else
		{
			if(WaitForSingleObject(overlapped.hEvent,200)!=WAIT_OBJECT_0)
			{
				continue;	
			}
			GetOverlappedResult(pPort->m_hComm,&overlapped,&requestedBytesRead,TRUE);

		}
		switch(dwEventMask)
		{	
		case EV_RXCHAR:
			break;
		default:
			continue;
			break;
		}
		ClearCommError(pPort->m_hComm,&dwError,&comstat);
		requestedBytesRead = comstat.cbInQue;//(comstat.cbInQue < 2) ? 2 : (comstat.cbInQue & 0xFFFFFFFE);
		buffer = new unsigned char[requestedBytesRead+1];
			
		if(ReadFile(pPort->m_hComm,buffer,requestedBytesRead,&actualBytesRead,&(pPort->m_rxOv)))
		{
			if(actualBytesRead == requestedBytesRead)
			{
				//TRACE("Received %d bytes immediately\n", actualBytesRead);
				//SendMessage(*pPort->m_parent,WM_RECEIVE_DATA, (WPARAM)actualBytesRead, (LPARAM)buffer);
				//pParent->OnReceiveData((WPARAM)actualBytesRead, (LPARAM)buffer);
				//TRACE("Tx...Buffer = %#X\tNumBytesReceived = %d\n",buffer,actualBytesRead);
				buffer[actualBytesRead] = '\0';
				pPort->m_parent->PostMessage(WM_RECEIVE_SERIAL_DATA, (WPARAM)actualBytesRead, (LPARAM)buffer);
			}
			else if(actualBytesRead > requestedBytesRead)
			{
				TRACE(_T("Error: ReadFile returned but read more bytes than requested\n"));
			}
			else if(actualBytesRead < requestedBytesRead)
			{
				TRACE(_T("Error: ReadFile returned but read fewer bytes than requested\n"));
			}
		}			
		else
		{
			switch(dwError = GetLastError())
			{
			case ERROR_IO_PENDING:
				break;
			default:
				OutputError("Error reading COM port, ",dwError);	
				TRACE(_T("Aborting read\n"));
				delete buffer;
				continue;
			}

			while((dwEvent = WaitForSingleObject(pPort->m_rxOv.hEvent,200)) == WAIT_TIMEOUT)
				if(!pPort->IsConnected())
					break;

			switch(dwEvent)
			{
			case WAIT_OBJECT_0:
				
				//our overlapped structure was signaled
				if(GetOverlappedResult(pPort->m_hComm,&pPort->m_rxOv,&actualBytesRead,TRUE))
				{
					if(actualBytesRead == requestedBytesRead)
					{
						//TRACE("Received %d bytes asynchronously\n", actualBytesRead);
						//SendMessage(*pPort->m_parent,WM_RECEIVE_DATA, (WPARAM)actualBytesRead, (LPARAM)buffer);		
						//pParent->OnReceiveData((WPARAM)actualBytesRead, (LPARAM)buffer);
						//TRACE("Tx...Buffer = %#X\tNumBytesReceived = %d\n",buffer,actualBytesRead);
						buffer[actualBytesRead] = '\0';
						pPort->m_parent->PostMessage(WM_RECEIVE_SERIAL_DATA, (WPARAM)actualBytesRead, (LPARAM)buffer);
					}
					else if(actualBytesRead > requestedBytesRead)
					{
						TRACE(_T("Error: Overlapped ReadFile returned but read more bytes than requested\n"));
					}
					else if(actualBytesRead < requestedBytesRead && actualBytesRead != 0)
					{
						TRACE(_T("Error: Overlapped ReadFile returned but read fewer bytes than requested\n"));
					}
				}
				else
				{
					OutputError("GetOverlappedResult failed, ",GetLastError());
				}	
				break;
			}
		}
		//delete[] buffer;
	}
	TRACE(_T("Thread Exiting...\n"));
	CloseHandle(pPort->m_hComm);
	pPort->m_hComm = INVALID_HANDLE_VALUE;
	return 1;
}

bool CSerialPort::IsConnected()
{
	return m_bConnected;
}

bool CSerialPort::ClosePort()
{
	if(IsConnected()){
		TRACE(_T("Requesting COM port closure\n"));
		m_bConnected = false;
		if(m_rxThread != NULL){
			WaitForSingleObject(m_rxThread->m_hThread,INFINITE);
			if(m_rxThread){
				delete m_rxThread;
				m_rxThread=NULL;
			}
		}
#if 0
		if(m_txThread != NULL){
			SetEvent(m_hTxUpdateEvent);
			WaitForSingleObject(m_txThread->m_hThread,INFINITE);
			if(m_txThread){
				delete m_txThread;
				m_txThread=NULL;
			}
		}
#endif
		CloseHandle(m_hComm);
		m_hComm = INVALID_HANDLE_VALUE;
	}
	ClearQueue();
	//((CIMoteTerminal *)m_parent)->DisplayChange();
	return true;
}



bool CSerialPort::IsRxThreadAlive()
{
	DWORD retVal;
	GetExitCodeThread(m_rxThread->m_hThread, &retVal);
	if(retVal!=STILL_ACTIVE)
	{
		if(m_rxThread)
		{
			delete m_rxThread;
			m_rxThread=NULL;
		}
		return false;
	}
	else return true;
}

bool CSerialPort::PrivateClosePort()
{
	bool retVal=true;
	TRACE(_T("Closing COM port\n"));
	CloseHandle(m_hComm);
	m_hComm = INVALID_HANDLE_VALUE;
	return retVal;
}

void CSerialPort::OutputError(char *string, DWORD error)
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

void CSerialPort::SetParent(CWnd *parent)
{
	m_parent=parent;
}

void CSerialPort::CheckBuffer()
{
	COMSTAT comstat;
	DWORD dwError;
	ClearCommError(m_hComm,&dwError,&comstat);	

	DWORD temp;
	GetCommMask(m_hComm, &temp);
}

bool CSerialPort::SetBreak(bool On)
{
	bool bret;
	if(On)
	{
		bret = (bool)SetCommBreak(m_hComm);
	}
	else
	{
		bret = (bool)ClearCommBreak(m_hComm);	
	}
	if(bret)
	{
		TRACE(_T("Succeded: Set or clear break\r\n"));
	}
	else
	{
		TRACE(_T("Failed: Set or clear break\r\n"));
	}
	return bret;
}
