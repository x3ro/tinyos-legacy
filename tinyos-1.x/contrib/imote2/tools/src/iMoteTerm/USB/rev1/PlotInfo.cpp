// PlotInfo.cpp: implementation of the CPlotInfo class.
//
//////////////////////////////////////////////////////////////////////

#include "stdafx.h"
#include "iMoteConsole.h"
#include "PlotInfo.h"

#ifdef _DEBUG
#undef THIS_FILE
static char THIS_FILE[]=__FILE__;
#define new DEBUG_NEW
#endif

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////
IMPLEMENT_SERIAL(CPlotInfo,CObject,1)

void CPlotInfo::Serialize(CArchive &archive)
{
	if(archive.IsStoring())
	{	
		for(int i=0; i<pointcount;i++)
		{
			archive<<x[i];
		}
	}
	else
	{

	}
}

void CPlotInfo::SaveAscii(CFile &archive)
{
	CString text;
	text.Format("\nX data is first column, Y data is second column\n");
	archive.Write(text,text.GetLength());
	for(int i=0; i<pointcount;i++)
	{
		CString text;
		double xTemp=((double)x[i]);
		double yTemp=((double)y[i]);
		text.Format("%f %f\n", xTemp, yTemp);
		archive.Write(text,text.GetLength());
	}
}

CPlotInfo::CPlotInfo() : pointcount(0),bufpos(0)
{
	int i;
	for(i=0; i<BUFLEN; i++)
	{
		buffer[i].x = 0;
		buffer[i].y = 0;
	}
	for(i=0;i<NUMPOINTS; i++)
	{
		x[i] = 0;
		y[i] = 0;
		z[i] = 0;
	}
	validmask=0;
}


CPlotInfo::~CPlotInfo()
{

}

unsigned char CPlotInfo::SetValidMask(unsigned char newmask)
{	
	unsigned char oldmask=validmask;
	validmask=newmask;
	return oldmask;
}

