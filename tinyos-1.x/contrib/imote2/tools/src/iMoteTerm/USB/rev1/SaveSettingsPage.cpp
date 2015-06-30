// SaveSettingsPage.cpp : implementation file
//

#include "stdafx.h"
#include "iMoteConsole.h"
#include "SaveSettingsPage.h"


// CSaveSettingsPage dialog

IMPLEMENT_DYNAMIC(CSaveSettingsPage, CPropertyPage)
CSaveSettingsPage::CSaveSettingsPage(CWnd* pParent /*=NULL*/)
	: CPropertyPage(CSaveSettingsPage::IDD)
{
}

CSaveSettingsPage::~CSaveSettingsPage()
{
}

void CSaveSettingsPage::DoDataExchange(CDataExchange* pDX)
{
	CPropertyPage::DoDataExchange(pDX);
}


BEGIN_MESSAGE_MAP(CSaveSettingsPage, CPropertyPage)
END_MESSAGE_MAP()


// CSaveSettingsPage message handlers
