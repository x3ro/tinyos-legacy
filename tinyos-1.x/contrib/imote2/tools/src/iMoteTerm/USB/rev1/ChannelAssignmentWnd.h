#pragma once


// CChannelAssignmentWnd
class CColorCtrl: public CWnd
{
	DECLARE_DYNAMIC(CColorCtrl)

public:
	CColorCtrl();
	virtual ~CColorCtrl();
	
	COLORREF m_color;
protected:
	DECLARE_MESSAGE_MAP()
public:
	afx_msg void OnPaint();	
	afx_msg void OnLButtonDblClk(UINT nFlags, CPoint point);
};

// CChannelAssignmentWnd
class CChannelConfigCtrl: public CWnd
{
	DECLARE_DYNAMIC(CChannelConfigCtrl)

public:
	CChannelConfigCtrl();
	virtual ~CChannelConfigCtrl();
	
	CColorCtrl m_ColorCtrl;
	CEdit m_EditAddress;
	CComboBox m_ComboChannel;
protected:
	DECLARE_MESSAGE_MAP()
public:
	afx_msg void OnPaint();	
	afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct);
};

class CChannelAssignmentWnd : public CWnd
{
	DECLARE_DYNAMIC(CChannelAssignmentWnd)

public:
	CChannelAssignmentWnd();
	virtual ~CChannelAssignmentWnd();

protected:
	DECLARE_MESSAGE_MAP()
public:
	afx_msg void OnPaint();

	CHeaderCtrl m_HeaderCtrl;
	CFont m_font;
	afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct);
	CChannelConfigCtrl m_ChannelConfigCtrl;
};



