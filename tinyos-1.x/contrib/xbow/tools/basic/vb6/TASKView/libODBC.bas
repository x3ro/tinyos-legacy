Attribute VB_Name = "libODBC"
''====================================================================
'' libODBC.bas
''====================================================================
'' DESCRIPTION:  This library provides the low-level ODBC API
''               by exposing direct DLL calls to Visual Basic.
''
'' HISTORY:      mturon      2004/2/11    Initial revision
''
'' $Id: libODBC.bas,v 1.4 2004/03/29 23:07:55 mturon Exp $
''====================================================================

'19.1
Option Explicit
'
' ODBC API Declarations
'

'
'basic ODBC Declares
Declare Function SQLAllocEnv Lib "ODBC32.DLL" (env As Long) As Integer

Declare Function SQLFreeEnv Lib "ODBC32.DLL" (ByVal env As Long) As Integer

Declare Function SQLAllocConnect Lib "ODBC32.DLL" (ByVal env As Long, _
 hDbc As Long) As Integer
 
Declare Function SQLConnect Lib "ODBC32.DLL" (ByVal env As Long, _
 ByVal Server As String, ByVal serverlen As Integer, _
 ByVal uid As String, ByVal uidlen As Integer, ByVal pwd As String, _
 ByVal pwdlen As Integer) As Integer
 
Declare Function SQLFreeConnect Lib "ODBC32.DLL" (ByVal hDc As Long) _
 As Integer

Declare Function SQLDisconnect Lib "ODBC32.DLL" (ByVal hDc As Long) _
 As Integer
 
Declare Function SQLAllocStmt Lib "ODBC32.DLL" (ByVal hDc As Long, _
 hStmt As Long) As Integer
 
Declare Function SQLFreeStmt Lib "ODBC32.DLL" (ByVal hStmt As Long, _
 ByVal EndOption As Integer) As Integer
 
Declare Function SQLExecDirect Lib "ODBC32.DLL" (ByVal hStmt As Long, _
 ByVal sqlString As String, ByVal sqlstrlen As Long) As Integer

Declare Function SQLNumResultCols Lib "ODBC32.DLL" (ByVal hStmt As Long, _
 NumCols As Integer) As Integer
 
Declare Function SQLRowCount Lib "ODBC32.DLL" (ByVal hStmt As Long, _
 NumRows As Integer) As Integer
 
Declare Function SQLFetch Lib "ODBC32.DLL" (ByVal hStmt As Long) As Integer

Declare Function SQLSetPos Lib "ODBC32.DLL" (ByVal hStmt As Long, _
 ByVal RowNumber As Integer, ByVal Operation As Integer, _
 ByVal LockType As Integer) As Integer

Declare Function SQLGetData Lib "ODBC32.DLL" (ByVal hStmt As Long, _
 ByVal col As Integer, ByVal wConvType As Integer, ByVal lpbBuf As String, _
 ByVal dwbuflen As Long, lpcbout As Long) As Integer
 
Declare Function sqlError Lib "ODBC32.DLL" Alias "SQLError" (ByVal env As _
 Long, ByVal hDbc As Long, ByVal hStmt As Long, ByVal SQLState As _
 String, NativeError As Long, ByVal Buffer As String, ByVal BufLen As _
 Integer, OutLen As Integer) As Integer
 
Declare Function SQLSetConnectOption Lib "ODBC32.DLL" (ByVal hDbc&, _
 ByVal fOption%, ByVal vParam&) As Integer
 
Declare Function SQLSetStmtOption Lib "ODBC32.DLL" (ByVal hStmt&, _
 ByVal fOption%, ByVal vParam&) As Integer
 
Declare Function SQLTables Lib "ODBC32.DLL" (ByVal hStmt&, _
 ByVal CatalogName$, ByVal CatalogNameLength%, ByVal SchemaName$, _
 ByVal SchemaNameLength%, ByVal TableName$, ByVal TableNameLength%, _
 ByVal TableType$, ByVal TableTypeLength%) As Integer
 
Declare Function SQLDescribeCol Lib "ODBC32.DLL" (ByVal hStmt As Long, _
  ByVal ColumnNumber As Integer, ByRef ColumnName As String, _
  ByVal BufferLength As Integer, ByRef NameLengthPtr As Integer, _
  ByRef DataTypePtr As Integer, ByRef ColumnSizePtr As Integer, _
  ByRef DecimalDigitsPtr As Integer, ByRef NullablePtr As Integer) As Integer
   
Declare Function SQLColAttribute Lib "ODBC32.DLL" (ByVal hStmt As Long, _
  ByVal ColumnNumber As Integer, ByVal FieldIdentifier As Integer, _
  CharacterAttributePtr As String, ByVal BufferLength As Integer, _
  StringLengthPtr As Integer, NumericAttributePtr As Integer) As Integer
         

'19.2
'
' misc constants
Public Const sqlChar = 1
Public Const sqlMaxMsgLen = 512
Public Const sqlFetchNext = 1
Public Const sqlFetchFirst = 2
Public Const sqlStillExecuting = 2
Public Const sqlODBCCursors = 110
Public Const sqlConcurrency = 7
Public Const sqlCursorType = 6
Public Const SQL_DESC_BASE_COLUMN_NAME = 22


'following structure is filled after reading the .cfg file
Public Const MAX_SENSORS = 32
Public Const MAX_MOTES = 256
Public Const MAX_QUERIES = 1024

Public Const MOTE_NO_PARENT = 65535 '&HFFFF

Public Type stTaskInfo
    nmb_motes As Integer                'number of mote in the task_info db
    mote_id(MAX_MOTES) As Integer       'mote id of each mote
'    mote_xcord(MAX_MOTES) As Integer    'x coordinate of mote on map picture
'    mote_ycord(MAX_MOTES) As Integer    'y coordinate of mote on map picture
'    mote_calib(MAX_MOTES) As Variant    'calibration constants for mote sensors
    nmb_sensors As Integer              '# of different sensor readings from database
    sensor(1 To MAX_SENSORS) As String  'name of sensor (same order as in .cfg file
    DataTimeStart As Date               'time of earliest sample in database
    DataTimeEnd As Date                 'latest time of data in database
                                        'total test time is DataTimeM + DataTimeD + DataTimeH
    DataTimeW As Integer                'test time duration, weeks
    DataTimeD As Integer                'test time duration, days
    DataTimeH As Integer                'test time duration, hrs
    GraphPlotStartTime As Date          ' History Sample start
    GraphPlotEndTime As Date            ' History Sample end
End Type

Public TaskInfo As stTaskInfo


Public Type stSensorInfoTable
    sensorName As String
    sensorDesc As String
    bGridSelected As Boolean
    bPlotSelected As Boolean
End Type
Public SensorInfoTable(1 To MAX_SENSORS) As stSensorInfoTable

Public Type stNodeInfoTable
    nodeid As Integer
    bGraphSelected As Boolean
End Type
Public NodeInfoTable(0 To MAX_MOTES - 1) As stNodeInfoTable

'
' Interface to send data to graphics client
'
Public Type stTaskDataGrid
    Value(1 To MAX_SENSORS) As Long  'data for each sensor in query
    Time As String
End Type

Public TaskDataArray(1 To 256) As stTaskDataGrid


Public Type stQuery
    TaskInfoDB As String              'name of dbase where mote id,position.... stored
    TaskDataDB As String              'name of dbase for data
    TaskQueryString As String         'string for query
    TaskLastQueryTime As Date         ' max(result_time) of last query to speed up
                                      ' subsequent queries
    bDebugLiveUpdates As Boolean      ' To test live updates from stored table
    TaskActualEndTime As Date         ' Actual End Time saved while testing
                                      ' live updates by faking EndTime
End Type
Public TaskDBCfg As stQuery

Public TotalSensors As Integer

Public bNotFirstTime As Boolean

Public Type stQueryInfo
    QueryName As String
    SensorList As String            'Comma delimited. For array use Split()
    Selection As Integer            'Sensor selected bit field relative to local
    SamplePeriod As String
End Type

Public QueryList() As stQueryInfo
Public QuerySelected As Integer

Public g_DatabaseList() As String

