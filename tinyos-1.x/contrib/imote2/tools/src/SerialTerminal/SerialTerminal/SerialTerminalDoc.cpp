// SerialTerminalDoc.cpp : implementation of the CSerialTerminalDoc class
//

#include "stdafx.h"
#include "SerialTerminal.h"
#include "MainFrm.h"

#include "SerialTerminalDoc.h"
#include "SerialTerminalView.h"
#include "ConfigurationPage.h"


#ifdef _DEBUG
#define new DEBUG_NEW
#endif


// CSerialTerminalDoc

IMPLEMENT_DYNCREATE(CSerialTerminalDoc, CDocument)

BEGIN_MESSAGE_MAP(CSerialTerminalDoc, CDocument)
	ON_COMMAND(ID_EDIT_OPTIONS, &CSerialTerminalDoc::OnEditOptions)
	ON_BN_CLICKED(IDC_BUTTON_CONNECT, &CSerialTerminalDoc::OnBnClickedButtonConnect)
	ON_BN_CLICKED(IDC_BUTTON_LOG, &CSerialTerminalDoc::OnBnClickedButtonLog)
END_MESSAGE_MAP()


// CSerialTerminalDoc construction/destruction

CSerialTerminalDoc::CSerialTerminalDoc()
: m_strPortName(_T("")), m_strLogfileName(_T("logfile.log")), 
m_bAutoStart(true), m_bAppendLog(false), m_logging(false)
{
	// TODO: add one-time construction code here
	memset(&m_CommConfig,0,sizeof(COMMCONFIG));
	m_CommConfig.dwSize = sizeof(COMMCONFIG);
	m_CommConfig.dcb.DCBlength = sizeof(DCB);
	InsertNewLastLine();
}

CSerialTerminalDoc::~CSerialTerminalDoc()
{
}

BOOL CSerialTerminalDoc::OnNewDocument()
{
	if (!CDocument::OnNewDocument())
		return FALSE;

	// TODO: add reinitialization code here
	// (SDI documents will reuse this document)

	return TRUE;
}




// CSerialTerminalDoc serialization

void CSerialTerminalDoc::Serialize(CArchive& ar)
{
	if (ar.IsStoring())
	{
		ar.Write(&m_CommConfig,sizeof(COMMCONFIG));
		ar.Write(&m_bAppendLog,sizeof(m_bAppendLog));
		ar.Write(&m_bAutoStart,sizeof(m_bAutoStart));
		ar.WriteString(m_strLogfileName);
		ar.WriteString(_T("\n"));
		ar.WriteString(m_strPortName);
		ar.WriteString(_T("\n"));
	}
	else
	{
		ar.Read(&m_CommConfig, sizeof(COMMCONFIG));
		ar.Read(&m_bAppendLog,sizeof(m_bAppendLog));
		ar.Read(&m_bAutoStart,sizeof(m_bAutoStart));
		ar.ReadString(m_strLogfileName);
		ar.ReadString(m_strPortName);
	}
}


// CSerialTerminalDoc diagnostics

#ifdef _DEBUG
void CSerialTerminalDoc::AssertValid() const
{
	CDocument::AssertValid();
}

void CSerialTerminalDoc::Dump(CDumpContext& dc) const
{
	CDocument::Dump(dc);
}
#endif //_DEBUG


// CSerialTerminalDoc commands

void CSerialTerminalDoc::OnEditOptions()
{
	CPropertySheet sheet(_T("Options"),AfxGetApp()->m_pMainWnd,0);
	
 	CConfigurationPage configPage(&m_CommConfig,m_strPortName, m_strLogfileName);
	configPage.m_bAutoStart = m_bAutoStart;
	configPage.m_bAppendLog = m_bAppendLog;
	
	sheet.AddPage(&configPage);
	
	if(sheet.DoModal() == IDOK)
	{
		//update the port info
		SetTitle(configPage.m_comportComboValue);
		m_strPortName = _T("\\\\.\\") + configPage.m_comportComboValue;
		m_bAutoStart = configPage.m_bAutoStart;
		m_strLogfileName = configPage.m_filename;
		m_bAppendLog = configPage.m_bAppendLog;
	}
}


void CSerialTerminalDoc::SetPathName(LPCTSTR lpszPathName, BOOL bAddToMRU)
{
	CDocument::SetPathName(lpszPathName, bAddToMRU);
	SetTitle(m_strPortName.Right(m_strPortName.GetLength() - 4));
}

void CSerialTerminalDoc::OnBnClickedButtonConnect()
{
	CMainFrame *pMainFrame= (CMainFrame *)AfxGetApp()->m_pMainWnd;
	CDialogBar *pDialogBar = &(pMainFrame->m_mainDialogBar);
	CButton *connectButton = (CButton *)pDialogBar->GetDlgItem(IDC_BUTTON_CONNECT);
	
	if(!m_port.IsConnected()){
		//port is not connected
		if(m_strPortName.IsEmpty()){
			//we haven't been configured yet
			OnEditOptions();
			if(m_strPortName.IsEmpty()){
				//user cancelled out of the config dialog box
				return;
			}
		}
		if(m_port.OpenPort(m_strPortName,&m_CommConfig.dcb)){
			POSITION pos = GetFirstViewPosition();
			CView* pView = GetNextView(pos);
			m_port.SetParent(pView);
			if(m_bAutoStart){
				OnBnClickedButtonLog();
			}
			if(m_bAppendLog==FALSE){
				ClearDocument();
			}
			UpdateAllViews(NULL);
			ScrollAllViews();
			connectButton->SetWindowTextW(_T("Disconnect"));
		}
		else{
			pMainFrame->MessageBox(_T("Unable to open Port.  Please check your settings"));
		}	
	}
	else{
		m_port.ClosePort();
		if(m_logging){
			OnBnClickedButtonLog();
		}
		connectButton->SetWindowTextW(_T("Connect"));		
	}
}

void CSerialTerminalDoc::OnBnClickedButtonLog()
{
	CMainFrame *pMainFrame= (CMainFrame *)AfxGetApp()->m_pMainWnd;
	CDialogBar *pDialogBar = &(pMainFrame->m_mainDialogBar);
	CButton *pButton = (CButton *)pDialogBar->GetDlgItem(IDC_BUTTON_LOG);
	
	CString text;
	pButton->GetWindowText(text);

	if(text == _T("StartLog")){
		CString filename = m_strLogfileName;
		if(filename.Find(_T("%D")) >= 0){
			CTime currentTime = CTime::GetCurrentTime();
			filename.Replace(_T("%D"),currentTime.Format("%m%d%Y"));
		}
		m_logging = logfile.Open(filename, CFile::modeCreate|(m_bAppendLog ? CFile::modeNoTruncate : 0) | CFile::modeWrite | CFile::shareDenyNone );
		if(m_logging){
			logfile.SeekToEnd();
			pButton->SetWindowText(_T("StopLog"));
		}
	}
	else{
		logfile.Close();
		m_logging = false;
		pButton->SetWindowText(_T("StartLog"));
	}
}

void CSerialTerminalDoc::ClearDocument(){
	POSITION pos = m_docData.GetTailPosition();
	while(pos != NULL){
		SDocData *currentItem = m_docData.GetPrev(pos);
		delete currentItem;
		m_docData.RemoveTail();
	}
}
void CSerialTerminalDoc::OnCloseDocument()
{
//make sure that the port is closed when we close the document
	if(!m_port.IsConnected()){
		m_port.ClosePort();
	}

	ClearDocument();	

	CDocument::OnCloseDocument();
}


int CSerialTerminalDoc::LogText(char *buffer, DWORD numBytes)
{
	if(m_logging){
		logfile.Write(buffer,numBytes);
	}
	return 0;
}

int CSerialTerminalDoc::LogText(CString &text)
{
	if(m_logging){
		logfile.WriteString(text);
		logfile.Flush();
	}
	return 0;
}

int CSerialTerminalDoc::AddChar(UINT nChar)
{
	BYTE *pData = new BYTE[1];
	pData[0] = nChar;
	m_port.WriteData(pData, 1);
	delete pData;
	return 1;
}

int CSerialTerminalDoc::ScrollAllViews(){

	POSITION pos = GetFirstViewPosition();
	CSerialTerminalView* pView;
	int count = (int)m_docData.GetCount();
	while (pos != NULL){
		pView = (CSerialTerminalView *)GetNextView( pos );
		pView->ScrollView(count);
	}   
	return count;
}


int CSerialTerminalDoc::AppendText(CString &text)
{
	int start=0, newlineLocation=0;
	CString currentline;

	//remove \r's from the buffer if they exist
 	text.Remove('\r');
	
	while( (newlineLocation = text.Find('\n',start)) != -1)
	{
		currentline = text.Mid(start,newlineLocation+1-start);
		AppendToLastLine(currentline);
		CommitLastLine();
		InsertNewLastLine();
		start = newlineLocation + 1;
	}
	
	if(start != text.GetLength()){
		currentline = text.Mid(start,text.GetLength()-start);
		AppendToLastLine(currentline);
	}
	return 0;
}

int CSerialTerminalDoc::InsertNewLastLine(void)
{
	//make sure that this line actually has a \n in it 
	SDocData *newDocData = new SDocData;
	newDocData->line = _T("");
	m_docData.AddTail(newDocData);
	ScrollAllViews();
	return 0;
}

int CSerialTerminalDoc::AppendToLastLine(CString &line)
{
	//make sure that this line actually has a \n in it 
	POSITION pos = m_docData.GetTailPosition();
	if(pos == NULL){
		//something was wrong and we didn't have a last line
		return 0;
	}
		
	SDocData *newDocData = m_docData.GetPrev(pos);

	if(newDocData->line == _T("")){
		CTime currentTime = CTime::GetCurrentTime();
		newDocData->timestamp = currentTime.Format("%c>> ");
	}
	for(int i=0; i< line.GetLength(); i++){
		switch(line[i]){
			case '\b':
				{
					int length = newDocData->line.GetLength();
					if(length > 0){
						newDocData->line.Delete(length-1,1);
					}
				}
				break;
			case 0x07:
				MessageBeep(-1);
				break;
			default:
				newDocData->line += line[i];
		}
	}
	UpdateAllViews(NULL);
	return 0;
}

int CSerialTerminalDoc::CommitLastLine()
{
	//make sure that this line actually has a \n in it 
	POSITION pos = m_docData.GetTailPosition();
	if(pos == NULL){
		//something was wrong and we didn't have a last line
		return 0;
	}
		
	SDocData *newDocData = m_docData.GetPrev(pos);
	LogText(newDocData->timestamp);
	LogText(newDocData->line);
	return 0;
}
