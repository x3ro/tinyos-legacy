#pragma once
#include "afxwin.h"
#include "ChannelAssignmentWnd.h"

// CConfigurationPage dialog

class CConfigurationPage : public CPropertyPage
{
	DECLARE_DYNAMIC(CConfigurationPage)

public:
	CConfigurationPage(COMMCONFIG *CommConfig, CString COMPortName);
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
	CChannelAssignmentWnd m_ChannelAssignmentWnd;
};
