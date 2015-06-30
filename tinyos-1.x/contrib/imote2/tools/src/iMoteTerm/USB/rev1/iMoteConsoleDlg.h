// iMoteConsoleDlg.h : header file
//

#include "SerialPort.h"
#include "USBDevice.h"
#include "SymTable.h"
#include "RichEditExt.h"
#include "IMoteTerminal.h"

#if !defined(AFX_IMOTECONSOLEDLG_H__CADB84BB_FA86_4487_9E9B_023D2C7975AE__INCLUDED_)
#define AFX_IMOTECONSOLEDLG_H__CADB84BB_FA86_4487_9E9B_023D2C7975AE__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

/////////////////////////////////////////////////////////////////////////////
// CIMoteConsoleDlg dialog
#include "DataFormatPage.h"
#include "PlotInfo.h"
#include <fstream>
#include "IMoteCartesianPlot.h"
#include "IMoteListDisp.h"
#include "afxwin.h"
#include "afxcmn.h"
#include "dynarray.h"

extern CIMoteConsoleApp theApp;
#define NUMCHANNELS (20)

using namespace std;

class CIMoteConsoleDlg : public CDialog
{
// Construction
public:
	CIMoteConsoleDlg(CWnd* pParent = NULL);	// standard constructor
	virtual ~CIMoteConsoleDlg();	// standard constructor
	void LoadProfileInfo(void);
	void SaveProfileInfo(void);
// Dialog Data
	//{{AFX_DATA(CIMoteConsoleDlg)
	enum { IDD = IDD_IMOTECONSOLE_DIALOG };
	//}}AFX_DATA

	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CIMoteConsoleDlg)
	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support
	//}}AFX_VIRTUAL

// Implementation
protected:
	HICON m_hIcon;

	// Generated message map functions
	//{{AFX_MSG(CIMoteConsoleDlg)
	virtual BOOL OnInitDialog();
	afx_msg void OnSysCommand(UINT nID, LPARAM lParam);
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	
	afx_msg void OnClose();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
private:
	CToolBar	m_wndConnectionToolBar;
	int CreateConnectionToolBar(void);
	CSymTable *m_terminalList;

	SDataFormatSettings *m_pDataFormatSettings;
	CObArray m_WindowArray;
	BOOL DoRegisterDeviceInterface(GUID InterfaceClassGuid, HDEVNOTIFY *hDevNotify);
	HDEVNOTIFY m_devNotificationHandle;
public:
	CString m_strPortName;
	COMMCONFIG *m_pCommConfig;
	void BufferAppend(char x);
	void BufferAppend(CIMoteTerminal *out, char x);
	void BufferAppend(CIMoteTerminal *out, CString x);
	void BufferAppend(CIMoteTerminal *out, char * y);
	afx_msg void OnEditOptions();
	afx_msg void OnEditNewwin();
	afx_msg void OnInitMenuPopup(CMenu *pPopupMenu, UINT nIndex,BOOL bSysMenu);
	CIMoteCartesianPlot *CreateNewView(UINT ID, UINT iMoteID, UINT channelID);
	CIMoteListDisp *CreateNewList(UINT ID, UINT iMoteID, UINT channelID, bool bcreatenew=false, CIMoteListDisp *oldframe=NULL, CString headerX="",CString headerY="",CString headerZ="");
	void PopulateUSBDevices();

	CPlotInfo plotinfo[NUMCHANNELS];
	int MoteIDs[NUMCHANNELS];
	ofstream logfile;
	void AddPoint(POINT newpoint, int channelID);
	CPoint Filter(POINT newpoint, int channelID);
	bool smooth;
	bool rawdata;
	bool bAppClosing;
	void SaveLogEntry(CString *str);
	void SaveLogEntryToScreen(CString *str);
	afx_msg LRESULT OnReceiveData(WPARAM wParam, LPARAM lParam);
	void BuildJPG(unsigned char *jpeg_data, int length, unsigned char *whole_jpg, int *whole_jpg_len);
protected:
	virtual void OnCancel();
public:
	afx_msg void OnTimer(UINT nIDEvent);
	afx_msg void OnEditTest();
	afx_msg void OnViewSmooth();
	afx_msg void OnUpdateViewSmooth(CCmdUI *pCmdUI);
	afx_msg void OnEditTestnewlist();
	afx_msg void OnDisplayChange();
	int AddMote(void);
	CComboBox m_displayedMoteComboControl;
	CString m_displayedMoteComboValue;
	CStatic m_comNumStatic;
	CStatic m_detachedStatic;
	afx_msg BOOL OnDeviceChange(UINT nEventType, DWORD_PTR dwData);
	afx_msg void OnBnClickedButtonWindowBuffer();


	afx_msg void OnHelpAbout();
};

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_IMOTECONSOLEDLG_H__CADB84BB_FA86_4487_9E9B_023D2C7975AE__INCLUDED_)
