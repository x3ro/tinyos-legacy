// iMoteConsoleDlg.cpp : implementation file
//

#include "stdafx.h"
#include "iMoteConsole.h"
#include "iMoteConsoleDlg.h"
#include ".\imoteconsoledlg.h"
#include "ConfigurationPage.h"
#include "DataFormatPage.h"
#include "SaveSettingsPage.h"
#include "IMoteCartesianPlot.h"
#include "header.h"
#include "qtables.h"
#include "cmCommand.h"
#include "assert.h"
#include <windows.h>
#include <dbt.h>


#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif



/////////////////////////////////////////////////////////////////////////////
// CAboutDlg dialog used for App About

class CAboutDlg : public CDialog
{
public:
	CAboutDlg();

// Dialog Data
	enum { IDD = IDD_ABOUTBOX };

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support

// Implementation
protected:
	DECLARE_MESSAGE_MAP()
};

CAboutDlg::CAboutDlg() : CDialog(CAboutDlg::IDD)
{
}

void CAboutDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
}

BEGIN_MESSAGE_MAP(CAboutDlg, CDialog)
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CIMoteConsoleDlg dialog

//static USBdata USBin;

void displayChange(const char *pcKey, void *pvValue, void *pvExtra){
	((CIMoteTerminal *)pvValue)->DisplayChange();
}
void closePort(const char *pcKey, void *pvValue, void *pvExtra){
	((CIMoteTerminal *)pvValue)->Disconnect();
}
void ifAttClosePort(const char *pcKey, void *pvValue, void *pvExtra){
	CIMoteTerminal *temp = (CIMoteTerminal *)pvValue;
	if(!temp->isAttached())
		temp->Disconnect();
}
void deleteBuffer(const char *pcKey, void *pvValue, void *pvExtra){
	delete((CIMoteTerminal *)pvValue);
}
void setAttached(const char *pcKey, void *pvValue, void *pvExtra){
	((CIMoteTerminal *)pvValue)->setAttached(false);
}
CIMoteConsoleDlg::CIMoteConsoleDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CIMoteConsoleDlg::IDD, pParent)
	, m_pCommConfig(0), m_pDataFormatSettings(0), smooth(true), rawdata(false), logfile("logfile.txt"), bAppClosing(false)
	, m_displayedMoteComboValue(_T(""))
{
	m_hIcon = AfxGetApp()->LoadIcon(IDI_IMOTE2);
}

CIMoteConsoleDlg::~CIMoteConsoleDlg()
{
	m_terminalList->map(deleteBuffer,NULL);
	delete m_terminalList;
	if(m_pCommConfig)
	{
		delete m_pCommConfig;
	}
	if(m_pDataFormatSettings)
	{
		delete m_pDataFormatSettings;
	}

}
void CIMoteConsoleDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CIMoteConsoleDlg)
	//}}AFX_DATA_MAP
	DDX_Control(pDX, IDC_COMBO_DISPLAYED_IMOTE, m_displayedMoteComboControl);
	DDX_CBString(pDX, IDC_COMBO_DISPLAYED_IMOTE, m_displayedMoteComboValue);
	DDX_Control(pDX, IDC_STATIC_COM_NUM, m_comNumStatic);
	DDX_Control(pDX, IDC_STATIC_DETACHED, m_detachedStatic);
}

BEGIN_MESSAGE_MAP(CIMoteConsoleDlg, CDialog)
	//{{AFX_MSG_MAP(CIMoteConsoleDlg)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	//ON_MESSAGE(WM_RECEIVE_DATA,OnReceiveData)
	ON_BN_CLICKED(IDOK, OnClose)
	//}}AFX_MSG_MAP
	ON_WM_INITMENUPOPUP()
	ON_COMMAND(ID_EDIT_OPTIONS, OnEditOptions)
	ON_COMMAND(ID_EDIT_NEWWIN, OnEditNewwin)
	ON_WM_TIMER()
	ON_WM_DEVICECHANGE()
	ON_COMMAND(ID_EDIT_TEST, OnEditTest)
	ON_COMMAND(ID_VIEW_SMOOTH, OnViewSmooth)
	ON_UPDATE_COMMAND_UI(ID_VIEW_SMOOTH, OnUpdateViewSmooth)
	ON_COMMAND(ID_EDIT_TESTNEWLIST, OnEditTestnewlist)
	ON_CBN_SELENDOK(IDC_COMBO_DISPLAYED_IMOTE, OnDisplayChange)
//	ON_WM_SIZE()
	ON_BN_CLICKED(IDC_BUTTON_WINDOW_BUFFER, OnBnClickedButtonWindowBuffer)
	ON_COMMAND(ID_HELP_ABOUT, OnHelpAbout)
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CIMoteConsoleDlg message handlers

BOOL CIMoteConsoleDlg::OnInitDialog()
{
	CDialog::OnInitDialog();
	// Add "About..." menu item to system menu.

	// IDM_ABOUTBOX must be in the system command range.
	ASSERT((IDM_ABOUTBOX & 0xFFF0) == IDM_ABOUTBOX);
	ASSERT(IDM_ABOUTBOX < 0xF000);

	CMenu* pSysMenu = GetSystemMenu(FALSE);
	if (pSysMenu != NULL)
	{
		CString strAboutMenu;
		strAboutMenu.LoadString(IDS_ABOUTBOX);
		if (!strAboutMenu.IsEmpty())
		{
			pSysMenu->AppendMenu(MF_SEPARATOR);
			pSysMenu->AppendMenu(MF_STRING, IDM_ABOUTBOX, strAboutMenu);
		}
	}

	// Set the icon for this dialog.  The framework does this automatically
	//  when the application's main window is not a dialog
	SetIcon(m_hIcon, TRUE);			// Set big icon
	SetIcon(m_hIcon, FALSE);		// Set small icon
	CreateConnectionToolBar();

	SetWindowText("iMoteConsole");

	m_terminalList = new CSymTable();
	m_displayedMoteComboControl.InitStorage(256, 10);
	CIMoteTerminal *serialTerm = new CIMoteTerminal(this, NULL, false);
	m_terminalList->put("Serial",serialTerm);
	m_displayedMoteComboControl.AddString("Serial");
	m_displayedMoteComboControl.SetCurSel(0);

	m_comNumStatic.SetWindowText(m_strPortName.Mid(4,4));
	serialTerm->SetWindowText(m_strPortName.Mid(4,4));
	serialTerm->m_comNumStatic.SetWindowText(m_strPortName.Mid(4,4));

	GUID HidGuid;
	HidD_GetHidGuid(&HidGuid);
	PopulateUSBDevices();
	DoRegisterDeviceInterface(HidGuid,&m_devNotificationHandle);

	return TRUE;  // return TRUE  unless you set the focus to a control
}

void CIMoteConsoleDlg::OnSysCommand(UINT nID, LPARAM lParam)
{
	if ((nID & 0xFFF0) == IDM_ABOUTBOX)
	{
		CAboutDlg dlgAbout;
		dlgAbout.DoModal();
	}
	else
	{
		CDialog::OnSysCommand(nID, lParam);
	}
}

// If you add a minimize button to your dialog, you will need the code below
//  to draw the icon.  For MFC applications using the document/view model,
//  this is automatically done for you by the framework.

void CIMoteConsoleDlg::OnPaint() 
{
	if (IsIconic())
	{
		CPaintDC dc(this); // device context for painting

		SendMessage(WM_ICONERASEBKGND, (WPARAM) dc.GetSafeHdc(), 0);

		// Center icon in client rectangle
		int cxIcon = GetSystemMetrics(SM_CXICON);
		int cyIcon = GetSystemMetrics(SM_CYICON);
		CRect rect;
		GetClientRect(&rect);
		int x = (rect.Width() - cxIcon + 1) / 2;
		int y = (rect.Height() - cyIcon + 1) / 2;

		// Draw the icon
		dc.DrawIcon(x, y, m_hIcon);
	}
	else
	{
		CDialog::OnPaint();
	}
}

// The system calls this to obtain the cursor to display while the user drags
//  the minimized window.
HCURSOR CIMoteConsoleDlg::OnQueryDragIcon()
{
	return (HCURSOR) m_hIcon;
}

void OutputError(char *string, DWORD error)
{
	LPVOID lpMsgBuf;

	FormatMessage( 
				FORMAT_MESSAGE_ALLOCATE_BUFFER | 
				FORMAT_MESSAGE_FROM_SYSTEM | 
				FORMAT_MESSAGE_IGNORE_INSERTS,
				NULL,
				error,
				MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
				(LPTSTR) &lpMsgBuf,
				0,
				NULL 
			);

	TRACE(string);
	TRACE((char*)lpMsgBuf);
	LocalFree( lpMsgBuf );
	
}
void CIMoteConsoleDlg::PopulateUSBDevices(){
	GUID HidGuid;
	HidD_GetHidGuid(&HidGuid);
	PSP_DEVICE_INTERFACE_DETAIL_DATA detailData = NULL;
	
	HDEVINFO hDevInfo=SetupDiGetClassDevs(&HidGuid, NULL, NULL, 
		DIGCF_DEVICEINTERFACE | DIGCF_PRESENT);
	SP_DEVICE_INTERFACE_DATA devInfoData;
	devInfoData.cbSize = sizeof(devInfoData);
	DWORD index = 0, length;
	BOOLEAN Result;
	HANDLE DeviceHandle;
	
	m_terminalList->map(setAttached,NULL);
	for(index = 0; TRUE; index++)
	{
		Result = SetupDiEnumDeviceInterfaces(hDevInfo,NULL,&HidGuid,index,&devInfoData);
		if(!Result && GetLastError() == ERROR_NO_MORE_ITEMS){
			break;
		}
		Result = SetupDiGetDeviceInterfaceDetail(hDevInfo,&devInfoData,NULL,0,&length,NULL);
		detailData = (PSP_DEVICE_INTERFACE_DETAIL_DATA)malloc(length);
		detailData->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA);
		Result = SetupDiGetDeviceInterfaceDetail(hDevInfo,&devInfoData,detailData,length,NULL,NULL);
		assert(Result != FALSE);
		DeviceHandle = CreateFile(detailData->DevicePath, 0, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
		assert(DeviceHandle != INVALID_HANDLE_VALUE);
		HIDD_ATTRIBUTES Attributes;
		Attributes.Size = sizeof(Attributes);
		Result = HidD_GetAttributes(DeviceHandle, &Attributes);
		assert(Result != FALSE);

		if(Attributes.VendorID == vID && Attributes.ProductID == pID){
			WCHAR buffer[8];
			Result = HidD_GetSerialNumberString(DeviceHandle,buffer,8*2);
			char serial[9];
			serial[8] = '\0';
			for(int i = 0; i < 8; i++)serial[i] = (char)buffer[i];
			CString temp = "USB ";
			temp += serial;

			if(!m_terminalList->contains((LPCTSTR)temp)){
				CUSBDevice *newDev = new CUSBDevice(temp);
				newDev->setDetail(detailData->DevicePath);
				CIMoteTerminal *pTerm = new CIMoteTerminal(this,newDev,true);
				pTerm->SetWindowText(temp);
				m_terminalList->put((LPCTSTR)temp,pTerm);
				m_displayedMoteComboControl.AddString(temp);
			}
			else{
				CIMoteTerminal *x = (CIMoteTerminal *)m_terminalList->get((LPCTSTR)temp);
				x->setPath(detailData->DevicePath);
				x->setAttached(true);
			}
		}
		free(detailData);
		detailData = NULL;
	}
	m_terminalList->map(ifAttClosePort,NULL);
}

#if 0
LRESULT CIMoteConsoleDlg::OnReceiveData(WPARAM wParam, LPARAM lParam)
{
	//following couple of lines allow us to debug a raw datastream
	unsigned char *rxstring = (unsigned char *)lParam;
	DWORD numBytesReceived = (DWORD) wParam;
#if 0
	DWORD i,offset;
	//TRACE("Rx...Buffer = %#X\tNumBytesReceived = %d\n",rxstring,numBytesReceived);
	/*****
	data format for the accelerometer data looks something like:
	0{2 bit addr}{5 data bits} {1}{7 data bits}
	******/
	for(offset=0; offset<numBytesReceived; offset++)
	{
		//find the correct first bytes
		if((rxstring[offset]  & 0xE0) == 0)
		{
			break;
		}
	}
	//offset current points to the correct first element for us to look at
	//start reconstructing the 16 bit numbers and doing the divide
	
	for(i=offset;(i+6)<numBytesReceived; i+=6)
	{	
		static bool init = false;
		POINT point;
		DWORD B,C,D,Tx, Ty,T;
		int Rx, Ry;
		B = ((rxstring[i] & 0x1F)<<7) | (rxstring[i+1] & 0x7F);
		C = ((rxstring[i+2] & 0x1F)<<7) | (rxstring[i+3] & 0x7F);
		D = ((rxstring[i+4] & 0x1F)<<7) | (rxstring[i+5] & 0x7F);
		Tx = B;
		Ty = D-C;
		T = C/2 + D/2 - B/2;

		Rx = ((Tx << 16) / T) - (65536/2);
		Ry = ((Ty << 16) / T) - (65536/2);
		//point.x =(LONG)( (rxstring[byte_index]<<8) + rxstring[byte_index+1]) -(65536/2);
		//point.x = (LONG)( (rxstring[byte_index]<<8) + rxstring[byte_index+1]);
		//TRACE("%d %d = %d\n",rxstring[i], rxstring[i+1], point.x);
		//TRACE("Found T, index %d \n", byte_index);
		//TRACE("Tx = %d, Ty = %d, T = %d, Rx = %d, Ry = %d\n",Tx, Ty, T, Rx, Ry);
		point.x = (LONG) Rx;
		point.y = (LONG) Ry;

		if(!init)
		{
			CIMoteCartesianPlot *pFrame=CreateNewView(0,0xDEADBEEF,0);
			pFrame->SetMappingFunction(-2,2);
			init = true;
		}
		AddPoint(point, 0);
	}
		
	delete rxstring;

	
	return TRUE;
#endif;
	POINT point;
	static bool bGotBeef = 0;
	static bool bFirstTime = true;
	static unsigned short NumDataBytes;
	static unsigned short NumBytesProcessed;
	//static int MoteIDs[NUMCHANNELS];
	static unsigned short SensorID;
	static unsigned int MoteID;
	static unsigned int SensorType;
	static unsigned int ExtraInfo;
	static unsigned int TimeID;
	static unsigned int ChannelID;
	static unsigned char HeaderIndex;
	static unsigned char Header[16];
	unsigned short *short_ptr;
	unsigned int *int_ptr;
	DWORD byte_index;
	static unsigned char LastByte = 0;
//	unsigned int ProblemIndex;
	unsigned int EmptyChannel;
	static unsigned int NumProblems = 0;
	CString logentry;
	static bool bPrintheader=true;
	CTime time;
	static int Tx, Ty, T, Rx, Ry, Tb, Tc, Td, b0, b1;
	static int CurrentCounter, CurrentByte;
	// Hack, for now statically allocate 
	static unsigned char *CameraBuffer;
	static unsigned int CurrentCameraID;
	static unsigned int CameraBufferIndex;
	static unsigned int SegmentIndex;
	static bool PictureInProgress;
	static unsigned int LastPicID;

#define MAX_PIC_SIZE 80000
#define INVALID_SENSOR 0
#define PH_SENSOR 1
#define PRESSURE_SENSOR 2
#define ACCELEROMETER_SENSOR 3
#define CAMERA_SENSOR 4

#define FIRST_SEGMENT 0x1111
#define MID_SEGMENT 0
#define END_OF_PIC 0xffff

	for(int channel = 0; (channel < NUMCHANNELS) && bFirstTime; channel++) {
		MoteIDs[channel] = 0;
		HeaderIndex = 0;
		CurrentCameraID = 0;
		CameraBuffer = NULL;
		CameraBufferIndex = 0;
		PictureInProgress = false;
	}

	if (bFirstTime) {
		// Figure out the start of the file names
		CFileFind finder;
		CString TempName;
		unsigned int TempID;
		LastPicID = 0;
		BOOL bResult = finder.FindFile("c:\\icam\\*.jpg");

		while (bResult) {
			bResult = finder.FindNextFile();
			TempName = finder.GetFileName();
			if (sscanf((LPCSTR)TempName, "%d.jpg", &TempID) == 1) {
				// valid pic id
				if (LastPicID < TempID) {
					LastPicID = TempID;
				}
			}
		}
		LastPicID++;
	}


	bFirstTime = false;
	TRACE("Rx...Buffer = %#X\tNumBytesReceived = %d\n",rxstring,numBytesReceived);
	byte_index = 0;
	while(byte_index < numBytesReceived) {
		// Look for DEADBEEF, get all header info
		for(; (byte_index < numBytesReceived) && !bGotBeef; byte_index++) {
			switch (HeaderIndex) {
			case 0:
				if (rxstring[byte_index] == 0xEF) {
					HeaderIndex = 1;
				}
				break;
			case 1:
				if (rxstring[byte_index] == 0xBE) {
					HeaderIndex = 2;
				} else {
					HeaderIndex = 0;
				}
				break;
			case 2:
				if (rxstring[byte_index] == 0xAD) {
					HeaderIndex = 3;
				} else {
					HeaderIndex = 0;
				}
				break;
			case 3:
				if (rxstring[byte_index] == 0xDE) {
					HeaderIndex = 4;
				} else {
					HeaderIndex = 0;
				}
				break;
			case 13:
				// Done with header
				CurrentCounter = 0;
				CurrentByte = 0;
				bGotBeef = 1;
				Header[HeaderIndex] = rxstring[byte_index];
				/*
				* Header :
				* DEADBEEF (4B)
				* MOTE ID (4B)
				* Sensor TYPE (2B)
				* LENGTH (2B)
				* Extra Info (2B)
				* 
				*/
				int_ptr = (unsigned int *) &(Header[4]);
				MoteID = *int_ptr;
				short_ptr = (unsigned short *) &(Header[8]);
				SensorType = *short_ptr;
				short_ptr++;
				NumDataBytes = *short_ptr;
				short_ptr++;
				ExtraInfo = *short_ptr;
				NumBytesProcessed = 0;
				ChannelID = NUMCHANNELS;
				EmptyChannel = NUMCHANNELS;

				if (SensorType == CAMERA_SENSOR) {
					// check with segment
					TRACE("Camera seg %x, buf Index %d, NumDataBytes %d\r\n",
						ExtraInfo, CameraBufferIndex, NumDataBytes);
					if (ExtraInfo == FIRST_SEGMENT) {
						// first segment
						CurrentCameraID = MoteID;
						CameraBufferIndex = 0;						
						if (!PictureInProgress) {
							// create buffer
							CameraBuffer = new unsigned char[MAX_PIC_SIZE];
							PictureInProgress = true;
						}
					}
					SegmentIndex = 0;	// Per segment index
					break;	// don't process the channel stuff
				}
				// Find mote channel, 
				for(int channel = 0; channel < NUMCHANNELS; channel++) {
					if (MoteIDs[channel] == MoteID) {
						ChannelID = channel;
						break;
					} else {
						if (MoteIDs[channel] == 0) {
							EmptyChannel = channel;
						}
					}
				}
				

				if (ChannelID == NUMCHANNELS) {
					// Didn't find a channel
					if (EmptyChannel < NUMCHANNELS) {
						// assign the mote id to this channel
						MoteIDs[EmptyChannel] = MoteID;
						ChannelID = EmptyChannel;
						CIMoteCartesianPlot *pFrame=CreateNewView(ChannelID,MoteID,SensorID);
						/*
							Note to LAMA:  below is an example of how to use the setmapping function
							pFrame->SetMappingFunction(slope, offset, minrange, maxrange
						*/
						switch(SensorType) {
							case PH_SENSOR:
								pFrame->SetMappingFunction(0,14);
								rawdata = false;
								break;
							case PRESSURE_SENSOR:
								pFrame->SetMappingFunction(0,20.684);
								//pFrame->SetMappingFunction(0,300);
								rawdata = false;
								break;
							case ACCELEROMETER_SENSOR:
								pFrame->SetMappingFunction(-2,2);
								rawdata = false;
								break;
							default :
								//pFrame->SetMappingFunction(1,1,0,14);
								pFrame->SetMappingFunction(-32768,32768);
						}
						//UpdateAllViews(NULL);
					}  
					/*
					* NOTE: if ChannelID is not assigned, 
					* the processing will remain the same, but the data won't
					* be displayed.
					* TODO : handle later
					*/
				}
				//log transaction info to file here:
				if(bPrintheader)
				{
					logentry.Format("Timestamp, iMoteID, # of Bytes\r\n");
					//logfile<<logentry<<endl;
					SaveLogEntry(&logentry);
					bPrintheader=false;
				}
				time=time.GetCurrentTime();
				//logfile<<time.Format("%c");
				SaveLogEntry(&time.Format("%c"));
				logentry.Format(", %#X, %d\r\n",MoteID, NumDataBytes);
				//logfile<<logentry<<endl;
				SaveLogEntry(&logentry);				
				break;
			default:
				Header[HeaderIndex] = rxstring[byte_index];
				HeaderIndex++;
				break;
			}
		}
		if (!bGotBeef) {
			delete []rxstring;
			return TRUE;
		}
		// Got DEADBEEF, process data
		for(; byte_index <numBytesReceived; byte_index++,NumBytesProcessed ++) {
			if (NumBytesProcessed >= NumDataBytes) {
				// go back to start, look for DEADBEEF again
				bGotBeef = false;
				HeaderIndex = 0;
				TRACE("Mote ID %lx, NumBytes %ld, byte index %d \n", MoteID, NumDataBytes, byte_index);
				//MoteID = 0;
				//NumDataBytes = 0;
				break;
			}
			if (rawdata) {	//RAW_BYTES mode, no processing
				// Assume data is 2 bytes long, and back to back
				if (CurrentByte == 0) {
					b0 = rxstring[byte_index];
					CurrentByte = 1;
				} else {
					b1 = rxstring[byte_index];
					CurrentByte = 0;
					int sample_data;
					sample_data = (b1 <<8) + b0;
					//sample_data -= 0x2000;
					//sample_data = sample_data << 2;
					point.x = (LONG) sample_data;
					point.y = 0;
					//TRACE("sample is %d\r\n", sample_data);
					if (ChannelID < NUMCHANNELS) {
						// valid channel
						AddPoint(point, ChannelID);
					}
				}
			} else {
				if (CurrentByte == 0) {
					b0 = rxstring[byte_index];
					CurrentByte = 1;
					if (SensorType == CAMERA_SENSOR) {
						// just copy data
						CameraBuffer[CameraBufferIndex] = b0;
						SegmentIndex++;
						CameraBufferIndex++;
					}
				} else {
					b1 = rxstring[byte_index];
					CurrentByte = 0;
					switch(SensorType) {
						case PH_SENSOR:
							/*
							* A/D maps 0-5V range to 0-32 K 
							* pH = -7.752 * V + 16.237
							* V = raw_data * 5 / 32768
							* The plot output expects the 0 - 14 range to be represented in -32 - 32 K
							* point.x = (-7.752 * (raw_data * 5/32768) + 16.237) * 64K / 14 - 32K
							*/
							double ph_data;
							ph_data = (b1 <<8) + b0;
							ph_data = -7.752 * (ph_data/ 32768) * 5 + 16.237;
							ph_data = (ph_data * 65536 / 14) - 32768;
							point.x = (LONG) ph_data;
							point.y = 0;
							if (ChannelID < NUMCHANNELS) {
								// valid channel
								AddPoint(point, ChannelID);
							}
							break;
						case PRESSURE_SENSOR:
							/*
							* A/D maps 0-5V range to 0-32 K 
							* The plot output expects the 0 - 20.684 range to be represented in -32 - 32 K
							* point.x = (raw_data * 5/32768) * 64K / 20.684 - 32K
							*/
							int pressure_data;
							pressure_data = (b1 <<8) + b0;
							pressure_data = pressure_data * 2 - 32768;
							point.x = (LONG) pressure_data;
							point.y = 0;
							if (ChannelID < NUMCHANNELS) {
								// valid channel
								AddPoint(point, ChannelID);
							}
							break;
						case ACCELEROMETER_SENSOR:
							// TRACE("CurrentCounter %d, ByteIndex %d \n", CurrentCounter, byte_index);
							switch (CurrentCounter) {
								case 0:
									Tx = (b0 <<8) + b1;;	
									CurrentCounter = 1;
									//TRACE("Found Tx, index %d \n", byte_index);
									break;
								case 1:
									Ty = (b0 <<8) + b1;
									CurrentCounter = 2;
									//TRACE("Found Ty, index %d \n", byte_index);
									break;
								case 2:
									T = (b0 <<8) + b1;
									Rx = ((Tx << 16) / T) - (65536/2);
									Ry = ((Ty << 16) / T) - (65536/2);
									//point.x =(LONG)( (rxstring[byte_index]<<8) + rxstring[byte_index+1]) -(65536/2);
									//point.x = (LONG)( (rxstring[byte_index]<<8) + rxstring[byte_index+1]);
									//TRACE("%d %d = %d\n",rxstring[i], rxstring[i+1], point.x);
									//TRACE("Found T, index %d \n", byte_index);
									//TRACE("Tx = %d, Ty = %d, T = %d, Rx = %d, Ry = %d\n",Tx, Ty, T, Rx, Ry);
									point.x = (LONG) Rx;
									point.y = (LONG) Ry;
									if (ChannelID < NUMCHANNELS) {
										// valid channel
										AddPoint(point, ChannelID);
									}
									CurrentCounter = 0;
									break;
								default:
									break;
							}
							break;
						
						case CAMERA_SENSOR:
							// just copy data
							CameraBuffer[CameraBufferIndex] = b1;
							SegmentIndex++;
							CameraBufferIndex++;
							break;
						
					}
				}
			//for now, just save the point in the x field of the structure
			}
			//NumBytesProcessed += 2;		
		}
		TRACE("NumBytesProcessed %d, NumDataBytes %d\r\n", NumBytesProcessed, NumDataBytes);
		// Check if we reached the end of a picture, write it to file
		if ((SensorType == CAMERA_SENSOR) && (NumBytesProcessed == NumDataBytes) &&
			(ExtraInfo == END_OF_PIC)) {
				// Create output buffer , assume header < 1000
				unsigned char *JpgImage;
				int JpgImageLen;
				JpgImage = new unsigned char[CameraBufferIndex+1000];
				// build jpeg image
				BuildJPG(CameraBuffer, CameraBufferIndex, JpgImage, &JpgImageLen);
				// write to file
				char pszFileName[200];
				CFile PictureFile;
				CFileException fileException;

				sprintf(pszFileName, "c:\\icam\\%d.jpg", LastPicID);
				LastPicID++;

				if ( !PictureFile.Open( pszFileName, CFile::modeCreate |   
									CFile::modeWrite | CFile::typeBinary,
									&fileException ) )
				{
					TRACE( "Can't open file %s, error = %u\n",
								pszFileName, fileException.m_cause );
				}
				//PictureFile.Write(CameraBuffer, CameraBufferIndex);
				PictureFile.Write(JpgImage, JpgImageLen);
				PictureFile.Close();
				TRACE("Wrote Jpeg image raw %d\r\n", CameraBufferIndex);
				
				delete []CameraBuffer;
				delete []JpgImage;
				PictureInProgress = false;
		}
	}
	delete []rxstring;
	return TRUE;
}


#endif
void CIMoteConsoleDlg::OnClose(){
	/*if(GetFocus() == &m_outputRichEditControl)
		return;*/
	UnregisterDeviceNotification(m_devNotificationHandle);
	/*******************************************************************
	For now, assume that a calle to OnButtonConnect will kill the thread
	faster that OnOk kills the process...needs to fixed ;o)
	*******************************************************************/
	bAppClosing=true;
	//need to take care of killing the windows that we've created.
	int i, max=m_WindowArray.GetSize();
	for (i=0; i<max; i++)
	{
	 ((CIMoteCartesianPlot *)m_WindowArray[i])->DestroyWindow();
	}
	m_terminalList->map(closePort,NULL);
	
	OnOK();
}

void CIMoteConsoleDlg::OnEditOptions()
{
	CPropertySheet sheet("Options");
	
 	CConfigurationPage configPage(m_pCommConfig,m_strPortName);
	CDataFormatPage dataFormatPage(m_pDataFormatSettings);
	CSaveSettingsPage saveSettingsPage;

	sheet.AddPage(&configPage);
	sheet.AddPage(&dataFormatPage);
	sheet.AddPage(&saveSettingsPage);

	if(sheet.DoModal() == IDOK)
	{
		//update the port info
		//SetTitle(configPage.m_comportComboValue);
		CIMoteTerminal *temp = (CIMoteTerminal *)m_terminalList->get("Serial");
		temp->m_comNumStatic.SetWindowText(configPage.m_comportComboValue);
		temp->SetWindowText(configPage.m_comportComboValue);
		m_comNumStatic.SetWindowText(configPage.m_comportComboValue);
		m_strPortName = "\\\\.\\" + configPage.m_comportComboValue;
		
	}
}

void CIMoteConsoleDlg::OnEditNewwin()
{
	static int pos=0,currentChannel=0;
	int i;
	POINT point;
	MoteIDs[currentChannel] = 0x66+currentChannel;
	if(currentChannel>= NUMCHANNELS)
		return;
	for(i=0;i<NUMPOINTS;i++)
	{
		point.x=65536*i/NUMPOINTS - 65536/2;
		point.y=0;
		AddPoint(point,currentChannel);
	}	
	plotinfo[currentChannel].SetValidMask(X_VALID);
	pos+=i;
	CIMoteCartesianPlot *pFrame=CreateNewView(currentChannel,0x85000+currentChannel,1);
	pFrame->SetMappingFunction(-32768,32767);
	currentChannel++;
}
void CIMoteConsoleDlg::LoadProfileInfo(void)
{
	TRACE("Loading profile info\n");
	m_pDataFormatSettings = new SDataFormatSettings;
	SDataFormatSettings *pTempDataFormatSettings;
	UINT size;
	size = sizeof(SDataFormatSettings);
	if(theApp.GetProfileBinary("iMoteConsoleGraph","DataFormatSettings",(LPBYTE *) &pTempDataFormatSettings, &size))
	{
		memcpy(m_pDataFormatSettings,pTempDataFormatSettings,sizeof(SDataFormatSettings));
		delete pTempDataFormatSettings;
		TRACE("Found Data Format Settings\n");
	}
	else
	{
		TRACE("Unable to find Data Format Settings...using defaults\n");
		//defaults should be taken care of by the constructor
			//default settings:  16bit data, no magic number, no channel id, no fragment length
		m_pDataFormatSettings->b16BitData = true;
		m_pDataFormatSettings->bMagicNumber = false;
		m_pDataFormatSettings->MagicNumberSize = 2;
		m_pDataFormatSettings->MagicNumberValue = 0xDEADBEEF;
		m_pDataFormatSettings->bChannelID = false;
		m_pDataFormatSettings->ChannelIDSize = 0;
		m_pDataFormatSettings->bFragmentLength = false;
		m_pDataFormatSettings->FragmentLengthSize = 0;
	}
	m_pCommConfig = new COMMCONFIG;
	COMMCONFIG *pTempCommConfig;
	size = sizeof(COMMCONFIG);
	if(theApp.GetProfileBinary("iMoteConsoleGraph","CommConfig",(LPBYTE *)&pTempCommConfig,&size))
	{
		memcpy(m_pCommConfig,pTempCommConfig,sizeof(COMMCONFIG));
		delete pTempCommConfig;
		TRACE("Found profile info\n");
	}
	else
	{
		memset(m_pCommConfig,0,sizeof(COMMCONFIG));
		m_pCommConfig->dwSize = sizeof(COMMCONFIG);
		m_pCommConfig->dcb.DCBlength = sizeof(DCB);
	}	//GetInitialCommConfig();
	m_strPortName = theApp.GetProfileString("iMoteConsoleGraph","CommPort","\\\\.\\COM1");
}
void CIMoteConsoleDlg::SaveProfileInfo(void)
{
	TRACE("Saving profile info\n");
	theApp.WriteProfileBinary("iMoteConsoleGraph","CommConfig",(LPBYTE)m_pCommConfig,sizeof(COMMCONFIG));
	theApp.WriteProfileString("iMoteConsoleGraph","CommPort",m_strPortName);
	//we're closing.  If we've set any parameters in the CommConfig, we need to store in the registry	
	//we probably have some serious race conditions here....need to clean up
}
void CIMoteConsoleDlg::SaveLogEntry(CString *str)
{
	logfile<<(*str);	
}
void CIMoteConsoleDlg::SaveLogEntryToScreen(CString *str)
{
	/*outputBuffer *temp = (outputBuffer *)m_terminalList->get((LPCTSTR)m_displayedMoteComboValue);
	temp->buffer += *str;
	m_outputRichEditControl.SetWindowText(temp->buffer);*/
}


int CIMoteConsoleDlg::CreateConnectionToolBar()
{	
	//disable for now because a Dialog Box can't have a toolbar
#if 0
	if (!m_wndConnectionToolBar.CreateEx(this, TBSTYLE_FLAT, WS_CHILD | WS_VISIBLE | CBRS_TOP
		| CBRS_GRIPPER | CBRS_TOOLTIPS | CBRS_FLYBY | CBRS_SIZE_DYNAMIC))
	{
		TRACE0("Failed to create toolbar\n");
		return -1;      // fail to create
	}

	// TODO: Delete these three lines if you don't want the toolbar to be dockable
	m_wndConnectionToolBar.EnableDocking(CBRS_ALIGN_ANY);
	//DockControlBar(&m_wndConnectionToolBar);

	TBBUTTON bs;
	bs.fsState = TBSTATE_ENABLED;
	bs.fsStyle = TBSTYLE_BUTTON;
	bs.idCommand = ID_EDIT_CONNECT;
	bs.iString = -1;
	
	CToolBarCtrl *toolbarCtrl = &(m_wndConnectionToolBar.GetToolBarCtrl());
	
	bs.iBitmap = toolbarCtrl->AddBitmap(1,IDB_BITMAP_CONNECT);
	toolbarCtrl->AddBitmap(1,IDB_BITMAP_DISCONNECT);
	toolbarCtrl->AddButtons(1,&bs);
	
	//add the zoom buttons...
	bs.iBitmap= toolbarCtrl->AddBitmap(1,IDB_BITMAP_ZOOMIN);
	bs.idCommand = ID_VIEW_ZOOMIN;
	toolbarCtrl->AddButtons(1, &bs);

	bs.iBitmap= toolbarCtrl->AddBitmap(1,IDB_BITMAP_ZOOMOUT);
	bs.idCommand = ID_VIEW_ZOOMOUT;
	toolbarCtrl->AddButtons(1, &bs);
#endif
	return 1;

}
CIMoteCartesianPlot *CIMoteConsoleDlg::CreateNewView(UINT ID, UINT iMoteID, UINT channelID)
{
	CIMoteCartesianPlot *pFrame = new CIMoteCartesianPlot(&plotinfo[ID],iMoteID,channelID);
	CString NewWindowTitle;
	NewWindowTitle.Format("iMote %#X channel %d",iMoteID, channelID);
	pFrame->Create(NULL,NewWindowTitle,WS_OVERLAPPEDWINDOW|WS_VISIBLE,CFrameWnd::rectDefault,NULL,NULL,WS_EX_APPWINDOW|WS_EX_OVERLAPPEDWINDOW|WS_EX_CONTROLPARENT);
	NewWindowTitle = "Created new view for " + NewWindowTitle;
	SaveLogEntryToScreen(&NewWindowTitle);
	m_WindowArray.Add(pFrame);
	return pFrame;
}

CIMoteListDisp *CIMoteConsoleDlg::CreateNewList(UINT ID, UINT iMoteID, UINT channelID, bool bcreatenew, CIMoteListDisp *oldframe, CString headerX, CString headerY, CString headerZ)
{
	static CIMoteListDisp *storedFrame=NULL;
	CIMoteListDisp *pFrame=NULL;
	/////////////
	//  Possible Scenarios and behaviors
	//
	//	oldFrame==storeFrame==NULL.  Treat breatenew as a don't care, create the new window, store it in storeframe, return that value
    //	bcreatenew = true.			 treat other 2 as don't cares, create a new window, store it in storedFrame, return it
	//	oldFrame = nonNULL, createnew=false			 use the oldframe..don't save the state
	//  oldframe = NULL, createnew=false,			use storedFrame
	if(bcreatenew==true)
    {
			storedFrame = new CIMoteListDisp();
			CString NewWindowTitle;
			NewWindowTitle.Format("iMote Data List Display");
			storedFrame->Create(NULL,NewWindowTitle,WS_OVERLAPPEDWINDOW|WS_VISIBLE,CFrameWnd::rectDefault,NULL,NULL,WS_EX_APPWINDOW|WS_EX_OVERLAPPEDWINDOW|WS_EX_CONTROLPARENT);
			NewWindowTitle = "Created new view for " + NewWindowTitle;
			SaveLogEntryToScreen(&NewWindowTitle);
			m_WindowArray.Add(storedFrame);
	}

	if(oldframe == NULL)
	{
		//if we don't have a stored frame nor an old frame, create a new frame, store it, and use it
		if(storedFrame==NULL)
		{
			storedFrame = new CIMoteListDisp();
			CString NewWindowTitle;
			NewWindowTitle.Format("iMote Data List Display");
			storedFrame->Create(NULL,NewWindowTitle,WS_OVERLAPPEDWINDOW|WS_VISIBLE,CFrameWnd::rectDefault,NULL,NULL,WS_EX_APPWINDOW|WS_EX_OVERLAPPEDWINDOW|WS_EX_CONTROLPARENT);
			NewWindowTitle = "Created new view for " + NewWindowTitle;
			SaveLogEntryToScreen(&NewWindowTitle);
			m_WindowArray.Add(storedFrame);
		}
		pFrame = storedFrame; //in this case, used the stored frame.
	}
	else
	{
		//we have an oldframe that we want to use
		pFrame=oldframe;
	}
	
	//else we already have a framewnd, so don't create it
	pFrame->AddMote(&plotinfo[ID],iMoteID,channelID, headerX,headerY,headerZ);

	return pFrame;
}


void CIMoteConsoleDlg::AddPoint(POINT newpoint, int channelID)
{
	CPoint currentpoint;

	if(channelID >= NUMCHANNELS)
	{
		TRACE("ERROR:  Invalid channelID in AddPoint");
		return;
	}
	
	if(	smooth)
	{
		currentpoint = Filter(newpoint, channelID); 
	}
	else
	{
		currentpoint = newpoint;
	}

	if(plotinfo[channelID].pointcount == NUMPOINTS)
	{
		//need to erase the background here
		//UpdateAllViews(NULL);
		//POSITION pos = GetFirstViewPosition();
		//while (pos != NULL)
		//{
		//	CView* pView = GetNextView(pos);
			//ASSERT_VALID(pView);
			//if (pView != pSender)
			//	pView->OnUpdate(pSender, lHint, pHint);
		//	pView->Invalidate();
		//}
		plotinfo[channelID].pointcount = 0;
	}
	int pointcount = plotinfo[channelID].pointcount;

	plotinfo[channelID].x[pointcount] = currentpoint.x;
	plotinfo[channelID].y[pointcount] = currentpoint.y;
		
	plotinfo[channelID].pointcount++;
#if 0
	CString str;
	str.Format("Added point %d %d\n",currentpoint.x,currentpoint.y);
	TRACE("%d\n",currentpoint.x);
	//SaveLogEntryToScreen(&str);
#endif
#if 1
	if(plotinfo[channelID].pointcount == NUMPOINTS)
	{
		CString text;
		//should save the file information here.
		CString filename;
		filename.Format("%Xdata.mot", MoteIDs[channelID]);		
		TRACE("Saving file %s\n",filename);
		CFile file(filename,CFile::modeCreate|CFile::modeWrite|CFile::shareDenyNone);
		CArchive ar(&file,CArchive::store);
		plotinfo[channelID].Serialize(ar);
		//file.Flush();
		//file.Close();

#if 1
//this section controls the ascii data writing feature
		
		filename.Format("%Xdata.txt", MoteIDs[channelID]);	
		CFile file2(filename,CFile::modeCreate|CFile::modeNoTruncate|CFile::modeWrite|CFile::shareDenyNone);
		file2.SeekToEnd();
		text.Format("Accelerometer Data for iMote %#x\n",MoteIDs[channelID]);
		file2.Write(text,text.GetLength());
		plotinfo[channelID].SaveAscii(file2);
#endif	
		//file2.Flush();
		//file2.Close();
	}
#endif
}

CPoint CIMoteConsoleDlg::Filter(POINT newpoint, int channelID)
{
	int i;
	CPoint output(0,0);
	
	if(channelID >= NUMCHANNELS)
	{
		TRACE("ERROR:  Filter() received an invalid channel ID");
		return CPoint(-1,-1);	
	}
	
	//add the newpoint to the circular buffer
	int bufpos = plotinfo[channelID].bufpos;
	plotinfo[channelID].buffer[bufpos] = newpoint;
	plotinfo[channelID].bufpos++;
		
	if(plotinfo[channelID].bufpos == BUFLEN)
	{
			plotinfo[channelID].bufpos = 0;
	}
	
	for(i=0; i<BUFLEN; i++)
	{
		output.x += plotinfo[channelID].buffer[i].x;
		output.y += plotinfo[channelID].buffer[i].y;
	}
	output.x /= BUFLEN;
	output.y /= BUFLEN;
	
	return output;		
}
void CIMoteConsoleDlg::OnCancel()
{
	OnClose();
}

void CIMoteConsoleDlg::OnTimer(UINT nIDEvent)
{
	static int pos=0;
	POINT point;
	point.x=65536*pos/NUMPOINTS - 65536/2;
	point.y=0;
	AddPoint(point,0);
	pos++;
	pos=pos%NUMPOINTS;

	CDialog::OnTimer(nIDEvent);
}

void CIMoteConsoleDlg::OnEditTest()
{
	static UINT_PTR nTimerID=0;

	if(nTimerID==0)
	{
		nTimerID=SetTimer(1,10,0);
	}
	else
	{
		KillTimer(nTimerID);
		nTimerID=0;
	}
}



long int m_qtd = 0;     /* offset in qtable to get ctable */
long int m_width = CM_SZR_OUT_W;        /* width in pixels */
long int m_height = CM_SZR_OUT_H;       /* height in pixels */
long int m_width_still = CM_SZR_OUT_W;  /* width in pixels */
long int m_height_still = CM_SZR_OUT_H; /* height in pixels */
/* W A R N I N G ---- The jpeg mode is set here but it really depends upon the
   settings in the VIDEO and STILL configuration registers.  In a future 
   revision, this information will be passed in as a parameter */
int jpeg_mode = 1;                      /* jpeg compression 0 = grey, 1 = 444, 2=422 */


void CIMoteConsoleDlg::BuildJPG(unsigned char *jpeg_data, int length, unsigned char *whole_jpg, int *whole_jpg_len)
{
    unsigned char Yqtable = jpeg_data[4];
    unsigned char Cqtable = Yqtable + (unsigned char)m_qtd;  // add qtable delta to Yqtable to get Cqtable

    unsigned char *Yqtable_ptr  = qtable_list[Yqtable];
    unsigned char *Cqtable_ptr  = qtable_list[Cqtable];

    int header_length;
    BYTE *header;
    int height, width;
	int grayscale = 0;

    width  = m_width;

    width  = m_width;
    height = m_height;

    if ( 0x50 == jpeg_data[0]) {
        width  = m_width_still;
        height = m_height_still;
    }

    if (0 == jpeg_mode) {
        // grayscale

        // copy table to header
        memcpy(header_gray.QTABLE0 + 5, Yqtable_ptr, 64);

        // set image size in header
        //
        header_gray.SOF0[5] = (height >> 8) & 0xff;
        header_gray.SOF0[6] = (height) & 0xff;
        header_gray.SOF0[7] = (width >> 8) & 0xff;
        header_gray.SOF0[8] = (width) & 0xff;

        header = (UCHAR *) &header_gray;
        header_length = sizeof(header_gray);
    }
    else if (0x1 == jpeg_mode) {
        // 444


        // copy tables to header
        memcpy(header_4xx.QTABLE0 + 5, Yqtable_ptr, 64);
        memcpy(header_4xx.QTABLE1 + 5, Cqtable_ptr, 64);
        memcpy(header_4xx.QTABLE2 + 5, Cqtable_ptr, 64);

        // set image size in header
        //
        header_4xx.SOF0[5] = (height >> 8) & 0xff;
        header_4xx.SOF0[6] = (height) & 0xff;
        header_4xx.SOF0[7] = (width >> 8) & 0xff;
        header_4xx.SOF0[8] = (width) & 0xff;

        header_4xx.SOF0[11] = 0x11;   // 444

        header = (UCHAR *) &header_4xx;
        header_length = sizeof(header_4xx);
    } else if (0x2 == jpeg_mode) {
        // 422
        // copy tables to header
        memcpy(header_4xx.QTABLE0 + 5, Yqtable_ptr, 64);
        memcpy(header_4xx.QTABLE1 + 5, Cqtable_ptr, 64);
        memcpy(header_4xx.QTABLE2 + 5, Cqtable_ptr, 64);

        // set image size in header
        //
        header_4xx.SOF0[5] = (height >> 8) & 0xff;
        header_4xx.SOF0[6] = (height) & 0xff;
        header_4xx.SOF0[7] = (width >> 8) & 0xff;
        header_4xx.SOF0[8] = (width) & 0xff;

        header_4xx.SOF0[11] = 0x21;   // 422

        header = (UCHAR *) &header_4xx;
        header_length = sizeof(header_4xx);
    }
    else {
        return;
    }

    length = length - 7;  // subtract leading 5 bytes & trailing status byte
//    length = length - 5;  // subtract leading 5 bytes & trailing status byte


    // build image
    //

    memcpy(whole_jpg,header,header_length);
    memcpy(whole_jpg+header_length,jpeg_data+5,length);

	*whole_jpg_len = header_length + length;	/* global variable write */
}


void CIMoteConsoleDlg::OnViewSmooth()
{
	smooth=!smooth;
}

void CIMoteConsoleDlg::OnUpdateViewSmooth(CCmdUI *pCmdUI)
{
	pCmdUI->SetCheck((smooth==false)? 0:1);	
}

void CIMoteConsoleDlg::OnEditTestnewlist()
{
	
	static int pos=0,currentChannel=0;
	int i;
	POINT point;
	MoteIDs[currentChannel] = 0x66+currentChannel;
	if(currentChannel>= NUMCHANNELS)
		return;
	for(i=0;i<NUMPOINTS;i++)
	{
		point.x=65536*i/NUMPOINTS - 65536/2;
		point.y=0;
		AddPoint(point,currentChannel);
	}
	plotinfo[currentChannel].SetValidMask(TIMESTAMP_VALID|X_VALID|Y_VALID|Z_VALID);
	pos+=i;
	CIMoteListDisp *pFrame=CreateNewList(currentChannel,0x85000+currentChannel,1,false,NULL,"temp","hum");
	currentChannel++;
}

void CIMoteConsoleDlg::OnDisplayChange()
{
	UpdateData();
	char *strtemp = (char *)malloc(m_displayedMoteComboControl.GetLBTextLen(m_displayedMoteComboControl.GetCurSel()) + 1);
	m_displayedMoteComboControl.GetLBText(m_displayedMoteComboControl.GetCurSel(), strtemp);
	CIMoteTerminal *temp = (CIMoteTerminal *)m_terminalList->get(strtemp);
	free(strtemp);
	if(temp == NULL)
		return;
	if(temp->m_usb == NULL){ //serial device
		m_detachedStatic.ShowWindow(SW_HIDE);
		m_comNumStatic.ShowWindow(SW_SHOW);
	}
	else{
		if(temp->isAttached())
			m_detachedStatic.ShowWindow(SW_HIDE);
		else
			m_detachedStatic.ShowWindow(SW_SHOW);
		m_comNumStatic.ShowWindow(SW_HIDE);
	}
}
BOOL CIMoteConsoleDlg::OnDeviceChange(UINT nEventType, DWORD_PTR dwData){
	if(nEventType == DBT_DEVICEARRIVAL || nEventType == DBT_DEVICEREMOVECOMPLETE){
		PopulateUSBDevices();
		m_terminalList->map(displayChange, NULL);
		OnDisplayChange();
	}
	return TRUE;
}
void CIMoteConsoleDlg::OnInitMenuPopup(CMenu *pPopupMenu, UINT nIndex,BOOL bSysMenu)
{
    ASSERT(pPopupMenu != NULL);
    // Check the enabled state of various menu items.

    CCmdUI state;
    state.m_pMenu = pPopupMenu;
    ASSERT(state.m_pOther == NULL);
    ASSERT(state.m_pParentMenu == NULL);

    // Determine if menu is popup in top-level menu and set m_pOther to
    // it if so (m_pParentMenu == NULL indicates that it is secondary popup).
    HMENU hParentMenu;
    if (AfxGetThreadState()->m_hTrackingMenu == pPopupMenu->m_hMenu)
        state.m_pParentMenu = pPopupMenu;    // Parent == child for tracking popup.
    else if ((hParentMenu = ::GetMenu(m_hWnd)) != NULL)
    {
        CWnd* pParent = this;
           // Child windows don't have menus--need to go to the top!
        if (pParent != NULL &&
           (hParentMenu = ::GetMenu(pParent->m_hWnd)) != NULL)
        {
           int nIndexMax = ::GetMenuItemCount(hParentMenu);
           for (int nIndex = 0; nIndex < nIndexMax; nIndex++)
           {
            if (::GetSubMenu(hParentMenu, nIndex) == pPopupMenu->m_hMenu)
            {
                // When popup is found, m_pParentMenu is containing menu.
                state.m_pParentMenu = CMenu::FromHandle(hParentMenu);
                break;
            }
           }
        }
    }

    state.m_nIndexMax = pPopupMenu->GetMenuItemCount();
    for (state.m_nIndex = 0; state.m_nIndex < state.m_nIndexMax;
      state.m_nIndex++)
    {
        state.m_nID = pPopupMenu->GetMenuItemID(state.m_nIndex);
        if (state.m_nID == 0)
           continue; // Menu separator or invalid cmd - ignore it.

        ASSERT(state.m_pOther == NULL);
        ASSERT(state.m_pMenu != NULL);
        if (state.m_nID == (UINT)-1)
        {
           // Possibly a popup menu, route to first item of that popup.
           state.m_pSubMenu = pPopupMenu->GetSubMenu(state.m_nIndex);
           if (state.m_pSubMenu == NULL ||
            (state.m_nID = state.m_pSubMenu->GetMenuItemID(0)) == 0 ||
            state.m_nID == (UINT)-1)
           {
            continue;       // First item of popup can't be routed to.
           }
           state.DoUpdate(this, TRUE);   // Popups are never auto disabled.
        }
        else
        {
           // Normal menu item.
           // Auto enable/disable if frame window has m_bAutoMenuEnable
           // set and command is _not_ a system command.
           state.m_pSubMenu = NULL;
           state.DoUpdate(this, FALSE);
        }

        // Adjust for menu deletions and additions.
        UINT nCount = pPopupMenu->GetMenuItemCount();
        if (nCount < state.m_nIndexMax)
        {
           state.m_nIndex -= (state.m_nIndexMax - nCount);
           while (state.m_nIndex < nCount &&
            pPopupMenu->GetMenuItemID(state.m_nIndex) == state.m_nID)
           {
            state.m_nIndex++;
           }
        }
        state.m_nIndexMax = nCount;
    }
}
BOOL CIMoteConsoleDlg::DoRegisterDeviceInterface(GUID InterfaceClassGuid, HDEVNOTIFY *hDevNotify)
/*
Routine Description:
    Registers for notification of changes in the device interfaces for
    the specified interface class GUID. 

Parameters:
    InterfaceClassGuid - The interface class GUID for the device 
        interfaces. 

    hDevNotify - Receives the device notification handle. On failure, 
        this value is NULL.

Return Value:
    If the function succeeds, the return value is TRUE.
    If the function fails, the return value is FALSE.
*/

{
    DEV_BROADCAST_DEVICEINTERFACE NotificationFilter;
    char szMsg[80];

    ZeroMemory( &NotificationFilter, sizeof(NotificationFilter) );
    NotificationFilter.dbcc_size = 
        sizeof(DEV_BROADCAST_DEVICEINTERFACE);
    NotificationFilter.dbcc_devicetype = DBT_DEVTYP_DEVICEINTERFACE;
    NotificationFilter.dbcc_classguid = InterfaceClassGuid;

	*hDevNotify = RegisterDeviceNotification( m_hWnd, 
        &NotificationFilter,
        DEVICE_NOTIFY_WINDOW_HANDLE
    );

    if(!*hDevNotify) 
    {
        wsprintf(szMsg, "RegisterDeviceNotification failed: %d\n", 
                GetLastError());
        MessageBox(szMsg, "Registration", MB_OK);        
        return FALSE;
    }

    return TRUE;
}

void CIMoteConsoleDlg::BufferAppend(char x){
	UpdateData();
	((CIMoteTerminal *)m_terminalList->get((LPCTSTR)m_displayedMoteComboValue))->BufferAppend(x);
}
void CIMoteConsoleDlg::BufferAppend(CIMoteTerminal *term, char x){
	term->BufferAppend(x);
}

void CIMoteConsoleDlg::BufferAppend(CIMoteTerminal *term, CString x){
	term->BufferAppend(x);
}
void CIMoteConsoleDlg::BufferAppend(CIMoteTerminal *term, char * y){
	term->BufferAppend(y);
}
void CIMoteConsoleDlg::OnBnClickedButtonWindowBuffer(){
	UpdateData();
	((CIMoteTerminal *)m_terminalList->get((LPCTSTR)m_displayedMoteComboValue))->ShowWindow(SW_SHOW);

}

void CIMoteConsoleDlg::OnHelpAbout(){
	CAboutDlg dlgAbout;
	dlgAbout.DoModal();
}
