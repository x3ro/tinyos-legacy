// IMoteTerminal.cpp : implementation file
//

#include "stdafx.h"
#include "iMoteConsole.h"
#include "IMoteTerminal.h"
#include "assert.h"	
#include ".\imoteterminal.h"

// CIMoteTerminal dialog

IMPLEMENT_DYNAMIC(CIMoteTerminal, CDialog)

CIMoteTerminal::CIMoteTerminal(CWnd* pParent /*=NULL*/, CUSBDevice *dev /*=NULL*/,
							   bool att /*=false*/) : CDialog(CIMoteTerminal::IDD, pParent), m_bTextFile(FALSE)
							   , m_fileOpenName(_T(""))
{
	m_parent = pParent;
	m_usb = dev;
	if(dev == NULL){
		m_serialport = new CSerialPort();
		m_serialport->SetParent(this);
	}
	else{
		m_serialport = NULL;
		m_usb->SetParent(this);
	}
	m_attached = att;

	m_buffer = "";
	m_bufferTrue = "";
	m_visible = "";

	m_lines.Add(0);
	m_curLine = 0;
	m_trueCurLine = 0;
	m_trueLines = 0;
	m_sizeCount = 0;
	m_hIcon = AfxGetApp()->LoadIcon(IDI_IMOTE2);
	Create(IDD_IMOTETERMINAL,m_parent);

	DWORD dirLen = sizeof(TCHAR) * GetCurrentDirectory(0,NULL);
	TCHAR *curDir = (TCHAR *)malloc(dirLen);
	assert(dirLen == GetCurrentDirectory(dirLen,curDir) + 1);

	m_curDir.Format("%s", curDir);
	free(curDir);
}

CIMoteTerminal::~CIMoteTerminal()
{
	if(m_usb == NULL)
		delete m_serialport;
	else
		delete m_usb;
	
}

void CIMoteTerminal::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_BUTTON_TERM_CONNECT, m_connectButton);
	DDX_Control(pDX, IDC_BUTTON_TERM_SENDBREAK, m_sendBreakButton);
	DDX_Control(pDX, IDC_STATIC_TERM_DETACHED, m_detachedStatic);
	DDX_Control(pDX, IDC_STATIC_TERM_COM_NUM, m_comNumStatic);
	DDX_Control(pDX, IDC_BUTTON_TERM_SENDFILE, m_sendFileButton);
	DDX_Check(pDX, IDC_CHECK_TERM_TEXT_FILE, m_bTextFile);
	DDX_Control(pDX, IDC_CHECK_TERM_TEXT_FILE, m_textFileCheck);
	DDX_Control(pDX, IDC_RICHEDIT_TERM_FILE, m_fileRichEditControl);
	DDX_Text(pDX, IDC_RICHEDIT_TERM_FILE, m_fileOpenName);
}

LRESULT CIMoteTerminal::OnClosePort(WPARAM wParam, LPARAM lParam){
	closePort();
	return true;
}

void CIMoteTerminal::closePort(){
	if(m_usb != NULL)
		m_usb->CloseDevice();
	else
		m_serialport->ClosePort();
}

void CIMoteTerminal::setAttached(bool att){
	m_attached = att;
}

bool CIMoteTerminal::isAttached(){
	return m_attached;
}

void CIMoteTerminal::setPath(TCHAR *path){
	if(m_usb != NULL)
		m_usb->setDetail(path);

}

BEGIN_MESSAGE_MAP(CIMoteTerminal, CDialog)
	ON_UPDATE_COMMAND_UI(ID_TERM_EDIT_ECHO, OnUpdateTermEditEcho)
	ON_COMMAND(ID_TERM_EDIT_ECHO, OnTermEditEcho)
	ON_BN_CLICKED(IDC_BUTTON_TERM_SENDBREAK, OnBnClickedButtonTermSendbreak)
	ON_BN_CLICKED(IDC_BUTTON_TERM_CLEAR_BUFFER, OnBnClickedButtonTermClearBuffer)
	ON_BN_CLICKED(IDC_BUTTON_TERM_CONNECT, OnBnClickedButtonTermConnect)
	ON_WM_INITMENUPOPUP()
	ON_COMMAND(ID_TERM_EDIT_CLEAR_BUFFER, OnTermEditClearBuffer)
	ON_COMMAND(ID_TERM_EDIT_CONNECT, OnTermEditConnect)
	ON_WM_SIZE()
	ON_WM_SIZING()
	ON_MESSAGE(WM_RECEIVE_USB_DATA,OnReceiveUSBData)
	ON_MESSAGE(WM_RECEIVE_SERIAL_DATA,OnReceiveSerialData)
	ON_MESSAGE(WM_CLOSE_PORT,OnClosePort)
	ON_WM_QUERYDRAGICON()
	ON_COMMAND(ID_TERM_FILE_SAVE, OnTermFileSave)
	ON_COMMAND(ID_TERM_FILE_HIDE, OnTermFileHide)
	ON_COMMAND(ID_TERM_EDIT_COPY, OnTermEditCopy)
	ON_COMMAND(ID_TERM_FILE_SAVEAS, OnTermFileSaveAs)
	ON_BN_CLICKED(IDC_BUTTON_TERM_SENDFILE, OnBnClickedButtonTermSendFile)
	ON_COMMAND(ID_TERM_FILE_OPENFILE, OnTermFileOpenFile)
END_MESSAGE_MAP()


// CIMoteTerminal message handlers

BOOL CIMoteTerminal::OnInitDialog()
{
	CDialog::OnInitDialog();
	SetIcon(m_hIcon, TRUE);			// Set big icon
	SetIcon(m_hIcon, FALSE);		// Set small icon

	m_outputRichEditControl.Create(ES_MULTILINE | ES_READONLY | WS_CHILD |
		ES_AUTOHSCROLL | WS_VISIBLE | WS_BORDER | WS_VSCROLL | ES_WANTRETURN,
		CRect(100, 41, 480 - 10, 280 - 10), this, IDC_RICHEDIT_OUTPUT);
	m_outputRichEditControl.EnableScrollBar(SB_VERT);
	m_outputRichEditControl.SetParent(this);
	m_outputScrollInfo.cbSize = sizeof(SCROLLINFO);
	m_outputScrollInfo.fMask = SIF_POS | SIF_RANGE;
	m_outputScrollInfo.nMin = 0;
	m_detachedStatic.ShowWindow(SW_HIDE);
	if(m_usb != NULL){
		m_comNumStatic.ShowWindow(SW_HIDE);
		m_sendBreakButton.ShowWindow(SW_HIDE);
		m_sendBreakButton.EnableWindow(0);
	}
	else
		m_comNumStatic.ShowWindow(SW_SHOW);
	
	m_hAccel = ::LoadAccelerators(AfxGetResourceHandle(), MAKEINTRESOURCE(IDR_ACCELERATOR_TERM));
	m_outputRichEditControl.SetWindowText(m_visible);
	
	return TRUE;  // return TRUE unless you set the focus to a control
	// EXCEPTION: OCX Property Pages should return FALSE
}

void CIMoteTerminal::DisplayChange()
{
	if(m_usb != NULL){ //serial device
		if(m_attached)
			m_detachedStatic.ShowWindow(SW_HIDE);
		else
			m_detachedStatic.ShowWindow(SW_SHOW);
		if(m_usb->IsConnected())
			m_connectButton.SetWindowText("Disconnect");
		else
			m_connectButton.SetWindowText("Connect");
	}
	else{
		if(m_serialport->IsConnected())
			m_connectButton.SetWindowText("Disconnect");
		else
			m_connectButton.SetWindowText("Connect");
	}
}
void CIMoteTerminal::SendData(CString data){
	if(m_usb == NULL)
		m_serialport->WriteData((BYTE *)((LPCSTR)data), data.GetLength());
	else
		m_usb->WriteData((BYTE *)((LPCSTR)data), data.GetLength(), IMOTE_HID_TYPE_CL_GENERAL);
}

void CIMoteTerminal::SendData(BYTE *data, DWORD len, BYTE type) 
{
	if(m_usb == NULL)
		m_serialport->WriteData(data, len);
	else
		m_usb->WriteData(data, len, type);
}

bool CIMoteTerminal::Scroll(bool up){
	TRACE("info, curline, lines, etc %d %d %d %d %d\r\n", m_curLine, m_lines.GetSize(), m_outputScrollInfo.nPos, m_outputScrollInfo.nMin, m_outputScrollInfo.nMax);
		
	if((m_curLine == 0 && up) || (m_curLine > m_lines.GetSize() - m_outputRichEditControl.MaxLineCount() - 1 && !up) || 
		(m_lines.GetSize() < m_outputRichEditControl.MaxLineCount()))
		return false;
	int startindex, endindex;
	startindex = m_lines.Get(m_curLine += (up?-1:1));

	if(m_buffer[startindex] == '\r'){
		startindex++;
		m_trueCurLine += (up?-1:1);
	}
	if(m_buffer[startindex] == '\n')
		startindex++;
	endindex = m_lines.Get(m_curLine + m_outputRichEditControl.MaxLineCount());

	if(endindex < 0)
		m_visible = m_buffer.Mid(startindex);
	else
		m_visible = m_buffer.Mid(startindex, endindex - startindex);
	return true;
}
void CIMoteTerminal::ScrollToTop(){
	if(m_lines.GetSize() > m_outputRichEditControl.MaxLineCount()){
		m_curLine = 0;
		m_trueCurLine = 0;
		int endindex = m_lines.Get(m_outputRichEditControl.MaxLineCount());
		m_visible = m_buffer.Mid(0, endindex);
	}
	else
		m_visible = m_buffer;
}
void CIMoteTerminal::ScrollToBottom(){
	if(m_lines.GetSize() > m_outputRichEditControl.MaxLineCount()){
		m_curLine = m_lines.GetSize() - m_outputRichEditControl.MaxLineCount();
		m_trueCurLine = m_trueLines - m_visible.Replace('\r','\r');;
		int startindex = m_lines.Get(m_curLine);
		if(m_buffer[startindex] == '\r')
			startindex++;
		if(m_buffer[startindex] == '\n')
			startindex++;
		m_visible = m_buffer.Mid(startindex);
	}
	else
		m_visible = m_buffer;
}

void CIMoteTerminal::UpdateText(){
	m_outputScrollInfo.fMask = 0;
	m_outputRichEditControl.SetWindowText(m_visible);
	if(m_outputScrollInfo.nMax != m_lines.GetSize() - m_outputRichEditControl.MaxLineCount()){
		m_outputScrollInfo.nMax = m_lines.GetSize() - m_outputRichEditControl.MaxLineCount();
		m_outputScrollInfo.fMask |= SIF_RANGE;
	}
	if(m_outputScrollInfo.nPos != m_curLine){
		m_outputScrollInfo.nPos = m_curLine;
		m_outputScrollInfo.fMask |= SIF_POS;
	}
	int temp = m_visible.GetLength();
	m_outputRichEditControl.SetSel(temp, temp);
	m_outputRichEditControl.SetScrollInfo(SB_VERT,&m_outputScrollInfo);
	m_outputRichEditControl.ShowScrollBar(SB_VERT);
	UpdateData();
}
void CIMoteTerminal::WidthAdjustment(){
	if(!m_outputRichEditControl.MaxCharCountChange())
		return;
	m_lines.Clear();
	m_lines.Add(0);
	m_buffer = m_bufferTrue;
	//m_buffer.Replace("\\\n","");
	for(int i = 0, j = 0; i < m_buffer.GetLength(); i++, j++){
		if(m_buffer[i] == '\r'){
			m_lines.Add(i);
			if(i + 1 < m_buffer.GetLength() && m_buffer[i + 1] == '\n')
				i++;
			j = -1;
		}
		else if(j == m_outputRichEditControl.MaxCharCount()){
			m_buffer.Insert(i - 1, '\\');
			m_lines.Add(i++);
			m_buffer.Insert(i - 1, '\n');
			j = 1;
			i++;
		}
	}
	int oldLine = m_curLine;
	if(m_trueCurLine == m_trueLines)
		ScrollToBottom();
	else if(oldLine < m_lines.GetSize() / 2){
		ScrollToTop();
		while(m_curLine < oldLine)
			Scroll(false);
	}
	else if(oldLine < m_lines.GetSize()){
		ScrollToBottom();
		while(m_curLine > oldLine)
			Scroll(true);
	}
	else
		ScrollToBottom();
	UpdateText();
}
void CIMoteTerminal::BufferAppend(char x, bool refresh){
	UpdateData();
	if(x != '\a' && x != '\0'){
		m_buffer.AppendChar(x);
		m_bufferTrue.AppendChar(x);
		if(x == '\r' || (x == '\n' && m_buffer[m_buffer.GetLength() - 2] != '\r')){
			m_lines.Add(m_buffer.GetLength() - 1);
			m_trueLines++;
		}
		else if(x == '\b'){
			if(m_buffer.GetLength() == 1){
				m_buffer = "";
				m_bufferTrue = "";
			}
			else if(m_buffer.GetLength() > 1){
				if(m_buffer[m_buffer.GetLength() - 2] == '\r'){
					m_lines.Pop();
					m_trueLines--;
					m_buffer = m_buffer.Left(m_buffer.GetLength() - 2);
					m_bufferTrue = m_bufferTrue.Left(m_bufferTrue.GetLength() - 2);
				}
				else if(m_buffer.GetLength() > 2 &&
					m_buffer[m_buffer.GetLength() - 2] == '\n' && 
					m_buffer[m_buffer.GetLength() - 3] == '\r'){
					m_lines.Pop();
					m_trueLines--;
					m_buffer = m_buffer.Left(m_buffer.GetLength() - 3);
					m_bufferTrue = m_bufferTrue.Left(m_bufferTrue.GetLength() - 3);
				}
				else if(m_buffer.GetLength() > 4 && 
					m_buffer[m_buffer.GetLength() - 3] == '\n' && 
					m_buffer[m_buffer.GetLength() - 4] == '\\'){
						m_lines.Pop();
						m_buffer = m_buffer.Left(m_buffer.GetLength() - 4);
					}
				else if(m_buffer[m_buffer.GetLength() - 2] == '\n'){
					m_lines.Pop();
					m_trueLines--;
					m_buffer = m_buffer.Left(m_buffer.GetLength() - 2);
					m_bufferTrue = m_bufferTrue.Left(m_bufferTrue.GetLength() - 2);
				}
				else{
					m_buffer = m_buffer.Left(m_buffer.GetLength() - 2);
					m_bufferTrue = m_bufferTrue.Left(m_bufferTrue.GetLength() - 2);
				}

			}
		}
		else{
			int temp = m_lines.Get(m_lines.GetSize() - 1);
			if(m_buffer.GetLength() - (temp==0?0:temp + 1) == m_outputRichEditControl.MaxCharCount()){
				m_buffer.Insert(m_buffer.GetLength() - 1, '\\');//BufferAppend(out,'\\');
				m_lines.Add(m_buffer.GetLength() - 1);
				m_buffer.Insert(m_buffer.GetLength() - 1, '\n');//BufferAppend(out,'\n');
			}
		}
	}
	if(refresh){
		ScrollToBottom();
		UpdateText();
	}
}

void CIMoteTerminal::BufferAppend(CString x){
	for(int i = 0; i < x.GetLength(); i++)
		BufferAppend(x[i], false);
	ScrollToBottom();
	UpdateText();
}
void CIMoteTerminal::BufferAppend(char * y){
	size_t len = strlen(y);
	for(size_t i = 0; i < len; i++)
		BufferAppend(y[i], false);
	ScrollToBottom();
	UpdateText();
}
void CIMoteTerminal::BufferAppend(char * y, DWORD len){
	for(size_t i = 0; i < len; i++)
		BufferAppend(y[i], false);
	ScrollToBottom();
	UpdateText();
}
void CIMoteTerminal::OnUpdateTermEditEcho(CCmdUI *pCmdUI){
	pCmdUI->SetCheck(m_outputRichEditControl.getEcho());
}

void CIMoteTerminal::OnTermEditEcho(){
	m_outputRichEditControl.dEcho();
}

void CIMoteTerminal::OnBnClickedButtonTermSendbreak()
{
	if(m_usb != NULL)
		return;

	Sleep(20);
	m_serialport->SetBreak(true);
	Sleep(10);
	m_serialport->SetBreak(false);
}

void CIMoteTerminal::OnBnClickedButtonTermClearBuffer(){
	OnTermEditClearBuffer();
}

void CIMoteTerminal::OnBnClickedButtonTermConnect(){
	OnTermEditConnect();
}



void CIMoteTerminal::OnInitMenuPopup(CMenu* pPopupMenu, UINT nIndex, BOOL bSysMenu)
{
	ASSERT(pPopupMenu != NULL);
    // Check the enabled state of various menu items.

    CCmdUI state;
    state.m_pMenu = pPopupMenu;
    ASSERT(state.m_pOther == NULL);
    ASSERT(state.m_pParentMenu == NULL);

    // Determine if menu is popup in top-level menu and set m_pOther to
    // it if so (m_pParentMenu == NULL indicates that it is secondary popup).
    HMENU hParentMenu;
    if (AfxGetThreadState()->m_hTrackingMenu == pPopupMenu->m_hMenu)
        state.m_pParentMenu = pPopupMenu;    // Parent == child for tracking popup.
    else if ((hParentMenu = ::GetMenu(m_hWnd)) != NULL)
    {
        CWnd* pParent = this;
           // Child windows don't have menus--need to go to the top!
        if (pParent != NULL &&
           (hParentMenu = ::GetMenu(pParent->m_hWnd)) != NULL)
        {
           int nIndexMax = ::GetMenuItemCount(hParentMenu);
           for (int nIndex = 0; nIndex < nIndexMax; nIndex++)
           {
            if (::GetSubMenu(hParentMenu, nIndex) == pPopupMenu->m_hMenu)
            {
                // When popup is found, m_pParentMenu is containing menu.
                state.m_pParentMenu = CMenu::FromHandle(hParentMenu);
                break;
            }
           }
        }
    }

    state.m_nIndexMax = pPopupMenu->GetMenuItemCount();
    for (state.m_nIndex = 0; state.m_nIndex < state.m_nIndexMax;
      state.m_nIndex++)
    {
        state.m_nID = pPopupMenu->GetMenuItemID(state.m_nIndex);
        if (state.m_nID == 0)
           continue; // Menu separator or invalid cmd - ignore it.

        ASSERT(state.m_pOther == NULL);
        ASSERT(state.m_pMenu != NULL);
        if (state.m_nID == (UINT)-1)
        {
           // Possibly a popup menu, route to first item of that popup.
           state.m_pSubMenu = pPopupMenu->GetSubMenu(state.m_nIndex);
           if (state.m_pSubMenu == NULL ||
            (state.m_nID = state.m_pSubMenu->GetMenuItemID(0)) == 0 ||
            state.m_nID == (UINT)-1)
           {
            continue;       // First item of popup can't be routed to.
           }
           state.DoUpdate(this, TRUE);   // Popups are never auto disabled.
        }
        else
        {
           // Normal menu item.
           // Auto enable/disable if frame window has m_bAutoMenuEnable
           // set and command is _not_ a system command.
           state.m_pSubMenu = NULL;
           state.DoUpdate(this, FALSE);
        }

        // Adjust for menu deletions and additions.
        UINT nCount = pPopupMenu->GetMenuItemCount();
        if (nCount < state.m_nIndexMax)
        {
           state.m_nIndex -= (state.m_nIndexMax - nCount);
           while (state.m_nIndex < nCount &&
            pPopupMenu->GetMenuItemID(state.m_nIndex) == state.m_nID)
           {
            state.m_nIndex++;
           }
        }
        state.m_nIndexMax = nCount;
    }
}

void CIMoteTerminal::OnTermEditClearBuffer(){
	m_buffer = "";
	m_bufferTrue = "";
	m_visible = "";
	m_curLine = 0;
	m_trueLines = 0;
	m_lines.Clear();
	m_lines.Add(0);
	m_outputRichEditControl.SetWindowText(m_visible);
	if(!m_attached && m_usb != NULL)
		ShowWindow(SW_HIDE);
}

void CIMoteTerminal::OnTermEditConnect()
{
	if(m_usb == NULL){ //serial device
		if(!m_serialport->IsConnected())
			if(m_serialport->OpenPort(((CIMoteConsoleDlg *)m_parent)->m_strPortName, &(((CIMoteConsoleDlg *)m_parent)->m_pCommConfig->dcb)))
				m_connectButton.SetWindowText("Disconnect");
			else
				MessageBox("Error opening COM port");
		else
			if(m_serialport->ClosePort())
				m_connectButton.SetWindowText("Connect");
			else
				MessageBox("Unable to close COM port");
	}
	else{
		if(!m_usb->IsConnected())
			if(m_usb->ConnectDevice())
				m_connectButton.SetWindowText("Disconnect");
			else
				MessageBox("Error accessing USB device");
		else
			if(m_usb->CloseDevice())
				m_connectButton.SetWindowText("Connect");
			else
				MessageBox("Unable to disconnect from USB device");
	}
}

void CIMoteTerminal::OnSize(UINT nType, int cx, int cy)
{	
	//TRACE("size %d %d\r\n",cx,cy);
	if(m_sizeCount == 0)
		m_sizeCount++;
	else if(nType != SIZE_MINIMIZED){
		m_fileRichEditControl.SetWindowPos(NULL , 100, 0, cx - 110, 23, SWP_NOREPOSITION | SWP_NOMOVE | SWP_SHOWWINDOW);
		m_outputRichEditControl.SetWindowPos(NULL, 100, 41, cx - 110, cy - 41 - 10, SWP_NOREPOSITION | SWP_NOMOVE | SWP_SHOWWINDOW);
		WidthAdjustment();
	}
	
	CDialog::OnSize(nType, cx, cy);
}

void CIMoteTerminal::OnSizing(UINT fwSide, LPRECT pRect)
{
	if(pRect->right - pRect->left < 288)
		if(fwSide == 1 || fwSide == 4 || fwSide == 7)
			pRect->left = pRect->right - 280 - 8;
		else
			pRect->right = pRect->left + 280 + 8;

	if(pRect->bottom - pRect->top < 190 + 54)
		if(fwSide == 3 || fwSide == 4 || fwSide == 5)
			pRect->top = pRect->bottom - 190 - 54;
		else
			pRect->bottom = pRect->top + 190 + 54;
	CDialog::OnSizing(fwSide, pRect);
}

LRESULT CIMoteTerminal::OnReceiveSerialData(WPARAM wParam, LPARAM lParam)
{
	//following couple of lines allow us to debug a raw datastream
	char *rxstring = (char *)lParam;
	DWORD numBytesReceived = (DWORD) wParam;
	BufferAppend(rxstring, numBytesReceived);
	delete []rxstring;
	return TRUE;

#if 0
	DWORD i,offset;
	//TRACE("Rx...Buffer = %#X\tNumBytesReceived = %d\n",rxstring,numBytesReceived);
	/*****
	data format for the accelerometer data looks something like:
	0{2 bit addr}{5 data bits} {1}{7 data bits}
	******/
	for(offset=0; offset<numBytesReceived; offset++)
	{
		//find the correct first bytes
		if((rxstring[offset]  & 0xE0) == 0)
		{
			break;
		}
	}
	//offset current points to the correct first element for us to look at
	//start reconstructing the 16 bit numbers and doing the divide
	
	for(i=offset;(i+6)<numBytesReceived; i+=6)
	{	
		static bool init = false;
		POINT point;
		DWORD B,C,D,Tx, Ty,T;
		int Rx, Ry;
		B = ((rxstring[i] & 0x1F)<<7) | (rxstring[i+1] & 0x7F);
		C = ((rxstring[i+2] & 0x1F)<<7) | (rxstring[i+3] & 0x7F);
		D = ((rxstring[i+4] & 0x1F)<<7) | (rxstring[i+5] & 0x7F);
		Tx = B;
		Ty = D-C;
		T = C/2 + D/2 - B/2;

		Rx = ((Tx << 16) / T) - (65536/2);
		Ry = ((Ty << 16) / T) - (65536/2);
		//point.x =(LONG)( (rxstring[byte_index]<<8) + rxstring[byte_index+1]) -(65536/2);
		//point.x = (LONG)( (rxstring[byte_index]<<8) + rxstring[byte_index+1]);
		//TRACE("%d %d = %d\n",rxstring[i], rxstring[i+1], point.x);
		//TRACE("Found T, index %d \n", byte_index);
		//TRACE("Tx = %d, Ty = %d, T = %d, Rx = %d, Ry = %d\n",Tx, Ty, T, Rx, Ry);
		point.x = (LONG) Rx;
		point.y = (LONG) Ry;

		if(!init)
		{
			CIMoteCartesianPlot *pFrame=CreateNewView(0,0xDEADBEEF,0);
			pFrame->SetMappingFunction(-2,2);
			init = true;
		}
		AddPoint(point, 0);
	}
		
	delete rxstring;

	
	return TRUE;
//#endif;
	POINT point;
	static bool bGotBeef = 0;
	static bool bFirstTime = true;
	static unsigned short NumDataBytes;
	static unsigned short NumBytesProcessed;
	//static int MoteIDs[NUMCHANNELS];
	static unsigned short SensorID;
	static unsigned int MoteID;
	static unsigned int SensorType;
	static unsigned int ExtraInfo;
	static unsigned int TimeID;
	static unsigned int ChannelID;
	static unsigned char HeaderIndex;
	static unsigned char Header[16];
	unsigned short *short_ptr;
	unsigned int *int_ptr;
	DWORD byte_index;
	static unsigned char LastByte = 0;
//	unsigned int ProblemIndex;
	unsigned int EmptyChannel;
	static unsigned int NumProblems = 0;
	CString logentry;
	static bool bPrintheader=true;
	CTime time;
	static int Tx, Ty, T, Rx, Ry, Tb, Tc, Td, b0, b1;
	static int CurrentCounter, CurrentByte;
	// Hack, for now statically allocate 
	static unsigned char *CameraBuffer;
	static unsigned int CurrentCameraID;
	static unsigned int CameraBufferIndex;
	static unsigned int SegmentIndex;
	static bool PictureInProgress;
	static unsigned int LastPicID;

#define MAX_PIC_SIZE 80000
#define INVALID_SENSOR 0
#define PH_SENSOR 1
#define PRESSURE_SENSOR 2
#define ACCELEROMETER_SENSOR 3
#define CAMERA_SENSOR 4

#define FIRST_SEGMENT 0x1111
#define MID_SEGMENT 0
#define END_OF_PIC 0xffff

	for(int channel = 0; (channel < NUMCHANNELS) && bFirstTime; channel++) {
		MoteIDs[channel] = 0;
		HeaderIndex = 0;
		CurrentCameraID = 0;
		CameraBuffer = NULL;
		CameraBufferIndex = 0;
		PictureInProgress = false;
	}

	if (bFirstTime) {
		// Figure out the start of the file names
		CFileFind finder;
		CString TempName;
		unsigned int TempID;
		LastPicID = 0;
		BOOL bResult = finder.FindFile("c:\\icam\\*.jpg");

		while (bResult) {
			bResult = finder.FindNextFile();
			TempName = finder.GetFileName();
			if (sscanf((LPCSTR)TempName, "%d.jpg", &TempID) == 1) {
				// valid pic id
				if (LastPicID < TempID) {
					LastPicID = TempID;
				}
			}
		}
		LastPicID++;
	}


	bFirstTime = false;
	TRACE("Rx...Buffer = %#X\tNumBytesReceived = %d\n",rxstring,numBytesReceived);
	byte_index = 0;
	while(byte_index < numBytesReceived) {
		// Look for DEADBEEF, get all header info
		for(; (byte_index < numBytesReceived) && !bGotBeef; byte_index++) {
			switch (HeaderIndex) {
			case 0:
				if (rxstring[byte_index] == 0xEF) {
					HeaderIndex = 1;
				}
				break;
			case 1:
				if (rxstring[byte_index] == 0xBE) {
					HeaderIndex = 2;
				} else {
					HeaderIndex = 0;
				}
				break;
			case 2:
				if (rxstring[byte_index] == 0xAD) {
					HeaderIndex = 3;
				} else {
					HeaderIndex = 0;
				}
				break;
			case 3:
				if (rxstring[byte_index] == 0xDE) {
					HeaderIndex = 4;
				} else {
					HeaderIndex = 0;
				}
				break;
			case 13:
				// Done with header
				CurrentCounter = 0;
				CurrentByte = 0;
				bGotBeef = 1;
				Header[HeaderIndex] = rxstring[byte_index];
				/*
				* Header :
				* DEADBEEF (4B)
				* MOTE ID (4B)
				* Sensor TYPE (2B)
				* LENGTH (2B)
				* Extra Info (2B)
				* 
				*/
				int_ptr = (unsigned int *) &(Header[4]);
				MoteID = *int_ptr;
				short_ptr = (unsigned short *) &(Header[8]);
				SensorType = *short_ptr;
				short_ptr++;
				NumDataBytes = *short_ptr;
				short_ptr++;
				ExtraInfo = *short_ptr;
				NumBytesProcessed = 0;
				ChannelID = NUMCHANNELS;
				EmptyChannel = NUMCHANNELS;

				if (SensorType == CAMERA_SENSOR) {
					// check with segment
					TRACE("Camera seg %x, buf Index %d, NumDataBytes %d\r\n",
						ExtraInfo, CameraBufferIndex, NumDataBytes);
					if (ExtraInfo == FIRST_SEGMENT) {
						// first segment
						CurrentCameraID = MoteID;
						CameraBufferIndex = 0;						
						if (!PictureInProgress) {
							// create buffer
							CameraBuffer = new unsigned char[MAX_PIC_SIZE];
							PictureInProgress = true;
						}
					}
					SegmentIndex = 0;	// Per segment index
					break;	// don't process the channel stuff
				}
				// Find mote channel, 
				for(int channel = 0; channel < NUMCHANNELS; channel++) {
					if (MoteIDs[channel] == MoteID) {
						ChannelID = channel;
						break;
					} else {
						if (MoteIDs[channel] == 0) {
							EmptyChannel = channel;
						}
					}
				}
				

				if (ChannelID == NUMCHANNELS) {
					// Didn't find a channel
					if (EmptyChannel < NUMCHANNELS) {
						// assign the mote id to this channel
						MoteIDs[EmptyChannel] = MoteID;
						ChannelID = EmptyChannel;
						CIMoteCartesianPlot *pFrame=CreateNewView(ChannelID,MoteID,SensorID);
						/*
							Note to LAMA:  below is an example of how to use the setmapping function
							pFrame->SetMappingFunction(slope, offset, minrange, maxrange
						*/
						switch(SensorType) {
							case PH_SENSOR:
								pFrame->SetMappingFunction(0,14);
								rawdata = false;
								break;
							case PRESSURE_SENSOR:
								pFrame->SetMappingFunction(0,20.684);
								//pFrame->SetMappingFunction(0,300);
								rawdata = false;
								break;
							case ACCELEROMETER_SENSOR:
								pFrame->SetMappingFunction(-2,2);
								rawdata = false;
								break;
							default :
								//pFrame->SetMappingFunction(1,1,0,14);
								pFrame->SetMappingFunction(-32768,32768);
						}
						//UpdateAllViews(NULL);
					}  
					/*
					* NOTE: if ChannelID is not assigned, 
					* the processing will remain the same, but the data won't
					* be displayed.
					* TODO : handle later
					*/
				}
				//log transaction info to file here:
				if(bPrintheader)
				{
					logentry.Format("Timestamp, iMoteID, # of Bytes\r\n");
					//logfile<<logentry<<endl;
					SaveLogEntry(&logentry);
					bPrintheader=false;
				}
				time=time.GetCurrentTime();
				//logfile<<time.Format("%c");
				SaveLogEntry(&time.Format("%c"));
				logentry.Format(", %#X, %d\r\n",MoteID, NumDataBytes);
				//logfile<<logentry<<endl;
				SaveLogEntry(&logentry);				
				break;
			default:
				Header[HeaderIndex] = rxstring[byte_index];
				HeaderIndex++;
				break;
			}
		}
		if (!bGotBeef) {
			delete []rxstring;
			return TRUE;
		}
		// Got DEADBEEF, process data
		for(; byte_index <numBytesReceived; byte_index++,NumBytesProcessed ++) {
			if (NumBytesProcessed >= NumDataBytes) {
				// go back to start, look for DEADBEEF again
				bGotBeef = false;
				HeaderIndex = 0;
				TRACE("Mote ID %lx, NumBytes %ld, byte index %d \n", MoteID, NumDataBytes, byte_index);
				//MoteID = 0;
				//NumDataBytes = 0;
				break;
			}
			if (rawdata) {	//RAW_BYTES mode, no processing
				// Assume data is 2 bytes long, and back to back
				if (CurrentByte == 0) {
					b0 = rxstring[byte_index];
					CurrentByte = 1;
				} else {
					b1 = rxstring[byte_index];
					CurrentByte = 0;
					int sample_data;
					sample_data = (b1 <<8) + b0;
					//sample_data -= 0x2000;
					//sample_data = sample_data << 2;
					point.x = (LONG) sample_data;
					point.y = 0;
					//TRACE("sample is %d\r\n", sample_data);
					if (ChannelID < NUMCHANNELS) {
						// valid channel
						AddPoint(point, ChannelID);
					}
				}
			} else {
				if (CurrentByte == 0) {
					b0 = rxstring[byte_index];
					CurrentByte = 1;
					if (SensorType == CAMERA_SENSOR) {
						// just copy data
						CameraBuffer[CameraBufferIndex] = b0;
						SegmentIndex++;
						CameraBufferIndex++;
					}
				} else {
					b1 = rxstring[byte_index];
					CurrentByte = 0;
					switch(SensorType) {
						case PH_SENSOR:
							/*
							* A/D maps 0-5V range to 0-32 K 
							* pH = -7.752 * V + 16.237
							* V = raw_data * 5 / 32768
							* The plot output expects the 0 - 14 range to be represented in -32 - 32 K
							* point.x = (-7.752 * (raw_data * 5/32768) + 16.237) * 64K / 14 - 32K
							*/
							double ph_data;
							ph_data = (b1 <<8) + b0;
							ph_data = -7.752 * (ph_data/ 32768) * 5 + 16.237;
							ph_data = (ph_data * 65536 / 14) - 32768;
							point.x = (LONG) ph_data;
							point.y = 0;
							if (ChannelID < NUMCHANNELS) {
								// valid channel
								AddPoint(point, ChannelID);
							}
							break;
						case PRESSURE_SENSOR:
							/*
							* A/D maps 0-5V range to 0-32 K 
							* The plot output expects the 0 - 20.684 range to be represented in -32 - 32 K
							* point.x = (raw_data * 5/32768) * 64K / 20.684 - 32K
							*/
							int pressure_data;
							pressure_data = (b1 <<8) + b0;
							pressure_data = pressure_data * 2 - 32768;
							point.x = (LONG) pressure_data;
							point.y = 0;
							if (ChannelID < NUMCHANNELS) {
								// valid channel
								AddPoint(point, ChannelID);
							}
							break;
						case ACCELEROMETER_SENSOR:
							// TRACE("CurrentCounter %d, ByteIndex %d \n", CurrentCounter, byte_index);
							switch (CurrentCounter) {
								case 0:
									Tx = (b0 <<8) + b1;;	
									CurrentCounter = 1;
									//TRACE("Found Tx, index %d \n", byte_index);
									break;
								case 1:
									Ty = (b0 <<8) + b1;
									CurrentCounter = 2;
									//TRACE("Found Ty, index %d \n", byte_index);
									break;
								case 2:
									T = (b0 <<8) + b1;
									Rx = ((Tx << 16) / T) - (65536/2);
									Ry = ((Ty << 16) / T) - (65536/2);
									//point.x =(LONG)( (rxstring[byte_index]<<8) + rxstring[byte_index+1]) -(65536/2);
									//point.x = (LONG)( (rxstring[byte_index]<<8) + rxstring[byte_index+1]);
									//TRACE("%d %d = %d\n",rxstring[i], rxstring[i+1], point.x);
									//TRACE("Found T, index %d \n", byte_index);
									//TRACE("Tx = %d, Ty = %d, T = %d, Rx = %d, Ry = %d\n",Tx, Ty, T, Rx, Ry);
									point.x = (LONG) Rx;
									point.y = (LONG) Ry;
									if (ChannelID < NUMCHANNELS) {
										// valid channel
										AddPoint(point, ChannelID);
									}
									CurrentCounter = 0;
									break;
								default:
									break;
							}
							break;
						
						case CAMERA_SENSOR:
							// just copy data
							CameraBuffer[CameraBufferIndex] = b1;
							SegmentIndex++;
							CameraBufferIndex++;
							break;
						
					}
				}
			//for now, just save the point in the x field of the structure
			}
			//NumBytesProcessed += 2;		
		}
		TRACE("NumBytesProcessed %d, NumDataBytes %d\r\n", NumBytesProcessed, NumDataBytes);
		// Check if we reached the end of a picture, write it to file
		if ((SensorType == CAMERA_SENSOR) && (NumBytesProcessed == NumDataBytes) &&
			(ExtraInfo == END_OF_PIC)) {
				// Create output buffer , assume header < 1000
				unsigned char *JpgImage;
				int JpgImageLen;
				JpgImage = new unsigned char[CameraBufferIndex+1000];
				// build jpeg image
				BuildJPG(CameraBuffer, CameraBufferIndex, JpgImage, &JpgImageLen);
				// write to file
				char pszFileName[200];
				CFile PictureFile;
				CFileException fileException;

				sprintf(pszFileName, "c:\\icam\\%d.jpg", LastPicID);
				LastPicID++;

				if ( !PictureFile.Open( pszFileName, CFile::modeCreate |   
									CFile::modeWrite | CFile::typeBinary,
									&fileException ) )
				{
					TRACE( "Can't open file %s, error = %u\n",
								pszFileName, fileException.m_cause );
				}
				//PictureFile.Write(CameraBuffer, CameraBufferIndex);
				PictureFile.Write(JpgImage, JpgImageLen);
				PictureFile.Close();
				TRACE("Wrote Jpeg image raw %d\r\n", CameraBufferIndex);
				
				delete []CameraBuffer;
				delete []JpgImage;
				PictureInProgress = false;
		}
	}
	delete []rxstring;
	return TRUE;
#endif;
}


LRESULT CIMoteTerminal::OnReceiveUSBData(WPARAM wParam, LPARAM lParam){
	//following couple of lines allow us to debug a raw datastream
	BYTE *InputReport = (BYTE *)lParam;
	DWORD BytesRead = ((USBmessage *)wParam)->actualBytesRead;
	BYTE type;
	BYTE valid;
	USBdata *USBin = &m_dataIn;

	type = *(InputReport + IMOTE_HID_TYPE);
	if((type >> IMOTE_HID_TYPE_MSC) != 0){	//the only protocol currently supported involves msc being 0
		free(InputReport);
		return FALSE;
	}
	if(isFlagged(type, _BIT(IMOTE_HID_TYPE_H))){
		USBin->i = 0;
		USBin->type = type;
		free(USBin->data);
		USBin->data = NULL;
		
		switch((USBin->type >> IMOTE_HID_TYPE_L) & 3){
			case IMOTE_HID_TYPE_L_BYTE:
                USBin->n = *(InputReport + IMOTE_HID_NI);
				if(USBin->n == 0){
					valid = *(InputReport + IMOTE_HID_NI + 1);
					USBin->data = (BYTE *)malloc(valid);
				}
				else{
					valid = IMOTE_HID_BYTE_MAXPACKETDATA;
					USBin->data = (BYTE *)malloc((USBin->n + 1) * IMOTE_HID_BYTE_MAXPACKETDATA - 1);
				}
				
				memcpy(USBin->data, InputReport + IMOTE_HID_NI + 1 + (USBin->n == 0?1:0), valid);
				break;
			case IMOTE_HID_TYPE_L_SHORT:
				USBin->n = (*(InputReport + IMOTE_HID_NI) << 8) | *(InputReport + IMOTE_HID_NI + 1);
				if(USBin->n == 0){
					valid = *(InputReport + IMOTE_HID_NI + 2);
					USBin->data = (BYTE *)malloc(valid);
				}
				else{
					valid = IMOTE_HID_SHORT_MAXPACKETDATA;
					USBin->data = (BYTE *)malloc((USBin->n + 1) * IMOTE_HID_SHORT_MAXPACKETDATA - 1);
				}
				memcpy(USBin->data, InputReport + IMOTE_HID_NI + 2 + (USBin->n == 0?1:0), valid);
                break;
			case IMOTE_HID_TYPE_L_INT:
				USBin->n = (*(InputReport + IMOTE_HID_NI) << 24) | (*(InputReport + IMOTE_HID_NI + 1) << 16) | (*(InputReport + IMOTE_HID_NI + 2) << 8) | *(InputReport + IMOTE_HID_NI + 3);
				if(USBin->n == 0){
					valid = *(InputReport + IMOTE_HID_NI + 4);
					USBin->data = (BYTE *)malloc(valid);
				}
				else{
					valid = IMOTE_HID_INT_MAXPACKETDATA;
					USBin->data = (BYTE *)malloc((USBin->n + 1) * IMOTE_HID_INT_MAXPACKETDATA - 1);
				}
				memcpy(USBin->data, InputReport + IMOTE_HID_NI + 4 + (USBin->n == 0?1:0), valid);
                break;
			default:
				TRACE("AH HAH!\r\n");
		}
	}
	else{
		switch((USBin->type >> IMOTE_HID_TYPE_L) & 3){
			case IMOTE_HID_TYPE_L_BYTE:
				assert(USBin->i == *(InputReport + IMOTE_HID_NI));
				if(USBin->n == USBin->i)
					valid = *(InputReport + IMOTE_HID_NI + 1);
				else
					valid = IMOTE_HID_BYTE_MAXPACKETDATA;
				memcpy(USBin->data + USBin->i * IMOTE_HID_BYTE_MAXPACKETDATA, InputReport + IMOTE_HID_NI + 1 + (USBin->n == USBin->i?1:0), valid);
				break;
			case IMOTE_HID_TYPE_L_SHORT:
				assert(USBin->i == ((*(InputReport + IMOTE_HID_NI) << 8) | (*(InputReport + IMOTE_HID_NI + 1))));
				if(USBin->n == USBin->i)
					valid = *(InputReport + IMOTE_HID_NI + 2);
				else
					valid = IMOTE_HID_SHORT_MAXPACKETDATA;
				memcpy(USBin->data + USBin->i * IMOTE_HID_SHORT_MAXPACKETDATA, InputReport + IMOTE_HID_NI + 2 + (USBin->n == USBin->i?1:0), valid);
				break;
			case IMOTE_HID_TYPE_L_INT:
				assert(USBin->i == ((*(InputReport + IMOTE_HID_NI) << 24) | (*(InputReport + IMOTE_HID_NI + 1) << 16) |
								(*(InputReport + IMOTE_HID_NI + 2) << 8) | (*(InputReport + IMOTE_HID_NI + 3))));
				if(USBin->n == USBin->i)
					valid = *(InputReport + IMOTE_HID_NI + 4);
				else
					valid = IMOTE_HID_INT_MAXPACKETDATA;
				memcpy(USBin->data + USBin->i * IMOTE_HID_INT_MAXPACKETDATA, InputReport + IMOTE_HID_NI + 4 + (USBin->n == USBin->i?1:0), valid);
				break;
		}
	}
	if(USBin->i >= USBin->n){
		switch((USBin->type >> IMOTE_HID_TYPE_L) & 3){
			case IMOTE_HID_TYPE_L_BYTE:
				BytesRead = USBin->n * IMOTE_HID_BYTE_MAXPACKETDATA + valid;
				break;
			case IMOTE_HID_TYPE_L_SHORT:
				BytesRead = USBin->n * IMOTE_HID_SHORT_MAXPACKETDATA + valid;
				break;
			case IMOTE_HID_TYPE_L_INT:
				BytesRead = USBin->n * IMOTE_HID_INT_MAXPACKETDATA + valid;
				break;
		}
		if((USBin->type & 0x3) == IMOTE_HID_TYPE_CL_BLUSH){
			USBin->data = (BYTE *)realloc(USBin->data, BytesRead + 1);
			assert(USBin->data != NULL);
			USBin->data[BytesRead] = '\0';
			USBin->len = BytesRead + 1;//or just bytesread?
		}
		else{
			USBin->data = (BYTE *)realloc(USBin->data, BytesRead);
			assert(USBin->data != NULL);
			USBin->len = BytesRead;
		}
		
		if((USBin->type & 0x3) == IMOTE_HID_TYPE_CL_GENERAL){ //signal for full transfer here
			free(USBin->data);	
			USBin->data = NULL;
		}
		else if((USBin->type & 0x3) == IMOTE_HID_TYPE_CL_BINARY){
			CString temp;
			temp.Format("Received packet; len %d\r\n", USBin->len);
			MessageBox(temp);
			/*DWORD bytesWritten = 0;
			
			HANDLE file = CreateFile("received.bin.out", GENERIC_WRITE,0,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL);
			if(file == INVALID_HANDLE_VALUE){
				MessageBox("Binary Save Failed: Cannot open handle to file");
				CloseHandle(file);
			}
			else{
				WriteFile(file,USBin->data, USBin->len, &bytesWritten, NULL);
				CloseHandle(file);
			}*/
			free(USBin->data);
			USBin->data = NULL;
		}
		else if((USBin->type & 0x3) == IMOTE_HID_TYPE_CL_RPACKET){
			free(USBin->data);	
			USBin->data = NULL;
		}
		else if((USBin->type & 0x3) == IMOTE_HID_TYPE_CL_BLUSH){
			BufferAppend((char *)USBin->data);
			free(USBin->data);
			USBin->data = NULL;
		}
		
		free(InputReport);
		InputReport = NULL;
		delete ((USBmessage *)wParam);
		return TRUE;
	}
	USBin->i++;

	free(InputReport);
	InputReport = NULL;
	delete ((USBmessage *)wParam);
	return FALSE;
}
HCURSOR CIMoteTerminal::OnQueryDragIcon()
{
	return (HCURSOR) m_hIcon;
	//return CDialog::OnQueryDragIcon();
}

void CIMoteTerminal::OnTermFileSave()
{
	DWORD bytesWritten = 0;
	
	if(m_fileSaveName == ""){
		OnTermFileSaveAs();
		return;
	}
	HANDLE file = CreateFile((LPCSTR)m_fileSaveName, GENERIC_WRITE,0,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL);
	if(file == INVALID_HANDLE_VALUE){
		MessageBox("Save Failed: Cannot open handle to file");
		CloseHandle(file);
		return;
	}	
	WriteFile(file,(LPCSTR)m_bufferTrue, m_bufferTrue.GetLength(), &bytesWritten, NULL);
	CloseHandle(file);
}

void CIMoteTerminal::OnTermFileHide(){
	ShowWindow(SW_HIDE);
}

void CIMoteTerminal::OnTermEditCopy(){
	m_outputRichEditControl.PostMessage(WM_COPY);
}

void CIMoteTerminal::OnTermFileSaveAs(){

	CFileDialog *fd;
	if(m_fileSaveName == ""){
		CString temp = m_curDir;
		temp.Append("\\data");
		fd = new CFileDialog(false,"log",(LPCSTR)temp, OFN_HIDEREADONLY | OFN_OVERWRITEPROMPT, NULL,this,sizeof(OPENFILENAME));
	}
	else
		fd = new CFileDialog(false,"log",(LPCSTR)m_fileSaveName, OFN_HIDEREADONLY | OFN_OVERWRITEPROMPT, NULL,this,sizeof(OPENFILENAME));
	if(fd->DoModal() == IDOK){
		m_fileSaveName = fd->GetPathName();
		OnTermFileSave();
	}
	delete fd;
}
void CIMoteTerminal::OnTermFileOpenFile()
{
	CFileDialog *fd = new CFileDialog(TRUE, NULL, NULL, OFN_HIDEREADONLY | OFN_OVERWRITEPROMPT, NULL, this, sizeof(OPENFILENAME));
	if(fd->DoModal() == IDOK)
		m_fileOpenName = fd->GetPathName();
	m_fileRichEditControl.SetWindowText(m_fileOpenName);
	delete fd;
}

void CIMoteTerminal::OnBnClickedButtonTermSendFile(){
	UpdateData();
	BYTE *buffer;
	DWORD length, bytesRead, capacity = 20;
	bool result = true;
	if(((m_usb != NULL && m_usb->IsConnected()) || (m_usb == NULL && m_serialport->IsConnected())) &&
		m_fileOpenName != ""){
			HANDLE file = CreateFile(m_fileOpenName, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
			if(file == INVALID_HANDLE_VALUE){
				CString temp;
				temp.Format("Cannot access file \'%s\'", m_fileOpenName);
				MessageBox(temp);
				return;
			}
			buffer = (BYTE *)malloc(capacity);
			for(length = 0; result; length++){
				if(capacity == length){
					capacity *= 2;
					buffer = (BYTE *)realloc(buffer, capacity);
					assert(buffer != NULL);
				}
				result = ReadFile(file, buffer + length, 1, &bytesRead, NULL);
				if(bytesRead == 0){//EOF
					result = false;
					buffer = (BYTE *)realloc(buffer, length + 1);//in case it's a text thing
					buffer[length] = '\0';
				}
			}
			length--;
			if(m_bTextFile){
				SendData(buffer, length, IMOTE_HID_TYPE_CL_BLUSH);
			}
			else
				SendData(buffer, length, IMOTE_HID_TYPE_CL_BINARY);
			free(buffer);
			CloseHandle(file);
		}
	else if(m_usb != NULL && !m_usb->IsConnected() || (m_usb == NULL && !m_serialport->IsConnected()))
		MessageBox("Device not connected");
	else if(m_fileOpenName == "")
		MessageBox("No file specified");
}

BOOL CIMoteTerminal::PreTranslateMessage(MSG* pMsg)
{
	if(WM_KEYFIRST <= pMsg->message && pMsg->message <= WM_KEYLAST)
		if(m_hAccel && ::TranslateAccelerator(m_hWnd, m_hAccel, pMsg))
			return TRUE;

	return CDialog::PreTranslateMessage(pMsg);
}