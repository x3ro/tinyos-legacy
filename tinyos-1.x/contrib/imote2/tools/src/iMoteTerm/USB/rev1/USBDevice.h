// USBDevice.h: interface for the CUSBDevice class.
//
//////////////////////////////////////////////////////////////////////

#ifndef __USBDEVICE_H
#define __USBDEVICE_H

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#define vID 0x042b
#define pID 0x1337

extern "C" {
#include "hidsdi.h"
#include <setupapi.h>
}
#include "DynQueue.h"

class CUSBDevice;

typedef struct __USBdata{
	__USBdata::__USBdata():data(NULL),i(0),len(0),n(0),type(0){}
	BYTE *data;
	DWORD i;
	DWORD n;
	BYTE type;
	DWORD len;
} USBdata;

typedef struct __USBmessage{
	__USBmessage::__USBmessage(CUSBDevice *u, DWORD bytes, CString serial){usb = u; actualBytesRead = bytes; serialNum = serial;};
	CUSBDevice *usb;
	DWORD actualBytesRead;
	CString serialNum;
} USBmessage;

#define isFlagged(_BITFIELD, _FLAG) (((_BITFIELD) & (_FLAG)) != 0)
#define _BIT(_bit) (1 << ((_bit) & 0x1f))

#define IMOTE_HID_TYPE_COUNT 4

//Imote2 HID report, byte positions
#define IMOTE_HID_TYPE 1
#define IMOTE_HID_NI 2
//Imote2 HID report, type byte,  bit positions
#define IMOTE_HID_TYPE_CL 0
#define IMOTE_HID_TYPE_L 2
#define IMOTE_HID_TYPE_H 4
#define IMOTE_HID_TYPE_MSC 5
//Imote2 HID report, type byte, L defintions
#define IMOTE_HID_TYPE_L_BYTE 0
#define IMOTE_HID_TYPE_L_SHORT 1
#define IMOTE_HID_TYPE_L_INT 2
//Imote2 HID report, L sizes
#define IMOTE_HID_TYPE_L_BYTE_SIZE 15871
#define IMOTE_HID_TYPE_L_SHORT_SIZE 3997695
#define IMOTE_HID_TYPE_L_INT_SIZE ULONG_MAX
//Imote2 HID report, type byte, CL defintions
#define IMOTE_HID_TYPE_CL_GENERAL 0
#define IMOTE_HID_TYPE_CL_BINARY 1
#define IMOTE_HID_TYPE_CL_RPACKET 2
#define IMOTE_HID_TYPE_CL_BLUSH 3
//Imote2 HID report, type byte, MSC definitions
#define IMOTE_HID_TYPE_MSC_DEFAULT 0
#define IMOTE_HID_TYPE_MSC_BLOADER 1
//Imote2 HID report, max packet data sizes
#define IMOTE_HID_BYTE_MAXPACKETDATA 62
#define IMOTE_HID_SHORT_MAXPACKETDATA 61
#define IMOTE_HID_INT_MAXPACKETDATA 59

#define WM_RECEIVE_SERIAL_DATA (WM_USER + 1)
#define WM_RECEIVE_USB_DATA (WM_USER + 2)
#define WM_CLOSE_PORT (WM_USER + 3)
class CUSBDevice  
{
public:
	/*bool IsRxThreadAlive();
	bool IsTxThreadAlive();*/
	bool CloseDevice(void);
	bool IsConnected();
	bool WriteData(BYTE *data, DWORD datalen, BYTE type);
	bool ConnectDevice();//, HIDP_CAPS Capabilities);
	CUSBDevice();
	CUSBDevice(CString serial);
	virtual ~CUSBDevice();
	void setDetail(TCHAR *path);
	void SetParent(CWnd* parent);

protected:
	static UINT USBThreadRxFunc(LPVOID pParam);
	static UINT USBThreadTxFunc(LPVOID pParam);
	COMMTIMEOUTS m_commtimeouts;
	HANDLE m_hDevice;
	
	OVERLAPPED m_rxOv, m_txOv;
	HANDLE m_hTxUpdateEvent;


private:
	int SendData(BYTE *data, DWORD requestedBytesWrote);
	void QueueData(BYTE *data);
	void ClearQueue();
	//bool PrivateClosePort(void);
	static void OutputError(char *string, DWORD error);
	bool m_bConnected;
	CWinThread *m_rxThread;
	CWinThread *m_txThread;
	CWnd *m_parent;
	HIDP_CAPS m_Capabilities;
	TCHAR *m_pPath;
	char *m_serialNumString;
	CDynQueue m_sendQueue;
};

#endif // !defined(AFX_USBDEVICE_H__69D89F91_3784_41DB_8142_AE1A84BDC69B__INCLUDED_)
