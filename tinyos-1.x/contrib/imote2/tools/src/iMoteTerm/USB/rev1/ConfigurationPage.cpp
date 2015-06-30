// ConfigurationPage.cpp : implementation file
//

#include "stdafx.h"
#include "iMoteConsole.h"
#include "ConfigurationPage.h"
#include ".\configurationpage.h"


// CConfigurationPage dialog

IMPLEMENT_DYNAMIC(CConfigurationPage, CPropertyPage)
CConfigurationPage::CConfigurationPage(COMMCONFIG *CommConfig, CString COMPortName)
	: CPropertyPage(CConfigurationPage::IDD), m_pCommConfig(CommConfig)
	, m_comportComboValue(_T("")), m_strPortName(COMPortName)
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
}


BEGIN_MESSAGE_MAP(CConfigurationPage, CPropertyPage)
	ON_BN_CLICKED(IDC_BUTTON_SETTINGS, OnBnClickedButtonSettings)
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
		TRACE("Unable to open HKLM\\HARDWARE\\DEVICEMAP\\SERIALCOMM\n");	
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
		TRACE("%s = %s\n",lpValueName, lpData);
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
		if(m_strPortName == ("\\\\.\\"+ string))
		{
			m_comportComboControl.SetCurSel(i);
			break;		
		}
	}
	if(i==NumEntries)
	{
		m_comportComboControl.SetCurSel(0);
	}
	
#if 0
	CRect rect;
	CStatic *pAssignmentBox=(CStatic *)GetDlgItem(IDC_STATIC_ASSIGNMENTBOX);
	//pAssignmentBox->GetClientRect(&rect);
	pAssignmentBox->GetWindowRect(&rect);
	ScreenToClient(&rect);
	rect.top+=20;
	rect.left+=10;
	rect.right-=10;
	rect.bottom -=10;
	//m_ChannelAssignmentWnd.Create(NULL,"Config",WS_OVERLAPPED|WS_VISIBLE|WS_BORDER,rect,this,1,NULL);
	
	CString strWndClass = AfxRegisterWndClass(CS_DBLCLKS,AfxGetApp()->LoadStandardCursor(IDC_ARROW),(HBRUSH) (COLOR_3DFACE),AfxGetApp()->LoadStandardIcon(IDI_WINLOGO));
	m_ChannelAssignmentWnd.CreateEx(WS_EX_OVERLAPPEDWINDOW,strWndClass, _T("Config"),WS_CHILD|WS_VISIBLE,rect,this,1);
#endif
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
