// iMoteConsole.h : main header file for the IMOTECONSOLE application
//

#if !defined(AFX_IMOTECONSOLE_H__22611AAE_E17A_492A_A0B6_E23266581A2D__INCLUDED_)
#define AFX_IMOTECONSOLE_H__22611AAE_E17A_492A_A0B6_E23266581A2D__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#ifndef __AFXWIN_H__
	#error include 'stdafx.h' before including this file for PCH
#endif

#include "resource.h"		// main symbols

/////////////////////////////////////////////////////////////////////////////
// CIMoteConsoleApp:
// See iMoteConsole.cpp for the implementation of this class
//

class CIMoteConsoleApp : public CWinApp
{
public:
	CIMoteConsoleApp();

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CIMoteConsoleApp)
	public:
	virtual BOOL InitInstance();
	//}}AFX_VIRTUAL

// Implementation

	//{{AFX_MSG(CIMoteConsoleApp)
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};


/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_IMOTECONSOLE_H__22611AAE_E17A_492A_A0B6_E23266581A2D__INCLUDED_)
