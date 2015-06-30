Attribute VB_Name = "basConfigFile"
''====================================================================
'' MoteFile.bas
''====================================================================
'' DESCRIPTION:  Library of routines for reading and writing mote
''               configuration files.
''
'' HISTORY:      mturon      2004/2/11    Initial revision
''
'' $Id: basConfigFile.bas,v 1.1 2004/03/25 19:53:35 mturon Exp $
''====================================================================

'====================================================================
' MoteFileWriteCfg
'====================================================================
' DESCRIPTION:  Saves the current config to the given file.
' HISTORY:      mturon      2004/2/11    Initial version
'
Public Function MoteFileWriteCfg(filename As String)
    
    ' First create the desired config file as a text string
    Dim configText As String
    configText = _
        ";-----------------------------------------------------------" + vbCrLf + _
        "; TASKVIEW config file" + vbCrLf + _
        "; To comment, use ';' as the first character in a line." + vbCrLf + _
        "; No blank lines.  Case sensitive." + vbCrLf + _
        "; Syntax: " + vbCrLf + _
        ";      Keyword: data<,data2_list,data3_list>" + vbCrLf + _
        "; Where: " + vbCrLf + _
        ";      Server: <hostname or ip_addr>" + vbCrLf + _
        ";      Database: <database_name>" + vbCrLf + _
        ";      Bitmap: <bitmap_filename>" + vbCrLf + _
        ";      Query: <query_table_name>" + vbCrLf + _
        ";      Sensors: sensor1,sensor2,sensor3  ;<list of selected sensors>" + vbCrLf + _
        ";-----------------------------------------------------------" + vbCrLf
    
    ' Process KEYWORD "Server:"
    configText = configText + "Server: " _
                            + objSQL.DBServer + vbCrLf
    
    ' Process KEYWORD "Database:"
    configText = configText + "Database: " _
                            + objSQL.DBName + vbCrLf
                
    ' Process KEYWORD "Bitmap:"
    configText = configText + "Bitmap: " _
                            + g_MapFileName + vbCrLf
    
    ' Process KEYWORD "Query:"
    ' After default header, insert selected query name
    configText = configText + "Query: " _
                            + QueryList(QuerySelected).QueryName + vbCrLf
                    ' A.K.A.  objSQL.DBTable
    
    ' Process KEYWORD "Sensors:"
    ' Add list of selected sensors
    configText = configText + "Sensors: "
    Dim firstItem As Boolean
    firstItem = True
    For i = 1 To TotalSensors
        If SensorInfoTable(i).bGridSelected = True Then
            If firstItem = True Then
                firstItem = False
            Else
                configText = configText + ","
            End If
            configText = configText + SensorInfoTable(i).sensorName
        End If
    Next
    
    ' Get a free file number, open the file, and dump the config text
    Dim fnum As Integer
    fnum = FreeFile()
    Open filename For Output As #fnum
    Print #fnum, configText
    Close #fnum
End Function

'====================================================================
' MoteFileReadCfg
'====================================================================
' DESCRIPTION:  Loads the given config file.
' HISTORY:      mturon      2004/2/11    Initial version
'
Public Function MoteFileReadCfg(filename As String) As Boolean
    ' Bootstrap legacy structures {TaskDBCfg}
    bNotFirstTime = False  ' Set Live update setting here for testing (later from config file)
    TaskDBCfg.bDebugLiveUpdates = False
    TaskDBCfg.TaskLastQueryTime = CDate(0)
    'TaskDBCfg.TaskQueryString = "nodeid,result_time"
    
    
    ' Get a free file number, open the file, and slurp in the config text
    Dim fnum As Integer
    fnum = FreeFile()
    Open filename For Input As #fnum
    Dim configText, tempString As String
    configText = Input(LOF(fnum), fnum)
    Close #fnum
    
    ' Now parse config file by splitting it into lines and filtering comments
    Dim configLines() As String
    configLines = Split(configText, vbLf)
    configLines = Filter(configLines, ";", False)
       
    ' split keyword / data using ':' delimiter
    Dim splitLine() As String
    
    ' Process KEYWORD "Bitmap:"
    splitLine = Filter(configLines, "Bitmap:")
    If UBound(splitLine) >= 0 Then
        splitLine = Split(splitLine(0), ":")
        If UBound(splitLine) > 1 Then
            ' Handle drive letters..
            'splitLine = Filter(splitLine, "Bitmap", False)
            'splitLine = Filter(splitLine, vbLf, False)
            'tempString = Join(splitLine, ":")  ' stupid vbLF at end..
            tempString = splitLine(1) + ":" + splitLine(2)
        Else
            tempString = splitLine(1)
        End If
        g_MapFileName = SafeTrim(tempString)
    End If
    
    ' Process KEYWORD "Server:"
    splitLine = Filter(configLines, "Server:")
    If UBound(splitLine) >= 0 Then
        splitLine = Split(splitLine(0), ":")
        objSQL.DBServer = SafeTrim(splitLine(1))
    End If
    
    ' Process KEYWORD "Database:"
    splitLine = Filter(configLines, "Database:")
    If UBound(splitLine) >= 0 Then
        splitLine = Split(splitLine(0), ":")
        objSQL.DBName = SafeTrim(splitLine(1))
    End If
    
    MoteFileReadCfg = objSQL.Reset() ' Reconnect DB connection if it has changed...
        
    ' Process KEYWORD "Sensors:"
    ' split keyword / data using ':' delimiter
    Dim sensorLines() As String
    sensorLines = Filter(configLines, "Sensors:")
    Dim sensorsSelected() As String
    sensorsSelected = Split(sensorLines(0), ":")
          
    ' split data fields using ',' delimiter
    sensorsSelected = Split(sensorsSelected(1), ",")
    For i = 0 To UBound(sensorsSelected)    ' trim whitespace i.e. "SafeSplit"
        sensorsSelected(i) = SafeTrim(sensorsSelected(i))
        TaskInfo.sensor(i + 1) = sensorsSelected(i)
        ' Strap into data grid...
        'TaskDBCfg.TaskQueryString = _
        '    TaskDBCfg.TaskQueryString + "," + sensorsSelected(i)
    Next
       
    ' Process KEYWORD "Query:"
    splitLine = Filter(configLines, "Query:")
    splitLine = Split(splitLine(0), ":")
    objSQL.DBTable = SafeTrim(splitLine(1))  ' queryToConfig
       
    ' Now fill internal structures with config information
    ' Calculate sensor selection bitfield.
    Dim querySensorList() As String
    querySensorList = Split(QueryList(QuerySelected).SensorList, ",")
    Dim bitField As Integer
    bitField = 0
    For i = LBound(sensorsSelected) To UBound(sensorsSelected)
        For j = LBound(querySensorList) To UBound(querySensorList)
            If StrComp(sensorsSelected(i), querySensorList(j)) = 0 Then
                bitField = bitField Or (2 ^ j)
                Exit For
            End If
        Next j
    Next i
    TaskInfo.nmb_sensors = UBound(sensorsSelected) - LBound(sensorsSelected) + 1
    QueryList(QuerySelected).Selection = bitField
                
       
    ' ********** DEBUG only **********
    'configText = "" 'Join(Filter(configLines, ";"), vbLf)
    'configText = configText + "Query: " + queryName + vbLf
    'configText = configText + "Sensors: " + Join(sensorsSelected, ",")
    'configText = configText + vbLf
    ' Get a free file number, open the file, and dump the config text
    'fnum = FreeFile()
    'Open Filename For Output As #fnum
    'Print #fnum, configText
    'Close #fnum
    
    ' Now that query selection is all squared away, we can get parent info
    objSQL.GetLastMoteResult
    
End Function
