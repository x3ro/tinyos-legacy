Attribute VB_Name = "basDynLib"
'==============================================================================
'Module Description:
'
'==============================================================================

'******************************************************************************
' DLL interfaces:
'******************************************************************************
Public Declare Function FLOAT2BYTES Lib "dynlib.dll" _
    (ByVal f As Single, ByRef lb1 As Long, ByRef lb2 As Long, ByRef lb3 As Long, _
    ByRef lB4 As Long) As Long

Public Declare Function BYTES2FLOAT Lib "dynlib.dll" _
    (ByRef f As Single, ByVal lb1 As Long, ByVal lb2 As Long, ByVal lb3 As Long, _
    ByVal lB4 As Long) As Long
'Shift left and right functions
Public Declare Function LSHFTL Lib "dynlib.dll" (ByVal wIn As Long, ByVal iBits As Integer) As Long
Public Declare Function LSHFTR Lib "dynlib.dll" (ByVal wIn As Long, ByVal iBits As Integer) As Long
Public Declare Function WSHFTL Lib "dynlib.dll" (ByVal wIn As Integer, ByVal iBits As Integer) As Integer
Public Declare Function WSHFTR Lib "dynlib.dll" (ByVal wIn As Integer, ByVal iBits As Integer) As Integer
'******************************************************************************
'global grid display constants
Public Const COLOR_DEF = &HFF8080              'Grid, default bckground color
Public Const COLOR_COMM_OPEN = &HC000&         'comm port open
Public Const COLOR_NO_RESPONSE = &HFF&         'Grid, no status cmd response color
Public Const COLOR_SAMPLING = &H80FF80         'Grid, sampling color
Public Const COLOR_LOGGING = &HC000&           'Grid, logging color
Public Const COLOR_IDLE = &HFFFF&              'Grid, idle color
Public Const COLOR_DARK_BLUE = &HFF0000
'==============================================================================
'global mote constants
Public Const MAX_MOTES = 32                   'maximum number of Motes allowed in network
Public Const ID_BASE_STATION = 126             'mote id for base station
Public Const MAX_MSG_INTRVL = 9998             'max time interval between mote msgs

Public Const TIME_UPDATE_GRID = 60000         '# of msec between grid updates
Public Const TIME_LIVE_UPDATE_GRID = 500      '# of msec between grid updates
Public Const DEBUG_TIME_UPDATE_GRID = 10000

'==============================================================================
'==============================================================================

'==============================================================================
Public g_MoteGroupId As Byte       'mote group_id
Public g_MoteCount As Integer      'number of motes, including base station

'==============================================================================
'global for data display
Public g_NmbDataTypes              'number of data types (ex RH%,Temp...) to display

'==============================================================================
'globals for routing map
Public g_MapFileName As String        'name of .bmp file to load for map
Public g_MapChanged As Boolean        'set when new .bmp file needs to load
Public g_map_width As Integer         'width of map, user values
Public g_map_height As Integer        'height of map, user values
Public g_map_screen_width As Integer  'size of map screen width
Public g_map_screen_height As Integer 'heigth of map screen
'==============================================================================
 
'enum for graph and file data arrays
Enum DArrIndx
  XIDX = 1
  YIDX = 2
  ZIDX = 3
  TIDX = 4
End Enum

'Public Mote_Group_Id As Byte              'Group ID of motes, basestation only talks a specific group
Public mote_id As Byte                    'Unique ID of mote (1-255)

'struc used for elapsed time
Type ETimeType
    Days As Integer
    Hrs As Integer
    Min As Integer
    Sec As Single
    fTimeTotal As Double            'total elapsed time
End Type
'------------------------------------------------------------------------------
' grid table configuration
' the following structure contains all of the info needed to init and control
' the grid tables

Public Const MAX_NMB_COLS = 40               'Max # of columns in grid display
Public Const MAX_NMB_ROWS = 60               'Max # of rows in grid display
Public Const MAX_TEXT_BOXES = 4              'Max text boxes that can be displayed on form

Public Const MAX_GRAPHS = 4
Public Const MAX_PLOTS = 12                 ' Max number of plots for Charts
Public Const MAX_NODE_COLORS = 18           ' Max number of plots for Charts


'structure for MSFlexGrid or other grid control
Public Type stGrid
   GridObj As Object                   'Grid display object to configure
   bDsplyMoteId As Boolean             'true => dsply mote_ids on column 0
   iNmbCols As Integer                 'number of columns
   iNmbRows As Integer                 'number of rows
   iColWidth(MAX_NMB_COLS) As Integer   'column size for each column
   sHdr1Name(MAX_NMB_COLS) As String   'column names for the 1st hdr row
   sHdr2Name(MAX_NMB_COLS) As String   'column names for the 2nd hdr row
   iRowData As Integer                 'row value for data
   sDataVal(MAX_NMB_COLS) As String    'column values
'Text Box Display
   TxtBox As Object                      'text box object
   BoxLbl As Object                      'lable box oject
   iTxtBox As Integer                    '# of text boxes to display on form
   iTxtBoxLbl(MAX_TEXT_BOXES) As String  'label for each text box on form
   iTxtBoxData(MAX_TEXT_BOXES) As String 'data for each text box in form
'Graph Display
   Graph As Object                       'the graph object on the form
   sXAxisLable As String                 'X Axis Lable
   sYaxisLable As String                 'Y Axis Lable
   bAutoScale As Boolean                 'true if autoscale graph
   GraphMin As Variant                   'min Y value
   GraphMax As Variant                   'max Y value
End Type

'---------------------------------------------------------------------------------
'Task Data Base
Public objSQL As Object

'Public gNumPlots As Integer
'Public gNumGraphs As Integer
Public gColors(1 To MAX_NODE_COLORS) As Long

'Public gsSensorSelected As String

Public Type stSensorHistoryList
    sensorName As String
    numPlots As Integer
    nodeIds(1 To MAX_PLOTS) As Integer
End Type
Public SensorHistoryList(1 To MAX_GRAPHS) As stSensorHistoryList

Public Type stTaskHistoryData
    Value() As Single
    Time() As Date
End Type
Public TaskHistoryData As stTaskHistoryData

Public g_dbTimeScaledValues(1 To 100) As Double






