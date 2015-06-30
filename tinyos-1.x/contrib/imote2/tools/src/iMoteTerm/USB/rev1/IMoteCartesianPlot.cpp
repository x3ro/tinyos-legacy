// IMoteCartesianPlot.cpp : implementation file
//

#include "stdafx.h"
#include "iMoteConsole.h"
#include "IMoteCartesianPlot.h"
#include ".\imotecartesianplot.h"
#include "PlotInfo.h"
#include "IMoteConsoleDlg.h"
#include "MappingFunctionDlg.h"

// CIMoteCartesianPlot

IMPLEMENT_DYNAMIC(CIMoteCartesianPlot, CWnd)
CIMoteCartesianPlot::CIMoteCartesianPlot(CPlotInfo *plotinfo,UINT ChannelID,UINT iMoteID) 
	: m_iMoteID(iMoteID),m_ChannelID(ChannelID),m_plotinfo(plotinfo)
{
	ZoomSettings[0]=.5;
	ZoomSettings[1]=.75;
	ZoomSettings[2]=1.0;
	ZoomSettings[3]=1.5;
	ZoomSettings[4]=2.0;
	ZoomIndex=2;

	m_MappingMinRange=0;
	m_MappingMaxRange=65535;
	
	LoadAccelTable(MAKEINTRESOURCE(IDR_ACCELERATOR_CARTESIAN));
}

CIMoteCartesianPlot::~CIMoteCartesianPlot()
{
}


BEGIN_MESSAGE_MAP(CIMoteCartesianPlot, CWnd)
	ON_WM_PAINT()
	ON_WM_ERASEBKGND()
	ON_WM_CREATE()
	ON_WM_DESTROY()
	ON_WM_TIMER()
	ON_COMMAND(ID_EDIT_SETMAPPINGFUNCTION, OnEditSetmappingfunction)
	ON_WM_CLOSE()
END_MESSAGE_MAP()



// CIMoteCartesianPlot message handlers


//BOOL CIMoteCartesianPlot::Create(LPCTSTR lpszClassName, LPCTSTR lpszWindowName, DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID, CCreateContext* pContext)
//{
//	// TODO: Add your specialized code here and/or call the base class
//
//	return CWnd::Create(lpszClassName, lpszWindowName, dwStyle, rect, pParentWnd, nID, pContext);
//}

void CIMoteCartesianPlot::OnPaint()
{
	CPaintDC dc(this); // device context for painting
	PrepareDC(&dc);
	DrawCartesian(&dc);
}

BOOL CIMoteCartesianPlot::OnEraseBkgnd(CDC* pDC)
{
	//TRACE("Erasing Background\n");
	PrepareDC(pDC);
	DrawCartesian(pDC,true);
	return TRUE;
}

void CIMoteCartesianPlot::PrepareDC(CDC *pDC)
{
	CRect rect;
	GetClientRect(&rect);
	pDC->SetMapMode(MM_ANISOTROPIC);
	pDC->SetWindowExt((int)(NUMPOINTS*ZoomSettings[ZoomIndex]),(int)(-MAXVAL*ZoomSettings[ZoomIndex]));
	pDC->SetViewportExt(rect.Width(),rect.Height());
	pDC->SetViewportOrg(rect.Width()/2,rect.Height()/2);
}
void CIMoteCartesianPlot::DrawBackground(CDC *pDC)
{
	CRect rect,rect_orig;
	CString str;
	TEXTMETRIC tm;

	GetClientRect(&rect);
	pDC->DPtoLP(&rect);
	rect_orig=rect;

	//fill the grey background
	pDC->FillSolidRect(rect, GetSysColor(COLOR_3DFACE));
	
	//deflate the rectangle and draw everything else
	rect.DeflateRect(1*rect.Width()/15, 1*rect.Height()/15);
	pDC->FillSolidRect(rect, pDC->GetBkColor());
	pDC->Rectangle(rect);

	//change the current pen to be a dashed blue pen
	CPen pen(PS_DASH,0,RGB(0,0,255));
	CPen *pOldPen = pDC->SelectObject(&pen);

	//draw the cross hairs...start at the middle so that we eliminate the weird scaling effect
	pDC->MoveTo(0,0);
	pDC->LineTo(rect.left,0);
	pDC->MoveTo(0, 0);
	pDC->LineTo(rect.right,0);

	pDC->MoveTo(0,0);
	pDC->LineTo(0,rect.top);
	pDC->MoveTo(0,0);
	pDC->LineTo(0,rect.bottom);

	//return the original pen to DC
	pDC->SelectObject(pOldPen);

	//add the labels
	CFont newFont;
	DWORD oldAlignment=pDC->SetTextAlign(TA_RIGHT);
	newFont.CreatePointFont(9000,"Arial");
	CFont *pOldFont=pDC->SelectObject(&newFont);
	pDC->GetTextMetrics(&tm);
	str.Format("%d",m_MappingMaxRange);
	pDC->TextOut(rect.left-(tm.tmAveCharWidth*5/4),rect.top+(tm.tmHeight/2),str);

	str.Format("%d",m_MappingMinRange);
	pDC->TextOut(rect.left-(tm.tmAveCharWidth*5/4),rect.bottom+(tm.tmHeight/2),str);

	str.Format("%d",(m_MappingMaxRange+m_MappingMinRange)/2);
	pDC->TextOut(rect.left-(tm.tmAveCharWidth*5/4),tm.tmHeight/2,str);
	pDC->SelectObject(pOldFont);
	pDC->SetTextAlign(oldAlignment);
}

void CIMoteCartesianPlot::DrawCartesian(CDC* pDC,bool bRedrawAll)
{	
	int pointcount, totalpoints;
	//CiMoteConsoleDoc *pDoc = GetDocument();

	//get the dimensions of the client space in logical units
	CRect rect,clipRect;
	GetClientRect(&rect);
	pDC->DPtoLP(&rect);
	pDC->GetClipBox(&clipRect);
	
#if 0
	if(clipRect!=rect && !bRedrawAll)
	{
		//for now, we only want to redraw if we're repainting the entire screen...this is a hack!!!
		return;
	}
#endif

	rect.DeflateRect(1*rect.Width()/15, 1*rect.Height()/15);
	pointcount =  m_plotinfo->pointcount;
	//basic idea:  keep track of the last location that we drew up to, and draw all
	// of the new points added since then.  If we wrap, draw up to the current location
	
	if(pointcount<m_LastDrawIndex || bRedrawAll)
	{
		DrawBackground(pDC);
		m_LastDrawIndex = 0;
	}
	totalpoints = pointcount - m_LastDrawIndex;
	if(totalpoints!=0)
	{
		//TRACE("drawing %d points, index =%d\n", totalpoints,m_LastDrawIndex);
	}
	else
	{
		//don't have anything to draw, so don't waste the time
		return;
	}
//because we're drawing in segments, we need to make sure that we draw the connecting segment)
#define REDRAWLEN 1
	POINT *cartesianXpoints = new POINT[(m_LastDrawIndex==0)?totalpoints:totalpoints+REDRAWLEN];
	POINT *cartesianYpoints = new POINT[(m_LastDrawIndex==0)?totalpoints:totalpoints+REDRAWLEN];
	POINT *cartesianZpoints = new POINT[(m_LastDrawIndex==0)?totalpoints:totalpoints+REDRAWLEN];

	int i, j;
	for(j=0,i= ((m_LastDrawIndex-REDRAWLEN< 0) ? 0:m_LastDrawIndex-REDRAWLEN);i< totalpoints+m_LastDrawIndex; i++,j++)
	{
		//compute for X
		if(m_plotinfo->validmask & X_VALID)
		{
			cartesianXpoints[j].x = ((i*rect.Width()/NUMPOINTS) - rect.Width()/2);
			cartesianXpoints[j].y = -(m_plotinfo->x[i])*rect.Height()/65536;
		}
		//compute for Y
		if(m_plotinfo->validmask & Y_VALID)
		{
			cartesianYpoints[j].x = ((i*rect.Width()/NUMPOINTS) - rect.Width()/2);
			cartesianYpoints[j].y = -(m_plotinfo->y[i])*rect.Height()/65536;
		}
		if(m_plotinfo->validmask & Z_VALID)
		{
			cartesianZpoints[j].x = ((i*rect.Width()/NUMPOINTS) - rect.Width()/2);
			cartesianZpoints[j].y = -(m_plotinfo->z[i])*rect.Height()/65536;
		}
		//TRACE("%d %d\n",m_plotinfo->points[i].x,cartesianpoints[j].y);
	}
	m_LastDrawIndex+=totalpoints;
	//change the current pen to a red pen before drawing
	
	//plot x in RED
	if(m_plotinfo->validmask & X_VALID)
	{
		CPen redpen(PS_SOLID,1,RGB(255,0,0));
		CPen *pOldPen = pDC->SelectObject(&redpen);
		pDC->Polyline(cartesianXpoints, j);
			//return the original pen to DC
		pDC->SelectObject(pOldPen);
	}

	//plot y in blue
	if(m_plotinfo->validmask & Y_VALID)
	{
		CPen bluepen(PS_SOLID,1,RGB(0,0,255));
		CPen *pOldPen = pDC->SelectObject(&bluepen);
		pDC->Polyline(cartesianYpoints, j);
			//return the original pen to DC
		pDC->SelectObject(pOldPen);
	}

	//plot z in green
	if(m_plotinfo->validmask & Z_VALID)
	{
		CPen greenpen(PS_SOLID,1,RGB(0,255,0));
		CPen *pOldPen = pDC->SelectObject(&greenpen);
		pDC->Polyline(cartesianZpoints, j);
			//return the original pen to DC
		pDC->SelectObject(pOldPen);
	}

	delete cartesianXpoints;
	delete cartesianYpoints;
	delete cartesianZpoints;

}
int CIMoteCartesianPlot::OnCreate(LPCREATESTRUCT lpCreateStruct)
{
	if (CWnd::OnCreate(lpCreateStruct) == -1)
		return -1;
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
	SetIcon(m_hIcon,TRUE);
	SetIcon(m_hIcon,FALSE);
	
	m_nTimerID = SetTimer(1,10,0);

	return 0;
}

void CIMoteCartesianPlot::OnDestroy()
{
	CFrameWnd::OnDestroy();
	KillTimer(m_nTimerID);
}

void CIMoteCartesianPlot::OnTimer(UINT nIDEvent)
{
	CRect rect;
	CClientDC dc(this);
	GetClientRect(&rect);
	dc.DPtoLP(&rect);
	InvalidateRect(&rect,FALSE);
	CFrameWnd::OnTimer(nIDEvent);
}

void CIMoteCartesianPlot::SetMappingFunction(int MinRange, int MaxRange)
{
	m_MappingMinRange=MinRange;
	m_MappingMaxRange=MaxRange;
	InvalidateRect(NULL);
}

void CIMoteCartesianPlot::OnEditSetmappingfunction()
{
	CMappingFunctionDlg dlg;
	dlg.m_EditMaxRangeValue=m_MappingMaxRange;
	dlg.m_EditMinRangeValue=m_MappingMinRange;
	if(dlg.DoModal()==IDOK)
	{
		SetMappingFunction(dlg.m_EditMinRangeValue,dlg.m_EditMaxRangeValue);
	}

}

void CIMoteCartesianPlot::OnClose()
{
	// TODO: Add your message handler code here and/or call default

	//CFrameWnd::OnClose();
}
