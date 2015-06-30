// SerialTerminal.h : main header file for the SerialTerminal application
//
#pragma once

#ifndef __AFXWIN_H__
	#error "include 'stdafx.h' before including this file for PCH"
#endif

#include "resource.h"       // main symbols


// CSerialTerminalApp:
// See SerialTerminal.cpp for the implementation of this class
//

class CSerialTerminalApp : public CWinApp
{
public:
	CSerialTerminalApp();


// Overrides
public:
	virtual BOOL InitInstance();

// Implementation
	afx_msg void OnAppAbout();
	DECLARE_MESSAGE_MAP()
};

extern CSerialTerminalApp theApp;