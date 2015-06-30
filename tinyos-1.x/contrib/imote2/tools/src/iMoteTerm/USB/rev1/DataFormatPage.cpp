// DataFormatPage.cpp : implementation file
//

#include "stdafx.h"
#include "iMoteConsole.h"
#include "DataFormatPage.h"
#include ".\dataformatpage.h"


// CDataFormatPage dialog

IMPLEMENT_DYNAMIC(CDataFormatPage, CPropertyPage)
CDataFormatPage::CDataFormatPage(SDataFormatSettings *pSettings, CWnd* pParent /*=NULL*/)
	: CPropertyPage(CDataFormatPage::IDD), m_pSettings(pSettings)
{
}

CDataFormatPage::~CDataFormatPage()
{
}

void CDataFormatPage::DoDataExchange(CDataExchange* pDX)
{
	CPropertyPage::DoDataExchange(pDX);
}


BEGIN_MESSAGE_MAP(CDataFormatPage, CPropertyPage)
//	ON_BN_CLICKED(IDC_CHECK1, OnBnClickedCheck1)
//ON_BN_CLICKED(IDC_CHECK1, OnBnClickedCheck1)
ON_BN_CLICKED(IDC_CHECK_16BITDATA, OnBnClickedCheck16bitdata)
ON_BN_CLICKED(IDC_CHECK_CHANNELID, OnBnClickedCheckChannelid)
ON_BN_CLICKED(IDC_CHECK_FRAGMENTLENGTH, OnBnClickedCheckFragmentlength)
ON_BN_CLICKED(IDC_CHECK_MAGICNUMBER, OnBnClickedCheckMagicnumber)
END_MESSAGE_MAP()


// CDataFormatPage message handlers

//void CDataFormatPage::OnBnClickedCheck1()
//{
//	// TODO: Add your control notification handler code here
//}

//void CDataFormatPage::OnBnClickedCheck1()
//{
//	// TODO: Add your control notification handler code here
//}

void CDataFormatPage::OnBnClickedCheck16bitdata()
{
	if(IsDlgButtonChecked(IDC_CHECK_16BITDATA))
	{
		//CComboBox pBox = GetDlgItem(IDC_COMBO_16BITDATA)
	}
	else
	{

	}
}

void CDataFormatPage::OnBnClickedCheckChannelid()
{
	CComboBox *pBox = (CComboBox *)GetDlgItem(IDC_COMBO_CHANNELID);
	if(IsDlgButtonChecked(IDC_CHECK_CHANNELID))
	{
		pBox->EnableWindow(TRUE);
	}
	else
	{
		pBox->EnableWindow(FALSE);
	}
}

void CDataFormatPage::OnBnClickedCheckFragmentlength()
{
	CComboBox *pBox = (CComboBox *)GetDlgItem(IDC_COMBO_FRAGMENTLENGTH);
	if(IsDlgButtonChecked(IDC_CHECK_FRAGMENTLENGTH))
	{
		pBox->EnableWindow(TRUE);
	}
	else
	{
		pBox->EnableWindow(FALSE);
	}
}

void CDataFormatPage::OnBnClickedCheckMagicnumber()
{
	CComboBox *pBox = (CComboBox *)GetDlgItem(IDC_COMBO_MAGICNUMBER);
	CEdit *pValue = (CEdit *)GetDlgItem(IDC_EDIT_MAGICNUMBER_VALUE);
	if(IsDlgButtonChecked(IDC_CHECK_MAGICNUMBER))
	{
		pBox->EnableWindow(TRUE);
		pValue->EnableWindow(TRUE);
	}
	else
	{
		pBox->EnableWindow(FALSE);
		pValue->EnableWindow(FALSE);
	}
}

BOOL CDataFormatPage::OnInitDialog()
{
	CPropertyPage::OnInitDialog();

	LoadSettings();
	return TRUE;  // return TRUE unless you set the focus to a control
}

void CDataFormatPage::LoadSettings(void)
{
	CButton *pBut;
	CComboBox *pBox;
	CEdit *pValue;

	pBut = (CButton*)GetDlgItem(IDC_CHECK_16BITDATA);
	pBut->SetCheck(m_pSettings->b16BitData);

	pBut = (CButton*)GetDlgItem(IDC_CHECK_CHANNELID);
	pBut->SetCheck(m_pSettings->bChannelID);
	pBox = (CComboBox*)GetDlgItem(IDC_COMBO_CHANNELID);
	pBox->SetCurSel(m_pSettings->ChannelIDSize);
	pBox->EnableWindow(m_pSettings->bChannelID);

	pBut = (CButton*)GetDlgItem(IDC_CHECK_MAGICNUMBER);
	pBut->SetCheck(m_pSettings->bMagicNumber);
	pBox = (CComboBox*)GetDlgItem(IDC_COMBO_MAGICNUMBER);
	pBox->SetCurSel(m_pSettings->MagicNumberSize);
	pBox->EnableWindow(m_pSettings->bMagicNumber);
	CString tempString;
	tempString.Format("0x%X",m_pSettings->MagicNumberValue);
	pValue=(CEdit *)GetDlgItem(IDC_EDIT_MAGICNUMBER_VALUE);
	pValue->SetWindowText(tempString);
	pValue->EnableWindow(m_pSettings->bMagicNumber);

	pBut = (CButton*)GetDlgItem(IDC_CHECK_FRAGMENTLENGTH);
	pBut->SetCheck(m_pSettings->bFragmentLength);
	pBox = (CComboBox*)GetDlgItem(IDC_COMBO_FRAGMENTLENGTH);
	pBox->SetCurSel(m_pSettings->FragmentLengthSize);
	pBox->EnableWindow(m_pSettings->bFragmentLength);
}

void CDataFormatPage::SaveSettings(void)
{
	CButton *pBut;
	CComboBox *pBox;
	CEdit *pValue;

	pBut = (CButton*)GetDlgItem(IDC_CHECK_16BITDATA);
	m_pSettings->b16BitData = (bool)pBut->GetCheck();

	pBut = (CButton*)GetDlgItem(IDC_CHECK_CHANNELID);
	m_pSettings->bChannelID= (bool)pBut->GetCheck();
	pBox = (CComboBox*)GetDlgItem(IDC_COMBO_CHANNELID);
	m_pSettings->ChannelIDSize = pBox->GetCurSel();
	
	pBut = (CButton*)GetDlgItem(IDC_CHECK_MAGICNUMBER);
	m_pSettings->bMagicNumber = (bool)pBut->GetCheck();
	pBox = (CComboBox*)GetDlgItem(IDC_COMBO_MAGICNUMBER);
	m_pSettings->MagicNumberSize = pBox->GetCurSel();
	CString tempString;
	tempString.Format("0x%X",m_pSettings->MagicNumberValue);
	pValue=(CEdit *)GetDlgItem(IDC_EDIT_MAGICNUMBER_VALUE);
	pValue->SetWindowText(tempString);
	pValue->EnableWindow(m_pSettings->bMagicNumber);

	pBut = (CButton*)GetDlgItem(IDC_CHECK_FRAGMENTLENGTH);
	pBut->SetCheck(m_pSettings->bFragmentLength);
	m_pSettings->bFragmentLength = (bool)pBut->GetCheck();
	pBox = (CComboBox*)GetDlgItem(IDC_COMBO_FRAGMENTLENGTH);
	m_pSettings->FragmentLengthSize = pBox->GetCurSel();
}

BOOL CDataFormatPage::OnApply()
{
	SaveSettings();
	return CPropertyPage::OnApply();
}
