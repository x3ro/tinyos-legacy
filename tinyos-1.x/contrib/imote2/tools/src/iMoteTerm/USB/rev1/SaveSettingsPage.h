#pragma once


// CSaveSettingsPage dialog

class CSaveSettingsPage : public CPropertyPage
{
	DECLARE_DYNAMIC(CSaveSettingsPage)

public:
	CSaveSettingsPage(CWnd* pParent = NULL);   // standard constructor
	virtual ~CSaveSettingsPage();

// Dialog Data
	enum { IDD = IDD_PP_SAVESETTINGS };

protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support

	DECLARE_MESSAGE_MAP()
};
