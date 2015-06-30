// MappingFunctionDlg.cpp : implementation file
//

#include "stdafx.h"
#include "iMoteConsole.h"
#include "MappingFunctionDlg.h"


// CMappingFunctionDlg dialog

IMPLEMENT_DYNAMIC(CMappingFunctionDlg, CDialog)
CMappingFunctionDlg::CMappingFunctionDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CMappingFunctionDlg::IDD, pParent)
	, m_EditMinRangeValue(0)
	, m_EditMaxRangeValue(65535)
{
}

CMappingFunctionDlg::~CMappingFunctionDlg()
{
}

void CMappingFunctionDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	DDX_Text(pDX, IDC_EDIT_MINRANGE, m_EditMinRangeValue);
	DDX_Text(pDX, IDC_EDIT_MAXRANGE, m_EditMaxRangeValue);
}


BEGIN_MESSAGE_MAP(CMappingFunctionDlg, CDialog)
END_MESSAGE_MAP()


// CMappingFunctionDlg message handlers
