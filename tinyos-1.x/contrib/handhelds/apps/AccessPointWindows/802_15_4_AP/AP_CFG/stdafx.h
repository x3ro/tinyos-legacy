// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

#define SIZEOF(array) (sizeof array / sizeof array[0])

#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
// Windows Header Files:
#include <windows.h>
#include <windowsx.h>
// C RunTime Header Files
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <tchar.h>
#include <stdio.h>

#include "AP_CFG.h"
#include "resource.h"


#include "..\tap-win32\constants.h"
#include "..\tap-win32\common.h"
#include "..\tap-win32\proto.h"

#include "..\H\if_telos_ap.h"
#include "..\H\telos_ap.h"
#include "..\H\common.h"


//#include <functional>
//#include <algorithm>
//#include <set>
#include <string>
#include <list>

using namespace std;
