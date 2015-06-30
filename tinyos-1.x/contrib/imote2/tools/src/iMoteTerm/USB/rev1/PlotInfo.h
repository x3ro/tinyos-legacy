// PlotInfo.h: interface for the CPlotInfo class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_PLOTINFO_H__C4DFF996_A32F_4741_9490_715D0FD47D2C__INCLUDED_)
#define AFX_PLOTINFO_H__C4DFF996_A32F_4741_9490_715D0FD47D2C__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#define NUMPOINTS (3000)
//#define NUMPOINTS (450)
#define BUFLEN (6)

#define TIMESTAMP_VALID 0x1
#define X_VALID 0x2
#define Y_VALID 0x4
#define Z_VALID 0x8

class CPlotInfo : public CObject  
{
	
public:
	CPlotInfo();
	virtual ~CPlotInfo();
	
	int pointcount;
	unsigned char validmask;
	int bufpos;
	
	POINT buffer[BUFLEN];;
	long x[NUMPOINTS];
	long y[NUMPOINTS];
	long z[NUMPOINTS];
	CString timestamps[NUMPOINTS];

	void Serialize( CArchive& archive );
	void SaveAscii( CFile& archive );
	unsigned char SetValidMask(unsigned char newmask);

	DECLARE_SERIAL(CPlotInfo)
};

#endif // !defined(AFX_PLOTINFO_H__C4DFF996_A32F_4741_9490_715D0FD47D2C__INCLUDED_)
