#pragma once


// CMappingFunctionDlg dialog

class CMappingFunctionDlg : public CDialog
{
	DECLARE_DYNAMIC(CMappingFunctionDlg)

public:
	CMappingFunctionDlg(CWnd* pParent = NULL);   // standard constructor
	virtual ~CMappingFunctionDlg();

// Dialog Data
	enum { IDD = IDD_DIALOG_MAPPINGFUNCTION };

protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support

	DECLARE_MESSAGE_MAP()
public:
	int m_EditMinRangeValue;
	int m_EditMaxRangeValue;
};
