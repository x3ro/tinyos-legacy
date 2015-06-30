VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "objODBC"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
''====================================================================
'' objODBC.cls
''====================================================================
'' DESCRIPTION:  The ODBC object supplies utility functions for
''               drawing data from the TASK database.
''
'' HISTORY:      mturon      2004/2/11    Initial revision
''
'' $Id: objODBC.cls,v 1.5 2004/03/31 06:51:28 mturon Exp $
''====================================================================

'19.3
'Option Explicit
'
'
Private Const BUFFERLEN = 256

'
' sql lock types
Public Enum sqlLockType
  sqlreadonly = 1
  sqllock = 2
  sqlrowver = 3
  sqlValues = 4
End Enum

'
' sql cursor drivers
Public Enum sqlCursorDriverType
  sqluseifneeded = 0
  sqlUseODBC = 1
  sqlUseDriver = 2
End Enum

'
' cursor types
Public Enum sqlResultSetType
  sqlforwardonly = 0
  sqlKeyset = 1
  sqlDynamic = 2
  sqlStatic = 3
End Enum

'
' sqlerror type
Public Enum sqlErrorType
  sqlSuccess = 0
  sqlSuccessWithInfo = 1
  sqlErr = -1
  sqlNoDataFound = 100
End Enum

Public Enum sqlStatement
  sqlClose = 0
  sqlDrop = 1
  sqlUnbind = 2
  sqlResetParams = 3
End Enum

' shared ODBC handle properties:
Public henv As Long
Public hDbc As Long
Public hStmt As Long
Public NumCols As Integer

'
' shared storage for properties
Private strDataSource As String
Private strDBName As String
Private strDBTable As String
Private strDBServer As String
Private strUserID As String
Private strPassword As String
Private strSQL As String
Private intRecordCount As Integer
Private strTable As String
Private strKey As String
Private intCursorDriver As Integer
Private intLockType As Integer
Private intResultSetType As Integer

'internal use
Dim intRecNum As Integer

'19.4
Public Property Get DataSource() As Variant
    DataSource = strDataSource
End Property

Public Property Let DataSource(ByVal vNewValue As Variant)
    strDataSource = vNewValue
End Property

Public Property Get DBName() As Variant
    DBName = strDBName
End Property

Public Property Let DBName(ByVal vNewValue As Variant)
    strDBName = vNewValue
End Property

Public Property Get DBTable() As Variant
    DBTable = strDBTable
End Property

Public Property Let DBTable(ByVal vNewValue As Variant)
    If StrComp(vNewValue, strDBTable) <> 0 Then
        ' If table name has changed, update the selection index
        For i = 1 To UBound(QueryList)
            If StrComp(vNewValue, QueryList(i).QueryName) = 0 Then
                QuerySelected = i
                Exit For
            End If
        Next
    End If
    
    strDBTable = vNewValue
End Property

Public Property Get DBServer() As Variant
    DBServer = strDBServer
End Property

Public Property Let DBServer(ByVal vNewValue As Variant)
    strDBServer = vNewValue
End Property

Public Property Get UserID() As Variant
    UserID = strUserID
End Property

Public Property Let UserID(ByVal vNewValue As Variant)
    strUserID = vNewValue
End Property

Public Property Get Password() As Variant
    Password = strPassword
End Property

Public Property Let Password(ByVal vNewValue As Variant)
    strPassword = vNewValue
End Property

Public Property Get RecordCount() As Variant
    RecordCount = intRecordCount
End Property

Public Property Let RecordCount(ByVal vNewValue As Variant)
    ' na
End Property

Public Property Get SQL() As Variant
    SQL = strSQL
End Property

Public Property Let SQL(ByVal vNewValue As Variant)
    strSQL = vNewValue
End Property

Public Property Get Table() As Variant
    Table = strTable
End Property

Public Property Let Table(ByVal vNewValue As Variant)
    strTable = vNewValue
End Property

Public Property Get Key() As Variant
    Key = strKey
End Property

Public Property Let Key(ByVal vNewValue As Variant)
    strKey = vNewValue
End Property

Public Property Get CursorDriver() As sqlCursorDriverType
    CursorDriver = intCursorDriver
End Property

Public Property Let CursorDriver(ByVal vNewValue As sqlCursorDriverType)
    intCursorDriver = vNewValue
End Property

Public Property Get LockType() As sqlLockType
    LockType = intLockType
End Property

Public Property Let LockType(ByVal vNewValue As sqlLockType)
    intLockType = vNewValue
End Property

Public Property Get ResultSetType() As sqlResultSetType
    ResultSetType = intResultSetType
End Property

Public Property Let ResultSetType(ByVal vNewValue As sqlResultSetType)
    intResultSetType = vNewValue
End Property

' 19.5
Private Sub Class_Initialize()
    '
    ' init properties
    '
    strDataSource = ""
    strDBServer = ""
    strDBName = ""
    strDBTable = ""
    strUserID = ""
    strPassword = ""
    strSQL = ""
    intRecordCount = 0
    intCursorDriver = sqlforwardonly
    intLockType = sqlreadonly
    '
End Sub

' 19.6
Private Function AllocateEnv()
    '
    ' Allocate an ODBC environment handle
    ' Stores result to hEnv property
    '
    Dim intResult As Integer
    '
    intResult = SQLAllocEnv(henv)
    '
    If intResult <> sqlSuccess Then
        Err.Raise vbObjectError + 1, App.EXEName, "Cannot allocate Environment handle"
    End If
    '
    AllocateEnv = sqlSuccess
    '
End Function

'19.7
Public Function Connect() As Integer
    '
    ' Allocates and establishes connection
    ' to DataSource stored in DataSource property
    '
    Dim intResult As Integer
    '
    AllocateEnv
    '
    ' Allocate connection handle:
    intResult = SQLAllocConnect(henv, hDbc)
    If intResult <> sqlSuccess Then
        Err.Raise vbObjectError + 3, App.EXEName, "Unable to allocate connection handle"
        Connect = intResult
        Exit Function
    End If
    '
    ' Set Cursor Driver
    intResult = SQLSetConnectOption(hDbc, sqlODBCCursors, intCursorDriver)
    If intResult <> sqlSuccess Then
        sqlErrorMsg "Error Setting CursorDriver"
        Exit Function
    End If
    '
    'Login to data source
    intResult = SQLConnect(hDbc, strDataSource, Len(strDataSource), strUserID, _
                            Len(strUserID), strPassword, Len(strPassword))
    If intResult <> sqlSuccess And intResult <> sqlSuccessWithInfo Then
        sqlErrorMsg "Unable to connect to DataSource [" & strDataSource & "]"
        Connect = intResult
        Exit Function
    End If
    '
    ' Allocate statement handle
    intResult = SQLAllocStmt(hDbc, hStmt)
    If intResult <> sqlSuccess Then
        sqlErrorMsg "Unable to allocate statement handle"
        Connect = intResult
        Exit Function
    End If
    '
    ' set cursor type (result set)
    intResult = SQLSetStmtOption(hStmt, sqlCursorType, intResultSetType)
    If intResult <> sqlSuccess Then
        sqlErrorMsg "Error Setting ResultSetType"
        Exit Function
    End If
    '
    'set locktype
    intResult = SQLSetStmtOption(hStmt, sqlConcurrency, intLockType)
    If intResult <> sqlSuccess Then
        sqlErrorMsg "Error Setting LockType"
        Exit Function
    End If
    Connect = sqlSuccess
    '
End Function

' 19.8
Public Function Disconnect()
    '
    ' disconnect from data source
    '
    Dim intResult As Integer
    '
    ' Deallocate statement handle:
    If hStmt <> 0 Then
        intResult = SQLFreeStmt(hStmt, sqlDrop)
        If intResult <> sqlSuccess Then
            Err.Raise vbObjectError + 6, App.EXEName, "Unable to free statement handle"
            Disconnect = intResult
        End If
    End If
    '
    ' Disconnect
    If hDbc <> 0 Then
        intResult = SQLDisconnect(hDbc)
        If intResult <> sqlSuccess Then
            Err.Raise vbObjectError + 7, App.EXEName, " Unable to disconnect from data source"
            Disconnect = intResult
        End If
    End If
    '
    ' Deallocate connection handle
    If hDbc <> 0 Then
        intResult = SQLFreeConnect(hDbc)
        If intResult <> sqlSuccess Then
            Err.Raise vbObjectError + 8, App.EXEName, "Unable to deallocate statement handle"
            Disconnect = intResult
        End If
    End If
    '
    DeallocateEnv
    '
    Disconnect = sqlSuccess
    '
End Function

Public Function Reconnect()
    Disconnect
    Connect
    
    MoteTableReset
    
    QueryMoteInfo
    GetDatabaseList
    'GetTableNames
    GetSensorNames
    GetQueryList
End Function

Public Function Reset() As Boolean
    Reset = False   ' Hopefully, most resets can be avoided.

    ' Get current server / database, and compare
    Dim tempText As String
    
    tempText = RegRead(HKEY_CURRENT_USER, _
        "Software\ODBC\ODBC.INI\PostgreSQL30", "Servername", "")
    If StrComp(tempText, objSQL.DBServer) <> 0 Then
        ' If our database name has changed, forward that to the registry,
        ' reconnect to the new DB, and return that this is a TRUE reset.
        RegWrite HKEY_CURRENT_USER, _
            "Software\ODBC\ODBC.INI\PostgreSQL30", "Servername", _
            REG_SZ, objSQL.DBServer
        Reset = True
    End If
        
    tempText = RegRead(HKEY_CURRENT_USER, _
        "Software\ODBC\ODBC.INI\PostgreSQL30", "Database", "")
    If StrComp(tempText, objSQL.DBName) <> 0 Then
        ' If our database name has changed, forward that to the registry,
        ' reconnect to the new DB, and return that this is a TRUE reset.
        RegWrite HKEY_CURRENT_USER, _
            "Software\ODBC\ODBC.INI\PostgreSQL30", "Database", _
            REG_SZ, objSQL.DBName
        Reset = True
    End If

    Reconnect
End Function

'19.9
Private Function DeallocateEnv()
    '
    ' Frees specified env handle
    ' clears stored in hEnv property
    '
    Dim intResult As Integer
    '
    If henv <> 0 Then
        intResult = SQLFreeEnv(henv)
        If intResult <> sqlSuccess Then
            Err.Raise vbObjectError + 2, App.EXEName, "Unable to free environment handle"
            DeallocateEnv = intResult
            Exit Function
        End If
    End If
    '
    DeallocateEnv = sqlSuccess
    '
End Function

' 19.10
Public Sub sqlErrorMsg(strMsg As String)
    '
    'report detailed SQL Error
    '
    Dim strSQLState As String * 16
    Dim strErrorMsg As String * sqlMaxMsgLen
    Dim intErrorMsgLen As Integer
    Dim intOutLen As Integer
    '
    Dim lngErrCode As Long
    Dim strErrCode As String
    Dim intResult As Integer
    Dim intTemp As Integer
    '
    Do
        intResult = sqlError(henv, hDbc, hStmt, strSQLState, lngErrCode, strErrorMsg, Len(strErrorMsg), intErrorMsgLen)
        If intResult = sqlSuccess Or intResult = sqlSuccessWithInfo Then
            If intErrorMsgLen = 0 Then
                Err.Raise vbObjectError + 9, App.EXEName, "Success or SuccessWithInfo Error"
            Else
                If lngErrCode = 0 Then
                    strErrCode = ""
                Else
                    strErrCode = Trim(CStr(lngErrCode)) & " "
                End If
                Err.Raise vbObjectError + 10, App.EXEName, "<" & strMsg & "> " & strErrCode & Left(strErrorMsg, intErrorMsgLen)
            End If
        End If
    Loop Until intResult <> sqlSuccess
    '
End Sub

' 19.12
Public Function ExecDirect()
    '
    'perform an SQL statement
    '
    Dim intResult As Integer
    '
    ' clear any in-process stuff
    If hStmt <> 0 Then
        intResult = SQLFreeStmt(hStmt, sqlClose)
        intResult = SQLFreeStmt(hStmt, sqlUnbind)
        intResult = SQLFreeStmt(hStmt, sqlResetParams)
    End If
    '
    If intResult <> sqlSuccess Then
        ExecDirect = intResult
        Err.Raise vbObjectError + 11, App.EXEName, "Error freeing old statement handle"
        intResult = SQLFreeStmt(hStmt, sqlClose)
        Exit Function
    End If
    '
    ' Do the query & wait
    intResult = SQLExecDirect(hStmt, SQL, Len(SQL))
    Do While intResult = sqlStillExecuting
        intResult = SQLExecDirect(hStmt, SQL, Len(SQL))
        DoEvents
    Loop
    '
    ' check for errors
    If intResult <> sqlSuccess Then
        ExecDirect = intResult
    '    Err.Raise vobjectError + 12, App.EXEName, "Error executing Query"
        intResult = SQLFreeStmt(hStmt, sqlClose)
        Exit Function
    End If
    '
    ExecDirect = sqlSuccess
    '
End Function

'19.13
Public Function FetchRow()
    '
    ' get a row of data
    '
    Dim intResult As Integer
    '
    intResult = SQLFetch(hStmt)
    If intResult <> sqlSuccess Then
        If intResult <> sqlNoDataFound Then
            Err.Raise vobjectError + 14, App.EXEName, "Error fetching row"
            FetchRow = intResult
        Else
            FetchRow = intResult
        End If
    Else
        FetchRow = sqlSuccess
    End If
    '
End Function

'19.14
Private Function GetColumn(strBuffer As String, intCol As Integer)
    '
    ' get a column from the current row
    '
    Dim intResult As Integer
    Dim lngBufferLen As Long
    '
    intResult = SQLGetData(hStmt, intCol, sqlChar, strBuffer, BUFFERLEN, _
                           lngBufferLen)
    If intResult <> sqlSuccess Then
        GetColumn = intResult
        Err.Raise vobjectError + 15, App.EXEName, "Error retrieving column data"
        Exit Function
    Else
        If lngBufferLen > 0 Then
            strBuffer = Left(strBuffer, lngBufferLen)
        Else
            strBuffer = ""
        End If
    End If
    '
    GetColumn = sqlSuccess
    '
End Function

Function GetDBNmbRows() As Long
'returns number of rows in TaskDataDB
Dim strBuffer As String * BUFFERLEN
'how many rows in database?
      objSQL.SQL = "SELECT COUNT(*) FROM " + objSQL.DBTable
    ' run the query
    intResult = ExecDirect
    If intResult <> sqlSuccess Then
        GetDBNmbRows = sqlErr
        Exit Function
    End If
    intResult = FetchRow()
    intResult = GetColumn(strBuffer, 1)
    GetDBNmbRows = CLng(strBuffer)
End Function

'
' Load query data
'
Public Function QueryDataFillOld()
    '
    ' collect data from result set
    '
    Dim intResult As Integer
    Dim intCols As Integer
    Dim nRows As Integer
    Dim lRowsInDB, lRowStart, lNmbRowsToReturn As Long
    Dim iMote_Id As Integer
    Dim strBuffer As String * BUFFERLEN
    Dim strItem As String
    Dim strData As String
    Dim sTmp0, sTmp1, sTmp2 As String
    Dim iIndx As Integer

    Dim strChrAttr As String * BUFFERLEN
    Dim StringLengthPtr As Integer
    Dim NumericAttributePtr As Integer
  
    'drop intermediate table
    objSQL.SQL = "DROP TABLE node_last_time"
    intResult = ExecDirect
    ' Don't bother if Call fails, since it will fail for the first time
    ' when it is non-existent
    
    ' Drop previous dummy table
    If TaskDBCfg.bDebugLiveUpdates = True Then
        objSQL.SQL = "DROP TABLE debug_table"
        intResult = ExecDirect
    End If
    
    ' Construct new debug table
    If TaskDBCfg.bDebugLiveUpdates = True Then
        sTmp0 = "SELECT * into debug_table " + _
            " FROM " + objSQL.DBTable + _
            " WHERE result_time <= '" + _
            CStr(TaskInfo.DataTimeEnd) + "'"
        objSQL.SQL = sTmp0
        intResult = ExecDirect
    End If
    
    ' create tmp table with mote_id and max times
    sTmp1 = "SELECT nodeid,max(result_time) AS last_time " + _
                " INTO node_last_time FROM "
    
    If TaskDBCfg.bDebugLiveUpdates = True Then
        sTmp1 = sTmp1 + " debug_table "
    Else
        sTmp1 = sTmp1 + objSQL.DBTable
    End If
    
    sTmp2 = ""
    ' This statement is for testing only,
    ' Remove after attaching to live query table
    ' TaskDBCfg.TaskLastQueryTime = CDate("2003-10-25 10:53:00")
    If (bNotFirstTime) Then
        sTmp2 = " WHERE result_time >= '" + _
                      CStr(TaskDBCfg.TaskLastQueryTime) + "'"
    End If
    sTmp2 = sTmp2 + " GROUP BY nodeid "
    objSQL.SQL = sTmp1 + sTmp2
                      
    intResult = ExecDirect
    If intResult <> sqlSuccess Then
        QueryDataFillOld = sqlErr
        Exit Function
    End If

    sTmp1 = "t.nodeid,t.result_time,"
    For iIndx = 1 To TaskInfo.nmb_sensors
        sTmp1 = sTmp1 + " t." + TaskInfo.sensor(iIndx)
        If iIndx < TaskInfo.nmb_sensors Then
            sTmp1 = sTmp1 + ","
        End If
    Next iIndx

    objSQL.SQL = "SELECT " + sTmp1 + " FROM " + objSQL.DBTable + _
                       " t, node_last_time n" _
                       + " WHERE t.nodeid = n.nodeid AND" _
                       + " t.result_time = n.last_time"

    intResult = ExecDirect
    If intResult <> sqlSuccess Then
        QueryDataFillOld = sqlErr
        Exit Function
    End If
  
    ' search the records for each mote and return it latest values
    intResult = SQLRowCount(hStmt, nRows)
      
    strBuffer = String(BUFFERLEN, 0)
    For iIndx = 1 To nRows
        intResult = SQLNumResultCols(hStmt, NumCols)
        intResult = FetchRow()
        intResult = GetColumn(strBuffer, 1)            'mote-id
        iMote_Id = CInt(strBuffer)
        intResult = GetColumn(strBuffer, 2)            'time
        TaskDataArray(iMote_Id).Time = Trim(strBuffer)
        
        'Removed, since we are not connected to live query table,
        ' Uncomment at release
        If (TaskDataArray(iMote_Id).Time > TaskDBCfg.TaskLastQueryTime) Then
            TaskDBCfg.TaskLastQueryTime = TaskDataArray(iMote_Id).Time
        End If
            
        For jindx = 1 To TaskInfo.nmb_sensors
            intResult = GetColumn(strBuffer, 2 + jindx)          'sensor data
            If Trim(strBuffer) = "" Then
                strBuffer = -1
            End If
            TaskDataArray(iMote_Id).Value(jindx) = CLng(strBuffer)
        Next jindx
    Next iIndx

    bNotFirstTime = True
    QueryDataFillOld = sqlSuccess
    
End Function

'====================================================================
' QueryDataFill
'====================================================================
' DESCRIPTION:
' HISTORY:      jprabhu     2004/1/15    Initial version
'               mturon      2004/2/27    Optimized SQL query
'
Public Function QueryDataFill()
    '
    ' collect data from result set
    '
    Dim intResult As Integer
    Dim intCols As Integer
    Dim nRows As Integer
    Dim lRowsInDB, lRowStart, lNmbRowsToReturn As Long
    Dim iMote_Id As Integer
    Dim strBuffer As String * BUFFERLEN
    Dim strItem As String
    Dim strData As String
    Dim sTmp0, sTmp1, sTmp2 As String
    Dim iIndx As Integer

    Dim strChrAttr As String * BUFFERLEN
    Dim StringLengthPtr As Integer
    Dim NumericAttributePtr As Integer
  
    sTmp1 = "nodeid, result_time,"
    For iIndx = 1 To TaskInfo.nmb_sensors
        sTmp1 = sTmp1 + " " + TaskInfo.sensor(iIndx)
        If iIndx < TaskInfo.nmb_sensors Then
            sTmp1 = sTmp1 + ","
        End If
    Next iIndx
    
    objSQL.SQL = "SELECT DISTINCT ON (nodeid) " + sTmp1 + _
                 " FROM " + objSQL.DBTable + _
                 " ORDER BY nodeid, result_time DESC"

    intResult = ExecDirect
    If intResult <> sqlSuccess Then
        QueryDataFill = sqlErr
        Exit Function
    End If
  
    ' search the records for each mote and return it latest values
    intResult = SQLRowCount(hStmt, nRows)
      
    strBuffer = String(BUFFERLEN, 0)
    For iIndx = 1 To nRows
        intResult = SQLNumResultCols(hStmt, NumCols)
        intResult = FetchRow()
        intResult = GetColumn(strBuffer, 1)            'mote-id
        If (Trim(strBuffer) = "") Then
            GoTo skip_loop                  ' filter out bad mote-ids
        End If
        iMote_Id = CInt(strBuffer)
        intResult = GetColumn(strBuffer, 2)            'time
        TaskDataArray(iMote_Id).Time = Trim(strBuffer)
        
        'Removed, since we are not connected to live query table,
        ' Uncomment at release
        If (TaskDataArray(iMote_Id).Time > TaskDBCfg.TaskLastQueryTime) Then
            TaskDBCfg.TaskLastQueryTime = TaskDataArray(iMote_Id).Time
        End If
            
        For jindx = 1 To TaskInfo.nmb_sensors
            intResult = GetColumn(strBuffer, 2 + jindx)          'sensor data
            If Trim(strBuffer) = "" Then
                strBuffer = -1
            End If
            TaskDataArray(iMote_Id).Value(jindx) = CLng(strBuffer)
        Next jindx
skip_loop:
    Next iIndx

    bNotFirstTime = True
    QueryDataFill = sqlSuccess
    
End Function

Public Function QueryHistoryFill(intNodeID As Integer, strSensor As String, _
                                 startTime As Date, endTime As Date)

    Dim intResult As Integer
    Dim intCols As Integer
    Dim intRows As Integer
    Dim iDataIndex() As index
    Dim strBuffer As String * BUFFERLEN
      
    'create the query
    sSQL = "SELECT result_time, " + strSensor + _
                 " FROM " + objSQL.DBTable + _
                 " WHERE nodeid = " + CStr(intNodeID) + _
                 " AND result_time >= '" + CStr(startTime) + _
                 "' AND result_time <= '" + CStr(endTime) + "'"
    
    objSQL.SQL = sSQL
    
    'run the query
    intResult = ExecDirect
    If intResult <> sqlSuccess Then
        QueryHistoryFill = sqlErr
        Exit Function
    End If
    
    '
    ' get the row count
    intResult = SQLRowCount(hStmt, intTotalRows)
      
    ' If Query did not return any results
    If (intTotalRows = 0) Then
        QueryHistoryFill = sqlErr
        Exit Function
    End If
    
    ReDim TaskHistoryData.Value(intTotalRows - 1)
    ReDim TaskHistoryData.Time(intTotalRows - 1)
        
    intRows = 0
    strBuffer = String(BUFFERLEN, 0)
    'get data
    Do While (1)
        intResult = FetchRow()
                                                   
        Select Case intResult
            Case sqlNoDataFound
                Exit Do
            Case sqlSuccess
                ' Initialise to a valid value
                TaskHistoryData.Time(intRows) = startTime
                TaskHistoryData.Value(intRows) = 0
                
                ' Get "result_time" of this reading
                intResult = GetColumn(strBuffer, 1)
                ' Check if the time is valid, else ignore reading
                If IsDate(strBuffer) Then
                    TaskHistoryData.Time(intRows) = Trim(strBuffer)
                    ' Get sensor reading
                    intResult = GetColumn(strBuffer, 2)
                    ' If the reading is a valid number add entry,
                    '   else copy old reading
                    If IsNumeric(strBuffer) Then
                        TaskHistoryData.Value(intRows) = _
                            UnitEngConvert(CLng(strBuffer), strSensor, intNodeID)
                    Else
                        If intRows > 0 Then
                            TaskHistoryData.Value(intRows) = _
                                TaskHistoryData.Value(intRows - 1)
                        Else
                            TaskHistoryData.Value(intRows) = -MOTE_NO_PARENT
                        End If
                    End If
                    intRows = intRows + 1
                End If
            Case Else
                intResult = SQLFreeStmt(hStmt, sqlClose)
                QueryHistoryFill = sqlErr
                Exit Function
        End Select
    'Next intRows
    Loop
    
    QueryHistoryFill = sqlSuccess
   
End Function

'
' Return number of motes and id of each mote
'
Public Function QueryMoteInfo() As Integer
    '
    ' read task_mote_info table
    '
    Dim intResult As Integer
    Dim intCols As Integer
    Dim intRows As Integer
    Dim mote_id As Integer
    Dim strBuffer As String * BUFFERLEN
    Dim strItem As String
    Dim strData As String
    Dim iMoteIndx As Integer
    Dim client As String
    
    client = "TASKView"
    
    ' The task_mote_info table is the standard place to get static
    ' information about motes in the network including:
    '   x/y/z position, and calibration constants
    objSQL.SQL = "SELECT * FROM task_mote_info ORDER BY mote_id"
    ' run the query
    intResult = ExecDirect
    If intResult <> sqlSuccess Then
        QueryMoteInfo = 0
        Exit Function
    End If
    iMoteIndx = 0
    Do
        intResult = FetchRow()
        Select Case intResult
            Case sqlNoDataFound
                If intRows > 0 Then
                    Exit Do
                Else
                    QueryMoteInfo = sqlErr
                    Exit Function
                End If
            
            Case sqlSuccess
                Dim myX, myY As Integer
                 
                intResult = GetColumn(strBuffer, 1)
                strBuffer = Trim(strBuffer)
                If (StrComp(strBuffer, "") <> 0) Then
                    mote_id = CInt(strBuffer)
                    ' invalidate skipped nodes
                    If (mote_id > iMoteIndx) Then
                        For i = iMoteIndx To mote_id - 1
                            TaskInfo.mote_id(i) = -1
                        Next i
                        iMoteIndx = mote_id
                    End If
                    TaskInfo.mote_id(mote_id) = mote_id
                    intResult = GetColumn(strBuffer, 2)
                    myX = CInt(strBuffer)
                    intResult = GetColumn(strBuffer, 3)
                    myY = CInt(strBuffer)
                    intResult = GetColumn(strBuffer, 5)
                    ' if calibration data exists, we assume it is for the MTS400:
                    ' Convert into a stream of 8 bytes.
                    Dim calibData(4) As Long
                    Dim byteH, byteL As Byte
                    For ic = 0 To 3
                        byteL = AscB(Mid(strBuffer, ic * 2 + 1, 1))
                        byteH = AscB(Mid(strBuffer, ic * 2 + 2, 1))
                        calibData(ic) = WSHFTL(byteH, 8) Or byteL
                    Next ic
                    'TaskInfo.mote_calib(mote_id) = calibData
                                        
                    intResult = GetColumn(strBuffer, 7)
                    If (StrComp(client, "") = 0) Then
                        client = strBuffer
                    Else
                        If (StrComp(client, Trim(strBuffer)) <> 0) Then
                            GoTo skip_mote
                        End If
                    End If
                                        
                    intRows = intRows + 1
                    iMoteIndx = iMoteIndx + 1
                
                    If (Not g_MoteInfo.Exists(mote_id)) Then
                        Set moteInfo = New objMote
                    Else
                        Set moteInfo = g_MoteInfo.Item(mote_id)
                        g_MoteInfo.Remove (mote_id)
                    End If
                    
                    moteInfo.m_nodeid = mote_id
                    moteInfo.m_x = myX
                    moteInfo.m_y = myY
                    moteInfo.m_flags = MF_SAVED
                    moteInfo.m_calib = calibData
                    moteInfo.m_name = "Mote #" & mote_id
                    moteInfo.m_color = gColors((mote_id Mod MAX_NODE_COLORS) + 1)
                    g_MoteInfo.Add mote_id, moteInfo
skip_mote:
                End If
                     
            Case Else
                intResult = SQLFreeStmt(hStmt, sqlClose)
                QueryMoteInfo = sqlErr
                QueryMoteInfo = iMoteIndx
                Exit Function
        End Select
    Loop
    QueryMoteInfo = iMoteIndx - 1 ' ignore Mote with Id 0 (basestation)
    
    ' ====== Strap into legacy structures
    TaskInfo.nmb_motes = iMoteIndx - 1
    TaskInfo.DataTimeEnd = objSQL.SampleMaxTime
    TaskInfo.DataTimeStart = objSQL.SampleMinTime
    If TaskDBCfg.bDebugLiveUpdates Then
        TaskDBCfg.TaskActualEndTime = TaskInfo.DataTimeEnd
        TaskInfo.DataTimeEnd = CDate((TaskInfo.DataTimeStart + _
                                    TaskDBCfg.TaskActualEndTime) / 2)
    End If

End Function

Public Function GetSensorNames() As Integer

Dim intResult As Integer
Dim intTotalRows As Integer
Dim intRows As Integer
Dim strBuffer As String * BUFFERLEN
Dim strName As String
Dim strDesc As String

Dim strColumnName As String * BUFFERLEN
Dim nNameLengthPtr As Integer
Dim nDataTypePtr As Integer
Dim nColumnSizePtr As Integer
Dim nDecimalDigitsPtr As Integer
Dim nNullablePtr As Integer
Dim nColNum As Integer


Dim strChrAttr As String * BUFFERLEN
Dim StringLengthPtr As Integer
Dim NumericAttributePtr As Integer


    ' find all the sensors from the task_attributes table
    objSQL.SQL = "SELECT name,description FROM task_attributes"
    
    'run the query
    intResult = ExecDirect
    If intResult <> sqlSuccess Then
        GetSensorNames = sqlErr
        Exit Function
    End If
    
    '
    ' get the row count
    intResult = SQLRowCount(hStmt, intTotalRows)
    If intResult <> sqlSuccess Then
        GetSensorNames = sqlErr
        Exit Function
    End If
    
    If intTotalRows > MAX_SENSORS Then
        'no space in table!
        GetSensorNames = sqlErr
        Exit Function
    End If
           
    TotalSensors = 0
    
    'Get Column Desc.
    
        'strColumnName = String(BUFFERLEN, 0)
        'nColNum = 1
        'intResult = SQLDescribeCol(hstmt, nColNum, strColumnName, BUFFERLEN, _
                     nNameLengthPtr, nDataTypePtr, nColumnSizePtr, _
                     nDecimalDigitsPtr, nNullablePtr)
        
    
    
    'strChrAttr = String(BUFFERLEN, 0)
    'StringLengthPtr = 0
    'NumericAttributePtr = 0
    'nColNum = 1
    'intResult = SQLColAttribute(hstmt, nColNum, _
                    SQL_DESC_BASE_COLUMN_NAME, strChrAttr, BUFFERLEN, _
                    StringLengthPtr, NumericAttributePtr)
    
    'If intResult <> sqlSuccess Then
    '    sqlErrorMsg "Unable to get column attributes"
    'End If
           
    
                    
    ' Now fill in the SensorInfoTable
    For intRows = 1 To intTotalRows
        intResult = FetchRow()
        
        intResult = GetColumn(strBuffer, 1)
        strName = Trim(strBuffer)
            '(StrComp(strName, "voltage", vbTextCompare) <> 0) And
        If ((StrComp(strName, "nodeid", vbTextCompare) <> 0) And _
            (StrComp(strName, "parent", vbTextCompare) <> 0) And _
            (StrComp(strName, "freeram", vbTextCompare) <> 0) And _
            (StrComp(strName, "qlen", vbTextCompare) <> 0) And _
            (StrComp(strName, "mhqlen", vbTextCompare) <> 0) And _
            (StrComp(strName, "depth", vbTextCompare) <> 0) And _
            (StrComp(strName, "timehi", vbTextCompare) <> 0) And _
            (StrComp(strName, "timelo", vbTextCompare) <> 0) And _
            (StrComp(strName, "qual", vbTextCompare) <> 0)) Then
            TotalSensors = TotalSensors + 1
            SensorInfoTable(TotalSensors).sensorName = strName
            intResult = GetColumn(strBuffer, 2)
            SensorInfoTable(TotalSensors).sensorDesc = Trim(strBuffer)
            SensorInfoTable(TotalSensors).bGridSelected = False
        End If
        
    Next intRows

End Function

'====================================================================
' GetQueryList
'====================================================================
' DESCRIPTION:  Builds a table of all outstanding TinyDB queries.
'               Information drawn from database includes
'               query name, sensor list, and sample period.
' HISTORY:      mturon      2004/2/9    Initial version
'
Public Function GetQueryList() As Integer

    Dim strBuffer As String * BUFFERLEN
    Dim strName As String
    Dim intResult As Integer
    Dim intTotalRows As Integer
    Dim i As Integer

    ' find all the queries in the task_query_log table
    objSQL.SQL = "SELECT table_name,query_text " _
               & "FROM task_query_log " _
               & "WHERE query_type='sensor'"
    
    'run the query
    intResult = ExecDirect
    If intResult <> sqlSuccess Then
        GetQueryList = sqlErr
        Exit Function
    End If
    
    ' get the row count
    intResult = SQLRowCount(hStmt, intTotalRows)
    If intResult <> sqlSuccess Then
        GetQueryList = sqlErr
        Exit Function
    End If
    
    If intTotalRows > MAX_QUERIES Then
        'no space in table!
        GetQueryList = sqlErr
        Exit Function
    End If
           
    'QuerySelected = -1
    ReDim Preserve QueryList(intTotalRows)
                    
    ' Now fill in the SensorInfoTable
    For i = 1 To intTotalRows
        intResult = FetchRow()
        intResult = GetColumn(strBuffer, 1)
        strName = Trim(strBuffer)
        QueryList(i).QueryName = strName
               
        ' Get the raw query to get a list of sensors and extract
        intResult = GetColumn(strBuffer, 2)
        strName = Trim(strBuffer)
        
        ' Prune out fields that are not sensors
        strName = Replace(strName, "nodeid,", "")
        strName = Replace(strName, "parent,", "")
        'strName = Replace(strName, "voltage,", "")
        strName = Replace(strName, "freeram,", "")
        strName = Replace(strName, "qlen,", "")
        strName = Replace(strName, "mhqlen,", "")
        strName = Replace(strName, "depth,", "")
        strName = Replace(strName, "timehi,", "")
        strName = Replace(strName, "timelo,", "")
        strName = Replace(strName, "qual,", "")
        
        ' Prune out KEYWORDS used by SQL and TASK
        strName = Replace(strName, "SELECT ", "")
        strName = Replace(strName, " SAMPLE", "")
        strName = Replace(strName, " PERIOD", "")
        
        Dim SensorList() As String
        SensorList = Split(strName, " ")
        
        ' Extract the SAMPLE PERIOD from end of list, and shrink list
        Dim SamplePeriod As String
        SamplePeriod = SensorList(UBound(SensorList))
        ReDim Preserve SensorList(UBound(SensorList) - 1)
               
        ' Fill in QueryInfo
        QueryList(i).SamplePeriod = SamplePeriod
        QueryList(i).SensorList = Join(SensorList, ",")
        
        ' Create a clear selection list
        QueryList(i).Selection = 0
        
    Next i

End Function

'====================================================================
' GetLastMoteResult
'====================================================================
' DESCRIPTION:  Queries for and fills in table of most recent mote
'               results.  This information includes:
'                   - new nodeid of motes joining the network
'                   - current parent of all the motes
'                   - last epoch returned by each mote
'
' HISTORY:      mturon      2004/2/13    Initial version
'
Public Function GetLastMoteResult() As Integer

    Dim strBuffer As String * BUFFERLEN
    Dim strName, sqlCmd As String
    Dim intResult As Integer
    Dim intTotalRows As Integer
    Dim i As Integer

    ' find the most recent result for each mote
    sqlCmd = "SELECT DISTINCT ON (nodeid) result_time,epoch,nodeid,parent" _
           & " FROM " & QueryList(QuerySelected).QueryName _
           & " ORDER BY nodeid, result_time DESC"
    objSQL.SQL = sqlCmd
    
    ' Reset MoteStat table
    MoteStatSize = 0
    
    ' Execute the SQL command
    intResult = ExecDirect
    If intResult <> sqlSuccess Then
        GetLastMoteResult = sqlErr
        Exit Function
    End If
    
    ' Get the row count
    intResult = SQLRowCount(hStmt, intTotalRows)
    If intResult <> sqlSuccess Then
        GetLastMoteResult = sqlErr
        Exit Function
    End If
        
    'g_MoteInfo.RemoveAll
    
    Dim thisMote As objMote
    Set thisMote = New objMote
    
    'thisMote.m_nodeid = 0
    'thisMote.m_parent = 0
    'thisMote.m_name = "Gateway"
    'g_MoteInfo.Add 0, thisMote
        
    ' Now fill in the MoteStats table
    For i = 1 To intTotalRows
        Dim lNodeId, lEpoch, lParent, lResultTime
        intResult = FetchRow()
        
        intResult = GetColumn(strBuffer, 1)
        lResultTime = Trim(strBuffer)
        intResult = GetColumn(strBuffer, 2)
        lEpoch = Trim(strBuffer)
        intResult = GetColumn(strBuffer, 3)
        lNodeId = Trim(strBuffer)
        intResult = GetColumn(strBuffer, 4)
        lParent = Trim(strBuffer)
            
        'If (lNodeId < UBound(g_MoteStats)) Then
        If (StrComp(lNodeId, "") <> 0) Then
            lNodeId = CInt(lNodeId)
            
            'lParent = CInt(lParent)
            If (g_MoteInfo.Exists(lNodeId)) Then
                Set thisMote = g_MoteInfo.Item(lNodeId)
                g_MoteInfo.Remove (lNodeId)
            Else
                Set thisMote = New objMote
                Dim calibData(4) As Long
                thisMote.m_calib = calibData
                thisMote.m_flags = 0            ' new mote!
                thisMote.m_color = gColors((lNodeId Mod MAX_NODE_COLORS) + 1)
            End If
            ' Allocate a fresh node to insert into MoteInfo table
            'Dim thisMote As New objMote
            thisMote.m_nodeid = lNodeId
            thisMote.m_parent = lParent
            thisMote.m_epoch = lEpoch
            thisMote.m_time = lResultTime
            thisMote.m_name = "Mote #" & lNodeId
            g_MoteInfo.Add lNodeId, thisMote
        
        End If
    
    Next i
    
End Function

'====================================================================
' SaveClientNew
'====================================================================
' @brief        Creates a new client in the task_client_info database
'
' @return       result of SQL command: sqlSuccess or sqlErr
'
' @version      mturon      2004/3/25    Initial version
'
Public Function SaveClientNew() As Integer
    Dim sqlInsert As String
    sqlInsert = "INSERT INTO task_client_info " & _
                "(name, type, clientinfo) " & _
                "VALUES ('TASKView', 'CONFIGURATION', '')"
    objSQL.SQL = sqlInsert
    SaveClientNew = ExecDirect   ' Execute the SQL command
End Function

'====================================================================
' SaveMoteNew
'====================================================================
' @brief        Creates a new mote in the task_mote_info database
'
' @param        moteV   The mote information objMote as Variant
' @return       result of SQL command: sqlSuccess or sqlErr
'
' @version      mturon      2004/3/25    Initial version
'
Public Function SaveMoteNew(moteV As Variant) As Integer
    Dim moteInfo As objMote
    Set moteInfo = moteV
    Dim sqlInsert As String
    sqlInsert = "INSERT INTO task_mote_info (mote_id, " & _
                "x_coord, y_coord, z_coord, calib, " & _
                "moteinfo, clientinfo_name) " & _
                "VALUES ( " & _
                moteInfo.m_nodeid & ", " & _
                moteInfo.m_x & ", " & _
                moteInfo.m_y & ", " & _
                moteInfo.m_z & ", '' , '" & _
                moteInfo.m_name & "', 'TASKView')"
    objSQL.SQL = sqlInsert
    SaveMoteNew = ExecDirect   ' Execute the SQL command
End Function

'====================================================================
' SaveMotePositions
'====================================================================
' @brief        Updates the database with the current mote positions
'
' @version      mturon      2004/2/18    Initial version
' @n            mturon      2004/3/25    Extended to insert new nodes
'
Public Function SaveMotePositions() As Integer

    Dim sqlBase, sqlNode As String
    Dim i, result As Integer

    sqlBase = "UPDATE task_mote_info SET"
    
    Dim v As Variant
    Dim moteInfo As objMote
    
    For Each v In g_MoteInfo.Items
        Set moteInfo = v
    
        sqlNode = " x_coord = " & moteInfo.m_x _
                & ",y_coord = " & moteInfo.m_y _
                & " WHERE mote_id = " & moteInfo.m_nodeid _
                & " AND clientinfo_name = 'TASKView'"
        
        objSQL.SQL = sqlBase + sqlNode
        ' Execute the SQL command
        result = ExecDirect
        If result <> sqlSuccess Then
            ' Assume the mote doesn't exist, and create it.
            If SaveMoteNew(v) <> sqlSuccess Then
                SaveClientNew
                result = SaveMoteNew(v)
            End If
        End If
    Next
    SaveMotePositions = result
End Function

'====================================================================
' GetDatabaseList
'====================================================================
' DESCRIPTION:  Builds a list of valid databases.
'
' HISTORY:      mturon      2004/2/23    Initial version
'
Public Function GetDatabaseList() As Integer

    Dim strBuffer As String * BUFFERLEN
    Dim strName, sqlCmd As String
    Dim intResult As Integer
    Dim intTotalRows As Integer
    Dim i As Integer

    ' find the most recent result for each mote
    sqlCmd = "SELECT datname FROM pg_database"
    objSQL.SQL = sqlCmd
        
    ' Execute the SQL command
    intResult = ExecDirect
    If intResult <> sqlSuccess Then
        GetDatabaseList = sqlErr
        Exit Function
    End If
    
    ' Get the row count
    intResult = SQLRowCount(hStmt, intTotalRows)
    If intResult <> sqlSuccess Then
        GetDatabaseList = sqlErr
        Exit Function
    End If
    
    ReDim Preserve g_DatabaseList(intTotalRows)
                    
    ' Now fill in the DatabaseList table
    For i = 1 To intTotalRows
        Dim lNodeId, lEpoch, lParent, lResultTime
        intResult = FetchRow()
        
        intResult = GetColumn(strBuffer, 1)
        g_DatabaseList(i) = Trim(strBuffer)
    Next i
    g_DatabaseList = Filter(g_DatabaseList, "template", False)
End Function

Public Function SampleMaxTime() As Date
    ''
    ' get the latest time in the sensor data table
    '
    Dim intResult As Integer
    Dim strSQL As String
    Dim strBuffer As String * BUFFERLEN
    '
    'make statement
    objSQL.SQL = "SELECT max(result_time) FROM " + objSQL.DBTable
    
    ' run the query
    intResult = ExecDirect
    If intResult <> sqlSuccess Then
        SampleMaxTime = sqlErr
        Exit Function
    End If
    '
    '
    'get the row
    intResult = SQLFetch(hStmt)
    If intResult <> sqlSuccess Then
        sqlErrorMsg "Unable to get max time record"
        intResult = SQLFreeStmt(hStmt, sqlClose)
    End If
    
    intResult = GetColumn(strBuffer, 1)
    If intResult <> sqlSuccess Then
        sqlErrorMsg "Unable to get max time column"
        intResult = SQLFreeStmt(hStmt, sqlClose)
    End If
    
    If (Trim(strBuffer) <> "") Then     ' Don't die on empty dates
        SampleMaxTime = CDate(strBuffer)
    End If
  
End Function

Public Function SampleMinTime() As Date
    '
    ' get the latest time in the sensor data table
    '
    Dim intResult As Integer
    Dim strSQL As String
    Dim strBuffer As String * BUFFERLEN
    '

    'make statement
    objSQL.SQL = "SELECT min(result_time) FROM " + objSQL.DBTable
    
    ' run the query
    intResult = ExecDirect
    If intResult <> sqlSuccess Then
        SampleMinTime = sqlErr
        Exit Function
    End If
    '
    'get the row
    intResult = SQLFetch(hStmt)
    If intResult <> sqlSuccess Then
        sqlErrorMsg "Unable to get min time record"
        intResult = SQLFreeStmt(hStmt, sqlClose)
    End If
    
    intResult = GetColumn(strBuffer, 1)
    If intResult <> sqlSuccess Then
        sqlErrorMsg "Unable to get min time column"
        intResult = SQLFreeStmt(hStmt, sqlClose)
    End If
    
    If (Trim(strBuffer) <> "") Then
        SampleMinTime = CDate(strBuffer)
    End If
    
End Function

