#pragma once
#include "afxwin.h"

// CConfigurationPage dialog

class CConfigurationPage : public CPropertyPage
{
	DECLARE_DYNAMIC(CConfigurationPage)

public:
	CConfigurationPage(COMMCONFIG *CommConfig, CString COMPortName, CString logfileName);
	virtual ~CConfigurationPage();

// Dialog Data
	enum { IDD = IDD_PP_CONFIGURATION };

protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support
	void PopulateSystemSerialPorts();

	DECLARE_MESSAGE_MAP()
public:
	virtual BOOL OnInitDialog();
	CComboBox m_comportComboControl;
	COMMCONFIG *m_pCommConfig;
	CString m_strPortName;
	afx_msg void OnBnClickedButtonSettings();
	CString m_comportComboValue;
	CString m_filename;
	BOOL m_bAutoStart;
	BOOL m_bAppendLog;
public:
	virtual BOOL OnApply();
public:
	afx_msg void OnBnClickedButtonBrowse();
	
};
