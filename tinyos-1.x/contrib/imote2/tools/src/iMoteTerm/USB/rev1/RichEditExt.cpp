// RichEditExt.cpp : implementation file
//

#include "stdafx.h"
#include "iMoteConsole.h"
#include "RichEditExt.h"
#include ".\richeditext.h"
#include "IMoteConsoleDlg.h"


// CRichEditExt

IMPLEMENT_DYNAMIC(CRichEditExt, CRichEditCtrl)
CRichEditExt::CRichEditExt()
{
	m_bEcho = false;
	m_bInit = false;
	m_bDMaxChar = false;
}

CRichEditExt::~CRichEditExt()
{
}


BEGIN_MESSAGE_MAP(CRichEditExt, CRichEditCtrl)
	ON_WM_CHAR()
	ON_WM_SIZE()
	ON_WM_MOUSEWHEEL()
	ON_WM_KEYDOWN()
	ON_WM_VSCROLL()
	ON_WM_CREATE()
END_MESSAGE_MAP()


bool CRichEditExt::dEcho(){
	m_bEcho = !m_bEcho;
	return m_bEcho;
}
bool CRichEditExt::getEcho(){
	return m_bEcho;
}

void CRichEditExt::SetParent(CWnd *parent)
{
	m_parent=parent;
}

int CRichEditExt::MaxLineCount(){
	if(!m_bInit){
		m_bInit = true;
		ExtraInit();
	}
	return m_maxLines;
}

bool CRichEditExt::MaxCharCountChange(){
	if(!m_bInit){
		m_bInit = true;
		ExtraInit();
	}
	if(m_bDMaxChar){
		m_bDMaxChar = false;
		return true;
	}
	return false;
}

int CRichEditExt::MaxCharCount(){
	if(!m_bInit){
		m_bInit = true;
		ExtraInit();
	}
	return m_maxChars;
}

void CRichEditExt::ExtraInit(){
	
	CFont courier;
	CFont *original_font;

	courier.CreatePointFont(100, "Courier", NULL);
	SetFont(&courier);
	CDC *pdc = GetDC();	
	original_font = pdc->SelectObject(&courier);

	TEXTMETRIC tm;
	pdc->GetTextMetrics(&tm);
	CRect rect;
	GetClientRect(&rect);
	m_maxLines = rect.Height() / tm.tmHeight - 1;
	m_bDMaxChar = (m_maxChars != rect.Width() / tm.tmMaxCharWidth);
	m_maxChars = rect.Width() / tm.tmMaxCharWidth;
	//TRACE("width %d %d %d %d\r\n", rect.Width(), tm.tmMaxCharWidth, tm.tmAveCharWidth, m_maxChars);
	//TRACE("fixed pitch? %d\r\n", tm.tmPitchAndFamily & TMPF_FIXED_PITCH);
	pdc->SelectObject(original_font);
	ReleaseDC(pdc);
}

void CRichEditExt::OnChar(UINT nChar, UINT nRepCnt, UINT nFlags)
{
	if(m_bEcho)
		((CIMoteTerminal *)m_parent)->BufferAppend(nChar, true);
	BYTE * temp = (BYTE *)malloc(1);
	temp[0] = nChar;
	((CIMoteTerminal *)m_parent)->SendData(temp,1,IMOTE_HID_TYPE_CL_BLUSH);
	free(temp);
	((CIMoteTerminal *)m_parent)->ScrollToBottom();
	((CIMoteTerminal *)m_parent)->UpdateText();

	//TRACE("Char %x\r\n", nChar);
	//CRichEditCtrl::OnChar(nChar, nRepCnt, nFlags);
}
#include "winuser.h"
void CRichEditExt::OnSize(UINT nType, int cx, int cy)
{
	m_bInit = false;
//`	rect.TopLeft().x, rect.TopLeft().y + 200, rect.Width(), rect.Height() - 500
	CRichEditCtrl::OnSize(nType, cx, cy);
}
BOOL CRichEditExt::OnMouseWheel(UINT nFlags, short zDelta, CPoint pt)
{
	int temp = (zDelta<0?-zDelta:zDelta)/120;
	for(; temp > 0; temp--){
		if(((CIMoteTerminal *)m_parent)->Scroll(zDelta>0))
			((CIMoteTerminal *)m_parent)->UpdateText();
	}
	//TRACE("DIRECTION %d \r\n", zDelta);
	return CRichEditCtrl::OnMouseWheel(nFlags, zDelta, pt);
}

void CRichEditExt::OnKeyDown(UINT nChar, UINT nRepCnt, UINT nFlags){
	switch(nChar){
		case VK_UP: 
			if(((CIMoteTerminal *)m_parent)->Scroll(true))
				((CIMoteTerminal *)m_parent)->UpdateText();
			break; 
		case VK_DOWN:
			if(((CIMoteTerminal *)m_parent)->Scroll(false))
				((CIMoteTerminal *)m_parent)->UpdateText();
			break;
		/*case VK_LEFT:
			((CIMoteTerminal *)m_parent)->HScroll(true);
			break;
		case VK_RIGHT: 
			((CIMoteTerminal *)m_parent)->HScroll(false);
			break; */
		case VK_END: 
			((CIMoteTerminal *)m_parent)->ScrollToBottom();
			((CIMoteTerminal *)m_parent)->UpdateText();
			break; 
		case VK_HOME:
			((CIMoteTerminal *)m_parent)->ScrollToTop();
			((CIMoteTerminal *)m_parent)->UpdateText();
			break; 
		case VK_PRIOR:
			bool temp;
			for(int i = 0; i < MaxLineCount(); i++)
				temp = (((CIMoteTerminal *)m_parent)->Scroll(true) || temp?true:false);
			if(temp)
				((CIMoteTerminal *)m_parent)->UpdateText();
			break;
		case VK_NEXT:
			for(int i = 0; i < MaxLineCount(); i++)
				temp = (((CIMoteTerminal *)m_parent)->Scroll(false) || temp?true:false);
			if(temp)
				((CIMoteTerminal *)m_parent)->UpdateText();
			break;
	}
	//CRichEditCtrl::OnKeyDown(nChar, nRepCnt, nFlags);
}

void CRichEditExt::OnVScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar){
	switch(nSBCode){
		case SB_BOTTOM:
			((CIMoteTerminal *)m_parent)->ScrollToBottom();
			((CIMoteTerminal *)m_parent)->UpdateText();
			break; 
		case SB_LINEDOWN:
			if(((CIMoteTerminal *)m_parent)->Scroll(false))
				((CIMoteTerminal *)m_parent)->UpdateText();
			break;
		case SB_LINEUP:
			if(((CIMoteTerminal *)m_parent)->Scroll(true))
				((CIMoteTerminal *)m_parent)->UpdateText();
			break; 
		case SB_PAGEDOWN:
			bool temp;
			for(int i = 0; i < MaxLineCount(); i++)
				temp = (((CIMoteTerminal *)m_parent)->Scroll(false) || temp?true:false);
			if(temp)
				((CIMoteTerminal *)m_parent)->UpdateText();
			break;
		case SB_PAGEUP:
			for(int i = 0; i < MaxLineCount(); i++)
				temp = (((CIMoteTerminal *)m_parent)->Scroll(true) || temp?true:false);
			if(temp)
				((CIMoteTerminal *)m_parent)->UpdateText();
			break;
		case SB_TOP:
			((CIMoteTerminal *)m_parent)->ScrollToTop();
			((CIMoteTerminal *)m_parent)->UpdateText();
			break;
	}

	//CRichEditCtrl::OnVScroll(nSBCode, nPos, pScrollBar);
}

int CRichEditExt::OnCreate(LPCREATESTRUCT lpCreateStruct)
{
	if (CRichEditCtrl::OnCreate(lpCreateStruct) == -1)
		return -1;

	ShowScrollBar(SB_VERT, 1);

	return 0;
}

