
#pragma once
#include "RichEditExt.h"
#include "DynArray.h"
#include "USBDevice.h"
#include "SerialPort.h"
#include "IMoteStatus.h"

class CIMoteTerminal;
#include "iMoteConsoleDlg.h"
#include "afxwin.h"
#include "afxcmn.h"
// CIMoteTerminal dialog
#include "sampleHeader.h"

class CIMoteTerminal : public CDialog
{
	DECLARE_DYNAMIC(CIMoteTerminal)

public:
	CIMoteTerminal(CWnd* pParent = NULL, CUSBDevice *dev = NULL, bool att = false);
	virtual ~CIMoteTerminal();
	void ScrollToBottom();
	void ScrollToTop();
	bool Scroll(bool up);
	void UpdateText();
	void BufferAppend(char x, bool refresh);
	void BufferAppend(CString x);
	void BufferAppend(char *y);
	void BufferAppend(char * y, DWORD len);
	void WidthAdjustment();
	void SendData(BYTE *data, DWORD len, BYTE type);
	void SendData(CString data);
	void setAttached(bool att);
	bool isAttached();
	void setPath(TCHAR *path);
	void DisplayChange();
	void checkBinary(BYTE *data, DWORD BytesToCheck, DWORD Packet);
	void Connect();
	void Disconnect();

	CUSBDevice *m_usb;

// Dialog Data
	enum { IDD = IDD_IMOTETERMINAL };

protected:
	HICON m_hIcon;
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support

	DECLARE_MESSAGE_MAP()
private:
	CWnd *m_parent;
	
	CRichEditExt m_outputRichEditControl;
	CRichEditCtrl m_fileRichEditControl;
	SCROLLINFO m_outputScrollInfo;
	CSerialPort *m_serialport;
	USBdata m_dataIn[IMOTE_HID_TYPE_COUNT];
	bool m_attached;
	CDynArray m_lines;
	int m_trueLines;
	int m_trueCurLine;
	int m_curLine;
	CString m_buffer;
	CString m_bufferTrue;
	CString m_visible;
	int m_sizeCount, m_prevMaxCharCount;
	CString m_fileSaveName;
	CString m_fileOpenName;
	CString m_curDir;
	CIMoteStatus *m_sendFileStatus;
	bool m_sendFileBusy;
	BYTE *m_lastSendFile;
	bool m_lastSendFileValid;
	DWORD m_lastSendFileIndex;
	HACCEL m_hAccel;
	HANDLE binaryFile;
public:
	virtual BOOL OnInitDialog();
	afx_msg void OnUpdateTermEditEcho(CCmdUI *pCmdUI);
	afx_msg void OnTermEditEcho();
	afx_msg void OnBnClickedButtonTermSendbreak();
	afx_msg void OnBnClickedButtonTermClearBuffer();
	afx_msg void OnBnClickedButtonTermConnect();
	afx_msg void OnInitMenuPopup(CMenu* pPopupMenu, UINT nIndex, BOOL bSysMenu);
	afx_msg void OnTermEditClearBuffer();
	afx_msg void OnTermEditConnect();
	CButton m_connectButton;
	CButton m_sendBreakButton;
	CButton m_sendFileButton;
	CButton m_textFileCheck;
	CStatic m_detachedStatic;
	CStatic m_comNumStatic;
	BOOL m_bTextFile;
	afx_msg void OnSize(UINT nType, int cx, int cy);
	afx_msg void OnSizing(UINT fwSide, LPRECT pRect);
	afx_msg LRESULT OnReceiveUSBData(WPARAM wParam, LPARAM lParam);
	afx_msg LRESULT OnReceiveSerialData(WPARAM wParam, LPARAM lParam);
	afx_msg LRESULT OnClosePort(WPARAM wParam, LPARAM lParam);
	afx_msg HCURSOR OnQueryDragIcon();
	afx_msg void OnTermFileSave();
	afx_msg void OnTermFileHide();
	afx_msg void OnTermEditCopy();
	afx_msg void OnTermFileSaveAs();
	afx_msg void OnBnClickedButtonTermSendFile();
	afx_msg void OnTermFileOpenFile();
	virtual BOOL PreTranslateMessage(MSG* pMsg);
	afx_msg void OnClose();
	CRichEditCtrl m_addrRichEditControl;
	CButton m_executeButton;
	CStatic m_addrStatic;
	afx_msg void OnBnClickedButtonTermExecute();
	afx_msg void OnTermEditExecute();
	CString m_addrString;
	int processJTPacket(USBdata *USBin, BYTE validBytes);
};
