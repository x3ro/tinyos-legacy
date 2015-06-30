VERSION 5.00
Object = "{D8D562C3-878C-11D2-943F-444553540000}#1.0#0"; "ctlist.ocx"
Object = "{F9043C88-F6F2-101A-A3C9-08002B2F49FB}#1.2#0"; "comdlg32.ocx"
Begin VB.Form FrmDBCfg 
   Caption         =   "TASK Configuration"
   ClientHeight    =   6945
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   6375
   LinkTopic       =   "Form1"
   MDIChild        =   -1  'True
   ScaleHeight     =   6945
   ScaleWidth      =   6375
   Begin VB.ComboBox lbDatabaseList 
      Height          =   315
      Left            =   2160
      TabIndex        =   11
      Top             =   840
      Width           =   2535
   End
   Begin MSComDlg.CommonDialog cfgFileDialog 
      Left            =   1320
      Top             =   6240
      _ExtentX        =   847
      _ExtentY        =   847
      _Version        =   393216
      DialogTitle     =   "Open"
      Filter          =   "MOTE Files (*.txt)|*.txt"
      FilterIndex     =   1
   End
   Begin VB.ComboBox lbQueryList 
      Height          =   288
      Left            =   2160
      TabIndex        =   10
      Top             =   1200
      Width           =   2535
   End
   Begin VB.TextBox tbSamplePeriod 
      Alignment       =   1  'Right Justify
      BackColor       =   &H8000000B&
      Height          =   285
      Left            =   3960
      Locked          =   -1  'True
      TabIndex        =   9
      Top             =   1920
      Width           =   1575
   End
   Begin VB.CommandButton cbOpen 
      Caption         =   "Open"
      Height          =   375
      Left            =   360
      TabIndex        =   7
      Top             =   6240
      Width           =   850
   End
   Begin VB.CommandButton cbExit 
      Caption         =   "Exit"
      Height          =   375
      Left            =   5040
      TabIndex        =   6
      Top             =   6240
      Width           =   850
   End
   Begin VB.CommandButton cbSave 
      Caption         =   "Save "
      Height          =   375
      Left            =   2520
      TabIndex        =   5
      Top             =   6240
      Width           =   850
   End
   Begin CTLISTLibCtl.ctList ctSensorsList 
      Height          =   3615
      Left            =   480
      TabIndex        =   4
      Top             =   2400
      Width           =   5355
      _Version        =   65536
      _ExtentX        =   9446
      _ExtentY        =   6376
      _StockProps     =   77
      BackColor       =   16777215
      BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      BeginProperty TitleFont {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      BeginProperty HeaderFont {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "MS Sans Serif"
         Size            =   8.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      TitleBackImage  =   "FrmDBCfg.frx":0000
      HeaderPicture   =   "FrmDBCfg.frx":001C
      Picture         =   "FrmDBCfg.frx":0038
      CheckPicDown    =   "FrmDBCfg.frx":0054
      CheckPicUp      =   "FrmDBCfg.frx":0070
      CheckPicDisabled=   "FrmDBCfg.frx":008C
      BackImage       =   "FrmDBCfg.frx":00A8
      TitleText       =   "Sensors to View"
      ArrowAlign      =   0
      ShowTitle       =   -1  'True
      ShowHeader      =   -1  'True
      HorzGridLines   =   -1  'True
      VertGridLines   =   -1  'True
      HeaderData      =   "FrmDBCfg.frx":00C4
      PicArray0       =   "FrmDBCfg.frx":014C
      PicArray1       =   "FrmDBCfg.frx":0168
      PicArray2       =   "FrmDBCfg.frx":0184
      PicArray3       =   "FrmDBCfg.frx":01A0
      PicArray4       =   "FrmDBCfg.frx":01BC
      PicArray5       =   "FrmDBCfg.frx":01D8
      PicArray6       =   "FrmDBCfg.frx":01F4
      PicArray7       =   "FrmDBCfg.frx":0210
      PicArray8       =   "FrmDBCfg.frx":022C
      PicArray9       =   "FrmDBCfg.frx":0248
      PicArray10      =   "FrmDBCfg.frx":0264
      PicArray11      =   "FrmDBCfg.frx":0280
      PicArray12      =   "FrmDBCfg.frx":029C
      PicArray13      =   "FrmDBCfg.frx":02B8
      PicArray14      =   "FrmDBCfg.frx":02D4
      PicArray15      =   "FrmDBCfg.frx":02F0
      PicArray16      =   "FrmDBCfg.frx":030C
      PicArray17      =   "FrmDBCfg.frx":0328
      PicArray18      =   "FrmDBCfg.frx":0344
      PicArray19      =   "FrmDBCfg.frx":0360
      PicArray20      =   "FrmDBCfg.frx":037C
      PicArray21      =   "FrmDBCfg.frx":0398
      PicArray22      =   "FrmDBCfg.frx":03B4
      PicArray23      =   "FrmDBCfg.frx":03D0
      PicArray24      =   "FrmDBCfg.frx":03EC
      PicArray25      =   "FrmDBCfg.frx":0408
      PicArray26      =   "FrmDBCfg.frx":0424
      PicArray27      =   "FrmDBCfg.frx":0440
      PicArray28      =   "FrmDBCfg.frx":045C
      PicArray29      =   "FrmDBCfg.frx":0478
      PicArray30      =   "FrmDBCfg.frx":0494
      PicArray31      =   "FrmDBCfg.frx":04B0
      PicArray32      =   "FrmDBCfg.frx":04CC
      PicArray33      =   "FrmDBCfg.frx":04E8
      PicArray34      =   "FrmDBCfg.frx":0504
      PicArray35      =   "FrmDBCfg.frx":0520
      PicArray36      =   "FrmDBCfg.frx":053C
      PicArray37      =   "FrmDBCfg.frx":0558
      PicArray38      =   "FrmDBCfg.frx":0574
      PicArray39      =   "FrmDBCfg.frx":0590
      PicArray40      =   "FrmDBCfg.frx":05AC
      PicArray41      =   "FrmDBCfg.frx":05C8
      PicArray42      =   "FrmDBCfg.frx":05E4
      PicArray43      =   "FrmDBCfg.frx":0600
      PicArray44      =   "FrmDBCfg.frx":061C
      PicArray45      =   "FrmDBCfg.frx":0638
      PicArray46      =   "FrmDBCfg.frx":0654
      PicArray47      =   "FrmDBCfg.frx":0670
      PicArray48      =   "FrmDBCfg.frx":068C
      PicArray49      =   "FrmDBCfg.frx":06A8
      PicArray50      =   "FrmDBCfg.frx":06C4
      PicArray51      =   "FrmDBCfg.frx":06E0
      PicArray52      =   "FrmDBCfg.frx":06FC
      PicArray53      =   "FrmDBCfg.frx":0718
      PicArray54      =   "FrmDBCfg.frx":0734
      PicArray55      =   "FrmDBCfg.frx":0750
      PicArray56      =   "FrmDBCfg.frx":076C
      PicArray57      =   "FrmDBCfg.frx":0788
      PicArray58      =   "FrmDBCfg.frx":07A4
      PicArray59      =   "FrmDBCfg.frx":07C0
      PicArray60      =   "FrmDBCfg.frx":07DC
      PicArray61      =   "FrmDBCfg.frx":07F8
      PicArray62      =   "FrmDBCfg.frx":0814
      PicArray63      =   "FrmDBCfg.frx":0830
      PicArray64      =   "FrmDBCfg.frx":084C
      PicArray65      =   "FrmDBCfg.frx":0868
      PicArray66      =   "FrmDBCfg.frx":0884
      PicArray67      =   "FrmDBCfg.frx":08A0
      PicArray68      =   "FrmDBCfg.frx":08BC
      PicArray69      =   "FrmDBCfg.frx":08D8
      PicArray70      =   "FrmDBCfg.frx":08F4
      PicArray71      =   "FrmDBCfg.frx":0910
      PicArray72      =   "FrmDBCfg.frx":092C
      PicArray73      =   "FrmDBCfg.frx":0948
      PicArray74      =   "FrmDBCfg.frx":0964
      PicArray75      =   "FrmDBCfg.frx":0980
      PicArray76      =   "FrmDBCfg.frx":099C
      PicArray77      =   "FrmDBCfg.frx":09B8
      PicArray78      =   "FrmDBCfg.frx":09D4
      PicArray79      =   "FrmDBCfg.frx":09F0
      PicArray80      =   "FrmDBCfg.frx":0A0C
      PicArray81      =   "FrmDBCfg.frx":0A28
      PicArray82      =   "FrmDBCfg.frx":0A44
      PicArray83      =   "FrmDBCfg.frx":0A60
      PicArray84      =   "FrmDBCfg.frx":0A7C
      PicArray85      =   "FrmDBCfg.frx":0A98
      PicArray86      =   "FrmDBCfg.frx":0AB4
      PicArray87      =   "FrmDBCfg.frx":0AD0
      PicArray88      =   "FrmDBCfg.frx":0AEC
      PicArray89      =   "FrmDBCfg.frx":0B08
      PicArray90      =   "FrmDBCfg.frx":0B24
      PicArray91      =   "FrmDBCfg.frx":0B40
      PicArray92      =   "FrmDBCfg.frx":0B5C
      PicArray93      =   "FrmDBCfg.frx":0B78
      PicArray94      =   "FrmDBCfg.frx":0B94
      PicArray95      =   "FrmDBCfg.frx":0BB0
      PicArray96      =   "FrmDBCfg.frx":0BCC
      PicArray97      =   "FrmDBCfg.frx":0BE8
      PicArray98      =   "FrmDBCfg.frx":0C04
      PicArray99      =   "FrmDBCfg.frx":0C20
   End
   Begin VB.TextBox tbServerName 
      Height          =   315
      Left            =   2100
      TabIndex        =   2
      Top             =   480
      Width           =   2595
   End
   Begin VB.Label lbSampleTime 
      Caption         =   "Sampling Period"
      Height          =   255
      Left            =   2640
      TabIndex        =   8
      Top             =   1920
      Width           =   1215
   End
   Begin VB.Label lbMoteInfoTable 
      Caption         =   "Query Results"
      Height          =   255
      Left            =   960
      TabIndex        =   3
      Top             =   1245
      Width           =   1095
   End
   Begin VB.Label lbDBName 
      Caption         =   "Server"
      Height          =   255
      Left            =   1440
      TabIndex        =   1
      Top             =   525
      Width           =   495
   End
   Begin VB.Label lbDataTable 
      Caption         =   "Database"
      Height          =   255
      Left            =   1200
      TabIndex        =   0
      Top             =   900
      Width           =   735
   End
End
Attribute VB_Name = "FrmDBCfg"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
''====================================================================
'' FrmDBCfg.frm
''====================================================================
'' DESCRIPTION:  Implements the database configuration screen.
''
'' HISTORY:      mturon      2004/2/9    Initial revision
''
'' $Id: FrmDBCfg.frm,v 1.7 2004/03/31 06:51:28 mturon Exp $
''====================================================================

Option Explicit

'====================================================================
' cbExit_Click
'====================================================================
' DESCRIPTION:  Handles updating of all UI that has changed after
'               user altered configuration settings.
' HISTORY:      mturon      2004/2/11    Initial version
'
Private Sub cbExit_Click()

    Dim nIndex As Integer

    TaskDBCfg.TaskQueryString = "nodeid,result_time"
    TaskInfo.nmb_sensors = 0
    
    objSQL.DBName = lbDatabaseList.Text
    objSQL.DBServer = tbServerName.Text
    objSQL.DBTable = lbQueryList.Text
    
    ' Update the date range for the new table!
    TaskInfo.DataTimeStart = objSQL.SampleMinTime
    TaskInfo.DataTimeEnd = objSQL.SampleMaxTime
    FrmDataGrid.Update_TimeScales
    
    For nIndex = 1 To TotalSensors
        'Enable/Disable the sensors for the query
        If SensorInfoTable(nIndex).bGridSelected Then
            TaskDBCfg.TaskQueryString = TaskDBCfg.TaskQueryString + "," + _
                                        SensorInfoTable(nIndex).sensorName
            TaskInfo.nmb_sensors = TaskInfo.nmb_sensors + 1
            TaskInfo.sensor(TaskInfo.nmb_sensors) = _
                                SensorInfoTable(nIndex).sensorName
        End If
    Next nIndex
    
    bNotFirstTime = False ' Force Data Grid to read the whole table
    FrmDataGrid.Grid_Add_Motes
    FrmDataGrid.Grid_Display_Data
    FrmDataGrid.Timer1.Enabled = TIME_UPDATE_GRID
    Unload Me

End Sub

Private Sub lbDatabaseList_Click()
    objSQL.DBName = lbDatabaseList.Text
    objSQL.Reset
    QuerySelected = -1
    lbQueryList_Populate
    ctSensorsList_Populate
End Sub

Private Sub lbQueryList_Click()
    QuerySelected = lbQueryList.ListIndex + 1
    ctSensorsList_Populate
End Sub
'====================================================================
' cbOpen_Click
'====================================================================
' DESCRIPTION:  Opens file dialog, and loads the selected config file.
' HISTORY:      mturon      2004/2/11    Initial version
'
Private Sub cbOpen_Click()
    ' Grab the user selected filename from the file dialog
    Dim cfgFilename As String
    cfgFileDialog.ShowOpen
    cfgFilename = cfgFileDialog.filename
    If (cfgFilename = "") Then
        MsgBox ("Filename: " + cfgFilename + " not valid.")
        Exit Sub
    End If
    
    ' Load config data from file
    If MoteFileReadCfg(cfgFilename) = True Then
        ' If a reset occurred, repopulate
        lbQueryList_Populate
        FrmRouteMap.Refresh
    End If
    
    ' Update UI from globals after opening config.
    tbServerName.Text = objSQL.DBServer
    lbDatabaseList.Text = objSQL.DBName
    
    ctSensorsList_Populate

End Sub
'====================================================================
' cbSave_Click
'====================================================================
' DESCRIPTION:  Opens file dialog, and saves the current configuration
'               to the desired file.
' HISTORY:      mturon      2004/2/11    Initial version
'
Private Sub cbSave_Click()
    ' Grab the user selected filename from the file dialog
    Dim cfgFilename As String
    cfgFileDialog.ShowSave
    cfgFilename = cfgFileDialog.filename
    If (cfgFilename = "") Then
        MsgBox ("Filename: " + cfgFilename + " not valid.")
        Exit Sub
    End If
        
    ' Update globals from UI before saving
    objSQL.DBName = lbDatabaseList.Text
    objSQL.DBServer = tbServerName.Text
    
    ' Write config data to file
    MoteFileWriteCfg (cfgFilename)
End Sub

'====================================================================
' ctSensorsList_Populate
'====================================================================
' DESCRIPTION:  Populates the sensor table for a given query result
' HISTORY:      mturon      2004/2/9    Initial revision
'
Sub ctSensorsList_Populate()
    Dim i As Integer
    Dim sensorId As Integer
             
    If QuerySelected < 0 Then
        ' No query means no sensor selection...
        ctSensorsList.ClearList
        Exit Sub
    End If
    
    'Get index for currently selected TinyDB Query
    Dim queryId As Integer
    queryId = QuerySelected
    lbQueryList.ListIndex = QuerySelected - 1
        
    'Clear list UI
    ctSensorsList.ClearList
        
    ' Set sample period -- converted to closest logical time unit
    Dim sampTime As Long
    If (QueryList(queryId).SamplePeriod <> "") Then
        sampTime = QueryList(queryId).SamplePeriod
    Else
        sampTime = 0
    End If
    If sampTime < 1000 Then
        tbSamplePeriod.Text = sampTime & " ms"
    Else
        If sampTime < 60000 Then
            tbSamplePeriod.Text = Round(sampTime / 1000, 3) & " sec"
        Else
            tbSamplePeriod.Text = Round(sampTime / 60000, 3) & " min"
        End If
    End If
    
    ' Split out the sensor list into an array
    Dim SensorList() As String
    SensorList = Split(QueryList(queryId).SensorList, ",")
    
    ' Remove all sensors
    For i = 1 To TotalSensors
        SensorInfoTable(i).bGridSelected = False
    Next
    
    For i = LBound(SensorList) To UBound(SensorList)
        ' Add sensor name and description to table
        sensorId = SensorGetId(SensorList(i))
        If (sensorId > 0) Then
            ' Don't add health query items such as parent.
            ctSensorsList.AddItem _
                SensorList(i) + ";" + _
                SensorInfoTable(sensorId).sensorDesc
        End If
        
        ' If sensor is in selection bitfield, mark it checked
        If (QueryList(queryId).Selection And (2 ^ i)) Then
            ctSensorsList.ListColumnCheck(i, 1) = 1
            SensorInfoTable(sensorId).bGridSelected = True
        End If
    Next i
    
End Sub

Private Sub ctSensorsList_CheckClick(ByVal nIndex As Long, _
                                     ByVal nColumn As Integer, _
                                     ByVal nValue As Integer)
    Dim bitField As Integer
    
    ' Extract the queryId from the ComboBox UI
    Dim queryId As Integer
    queryId = lbQueryList.ListIndex + 1
        
    ' Split out the sensor list into an array
    Dim SensorList() As String
    SensorList = Split(QueryList(queryId).SensorList, ",")
    
    'Check Box ticked, enable the sensors in the query
    If (nValue = 1) Then
        SensorInfoTable(SensorGetId(SensorList(nIndex))).bGridSelected = True
        
        ' If a query is selected, add checked sensor to bitfield
        If (queryId > 0) Then
            bitField = QueryList(queryId).Selection
            bitField = bitField Or (2 ^ nIndex)
            QueryList(queryId).Selection = bitField
        End If
    End If
  
    'Check Box unchecked, disable the sensor for the query
    If (nValue = 0) Then
        SensorInfoTable(SensorGetId(SensorList(nIndex))).bGridSelected = False
        'SensorInfoTable(nIndex + 1).bGridSelected = False
    
        ' If a query is selected, remove unchecked sensor from bitfield
        If (queryId > 0) Then
            bitField = QueryList(queryId).Selection
            bitField = bitField And Not (2 ^ nIndex)
            QueryList(queryId).Selection = bitField
        End If
    End If
  
    'ignore disabled nValue
      
End Sub

Sub lbQueryList_Populate()
    lbQueryList.Clear
    Dim i, nTables As Integer
    nTables = UBound(QueryList)
    For i = 1 To nTables
        lbQueryList.AddItem QueryList(i).QueryName
        If (i = 1) Then
            lbQueryList.Text = QueryList(i).QueryName
        End If
    Next i
End Sub

Sub lbDatabaseList_Populate()
    lbDatabaseList.Clear
    Dim i, nTables As Integer
    nTables = UBound(g_DatabaseList)
    For i = 1 To nTables
        lbDatabaseList.AddItem g_DatabaseList(i)
        If (i = 1) Then
            lbDatabaseList.Text = g_DatabaseList(i)
        End If
        If (StrComp(g_DatabaseList(i), objSQL.DBName) = 0) Then
            lbDatabaseList.Text = g_DatabaseList(i)
        End If
    Next i
End Sub

Private Sub Form_Load()
    ' Initialize file dialog
    cfgFileDialog.Filter = "MOTE Files (*.txt)|*.txt"
    cfgFileDialog.FilterIndex = 1                     ' Specify default filter.

    tbServerName.Text = objSQL.DBServer
    
    ' Not sure why MDIChild sizes need to be hard-coded here...
    ' Width is set way too wide despite form builder settings
    ' without these explicit defaults.
    FrmDBCfg.Top = 50
    FrmDBCfg.Left = 2500
    FrmDBCfg.Width = 6500
    FrmDBCfg.Height = 7350
    
    lbDatabaseList_Populate
    lbQueryList_Populate
    ctSensorsList_Populate
    
End Sub

Private Sub Form_QueryUnload(Cancel As Integer, unloadmode As Integer)
    'user closed form via menu
    MDIForm1.MnWinDBConfig.Checked = False
End Sub

Private Sub Form_Terminate()
    Unload Me
End Sub

Private Sub tbServerName_Change()
    'objSQL.DBServer = tbServerName.Text
    'objSQL.Reset
End Sub
