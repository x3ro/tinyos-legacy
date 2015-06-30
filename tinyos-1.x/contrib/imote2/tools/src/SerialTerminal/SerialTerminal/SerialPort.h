// SerialPort.h: interface for the CSerialPort class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_SERIALPORT_H__69D89F91_3784_41DB_8142_AE1A84BDC69B__INCLUDED_)
#define AFX_SERIALPORT_H__69D89F91_3784_41DB_8142_AE1A84BDC69B__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

typedef struct __Commdata{
	BYTE *data;
	DWORD datalen;
} Commdata;
typedef Commdata *PCommdata;

#define WM_RECEIVE_SERIAL_DATA (WM_USER + 1)
#define WM_RECEIVE_USB_DATA (WM_USER + 2)
#define WM_CLOSE_PORT (WM_USER + 3)
class CSerialPort  
{
public:
	void CheckBuffer(void);
	bool IsRxThreadAlive();
	bool ClosePort(void);
	bool IsConnected();
	bool WriteData(BYTE *sendString, DWORD datalen);
	bool OpenPort(const wchar_t *lpcstrPort, DCB *pDCB);
	CSerialPort();
	virtual ~CSerialPort();
	void SetParent(CWnd *parent);

protected:
	static	UINT CommThreadRxFunc(LPVOID pParam);
	static	UINT CommThreadTxFunc(LPVOID pParam);
	COMMTIMEOUTS m_commtimeouts;
	HANDLE m_hComm;
	
	OVERLAPPED m_rxOv, m_txOv;
	HANDLE m_hTxUpdateEvent;

private:
	bool PrivateClosePort(void);
	static void OutputError(char *string, DWORD error);
	bool m_bConnected;
	CWinThread *m_rxThread;
	//CWinThread *m_txThread;
	CWnd *m_parent;
	void QueueData(PCommdata data);
	void ClearQueue();
	//CDynQueue m_sendQueue;
public:
	bool SetBreak(bool On);
};

#endif // !defined(AFX_SERIALPORT_H__69D89F91_3784_41DB_8142_AE1A84BDC69B__INCLUDED_)
