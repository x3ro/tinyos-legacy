// SerialTerminalView.h : interface of the CSerialTerminalView class
//


#pragma once
#include "afxwin.h"

class CSerialTerminalView : public CView
{
protected: // create from serialization only
	CSerialTerminalView();
	DECLARE_DYNCREATE(CSerialTerminalView)

// Attributes
public:
	CSerialTerminalDoc* GetDocument() const;

// Operations
public:

// Overrides
public:
	void ScrollView(int TotalLinesInDoc);
	virtual void OnDraw(CDC* pDC);  // overridden to draw this view
	virtual BOOL PreCreateWindow(CREATESTRUCT& cs);
protected:
	virtual BOOL OnPreparePrinting(CPrintInfo* pInfo);
	virtual void OnBeginPrinting(CDC* pDC, CPrintInfo* pInfo);
	virtual void OnEndPrinting(CDC* pDC, CPrintInfo* pInfo);
	afx_msg LRESULT OnReceiveSerialData(WPARAM numBytes, LPARAM pBuffer);
	int DrawText(CDC* pDC, CString &text, COLORREF *pCR, int xpos, int ypos);
	void DrawLine(CDC* pDC, SDocData *lineInfo, int xpos, int ypos);

// Implementation
public:
	virtual ~CSerialTerminalView();
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

protected:
	COLORREF m_timestampColor;
	COLORREF m_promptColor;
	CFont m_font;
	BOOL m_displayTimestamps;
	CString m_promptStr;
// Generated message map functions
protected:
	DECLARE_MESSAGE_MAP()
public:
public:
	virtual void OnInitialUpdate();
public:
	afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct);
public:
	afx_msg void OnSize(UINT nType, int cx, int cy);
public:
	afx_msg void OnTimer(UINT_PTR nIDEvent);
public:
//	afx_msg void OnChar(UINT nChar, UINT nRepCnt, UINT nFlags);
	afx_msg void OnBnClickedButtonClear();
	afx_msg void OnSetFocus(CWnd* pOldWnd);
	afx_msg void OnVScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar);
public:
	afx_msg void OnChar(UINT nChar, UINT nRepCnt, UINT nFlags);
public:
	afx_msg void OnBnClickedCheckTimestamping();
};

#ifndef _DEBUG  // debug version in SerialTerminalView.cpp
inline CSerialTerminalDoc* CSerialTerminalView::GetDocument() const
   { return reinterpret_cast<CSerialTerminalDoc*>(m_pDocument); }
#endif

