#pragma once

// CIMoteCartesianPlot
#include "PlotInfo.h"
#define MAXVAL (65536)
#define SCALINGFACTOR (2)

class CIMoteCartesianPlot : public CFrameWnd
{
	DECLARE_DYNAMIC(CIMoteCartesianPlot)

public:
	CIMoteCartesianPlot(CPlotInfo *plotinfo,UINT ChannelID,UINT iMoteID);
	virtual ~CIMoteCartesianPlot();

protected:
	DECLARE_MESSAGE_MAP()
	HICON m_hIcon;
public:
//	virtual BOOL Create(LPCTSTR lpszClassName, LPCTSTR lpszWindowName, DWORD dwStyle, const RECT& rect, CWnd* pParentWnd, UINT nID, CCreateContext* pContext = NULL);
	void PrepareDC(CDC *pDC);
	void DrawBackground(CDC *pDC);
	void DrawCartesian(CDC* pDC,bool bRedrawAll=false);

	afx_msg void OnPaint();
	afx_msg BOOL OnEraseBkgnd(CDC* pDC);

	int ZoomIndex;
	double ZoomSettings[5];
	int m_LastDrawIndex;
	afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct);
	void SetMappingFunction(int MinRange, int MaxRange);

	UINT m_nTimerID;
	UINT m_iMoteID;
	UINT m_ChannelID;
	UINT m_DataID;
	int m_MappingMinRange,m_MappingMaxRange;
	CPlotInfo *m_plotinfo;
	afx_msg void OnDestroy();
	afx_msg void OnTimer(UINT nIDEvent);
	afx_msg void OnEditSetmappingfunction();
	afx_msg void OnClose();
};


