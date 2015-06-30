// ConfigurationPage.cpp : implementation file
//

#include "stdafx.h"
#include "SerialTerminal.h"
#include "ConfigurationPage.h"

// CConfigurationPage dialog

IMPLEMENT_DYNAMIC(CConfigurationPage, CPropertyPage)
CConfigurationPage::CConfigurationPage(COMMCONFIG *CommConfig, CString COMPortName, CString logfileName)
	: CPropertyPage(CConfigurationPage::IDD), m_pCommConfig(CommConfig)
	, m_comportComboValue(_T("")), m_strPortName(COMPortName)
	, m_filename(logfileName)
	, m_bAutoStart(FALSE)
{
}

CConfigurationPage::~CConfigurationPage()
{
}

void CConfigurationPage::DoDataExchange(CDataExchange* pDX)
{
	CPropertyPage::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_COMBO_COMPORT, m_comportComboControl);
	DDX_CBString(pDX, IDC_COMBO_COMPORT, m_comportComboValue);
	DDX_Text(pDX, IDC_EDIT_FILENAME, m_filename);
	DDX_Check(pDX, IDC_CHECK_AUTOSTART, m_bAutoStart);
	DDX_Radio(pDX, IDC_RADIO_OVERWRITE, m_bAppendLog);
}


BEGIN_MESSAGE_MAP(CConfigurationPage, CPropertyPage)
	ON_BN_CLICKED(IDC_BUTTON_SETTINGS, OnBnClickedButtonSettings)
//	ON_EN_CHANGE(IDC_EDIT_FILENAME, &CConfigurationPage::OnEnChangeEditFilename)
//ON_BN_CLICKED(IDC_BUTTON1, &CConfigurationPage::OnBnClickedButton1)
ON_BN_CLICKED(IDC_BUTTON_BROWSE, &CConfigurationPage::OnBnClickedButtonBrowse)
END_MESSAGE_MAP()


// CConfigurationPage message handlers
void CConfigurationPage::PopulateSystemSerialPorts()
{
	//serial ports reside at HKLM/HARDWARE/DEVICEMAP/SERIALCOMM
	HKEY hkey;
	DWORD dwIndex = 0;
	TCHAR *lpValueName; 
	BYTE *lpData;
	DWORD values, maxValueNameLen, nameLen, maxValueDataLen, dataLen;
	
	if(RegOpenKeyEx(HKEY_LOCAL_MACHINE,
					TEXT("HARDWARE\\DEVICEMAP\\SERIALCOMM"),
					0,
					KEY_QUERY_VALUE,
					&hkey) != ERROR_SUCCESS) 
	{
		TRACE(_T("Unable to open HKLM\\HARDWARE\\DEVICEMAP\\SERIALCOMM\n"));	
		return;
	}
	
	RegQueryInfoKey(hkey, NULL, NULL, NULL, NULL, NULL, NULL, &values,&maxValueNameLen, &maxValueDataLen, NULL, NULL);
	maxValueNameLen++;//need to include the terminating NULL char
	maxValueDataLen++;//need to include the terminating NULL char
	lpValueName = new TCHAR[maxValueNameLen+1];
	lpData = new BYTE[maxValueDataLen+1];

	nameLen = maxValueNameLen;
	dataLen = maxValueDataLen;
	while(RegEnumValue(hkey, dwIndex, lpValueName, &nameLen, NULL, NULL, lpData, &dataLen) != ERROR_NO_MORE_ITEMS)
	{
		TRACE(_T("%s = %s\n"),lpValueName, lpData);
		dwIndex++;
		nameLen = maxValueNameLen;
		dataLen = maxValueDataLen;
		m_comportComboControl.AddString((LPCTSTR)lpData);
	}

	//	RegQueryValueEx(hkey, lpValueName, lpreserved, lptype, lpdata, lpcbdata);
	delete[] lpValueName;
	delete[] lpData;

	RegCloseKey(hkey);
}

BOOL CConfigurationPage::OnInitDialog()
{
	CPropertyPage::OnInitDialog();
	
	PopulateSystemSerialPorts();
	int i, NumEntries = m_comportComboControl.GetCount();
	for (i=0; i<NumEntries; i++)
	{	
		CString string;
		m_comportComboControl.GetLBText(i,string);
		if(m_strPortName == (_T("\\\\.\\")+ string))
		{
			m_comportComboControl.SetCurSel(i);
			break;		
		}
	}
	if(i==NumEntries)
	{
		m_comportComboControl.SetCurSel(0);
	}
	
	return TRUE;  // return TRUE unless you set the focus to a control
	// EXCEPTION: OCX Property Pages should return FALSE
}

void CConfigurationPage::OnBnClickedButtonSettings()
{
	UpdateData();
	if(!CommConfigDialog(m_comportComboValue,m_hWnd,m_pCommConfig))
	{
		LPVOID lpMsgBuf;

		FormatMessage( 
				FORMAT_MESSAGE_ALLOCATE_BUFFER | 
				FORMAT_MESSAGE_FROM_SYSTEM | 
				FORMAT_MESSAGE_IGNORE_INSERTS,
				NULL,
				GetLastError(),
				MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
				(LPTSTR) &lpMsgBuf,
				0,
				NULL 
			);

		TRACE((char*)lpMsgBuf);
		LocalFree( lpMsgBuf );
	}
}

BOOL CConfigurationPage::OnApply()
{
	ASSERT_VALID(this);
	
	//don't let the ok button be pressed unless the dcb structure as been filled in
	if(m_pCommConfig->dcb.BaudRate == 0){
		OnBnClickedButtonSettings();
	}
	if(m_pCommConfig->dcb.BaudRate == 0){
		
		//user must have cancelled out...don't do anything
		return FALSE;	
	}
	else{
		
		return TRUE;
	}
}

void CConfigurationPage::OnBnClickedButtonBrowse()
{
	UpdateData();

	CFileDialog dlg(TRUE,_T(".log"),m_filename);
	
	if(dlg.DoModal() == IDOK){
		m_filename = dlg.GetPathName();	
		UpdateData(FALSE);
	}	
}
