// IMoteListDisp.cpp : implementation file
//

#include "stdafx.h"
#include "iMoteConsole.h"
#include "IMoteListDisp.h"
#include ".\imotelistdisp.h"


// CIMoteListDisp

IMPLEMENT_DYNCREATE(CIMoteListDisp, CFrameWnd)

CIMoteListDisp::CIMoteListDisp() : m_bCreated(false), m_MoteInfArray()
{
}

CIMoteListDisp::~CIMoteListDisp()
{
	for(int i=0;i<m_MoteInfArray.GetCount();i++)
	{
		SMoteInf *pMote = (SMoteInf*)m_MoteInfArray[i];
		delete pMote;
	}
}

bool CIMoteListDisp::AddMote(CPlotInfo *plotinfo,UINT iMoteID,UINT ChannelID, CString headerX,CString headerY,CString headerZ)
{

	//need to add a list box and then in the timer handler, update it with the last x points
	int nNewIndex;
	SMoteInf *pMote= new SMoteInf;
	
	pMote->m_ChannelID=ChannelID;
	pMote->m_iMoteID=iMoteID;
	pMote->m_plotinfo=plotinfo;
	pMote->m_LastDispPoint=0;
	

	if(headerX=="")
	{
		headerX.Format("%#X X",iMoteID);
	}
	if(headerY=="")
	{
		headerY.Format("%#X Y",iMoteID);
	}
	if(headerZ=="")
	{
		headerZ.Format("%#X Z",iMoteID);
	}

	pMote->headers[0]=headerX;
	pMote->headers[1]=headerY;
	pMote->headers[2]=headerZ;
	
	nNewIndex = m_MoteInfArray.Add(pMote);
	//add it to the list ctrl as well if the list ctrl has been created

	//to get the number of columns, use the following piece of code...
	//int nColumnCount = pmyListCtrl->GetHeaderCtrl()->GetItemCount();

	nNewIndex = m_ListCtrl.GetHeaderCtrl()->GetItemCount();
	if(m_ListCtrl.m_hWnd)
	{
		if(plotinfo->validmask & TIMESTAMP_VALID)
		{
			m_ListCtrl.InsertColumn(nNewIndex,"timestamp",LVCFMT_CENTER,60,-1);
			nNewIndex++;
		}
		if(plotinfo->validmask & X_VALID)
		{
			m_ListCtrl.InsertColumn(nNewIndex,headerX,LVCFMT_CENTER,60,-1);
			nNewIndex++;
		}
		if(plotinfo->validmask & Y_VALID)
		{
			m_ListCtrl.InsertColumn(nNewIndex,headerY,LVCFMT_CENTER,60,-1);
			nNewIndex++;
		}
		if(plotinfo->validmask & Z_VALID)
		{
			m_ListCtrl.InsertColumn(nNewIndex,headerZ,LVCFMT_CENTER,60,-1);
			nNewIndex++;
		}
	}
	return true;
}

BEGIN_MESSAGE_MAP(CIMoteListDisp, CFrameWnd)
	ON_WM_CREATE()
	ON_WM_DESTROY()
	ON_WM_CLOSE()
	ON_WM_TIMER()
	ON_WM_SIZE()
END_MESSAGE_MAP()


// CIMoteListDisp message handlers

int CIMoteListDisp::OnCreate(LPCREATESTRUCT lpCreateStruct)
{
	int i;
	if (CFrameWnd::OnCreate(lpCreateStruct) == -1)
		return -1;

	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
	SetIcon(m_hIcon,TRUE);
	SetIcon(m_hIcon,FALSE);
	
	m_nTimerID = SetTimer(1,100,0);
	m_ListCtrl.Create(LVS_REPORT|LVS_NOSORTHEADER|WS_CHILD|WS_VISIBLE,CRect(10,10,400,200),this, 1);
	m_ListCtrl.InsertColumn(0,"index",LVCFMT_LEFT,60,0);
	for(i=0;i<20;i++)
	{
		CString itemText;
		itemText.Format("%d",i);
		m_ListCtrl.InsertItem(i,itemText);
	}

	return 0;
}

void CIMoteListDisp::OnDestroy()
{
	CFrameWnd::OnDestroy();
	KillTimer(m_nTimerID);
}

void CIMoteListDisp::OnClose()
{
	// TODO: Add your message handler code here and/or call default

//	CFrameWnd::OnClose();
}

void CIMoteListDisp::OnTimer(UINT nIDEvent)
{
	UpdateList();
	CFrameWnd::OnTimer(nIDEvent);
}

void CIMoteListDisp::OnSize(UINT nType, int cx, int cy)
{
	CFrameWnd::OnSize(nType, cx, cy);

	CRect rect;
	GetClientRect(&rect);
	m_ListCtrl.MoveWindow(&rect);
}

int CIMoteListDisp::UpdateList(void)
{
	//update the last 20 items in the array...
	int row,column,dispcolumn=0;
	SMoteInf *pMote;
	
	for(column=0;column<m_MoteInfArray.GetCount();column++)
	{
		CString text;
		pMote = ((SMoteInf *)m_MoteInfArray[column]);
		CPlotInfo *plotinfo = pMote->m_plotinfo;
		int index,pointcount = plotinfo->pointcount;

		if(pointcount == pMote->m_LastDispPoint) continue;
		if(plotinfo->validmask & TIMESTAMP_VALID)
		{
			for(row=0;row<20;row++)
			{
				index = pointcount-(1+row);
				if(index<0)
				{
					index = NUMPOINTS-index;
				}
				m_ListCtrl.SetItemText(row,dispcolumn+1,plotinfo->timestamps[index]);
			}
			dispcolumn++;
		}
		if(plotinfo->validmask & X_VALID)
		{
			for(row=0;row<20;row++)
			{
				index = pointcount-(1+row);
				if(index<0)
				{
					index = NUMPOINTS-index;
				}
				text.Format("%d",plotinfo->x[index]);
				m_ListCtrl.SetItemText(row,dispcolumn+1,text);
			}
			dispcolumn++;
		}
		if(plotinfo->validmask & Y_VALID)
		{
			for(row=0;row<20;row++)
			{
				index = pointcount-(1+row);
				if(index<0)
				{
					index = NUMPOINTS-index;
				}
				text.Format("%d",plotinfo->y[index]);
				m_ListCtrl.SetItemText(row,dispcolumn+1,text);
			}
			dispcolumn++;
		}
		if(plotinfo->validmask & Z_VALID)
		{
			for(row=0;row<20;row++)
			{
				index = pointcount-(1+row);
				if(index<0)
				{
					index = NUMPOINTS-index;
				}
				text.Format("%d",plotinfo->z[index]);
				m_ListCtrl.SetItemText(row,dispcolumn+1,text);
			}
			dispcolumn++;
		}

		pMote->m_LastDispPoint=pointcount;
	}
	return 0;
}
