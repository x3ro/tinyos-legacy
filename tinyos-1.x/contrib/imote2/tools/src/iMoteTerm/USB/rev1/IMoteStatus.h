#pragma once
#include "afxwin.h"
#include "afxcmn.h"


// CIMoteStatus dialog

class CIMoteStatus : public CDialog
{
	DECLARE_DYNAMIC(CIMoteStatus)

public:
	CIMoteStatus(CWnd* pParent = NULL);   // standard constructor
	virtual ~CIMoteStatus();

// Dialog Data
	enum { IDD = IDD_IMOTESTATUS };

protected:
	HICON m_hIcon;
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support

	DECLARE_MESSAGE_MAP()
private:
	CWnd *m_parent;
	DWORD m_iBurn;
	DWORD m_nBurn;
	DWORD m_iVerify;
	DWORD m_nVerify;
	CString m_dev;

public:
	CStatic m_burnStatic;
	CStatic m_verifyStatic;
	CProgressCtrl m_burnProgress;
	CProgressCtrl m_verifyProgress;
	void UpdateStatus(DWORD iBurn, DWORD nBurn,	DWORD iVerify, DWORD nVerify, BYTE toUpdate);
	void GetStatus(DWORD *iBurn, DWORD *nBurn, DWORD *iVerify, DWORD *nVerify);
protected:
	virtual void OnCancel();
};
