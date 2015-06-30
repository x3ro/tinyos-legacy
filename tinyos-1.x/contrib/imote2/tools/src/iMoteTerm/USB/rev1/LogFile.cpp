// LogFile.cpp : implementation file
//

#include "stdafx.h"
#include "iMoteConsole.h"
#include "LogFile.h"


// CLogFile

IMPLEMENT_DYNCREATE(CLogFile, CDocument)

CLogFile::CLogFile()
{
}

BOOL CLogFile::OnNewDocument()
{
	if (!CDocument::OnNewDocument())
		return FALSE;
	return TRUE;
}

CLogFile::~CLogFile()
{
}

void CLogFile::setBuffer(CString * buffer){
	m_pBuffer = buffer;
}

BEGIN_MESSAGE_MAP(CLogFile, CDocument)
END_MESSAGE_MAP()


// CLogFile diagnostics

#ifdef _DEBUG
void CLogFile::AssertValid() const
{
	CDocument::AssertValid();
}

void CLogFile::Dump(CDumpContext& dc) const
{
	CDocument::Dump(dc);
}
#endif //_DEBUG


// CLogFile serialization

void CLogFile::Serialize(CArchive& ar)
{
	if (ar.IsStoring())
	{
		CString temp = *m_pBuffer;
		temp.Replace("\\\n","");
		ar << temp; // TODO: add storing code here
	}
	else
	{
		// TODO: add loading code here
	}
}


// CLogFile commands
