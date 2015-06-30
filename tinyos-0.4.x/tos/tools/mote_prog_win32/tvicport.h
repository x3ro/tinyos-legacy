/* ========================================================================
   =================    TVicPort  DLL interface        ====================
   ==========            Shareware Version 3.0                  ===========
   ==========  Copyright (c) 1997,1998,1999 Victor I.Ishikeev     =========
   ========================================================================
   ==========         mail to tools@entechtaiwan.com            ===========
   ==========                 ivi@ufanet.ru                     ===========
   ==========         http://www.entechtaiwan.com/tools.htm     ===========
   ======================================================================== */


#if defined(WIN32)

#define VICFN  __stdcall
#else
#define VICFN  __pascal far
#endif // defined(WIN32)

#ifdef __cplusplus
    extern "C" {
#endif


#define BOOL char
#define USHORT char
#define ULONG int

//#pragma pack(1)
typedef struct _HDDInfo {
       char       Model[41];
       char       SerialNumber[21];
       char       Revision[9];
       BOOL       DoubleTransfer;
       USHORT     ControllerType;
       ULONG      BufferSize;
       USHORT     ECCMode;
       USHORT     SectorsPerInterrupt;
       USHORT     Cylinders;
       USHORT     Heads;
       USHORT     SectorsPerTrack;
} HDDInfo, *pHDDInfo;


void  VICFN CloseTVicPort();
BOOL  VICFN OpenTVicPort(); 
BOOL  VICFN IsDriverOpened();
		
BOOL  VICFN TestHardAccess();
void  VICFN SetHardAccess(BOOL bNewValue);

unsigned char VICFN ReadPort(unsigned short PortAddr); 
void  VICFN WritePort(unsigned short PortAddr, unsigned char nNewValue);
unsigned short VICFN ReadPortW(unsigned short PortAddr);
void  VICFN WritePortW(unsigned short PortAddr, unsigned short nNewValue);
unsigned long  VICFN ReadPortL(unsigned short PortAddr);
void  VICFN WritePortL(unsigned short PortAddr, unsigned long nNewValue);

void  VICFN ReadPortFIFO  (unsigned short PortAddr, unsigned short NumPorts, unsigned char * Buffer);
void  VICFN WritePortFIFO (unsigned short PortAddr, unsigned short NumPorts, unsigned char * Buffer);
void  VICFN ReadPortWFIFO (unsigned short PortAddr, unsigned short NumPorts, unsigned short * Buffer);
void  VICFN WritePortWFIFO(unsigned short PortAddr, unsigned short NumPorts, unsigned short * Buffer);

short VICFN GetLPTNumber();
void  VICFN SetLPTNumber(short nNewValue);
short VICFN GetLPTNumPorts();
short VICFN GetLPTBasePort();

BOOL  VICFN GetPin(unsigned short nPin);
void  VICFN SetPin(unsigned short nPin, BOOL bNewValue);

BOOL  VICFN GetLPTAckwl();
BOOL  VICFN GetLPTBusy();
BOOL  VICFN GetLPTPaperEnd();
BOOL  VICFN GetLPTSlct();
BOOL  VICFN GetLPTError(); 

void  VICFN LPTInit();
void  VICFN LPTSlctIn();
void  VICFN LPTStrobe();
void  VICFN LPTAutofd(BOOL Flag);

void  VICFN GetHDDInfo(unsigned char IdeNumber, 
					   unsigned char Master,
					   pHDDInfo Info);


#ifdef __cplusplus
	}
#endif
