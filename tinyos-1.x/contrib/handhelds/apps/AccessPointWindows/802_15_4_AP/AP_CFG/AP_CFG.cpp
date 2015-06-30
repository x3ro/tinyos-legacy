/*
 *  AP_CFG - small GUI program to do part of the configuration
 *           for AP_CON (the console-mode 802.15.4 AP for Windows)
 *
 *  This source code is Copyright (C) 2008 Realtime Technologies
 *  and is released under the GPL version 2 (see below)
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2
 *  as published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program (see the file COPYING included with this
 *  distribution); if not, write to the Free Software Foundation, Inc.,
 *  59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  Author: Caranfil Catalin <ccaranfil@shimmer-research.com>
 */ 


// AP_CFG v0.60
// the configuration is in 802_15_4_AP.INI

#include "stdafx.h"
#define MAX_LOADSTRING 100

// Global Variables:
HINSTANCE	g_hinstance;								// current instance
TCHAR		g_szTitle[MAX_LOADSTRING];					// The title bar text

HWND		g_h_dlg = 0;


// stuff to build info about where program + INI are located
char g_path_file_prg[2048] = "";
char g_path_dir_prg[2048] = "";
char g_full_name_INI[2048] = "";

const char * g_name_INI = "802_15_4_AP.INI";

char g_ini_section[]	= "AP_WIN32";
char g_ini_adapter[]	= "ADAPTER_ID";
char g_ini_COM[]		= "COM_PORT";
char g_ini_flag_udp[]	= "FLAG_UDP";
char g_ini_verbose[]	= "VERBOSE";

char	g_name_adapter[256]	= "";
char	g_name_COM[256]		= "";
bool	g_flag_udp			= false;
DWORD	g_verbose			= 0;


//#define ADAPTER_KEY "SYSTEM\\CurrentControlSet\\Control\\Class\\{4D36E972-E325-11CE-BFC1-08002BE10318}"
//#define NETWORK_CONNECTIONS_KEY "SYSTEM\\CurrentControlSet\\Control\\Network\\{4D36E972-E325-11CE-BFC1-08002BE10318}"



struct adapter_info
	{
	string		class_no;	// used under ADAPTER_KEY
	string		conn_guid;	// also the driver name
	string		name;		// name in list
	};


typedef list<adapter_info> list_adapter_info;


list_adapter_info g_list_adapter_info;






int filename_to_pathname_x(char * buff)
	{
	if(buff == 0 || buff[0] == 0)
		{
		return -1;
		}
	char * last_slash = 0;
	char * p = buff;
	int i = 0;
	while(*p)
		{
		if(*p == '\\' || *p == '/')
			{
			last_slash = p;
			}
		p = CharNext(p);
		}
	last_slash = CharNext(last_slash);
	*last_slash = 0;
	return last_slash - buff;
	}




//#define ADAPTER_KEY "SYSTEM\\CurrentControlSet\\Control\\Class\\{4D36E972-E325-11CE-BFC1-08002BE10318}"
//#define NETWORK_CONNECTIONS_KEY "SYSTEM\\CurrentControlSet\\Control\\Network\\{4D36E972-E325-11CE-BFC1-08002BE10318}"



void ErrorMessage(DWORD error, LPCTSTR caption = "Error")
	{
	char * lpMsgBuf;
	FormatMessage( 
		FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
		NULL,
		error,
		MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
		(LPTSTR) &lpMsgBuf,
		0,
		NULL 
	);
	// Display the string.
	MessageBox( NULL, lpMsgBuf, caption, MB_OK|MB_ICONINFORMATION );
	// Free the buffer.
	LocalFree( lpMsgBuf );
	}




#define SMALL_BUFF  0x01000
//#define MEDIUM_BUFF 0x80000

int build_adapter_list()
	{
	HKEY k1;
	LONG r = RegOpenKeyEx(HKEY_LOCAL_MACHINE, ADAPTER_KEY, 0, KEY_READ, &k1);
	if(r != ERROR_SUCCESS)
		{
		ErrorMessage(r);
		return -1;
		}

	int index=0;
	static char b1[SMALL_BUFF];
	DWORD l1=SMALL_BUFF;
//	static char b2[MEDIUM_BUFF];
//	DWORD l2=MEDIUM_BUFF;

	FILETIME ft;
	index = 0;

	do
		{
		l1 = SMALL_BUFF;
		//l2 = MEDIUM_BUFF;
		r = RegEnumKeyEx(k1, index, b1, &l1, 0, NULL, NULL, &ft);
		if(r == ERROR_NO_MORE_ITEMS)
			{
			break;
			}
		if(r != ERROR_SUCCESS )
			{
			ErrorMessage(r);
			}
		
		adapter_info ai;
		ai.class_no.assign(b1);

		HKEY k2;
		r = RegOpenKeyEx(k1, b1, 0, KEY_READ, &k2);
		if(r == ERROR_SUCCESS)
			{
			char b2[SMALL_BUFF] = "";
			DWORD l2 = SMALL_BUFF;
			r = RegQueryValueEx(k2, "NetCfgInstanceId", 0, 0, (BYTE*) b2, &l2);
			if(r == ERROR_SUCCESS)
				{
				ai.conn_guid.assign(b2);
				}
			b2[0]=0;
			l2 = SMALL_BUFF;
			r = RegQueryValueEx(k2, "DriverDesc", 0, 0, (BYTE*) b2, &l2);
			if(r == ERROR_SUCCESS)
				{
				ai.name.assign(b2);
				}
			RegCloseKey(k2);
			
			if(ai.conn_guid.length() > 0)
				{
				string net_conn_key_name(NETWORK_CONNECTIONS_KEY);
				net_conn_key_name += "\\";
				net_conn_key_name += ai.conn_guid;
				net_conn_key_name += "\\Connection";
				
				const char * p = net_conn_key_name.c_str();
				
				r = RegOpenKeyEx(HKEY_LOCAL_MACHINE, p, 0, KEY_READ, &k2);
				if(r == ERROR_SUCCESS)
					{
					b2[0]=0;
					l2 = SMALL_BUFF;
					r = RegQueryValueEx(k2, "Name", 0, 0, (BYTE*) b2, &l2);
					if(r == ERROR_SUCCESS)
						{
						ai.name += " - ";
						ai.name += b2;
						g_list_adapter_info.push_back(ai);
						}
					RegCloseKey(k2);
					}
				}
			}
		
		++index;
		l1=SMALL_BUFF;
		//l2=MEDIUM_BUFF;
		}
	while(1);

	if(r!=ERROR_NO_MORE_ITEMS)
		{
		ErrorMessage(r);
		}

	RegCloseKey(k1);

	return index;
	}



int init_main()
	{
	build_adapter_list();

	char buff[256];
	int len;
	
	GetModuleFileName(NULL, g_path_file_prg, SIZEOF(g_path_file_prg));
	strcpy(g_path_dir_prg ,g_path_file_prg);
	filename_to_pathname_x(g_path_dir_prg);

	SetCurrentDirectory(g_path_dir_prg);

	strcpy(g_full_name_INI, g_path_dir_prg);
	strcat(g_full_name_INI, g_name_INI);

	len = GetPrivateProfileString(g_ini_section, g_ini_adapter, "", buff, sizeof(buff), g_full_name_INI);
	if(len > 0)
		{
		strcpy(g_name_adapter, buff);
		}

	len = GetPrivateProfileString(g_ini_section, g_ini_COM, "", buff, sizeof(buff), g_full_name_INI);
	if(len > 0)
		{
		strcpy(g_name_COM, buff);
		}

	len = GetPrivateProfileString(g_ini_section, g_ini_flag_udp, "", buff, sizeof(buff), g_full_name_INI);
	if(len > 0)
		{
		int flag = 0;
		sscanf(buff, "%d", &flag);
		g_flag_udp = (flag != 0);
		}

	len = GetPrivateProfileString(g_ini_section, g_ini_verbose, "", buff, sizeof(buff), g_full_name_INI);
	if(len > 0)
		{
		DWORD v = 0;
		sscanf(buff, "%u", &v);
		g_verbose = v;
		}


	return 0;
	}













void CenterWindow(HWND hwnd)
	{
	RECT r1,r2;
	HWND parent;
	GetWindowRect(hwnd,&r1);
	parent=GetParent(hwnd);
	SystemParametersInfo(SPI_GETWORKAREA, 0, &r2, 0);
	int sx1=r1.right-r1.left;
	int sy1=r1.bottom-r1.top;
	int sx2=r2.right-r2.left;
	int sy2=r2.bottom-r2.top;
	int off_x = r2.left + (sx2-sx1)/2;
	int	off_y = r2.top + (sy2-sy1)/2;
	MoveWindow(hwnd, off_x, off_y, sx1, sy1, TRUE);
	}





BOOL Dlg_cfg_OnInitDialog(HWND hwnd, HWND hwndFocus,LPARAM lParam)
	{
	CenterWindow(hwnd);
	
	HWND hcombo = GetDlgItem(hwnd, IDC_COMBO_ADAPTER);
	ComboBox_ResetContent(hcombo);

	int found = -1;
	list_adapter_info::iterator it;
	int i;
	for(it = g_list_adapter_info.begin(); it != g_list_adapter_info.end(); ++it)
		{
		i = ComboBox_AddString(hcombo, it->name.c_str());
		if(it->conn_guid == g_name_adapter)
			{
			found = i;
			}
		}
	if(found >= 0)
		{
		ComboBox_SetCurSel(hcombo, found);
		}
	
	Edit_SetText(GetDlgItem(hwnd, IDC_EDIT_COM), g_name_COM);
	
	Button_SetCheck(GetDlgItem(hwnd, IDC_CHECK_UDP), g_flag_udp);

	Button_SetCheck(GetDlgItem(hwnd, IDC_CHECK_V_EVENTS), g_verbose & VERBOSE_EVENTS);
	Button_SetCheck(GetDlgItem(hwnd, IDC_CHECK_V_UNESCAPE), g_verbose & VERBOSE_UNESCAPE);
	Button_SetCheck(GetDlgItem(hwnd, IDC_CHECK_V_DATA), g_verbose & VERBOSE_DATA);
	Button_SetCheck(GetDlgItem(hwnd, IDC_CHECK_V_UNESC_ALL), g_verbose & VERBOSE_UNESC_ALL);
	Button_SetCheck(GetDlgItem(hwnd, IDC_CHECK_V_COMM_ALL), g_verbose & VERBOSE_COMM_ALL);
	
	return(TRUE);
	}






BOOL Dlg_cfg_OnCommand (HWND hwnd, int id, HWND hwndCtl, UINT codeNotify)
	{
	switch (id)
   		{
   	case IDOK:
   		{
   		int i = ComboBox_GetCurSel(GetDlgItem(hwnd, IDC_COMBO_ADAPTER));
   		if(i < 0)
   			{
   			break;
   			}
		list_adapter_info::iterator it = g_list_adapter_info.begin();
		advance(it, i);
		lstrcpyn(g_name_adapter, it->conn_guid.c_str(), SIZEOF(g_name_adapter));
		Edit_GetText(GetDlgItem(hwnd, IDC_EDIT_COM), g_name_COM, SIZEOF(g_name_COM));
		g_flag_udp = Button_GetCheck(GetDlgItem(hwnd, IDC_CHECK_UDP));
		WritePrivateProfileString(g_ini_section, g_ini_adapter, g_name_adapter, g_full_name_INI);
		WritePrivateProfileString(g_ini_section, g_ini_COM, g_name_COM, g_full_name_INI);
		WritePrivateProfileString(g_ini_section, g_ini_flag_udp, g_flag_udp ? "1" : "0", g_full_name_INI);

		{
		g_verbose = 0;
		if(Button_GetCheck(GetDlgItem(hwnd, IDC_CHECK_V_EVENTS)))
			{
			g_verbose |= VERBOSE_EVENTS;
			}
		if(Button_GetCheck(GetDlgItem(hwnd, IDC_CHECK_V_UNESCAPE)))
			{
			g_verbose |= VERBOSE_UNESCAPE;
			}
		if(Button_GetCheck(GetDlgItem(hwnd, IDC_CHECK_V_DATA)))
			{
			g_verbose |= VERBOSE_DATA;
			}
		if(Button_GetCheck(GetDlgItem(hwnd, IDC_CHECK_V_UNESC_ALL)))
			{
			g_verbose |= VERBOSE_UNESC_ALL;
			}
		if(Button_GetCheck(GetDlgItem(hwnd, IDC_CHECK_V_COMM_ALL)))
			{
			g_verbose |= VERBOSE_COMM_ALL;
			}
		char b[64];
		sprintf(b, "%u", g_verbose);
		WritePrivateProfileString(g_ini_section, g_ini_verbose, b, g_full_name_INI);
		}
		
		}
   		PostQuitMessage(IDOK);
        break;

  	case IDCANCEL:
   		PostQuitMessage(IDCANCEL);
        break;

	case IDC_EDIT_COM:
		{
		if(codeNotify!=EN_UPDATE && codeNotify!=EN_CHANGE)
			{
			break;
			}
		// extra ?
		}
		break;


	case IDC_COMBO_ADAPTER:
		{
		if(codeNotify==CBN_DROPDOWN)
			{
			}
		if(codeNotify==CBN_CLOSEUP)
			{
			}
		if(codeNotify==CBN_SETFOCUS)
			{
			}
		if(codeNotify==CBN_KILLFOCUS)
			{
			}
		if(codeNotify==CBN_SELCHANGE)
			{
			//Beep(5000, 10);
			//stip_lb_sel();
			}
		if(codeNotify!=CBN_SELENDOK)
			{
			break;
			}
		// save it locally
		} // IDC_COMBO_ADAPTER
		break;



	case IDC_CHECK_UDP:
		if(codeNotify==BN_CLICKED)
			{
			//goto p_changed;
			}
		break;


   		} // switch (id)

	return TRUE;
	}



BOOL CALLBACK Dlg_cfg_Proc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
	{
	BOOL fProcessed = FALSE;

	switch (uMsg)
		{
		HANDLE_MSG(hDlg, WM_INITDIALOG, 	Dlg_cfg_OnInitDialog);
		HANDLE_MSG(hDlg, WM_COMMAND,		Dlg_cfg_OnCommand);
//		HANDLE_MSG(hDlg, WM_TIMER,			Dlg_cfg_OnTimer);

//		HANDLE_MSG(hDlg, WM_MEASUREITEM,	Dlg_cfg_OnMeasureItem);
//		HANDLE_MSG(hDlg, WM_DRAWITEM,		Dlg_cfg_OnDrawItem);

//		HANDLE_MSG(hDlg, WM_QUERYENDSESSION,Dlg_cfg_OnQueryEndSession);
//		HANDLE_MSG(hDlg, WM_ENDSESSION,		Dlg_cfg_OnEndSession);

//		HANDLE_MSG(hDlg, WM_ACTIVATE,		Dlg_cfg_OnActivate);


	case WM_POWERBROADCAST:
		//Beep(5000, 300);
		return DefWindowProc(hDlg, uMsg, wParam, lParam);
	

	default:
		;

		}


	return(fProcessed);
	}







int APIENTRY _tWinMain(HINSTANCE hInstance,
                     HINSTANCE hPrevInstance,
                     LPTSTR    lpCmdLine,
                     int       nCmdShow)
	{
	g_hinstance	= hInstance;

	MSG msg;
	HACCEL hAccelTable;

	// Initialize global strings
	//LoadString(hInstance, IDS_APP_TITLE, g_szTitle, MAX_LOADSTRING);

	int i = init_main();

	g_h_dlg = CreateDialog(g_hinstance, MAKEINTRESOURCE(IDD_MAIN), NULL, (DLGPROC)Dlg_cfg_Proc);

	//SetWindowText(g_h_dlg, esx_string);

	LONG l = (LONG) LoadIcon(g_hinstance, MAKEINTRESOURCE(IDI_CFG));
	SetClassLong(g_h_dlg, GCL_HICON,l);

	ShowWindow(g_h_dlg, SW_SHOWNORMAL);
	//ShowWindow(g_h_dlg, nCmdShow);



	// Main message loop:
	while (GetMessage(&msg, NULL, 0, 0)) 
		{
		if(IsDialogMessage(g_h_dlg, &msg))
			{
			continue;
			}

//		if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg)) 
			{
			TranslateMessage(&msg);
			DispatchMessage(&msg);
			}
		}

	return (int) msg.wParam;
	}


