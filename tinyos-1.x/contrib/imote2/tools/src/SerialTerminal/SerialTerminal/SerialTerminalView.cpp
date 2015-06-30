// SerialTerminalView.cpp : implementation of the CSerialTerminalView class
//

#include "stdafx.h"
#include "SerialTerminal.h"

#include "MainFrm.h"
#include "SerialTerminalDoc.h"
#include "SerialTerminalView.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif


// CSerialTerminalView

IMPLEMENT_DYNCREATE(CSerialTerminalView, CView)

BEGIN_MESSAGE_MAP(CSerialTerminalView, CView)
	// Standard printing commands
	ON_COMMAND(ID_FILE_PRINT, &CView::OnFilePrint)
	ON_COMMAND(ID_FILE_PRINT_DIRECT, &CView::OnFilePrint)
	ON_COMMAND(ID_FILE_PRINT_PREVIEW, &CView::OnFilePrintPreview)
	ON_MESSAGE(WM_RECEIVE_SERIAL_DATA, &CSerialTerminalView::OnReceiveSerialData)
	ON_WM_CREATE()
	ON_WM_SIZE()
	ON_WM_TIMER()
//	ON_WM_CHAR()
ON_BN_CLICKED(IDC_BUTTON_CLEAR, &CSerialTerminalView::OnBnClickedButtonClear)
ON_WM_SETFOCUS()
ON_WM_VSCROLL()
ON_WM_CHAR()
ON_BN_CLICKED(IDC_CHECK_TIMESTAMPING, &CSerialTerminalView::OnBnClickedCheckTimestamping)
END_MESSAGE_MAP()

// CSerialTerminalView construction/destruction

CSerialTerminalView::CSerialTerminalView() : m_promptColor(RGB(0,200,0)) ,m_timestampColor(RGB(0,0,200)), m_displayTimestamps(1), m_promptStr(_T("BluSH"))
{
	// TODO: add construction code here
	m_font.CreatePointFont(80,_T("Courier New"));
}

CSerialTerminalView::~CSerialTerminalView()
{
}

BOOL CSerialTerminalView::PreCreateWindow(CREATESTRUCT& cs)
{
	// TODO: Modify the Window class or styles here by modifying
	//  the CREATESTRUCT cs

	return CView::PreCreateWindow(cs);
}

// CSerialTerminalView drawing
void CSerialTerminalView::DrawLine(CDC* pDC, SDocData *lineInfo, int xpos, int ypos){
	
	int promptpos;
	if(m_displayTimestamps){
		xpos += DrawText(pDC, lineInfo->timestamp, &m_timestampColor, xpos, ypos);
	}
	
	promptpos= lineInfo->line.Find(m_promptStr);
	if(promptpos == -1){
		DrawText(pDC,lineInfo->line, NULL, xpos, ypos);
	}
	else{
		//have a prompt somewhere in the line
		//get what might be to the left
		CString temp;
		temp = lineInfo->line.Left(promptpos);
		xpos += DrawText(pDC,temp, NULL, xpos, ypos);
		temp = lineInfo->line.Mid(promptpos, m_promptStr.GetLength()+1);
		xpos += DrawText(pDC,temp, &m_promptColor, xpos, ypos);
		temp = lineInfo->line.Right(lineInfo->line.GetLength() - promptpos - m_promptStr.GetLength()-1);
		xpos += DrawText(pDC,temp, NULL, xpos, ypos);
	}
}


int CSerialTerminalView::DrawText(CDC* pDC, CString &text, COLORREF *pCR, int xpos, int ypos){
	COLORREF oldcr;
	CSize textExtent;

	if(pCR != NULL){
		oldcr = pDC->SetTextColor(*pCR);
	}
	pDC->TextOut(xpos, ypos, text);
	textExtent = pDC->GetTextExtent(text);
	if(pCR != NULL){
		pDC->SetTextColor(oldcr);
	}
	return textExtent.cx;
}

void CSerialTerminalView::OnDraw(CDC* pDC)
{
	CRect clientRect;
	int maxLines, lineHeight, i=0;
	TEXTMETRIC tm;
	
	CSerialTerminalDoc* pDoc = GetDocument();
	if (!pDoc){
		return;	
	}
	ASSERT_VALID(pDoc);
	
	
	GetClientRect(clientRect);
	pDC->GetTextMetrics(&tm);
	CFont *oldFont = pDC->SelectObject(&m_font);	
	
	lineHeight = tm.tmHeight + tm.tmExternalLeading;
	maxLines = clientRect.Height()/lineHeight;

	if(pDoc->m_docData.GetCount() > maxLines){
		//we have more data than we can paint...
		//start drawing from where the scroll bar says to

		SCROLLINFO si;
		GetScrollInfo(SB_VERT, &si, SIF_ALL);
		POSITION pos = pDoc->m_docData.GetTailPosition();
		for(i=0; i<si.nMax-si.nPos; i++){
			pDoc->m_docData.GetPrev(pos);
		}
		for(i=0; (i<maxLines) && (pos != NULL); i++){
			SDocData *currentItem = pDoc->m_docData.GetNext(pos);
			DrawLine(pDC, currentItem, 0, i*lineHeight);
		}
	}
	else{
		POSITION pos = pDoc->m_docData.GetHeadPosition();
		while(pos != NULL){
			SDocData *currentItem = pDoc->m_docData.GetNext(pos);
			DrawLine(pDC, currentItem, 0, i*lineHeight);
			i++;
		}
	}
	pDC->SelectObject(oldFont);
}


// CSerialTerminalView printing

BOOL CSerialTerminalView::OnPreparePrinting(CPrintInfo* pInfo)
{
	// default preparation
	return DoPreparePrinting(pInfo);
}

void CSerialTerminalView::OnBeginPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/)
{
	// TODO: add extra initialization before printing
}

void CSerialTerminalView::OnEndPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/)
{
	// TODO: add cleanup after printing
}


// CSerialTerminalView diagnostics

#ifdef _DEBUG
void CSerialTerminalView::AssertValid() const
{
	CView::AssertValid();
}

void CSerialTerminalView::Dump(CDumpContext& dc) const
{
	CView::Dump(dc);
}

CSerialTerminalDoc* CSerialTerminalView::GetDocument() const // non-debug version is inline
{
	ASSERT(m_pDocument->IsKindOf(RUNTIME_CLASS(CSerialTerminalDoc)));
	return (CSerialTerminalDoc*)m_pDocument;
}
#endif //_DEBUG


// CSerialTerminalView message handlers

void CSerialTerminalView::OnInitialUpdate()
{
	CView::OnInitialUpdate();

	//we want to override the default font with something nice
	SetFont(&m_font);

	CMainFrame *pMainFrame= (CMainFrame *)AfxGetApp()->m_pMainWnd;
	CDialogBar *pDialogBar = &(pMainFrame->m_mainDialogBar);
	CButton *checkBox = (CButton *)pDialogBar->GetDlgItem(IDC_CHECK_TIMESTAMPING);

	checkBox->SetCheck(BST_CHECKED);

//	SetTimer(100, 1000, NULL);
	EnableScrollBarCtrl(SB_VERT);

	SCROLLINFO si;
	si.cbSize = sizeof(si);
	si.fMask  = SIF_PAGE | SIF_RANGE | SIF_POS | SIF_DISABLENOSCROLL;
	si.nPage = 0;
	si.nMin = 0;
	si.nMax = 0;
	si.nPos = 0;
	SetScrollInfo(SB_VERT,&si, TRUE);
}

int CSerialTerminalView::OnCreate(LPCREATESTRUCT lpCreateStruct)
{
	if (CView::OnCreate(lpCreateStruct) == -1)
		return -1;

	CRect rect;
	GetClientRect(rect);
	TRACE("Initial size of the Edit Ctrl is %d %d %d %d\n",rect.top, rect.left, rect.bottom, rect.right);

	return 0;
}

void CSerialTerminalView::OnSize(UINT nType, int cx, int cy)
{
	CView::OnSize(nType, cx, cy);
	CRect rect;
	CClientDC dc(this);
	int maxLines;
	TEXTMETRIC tm;
	SCROLLINFO si;

	CSerialTerminalDoc* pDoc = GetDocument();
	if (!pDoc){
		return;	
	}
	ASSERT_VALID(pDoc);



	//get the total size of our client area
	GetClientRect(rect);
	//get our textmetrics so that we can figure out the total lines
	dc.GetTextMetrics(&tm);
	maxLines = rect.Height()/(tm.tmHeight + tm.tmExternalLeading);

	if(pDoc->m_docData.GetSize() > maxLines){
		EnableScrollBarCtrl(SB_VERT, TRUE);
		si.fMask  = SIF_POS | SIF_RANGE | SIF_DISABLENOSCROLL;
		si.nMin = 0;
		si.nMax = (int)pDoc->m_docData.GetSize()-1;
		si.nPos = (int)pDoc->m_docData.GetSize()-1;
		SetScrollInfo(SB_VERT,&si, TRUE);
	}
	else{
		EnableScrollBarCtrl(SB_VERT, FALSE);
	}

	si.cbSize = sizeof(si);
	si.fMask  = SIF_PAGE | SIF_DISABLENOSCROLL;
	si.nPage = maxLines;
	SetScrollInfo(SB_VERT,&si, TRUE);


	TRACE("Window Resized to %d %d %d %d\n",rect.top, rect.left, rect.bottom, rect.right);
	//m_TerminalEditCtrl.SetWindowPos(&CWnd::wndTop,rect.left,rect.top,rect.Width(),rect.Height(), SWP_SHOWWINDOW);
	//m_TerminalEditCtrl.SetFocus();
}

afx_msg LRESULT CSerialTerminalView::OnReceiveSerialData(WPARAM numBytes, LPARAM pBuffer)
{
	
	//CMainFrame *pMainFrame= (CMainFrame *)AfxGetApp()->m_pMainWnd;
	//CDialogBar *pDialogBar = &(pMainFrame->m_mainDialogBar);
	//CButton *checkBox = (CButton *)pDialogBar->GetDlgItem(IDC_CHECK_TIMESTAMPING);
	DWORD length = (DWORD)numBytes;
	char *buffer = (char *)pBuffer;
	
	CString text(buffer);
 	
	//remove \r's from the buffer if they exist
 	text.Remove('\r');
	
//	GetDocument()->AppendText(text, checkBox->GetCheck() == BST_CHECKED);
	GetDocument()->AppendText(text);
	
	delete buffer;
	return 1;
}

void CSerialTerminalView::ScrollView(int TotalLinesInDoc){
	CClientDC dc(this);
	CRect clientRect;
	int maxLines;
	TEXTMETRIC tm;
	SCROLLINFO si;
	
	//get the total size of our client area
	GetClientRect(clientRect);
	dc.GetTextMetrics(&tm);
	maxLines = clientRect.Height()/(tm.tmHeight + tm.tmExternalLeading);


	if(TotalLinesInDoc > maxLines){
		EnableScrollBarCtrl(SB_VERT, TRUE);
		si.cbSize = sizeof(si);
		si.fMask  = SIF_POS | SIF_RANGE | SIF_DISABLENOSCROLL;
		si.nMin = 0;
		si.nMax = TotalLinesInDoc-1;
		si.nPos = TotalLinesInDoc-1;
		SetScrollInfo(SB_VERT,&si, TRUE);
	}
	else{
		EnableScrollBarCtrl(SB_VERT, FALSE);
	}
}


void CSerialTerminalView::OnTimer(UINT_PTR nIDEvent)
{
#if 1
	static int count = 0;
	
	WORD actualBytesRead = 500;
	char *buffer = new char[actualBytesRead];
    
    sprintf_s(buffer, actualBytesRead,"Total space allocated from system = \t%10u\r\nNumber of non-inuse chunks = \t\t%10u\r\nNumber of MMAPPED regions = \t\t%10u\r\nTotal space in MMAPPED regions = \t%10u\r\n",1234,5678, 91011,1234);
	
	actualBytesRead = strlen(buffer);

	this->PostMessage(WM_RECEIVE_SERIAL_DATA, (WPARAM)actualBytesRead, (LPARAM)buffer);
	CView::OnTimer(nIDEvent);

	count++;
	if(count > 10){
//		KillTimer(nIDEvent);
	}
#else
	//hack
	OnBnClickedButtonClear();
#endif
}


void CSerialTerminalView::OnBnClickedButtonClear()
{
#if 0
	m_TerminalEditCtrl.SetSel(0, -1);
	m_TerminalEditCtrl.Clear();
	m_TerminalEditCtrl.SetSel(0,-1);
	CHARFORMAT cf;
	cf.cbSize = sizeof(CHARFORMAT);
	cf.crTextColor = RGB(0,0,0);
	cf.dwMask = CFM_COLOR;
	cf.dwEffects = 0;
	m_TerminalEditCtrl.SetSelectionCharFormat(cf);
	m_TerminalEditCtrl.SetSel(-1,-1);
#endif
}

void CSerialTerminalView::OnSetFocus(CWnd* pOldWnd)
{
	//CView::OnSetFocus(pOldWnd);

	//m_TerminalEditCtrl.SetFocus();
}

void CSerialTerminalView::OnVScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar)
{
	// TODO: Add your message handler code here and/or call default
	SCROLLINFO si;
	GetScrollInfo(SB_VERT, &si, SIF_ALL);
	switch(nSBCode){
		case SB_BOTTOM:
			SetScrollPos(SB_VERT,si.nMax);
			break;
		case SB_LINEDOWN:
			SetScrollPos(SB_VERT,si.nPos+1);	
			break;
		case SB_LINEUP:
			SetScrollPos(SB_VERT,si.nPos-1);
			break;
		case SB_PAGEDOWN:
			SetScrollPos(SB_VERT,si.nPos+si.nPage);
			break;
		case SB_PAGEUP:
			SetScrollPos(SB_VERT,si.nPos-si.nPage);
			break;
		case SB_THUMBPOSITION:
			SetScrollPos(SB_VERT,nPos);
			break;
		case SB_THUMBTRACK:
			SetScrollPos(SB_VERT,nPos);
			break;
		case SB_TOP:
			SetScrollPos(SB_VERT,0);
			break;
		default:
			//unknown code
			return;
	}
	Invalidate();
	return;
}

void CSerialTerminalView::OnChar(UINT nChar, UINT nRepCnt, UINT nFlags)
{
	CSerialTerminalDoc *pDoc = GetDocument();
	if(pDoc == NULL){
		return;
	}
	ASSERT_VALID(pDoc);

	TRACE("OnChar %d %d %d\n",nChar, nRepCnt, nFlags);
	switch(nChar){
		case VK_RETURN:
			pDoc->AddChar('\r');
		break;
		case VK_BACK:
			pDoc->AddChar('\b');
		break;
		default:
			pDoc->AddChar(nChar);
	}
}

void CSerialTerminalView::OnBnClickedCheckTimestamping()
{
	CMainFrame *pMainFrame= (CMainFrame *)AfxGetApp()->m_pMainWnd;
	CDialogBar *pDialogBar = &(pMainFrame->m_mainDialogBar);
	CButton *checkBox = (CButton *)pDialogBar->GetDlgItem(IDC_CHECK_TIMESTAMPING);
	m_displayTimestamps = checkBox->GetCheck();
	Invalidate();
}
