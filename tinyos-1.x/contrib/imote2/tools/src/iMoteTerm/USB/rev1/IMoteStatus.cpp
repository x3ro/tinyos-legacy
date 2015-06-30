// IMoteStatus.cpp : implementation file
//

#include "stdafx.h"
#include "iMoteConsole.h"
#include "IMoteStatus.h"
#include ".\imotestatus.h"


// CIMoteStatus dialog

IMPLEMENT_DYNAMIC(CIMoteStatus, CDialog)
CIMoteStatus::CIMoteStatus(CWnd* pParent /*=NULL*/)	: CDialog(CIMoteStatus::IDD, pParent){
	m_parent = pParent;
	
	m_hIcon = AfxGetApp()->LoadIcon(IDI_IMOTE2);
	Create(IDD_IMOTESTATUS,m_parent);
}

CIMoteStatus::~CIMoteStatus()
{
}

void CIMoteStatus::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_STATIC_STATUS_BNUMBER, m_burnStatic);
	DDX_Control(pDX, IDC_STATIC_STATUS_VNUMBER, m_verifyStatic);
	DDX_Control(pDX, IDC_PROGRESS_STATUS_BURN, m_burnProgress);
	DDX_Control(pDX, IDC_PROGRESS_STATUS_VERIFY, m_verifyProgress);
}

void CIMoteStatus::UpdateStatus(DWORD iBurn, DWORD nBurn, DWORD iVerify, DWORD nVerify, BYTE toUpdate){
	if((toUpdate & 1) != 0){
		m_iBurn = iBurn;
		m_burnProgress.SetPos(m_iBurn);
	}
	if((toUpdate & 2) != 0){
		m_nBurn = nBurn;
		m_burnProgress.SetRange32(0,m_nBurn);
	}
	if((toUpdate & 4) != 0){
		m_iVerify = iVerify;
		m_verifyProgress.SetPos(m_iVerify);
	}
	if((toUpdate & 8) != 0){
		m_nVerify = nVerify;
		m_verifyProgress.SetRange32(0,m_nVerify);
	}

	CString temp;
	temp.Format("%d / %d Burned",m_iBurn, m_nBurn);
	m_burnStatic.SetWindowText(temp);
	temp.Format("%d / %d Verified",m_iVerify, m_nVerify);
	m_verifyStatic.SetWindowText(temp);
	
	DWORD percent;
	if(m_iBurn < m_nBurn)
		percent = (m_iBurn * 50) / (m_nBurn == 0?1:m_nBurn);
	else
		percent = 50 + (m_iVerify * 50) / (m_nVerify == 0?1:m_nVerify);

	m_parent->GetWindowText(m_dev);
	temp.Format("%d%% Complete; %s",percent,m_dev);
	SetWindowText(temp);
}

void CIMoteStatus::GetStatus(DWORD *iBurn, DWORD *nBurn, DWORD *iVerify, DWORD *nVerify){
	if(iBurn != NULL)
		*iBurn = m_iBurn;
	if(nBurn != NULL)
		*nBurn = m_nBurn;
	if(iVerify != NULL)
		*iVerify = m_iVerify;
	if(nVerify != NULL)
		*nVerify = m_nVerify;
}
BEGIN_MESSAGE_MAP(CIMoteStatus, CDialog)
END_MESSAGE_MAP()


// CIMoteStatus message handlers

void CIMoteStatus::OnCancel()
{
	// TODO: Add your specialized code here and/or call the base class
	//	CDialog::OnCancel();
}
