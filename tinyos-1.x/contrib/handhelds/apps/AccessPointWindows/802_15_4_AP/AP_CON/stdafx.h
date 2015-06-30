/*
 *  AP_CON - console-mode (command-line) program implemeting
 *           a simple 802.15.4 AP under Win32 (2000, XP, probably Vista)
 *
 *  This program is using/calling TAP-WIN32 GPL driver !!!
 *
 *  This source code is Copyright (C) 2008 Realtime Technologies
 *  and is released under the GPL version 2 (see below)
 *
 *  Portions of the code were inspired from ZATTACH.C and
 *  AccessPointApp (authors Andrew Christian <andrew.christian@hp.com>
 *	and Bor-rong Chen <bor-rong.chen@hp.com> )
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


// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

#define SIZEOF(array) (sizeof array / sizeof array[0])

//#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
#include <stdio.h>
#include <tchar.h>

#include <windows.h>
#include <process.h>


#include "..\tap-win32\constants.h"
#include "..\tap-win32\common.h"
#include "..\tap-win32\proto.h"

#include "..\H\if_telos_ap.h"
#include "..\H\telos_ap.h"
#include "..\H\common.h"


#define MAC_EQUAL(a,b)      (memcmp ((a), (b), sizeof (MACADDR)) == 0) 


#include <Winsock.h>


#include <functional>
#include <algorithm>
#include <set>

using namespace std;
