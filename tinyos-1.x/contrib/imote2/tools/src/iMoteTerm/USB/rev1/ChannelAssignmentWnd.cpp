// ChannelAssignmentWnd.cpp : implementation file
//

#include "stdafx.h"
#include "iMoteConsole.h"
#include "ChannelAssignmentWnd.h"
#include ".\channelassignmentwnd.h"


// CChannelAssignmentWnd

IMPLEMENT_DYNAMIC(CChannelAssignmentWnd, CWnd)
CChannelAssignmentWnd::CChannelAssignmentWnd()
{
}

CChannelAssignmentWnd::~CChannelAssignmentWnd()
{
}


BEGIN_MESSAGE_MAP(CChannelAssignmentWnd, CWnd)
	ON_WM_PAINT()
	ON_WM_CREATE()
END_MESSAGE_MAP()



// CChannelAssignmentWnd message handlers


void CChannelAssignmentWnd::OnPaint()
{
	CPaintDC dc(this); 

}

int CChannelAssignmentWnd::OnCreate(LPCREATESTRUCT lpCreateStruct)
{
	if (CWnd::OnCreate(lpCreateStruct) == -1)
		return -1;

	CRect rect;
	GetClientRect(&rect);
	rect.bottom = rect.top +15;

	m_font.CreateStockObject(DEFAULT_GUI_FONT);
	m_HeaderCtrl.Create(WS_CHILD|WS_VISIBLE|HDS_BUTTONS, rect,this, 2);
	
	m_HeaderCtrl.SetFont(&m_font);
	
	HDITEM  hdi;
	hdi.mask = HDI_TEXT | HDI_WIDTH | HDI_FORMAT;
	hdi.cxy = rect.Width()/3;
	hdi.fmt = HDF_STRING | HDF_CENTER;

	hdi.pszText = "Color";
	m_HeaderCtrl.InsertItem(0, &hdi);
	hdi.pszText = "iMoteID";
	m_HeaderCtrl.InsertItem(1, &hdi);
	hdi.pszText = "Axis";
	m_HeaderCtrl.InsertItem(2, &hdi);
	m_ChannelConfigCtrl.Create(NULL,"test",WS_CHILD|WS_VISIBLE|WS_BORDER,CRect(rect.left,15,rect.right,38),this,3);

	return 0;
}

// CColorCtrl

IMPLEMENT_DYNAMIC(CColorCtrl, CWnd)
CColorCtrl::CColorCtrl()
{
	m_color=RGB(255,0,0);
}

CColorCtrl::~CColorCtrl()
{
}


BEGIN_MESSAGE_MAP(CColorCtrl, CWnd)
	ON_WM_PAINT()
	ON_WM_LBUTTONDBLCLK()
END_MESSAGE_MAP()



// CColorCtrl message handlers


void CColorCtrl::OnPaint()
{
	CPaintDC dc(this); 
	
	CRect rect;
	GetClientRect(&rect);
	dc.FillSolidRect(&rect,m_color);
}

void CColorCtrl::OnLButtonDblClk(UINT nFlags, CPoint point)
{
	CColorDialog dlg;
	if(dlg.DoModal()==IDOK)
	{
		m_color = dlg.m_cc.rgbResult;
		Invalidate();
	}	
	CWnd::OnLButtonDblClk(nFlags, point);
}

// CChannelConfigCtrl

IMPLEMENT_DYNAMIC(CChannelConfigCtrl, CWnd)
CChannelConfigCtrl::CChannelConfigCtrl()
{
}

CChannelConfigCtrl::~CChannelConfigCtrl()
{
}


BEGIN_MESSAGE_MAP(CChannelConfigCtrl, CWnd)
	ON_WM_PAINT()
	ON_WM_CREATE()
END_MESSAGE_MAP()



// CColorCtrl message handlers


void CChannelConfigCtrl::OnPaint()
{
	CPaintDC dc(this); 
}

int CChannelConfigCtrl::OnCreate(LPCREATESTRUCT lpCreateStruct)
{ 
	if (CWnd::OnCreate(lpCreateStruct) == -1)
		return -1;

	CRect rect;
	GetClientRect(&rect);
	m_ColorCtrl.Create(NULL,"test",WS_CHILD|WS_VISIBLE|WS_BORDER,CRect(rect.left,rect.top,rect.Width()/3,rect.bottom),this,3);
	m_EditAddress.Create(WS_CHILD|WS_VISIBLE|ES_NUMBER|ES_RIGHT,CRect(rect.Width()/3,rect.top,2*rect.Width()/3,rect.bottom),this, 4);
	m_ComboChannel.Create(WS_CHILD|WS_VISIBLE|CBS_DROPDOWN,CRect(2*rect.Width()/3,rect.top,rect.Width(),rect.bottom+60),this, 5);
	m_ComboChannel.AddString("x");
	m_ComboChannel.AddString("y");
	m_ComboChannel.AddString("z");
	return 0;
}
