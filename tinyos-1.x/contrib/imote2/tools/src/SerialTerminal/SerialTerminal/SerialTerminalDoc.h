// SerialTerminalDoc.h : interface of the CSerialTerminalDoc class
//
#include "SerialPort.h"
#include <fstream>
#include <afxtempl.h>
#pragma once

using namespace std;

struct SDocData
{
	CString timestamp;
	CString line;
};

class CSerialTerminalDoc : public CDocument
{

protected: // create from serialization only
	CSerialTerminalDoc();
	DECLARE_DYNCREATE(CSerialTerminalDoc)

// Attributes
public:

// Operations
public:

// Overrides
public:
	virtual BOOL OnNewDocument();
	virtual void Serialize(CArchive& ar);

// Implementation
public:
	virtual ~CSerialTerminalDoc();
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

protected:

// Generated message map functions
protected:
	DECLARE_MESSAGE_MAP()
public:
	afx_msg void OnEditOptions();
	CList<SDocData*,SDocData*> m_docData;
private:
	CString m_strPortName;
	CString m_strLogfileName;
	COMMCONFIG m_CommConfig;
	CSerialPort m_port;
	BOOL m_bAutoStart;
	BOOL m_bAppendLog;
	BOOL m_logging;
	CStdioFile logfile;
public:
//	virtual BOOL OnOpenDocument(LPCTSTR lpszPathName);
public:
	virtual void SetPathName(LPCTSTR lpszPathName, BOOL bAddToMRU = TRUE);
public:
	afx_msg void OnBnClickedButtonConnect();
public:
	afx_msg void OnBnClickedButtonLog();
public:
	void ClearDocument();
	virtual void OnCloseDocument();
public:
	int LogText(char *buffer, DWORD numBytes);
	int LogText(CString &text);
public:
	int AddChar(UINT nChar);
	int AppendText(CString &text);
	int InsertNewLastLine(void);
	int AppendToLastLine(CString &line);
	int CommitLastLine();
	int ScrollAllViews();
};


