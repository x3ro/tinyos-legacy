#pragma once


// CDataFormatPage dialog

struct SDataFormatSettings
{
	bool b16BitData, bMagicNumber, bChannelID,bFragmentLength;
	unsigned int MagicNumberSize,ChannelIDSize, FragmentLengthSize;
	unsigned int MagicNumberValue;
};

class CDataFormatPage : public CPropertyPage
{
	DECLARE_DYNAMIC(CDataFormatPage)

public:
	CDataFormatPage(SDataFormatSettings *pSettings,CWnd* pParent = NULL);   // standard constructor
	virtual ~CDataFormatPage();

// Dialog Data
	enum { IDD = IDD_PP_DATAFORMAT };

protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support

	DECLARE_MESSAGE_MAP()
public:
//	afx_msg void OnBnClickedCheck1();
//	afx_msg void OnBnClickedCheck1();
	afx_msg void OnBnClickedCheck16bitdata();
	afx_msg void OnBnClickedCheckChannelid();
	afx_msg void OnBnClickedCheckFragmentlength();
	afx_msg void OnBnClickedCheckMagicnumber();
	virtual BOOL OnInitDialog();
	void LoadSettings(void);
	void SaveSettings(void);

private:
	SDataFormatSettings *m_pSettings;
public:
	virtual BOOL OnApply();
};
