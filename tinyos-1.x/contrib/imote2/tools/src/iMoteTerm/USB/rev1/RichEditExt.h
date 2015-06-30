#pragma once
//#define OUTPUTLINECOUNT 12

// CRichEditExt

class CRichEditExt : public CRichEditCtrl
{
	DECLARE_DYNAMIC(CRichEditExt)

public:
	CRichEditExt();
	virtual ~CRichEditExt();

protected:
	DECLARE_MESSAGE_MAP()
private:
	bool m_bEcho;
	CWnd *m_parent;
	int m_maxLines;
	int m_maxChars;
	bool m_bInit;
	bool m_bDMaxChar;
public:
	bool dEcho();
	bool getEcho();
	void SetParent(CWnd *parent);
	bool MaxCharCountChange();
	void ExtraInit();
	int MaxLineCount();
	int MaxCharCount();
	afx_msg void OnChar(UINT nChar, UINT nRepCnt, UINT nFlags);
	afx_msg void OnSize(UINT nType, int cx, int cy);
	afx_msg BOOL OnMouseWheel(UINT nFlags, short zDelta, CPoint pt);
	afx_msg void OnKeyDown(UINT nChar, UINT nRepCnt, UINT nFlags);
	afx_msg void OnVScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar);
	afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct);
};


