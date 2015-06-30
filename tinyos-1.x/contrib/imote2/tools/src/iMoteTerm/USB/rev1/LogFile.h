#pragma once


// CLogFile document

class CLogFile : public CDocument
{
	DECLARE_DYNCREATE(CLogFile)

public:
	CLogFile();
	virtual ~CLogFile();
	virtual void Serialize(CArchive& ar);   // overridden for document i/o
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif
	void setBuffer(CString * buffer);
private:
	CString *m_pBuffer;
protected:
	virtual BOOL OnNewDocument();

	DECLARE_MESSAGE_MAP()
};
