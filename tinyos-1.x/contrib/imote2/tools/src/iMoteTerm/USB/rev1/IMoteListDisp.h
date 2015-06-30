#pragma once
#include "plotinfo.h"
#include <afxtempl.h>

// CIMoteListDisp frame

struct SMoteInf{
	CPlotInfo *m_plotinfo;
	UINT m_ChannelID;
	UINT m_iMoteID;
	UINT m_LastDispPoint;
	CString headers[3];
};

class CIMoteListDisp : public CFrameWnd
{
	DECLARE_DYNCREATE(CIMoteListDisp)

	bool AddMote(CPlotInfo *plotinfo,UINT ChannelID,UINT iMoteID,CString header1, CString header2, CString header3); 
	CIMoteListDisp();           // protected constructor used by dynamic creation
	virtual ~CIMoteListDisp();
    bool m_bCreated;
protected:
	DECLARE_MESSAGE_MAP()
	UINT m_nTimerID;
	HICON m_hIcon;
	CPtrArray m_MoteInfArray;
	CListCtrl m_ListCtrl;
public:
	afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct);
	afx_msg void OnDestroy();
	afx_msg void OnClose();
	afx_msg void OnTimer(UINT nIDEvent);
	afx_msg void OnSize(UINT nType, int cx, int cy);
	int UpdateList(void);
};


