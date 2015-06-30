VERSION 5.00
Object = "{6B7E6392-850A-101B-AFC0-4210102A8DA7}#1.3#0"; "comctl32.ocx"
Object = "{F9043C88-F6F2-101A-A3C9-08002B2F49FB}#1.2#0"; "comdlg32.ocx"
Begin VB.MDIForm MDIForm1 
   AutoShowChildren=   0   'False
   BackColor       =   &H8000000C&
   Caption         =   "TASKVIEW"
   ClientHeight    =   8865
   ClientLeft      =   270
   ClientTop       =   795
   ClientWidth     =   10965
   LinkTopic       =   "MDIForm1"
   WindowState     =   2  'Maximized
   Begin ComctlLib.Toolbar Toolbar1 
      Align           =   1  'Align Top
      Height          =   420
      Left            =   0
      TabIndex        =   0
      Top             =   0
      Width           =   10965
      _ExtentX        =   19341
      _ExtentY        =   741
      ButtonWidth     =   614
      ButtonHeight    =   572
      Appearance      =   1
      ImageList       =   "ImageList1"
      _Version        =   327682
      BeginProperty Buttons {0713E452-850A-101B-AFC0-4210102A8DA7} 
         NumButtons      =   4
         BeginProperty Button1 {0713F354-850A-101B-AFC0-4210102A8DA7} 
            Key             =   "DataGrid"
            Object.ToolTipText     =   "Display Data Table"
            Object.Tag             =   "DataGridDsply"
            ImageIndex      =   4
         EndProperty
         BeginProperty Button2 {0713F354-850A-101B-AFC0-4210102A8DA7} 
            Key             =   "DataGraph"
            Object.ToolTipText     =   "Display Data Graph "
            Object.Tag             =   ""
            ImageIndex      =   3
         EndProperty
         BeginProperty Button3 {0713F354-850A-101B-AFC0-4210102A8DA7} 
            Key             =   "RouteMap"
            Object.ToolTipText     =   "Display Route Map"
            Object.Tag             =   ""
            ImageIndex      =   5
         EndProperty
         BeginProperty Button4 {0713F354-850A-101B-AFC0-4210102A8DA7} 
            Key             =   "DBConfig"
            Object.ToolTipText     =   "Database Config"
            Object.Tag             =   ""
            ImageIndex      =   6
         EndProperty
      EndProperty
   End
   Begin MSComDlg.CommonDialog CommonDialog1 
      Left            =   0
      Top             =   6000
      _ExtentX        =   847
      _ExtentY        =   847
      _Version        =   393216
   End
   Begin ComctlLib.ImageList ImageList1 
      Left            =   120
      Top             =   4560
      _ExtentX        =   1005
      _ExtentY        =   1005
      BackColor       =   -2147483625
      ImageWidth      =   16
      ImageHeight     =   16
      MaskColor       =   12632256
      _Version        =   327682
      BeginProperty Images {0713E8C2-850A-101B-AFC0-4210102A8DA7} 
         NumListImages   =   6
         BeginProperty ListImage1 {0713E8C3-850A-101B-AFC0-4210102A8DA7} 
            Picture         =   "frmMDI.frx":0000
            Key             =   "Grid2"
         EndProperty
         BeginProperty ListImage2 {0713E8C3-850A-101B-AFC0-4210102A8DA7} 
            Picture         =   "frmMDI.frx":01DA
            Key             =   ""
         EndProperty
         BeginProperty ListImage3 {0713E8C3-850A-101B-AFC0-4210102A8DA7} 
            Picture         =   "frmMDI.frx":03B4
            Key             =   ""
         EndProperty
         BeginProperty ListImage4 {0713E8C3-850A-101B-AFC0-4210102A8DA7} 
            Picture         =   "frmMDI.frx":058E
            Key             =   "Grid3"
         EndProperty
         BeginProperty ListImage5 {0713E8C3-850A-101B-AFC0-4210102A8DA7} 
            Picture         =   "frmMDI.frx":0768
            Key             =   ""
         EndProperty
         BeginProperty ListImage6 {0713E8C3-850A-101B-AFC0-4210102A8DA7} 
            Picture         =   "frmMDI.frx":0942
            Key             =   ""
         EndProperty
      EndProperty
   End
   Begin VB.Menu MnFile 
      Caption         =   "File"
      Begin VB.Menu MnuLoadCfg 
         Caption         =   "Load Config"
      End
      Begin VB.Menu MnuSaveCfg 
         Caption         =   "Save Config"
      End
      Begin VB.Menu MnExit 
         Caption         =   "Exit"
      End
   End
   Begin VB.Menu MnUnits 
      Caption         =   "Units"
      Begin VB.Menu MnUnitsTemp 
         Caption         =   "Temperature"
         Begin VB.Menu MnUnitsTempC 
            Caption         =   "Celsius (C)"
            Checked         =   -1  'True
         End
         Begin VB.Menu MnUnitsTempF 
            Caption         =   "Fahrenheit (F)"
         End
         Begin VB.Menu MnUnitsTempK 
            Caption         =   "Kelvin (K)"
         End
         Begin VB.Menu MnUnitsTempRaw 
            Caption         =   "Raw Sensor Data"
         End
      End
      Begin VB.Menu MnUnitsPress 
         Caption         =   "Pressure"
         Begin VB.Menu MnUnitsPressAtm 
            Caption         =   "Atmosphere (atm)"
            Checked         =   -1  'True
         End
         Begin VB.Menu MnUnitsPressBar 
            Caption         =   "Bar (bar)"
         End
         Begin VB.Menu MnUnitsPressPa 
            Caption         =   "Pascal (Pa)"
         End
         Begin VB.Menu MnUnitsPressTorr 
            Caption         =   "Per mm Hg (torr)"
         End
         Begin VB.Menu MnUnitsPressPsi 
            Caption         =   "Pounds per square inch (psi)"
         End
         Begin VB.Menu MnUnitsPressRaw 
            Caption         =   "Raw Sensor Data"
         End
      End
      Begin VB.Menu MnUnitsAccel 
         Caption         =   "Acceleration"
         Begin VB.Menu MnUnitsAccelMps 
            Caption         =   "Meters per second (m/s^2)"
         End
         Begin VB.Menu MnUnitsAccelG 
            Caption         =   "Relative gravity (g)"
            Checked         =   -1  'True
         End
         Begin VB.Menu MnUnitsAccelRaw 
            Caption         =   "Raw Sensor Data"
         End
      End
   End
   Begin VB.Menu MnOptions 
      Caption         =   "Options"
      Visible         =   0   'False
      Begin VB.Menu MnDebug 
         Caption         =   "Display Debug"
      End
   End
   Begin VB.Menu MnWindow 
      Caption         =   "Window"
      Begin VB.Menu MnWinDataTbl 
         Caption         =   "Data Table"
         Checked         =   -1  'True
      End
      Begin VB.Menu MnWinDataGraph 
         Caption         =   "Data Graph"
      End
      Begin VB.Menu MnWinRouteMap 
         Caption         =   "Route Map"
      End
      Begin VB.Menu MnWinDBConfig 
         Caption         =   "Database Configuration"
      End
      Begin VB.Menu MnWinQueryControl 
         Caption         =   "Query Control"
      End
   End
   Begin VB.Menu MnHelp 
      Caption         =   "Help"
      Begin VB.Menu MnHelpAbout 
         Caption         =   "About"
      End
   End
   Begin VB.Menu MnData 
      Caption         =   "MoteDisplay"
      Visible         =   0   'False
      Begin VB.Menu MnEU 
         Caption         =   "EU"
         Index           =   1
      End
      Begin VB.Menu MnEU 
         Caption         =   "EU"
         Index           =   2
      End
      Begin VB.Menu MnEU 
         Caption         =   "EU"
         Index           =   3
      End
      Begin VB.Menu MnEU 
         Caption         =   "EU"
         Index           =   4
      End
      Begin VB.Menu MnEU2 
         Caption         =   "Photo"
      End
   End
   Begin VB.Menu MnGridCntrl 
      Caption         =   "GridCntrl"
      Visible         =   0   'False
      Begin VB.Menu MnAscOrdr 
         Caption         =   "Ascending Order"
      End
   End
   Begin VB.Menu MnMotePopup 
      Caption         =   "Mote Info"
      Visible         =   0   'False
      Begin VB.Menu MnMoteRemove 
         Caption         =   "Remove"
      End
      Begin VB.Menu MnMoteNetStat 
         Caption         =   "Network Statistics"
      End
      Begin VB.Menu MnMoteProperties 
         Caption         =   "Properties"
      End
   End
   Begin VB.Menu MnNewMotePopup 
      Caption         =   "New Mote Info"
      Visible         =   0   'False
      Begin VB.Menu MnNewMoteAdd 
         Caption         =   "Add Mote"
      End
   End
End
Attribute VB_Name = "MDIForm1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
''====================================================================
'' frmMDI.frm
''====================================================================
'' DESCRIPTION:  This form is set as the default for the TASKView
''               application.  In essence, the MDI form contains all
''               other forms.
''
'' HISTORY:      mturon      2004/2/11    Initial revision
''
'' $Id: frmMDI.frm,v 1.7 2004/03/31 06:51:28 mturon Exp $
''====================================================================
Option Explicit

Dim bCfgFileOpen As Boolean
Dim sCfgFile As String

Private Sub MDIForm_Load()
    Dim i As Integer
    
    g_unitTemp = UNIT_TYPE_TEMP_C       ' setup default units
    g_unitPress = UNIT_TYPE_PRESS_ATM
    g_unitAccel = UNIT_TYPE_ACCEL_G
    
    'g_MoteCount = 16              'GET THIS FROM TASK !!!!!!!!!!!!!
    'g_NmbDataTypes = 1
      
    g_MapFileName = "xbow.bmp"    'GET THIS FROM TASK !!!!!!!!!!!!!
    
    'display .exe revision #
     MDIForm1.Caption = "TASKView " + " Rev:" + CStr(App.Major) + "." + CStr(App.Minor) + "." + CStr(App.Revision)
    
    gColors(1) = vbRed
    gColors(2) = vbGreen
    gColors(3) = vbCyan
    gColors(4) = vbYellow
    gColors(5) = vbBlue
    gColors(6) = vbMagenta
    gColors(7) = &HFF8080
    gColors(8) = &H80FF80
    gColors(9) = &H8080FF
    gColors(10) = &HFFFF80
    gColors(11) = &H80FFFF
    gColors(12) = &HFF80FF
    gColors(13) = &HCC4080
    gColors(14) = &H40CC80
    gColors(15) = &H4080CC
    gColors(16) = &HCCCC40
    gColors(17) = &H40CCCC
    gColors(18) = &HCC40CC
        
    'init menus
     'MnEUUnits.Checked = True      'use EU units
     'MnEUUnits.Caption = sDsplyADC
     
     Screen.MousePointer = vbDefault
     ChDir App.Path                        'current directory is app path
     StartDB
     OpenMoteConfig                        'open mote config file
    
     ' Get network topology
     'objSQL.GetLastMoteResult
       
     'Load FrmCntrl
     'FrmCntrl.Top = 0
     'FrmCntrl.Left = 0
     AttachFormToDB
     'Unload FrmCntrl

    'display data table
  
    'FrmDataGrid.Hide
    MnWinDataTbl.Checked = True
    'FrmDataGrid.Left = 0
    'FrmDataGrid.Top = 0 ' FrmCntrl.Top + FrmCntrl.Height
    'FrmDataGrid.Height = MDIForm1.Height - FrmCntrl.Height
    'FrmDataGrid.Visible = False
    Load FrmDataGrid
  
    'display route table
    'Load FrmRouteGrid   'done in frmcntrl
    'FrmDataGrid.Hide
    'FrmRouteGrid.Top = FrmDataGrid.Top
    'FrmRouteGrid.Left = FrmDataGrid.Left + FrmDataGrid.Width
    'MnRouteTbl.Checked = True

    'display route map
    Load FrmRouteMap
    FrmRouteMap.Top = 0
    FrmRouteMap.Left = 5500
    FrmRouteMap.Width = 9500
    FrmRouteMap.Height = 8500
    FrmRouteMap.Hide
    MnWinRouteMap.Checked = False
 
    'display data graph
    
    'FrmDataGraph.Top = FrmRouteMap.Top - 200
    FrmDataGraph.Top = 0 ' FrmCntrl.Top + FrmCntrl.Height
    FrmDataGraph.Left = 3000
    FrmDataGraph.Height = MDIForm1.Height * 0.85
    FrmDataGraph.Width = 12000
    Load FrmDataGraph
    FrmDataGraph.Hide
    MnWinDataGraph.Checked = False
    
    'FrmRouteMap.Show
    'FrmDataGraph.Show
    'FrmRouteGrid.Show
    
    'FrmDataGrid.Show
    'FrmCntrl.Show
    'InitElapsedTime
 
End Sub

Private Sub StartDB()
    '
    ' handle connecting and disconnecting data
    '
    
    ' Define some initial conditions
    ReDim Preserve g_DatabaseList(1)
    g_DatabaseList(0) = "task"
    ReDim Preserve QueryList(1)
    QueryList(0).QueryName = "query1"
    QuerySelected = 0
    
    ' create reference to ODBC object
    Set objSQL = New objODBC
    '
    ' populate properties
    objSQL.DataSource = "PostgreSQL30"
    objSQL.DBServer = "localhost"
    objSQL.DBName = "labapp_task"
    objSQL.UserID = "tele"
    objSQL.Password = "tiny"
    'objSQL.SQL = "SELECT * FROM task_attributes"
    'objSQL.SQL = "SELECT * FROM testdata_table"
    'objSQL.DBServer = "barnowl"
    'objSQL.DBName = "task"

    
    'objSQL.Table = "TaskAttributes"
    'objSQL.Table = "QueryResults"
    'objSQL.Key = "name"
    objSQL.Key = "result_time"
    objSQL.ResultSetType = sqlStatic
    objSQL.CursorDriver = sqlUseODBC
    objSQL.LockType = sqlValues
    '
    
    'objSQL.Connect ' establish connection
    
    ' Get List of databases
    'objSQL.GetDatabaseList

    'Get a list of Sensors
    'objSQL.GetSensorNames
    
    'Get a list of TinyDB Queries
    'objSQL.GetQueryList
    
End Sub

Public Sub AttachFormToDB()
    'get # of motes in data base
    TaskInfo.nmb_motes = objSQL.QueryMoteInfo
    'TxtNmbMotes.Text = TaskInfo.nmb_motes
    TaskInfo.DataTimeStart = objSQL.SampleMinTime
    TaskInfo.DataTimeEnd = objSQL.SampleMaxTime
    If TaskDBCfg.bDebugLiveUpdates Then
        TaskDBCfg.TaskActualEndTime = TaskInfo.DataTimeEnd
        TaskInfo.DataTimeEnd = CDate((TaskInfo.DataTimeStart + _
                                    TaskDBCfg.TaskActualEndTime) / 2)
    End If
    
    'setup data grid
    Load FrmDataGrid
  
    '
End Sub

Private Sub MnDebug_Click()
  'If MnDebug.Checked Then
  '  Unload FrmDebug
  '  MnDebug.Checked = False
  'Else
  '  Load FrmDebug
  '  FrmDebug.Show
  '  MnDataGraph.Checked = True
  'End If

End Sub

'################## Menu -- MnMotePopup #######################

Private Sub MnMoteRemove_Click()
    Dim nodeid As Integer
    nodeid = CInt(MnMotePopup.Tag)      ' Grab nodeid from popup tag
    
    Dim moteInfo As objMote
    Set moteInfo = g_MoteInfo.Item(nodeid)
    Dim Msg As String                   ' Display a confirmation dialog

    Msg = "Are you sure you want to remove" & vbLf & _
          "mote #" & moteInfo.m_nodeid & " from the database?"
    MsgBox (Msg)
    
    g_MoteInfo.Remove nodeid            ' Remove the node!

    FrmRouteMap.Picture1.Refresh        ' Update map
End Sub

Private Sub MnMoteNetStat_Click()
    Dim Msg As String
    Dim moteInfo As objMote
    Set moteInfo = g_MoteInfo.Item(CInt(MnMotePopup.Tag))
    Msg = "Network statistics for " & moteInfo.m_name & ":" _
        & vbLf & "     Last epoch = " & moteInfo.m_epoch
    MsgBox (Msg)
End Sub

Private Sub MnMoteProperties_Click()
    FrmMoteProp.Tag = MnMotePopup.Tag
    FrmMoteProp.Show
End Sub

'################## Menu -- MnNewMotePopup ####################

Private Sub MnNewMoteAdd_Click()
    Dim nodeid As Integer
    nodeid = MoteTableNextNodeId
    
    Dim newMoteInfo As objMote
    Set newMoteInfo = New objMote
    newMoteInfo.m_flags = 0            ' new mote!
    newMoteInfo.m_nodeid = nodeid
    newMoteInfo.m_parent = 0
    newMoteInfo.m_x = g_mouseX
    newMoteInfo.m_y = g_mouseY
    newMoteInfo.m_color = gColors((nodeid Mod MAX_NODE_COLORS) + 1)
    Dim calibData(4) As Long
    newMoteInfo.m_calib = calibData
    
    g_MoteInfo.Add nodeid, newMoteInfo
    
    FrmRouteMap.Picture1.Refresh
End Sub

'################## Menu -- MnHelpPopup #######################

Private Sub MnHelpAbout_Click()
    Dim Msg As String
    Msg = MDIForm1.Caption + vbLf + vbLf _
        + "  Copyright (c) 2004 Crossbow, Inc." + vbLf _
        + "  All rights reserved." + vbLf + vbLf _
        + "  Contributors: " + vbLf + vbLf _
        + "      Alan Broad, Jaidev Prabhu, Martin Turon"
    MsgBox (Msg)
End Sub


'################## Menu -- MnWindow #########################

Private Sub MnWinDataTbl_Click()
  If MnWinDataTbl.Checked Then
    FrmDataGrid.Hide
    MnWinDataTbl.Checked = False
  Else
    FrmDataGrid.Show
    MnWinDataTbl.Checked = True
  End If
End Sub

Private Sub MnWinDataGraph_Click()
    If MnWinDataGraph.Checked Then
        FrmDataGraph.Hide
        MnWinDataGraph.Checked = False
    Else
        FrmDataGraph.Show
        MnWinDataGraph.Checked = True
    End If
End Sub

Private Sub MnWinRouteMap_Click()
  If MnWinRouteMap.Checked Then
    FrmRouteMap.Hide
    MnWinRouteMap.Checked = False
  Else
    FrmRouteMap.Show
    MnWinRouteMap.Checked = True
  End If
End Sub

Private Sub MnWinDBConfig_Click()
  If MnWinDBConfig.Checked Then
    FrmDBCfg.Hide
    MnWinDBConfig.Checked = False
  Else
    FrmDBCfg.Show
    MnWinDBConfig.Checked = True
  End If
End Sub

Private Sub MnWinQueryControl_Click()
  If MnWinQueryControl.Checked Then
    FrmQuery.Hide
    MnWinQueryControl.Checked = False
  Else
    FrmQuery.Show
    MnWinQueryControl.Checked = True
  End If
End Sub


'################## Menu -- MnUnits ###########################

Private Sub MnUnitsPressClrChecked()
    MnUnitsPressAtm.Checked = False
    MnUnitsPressBar.Checked = False
    MnUnitsPressPa.Checked = False
    MnUnitsPressPsi.Checked = False
    MnUnitsPressTorr.Checked = False
    MnUnitsPressRaw.Checked = False
End Sub

Private Sub MnUnitsPressAtm_Click()
    MnUnitsPressClrChecked
    MnUnitsPressAtm.Checked = True
    g_unitPress = UNIT_TYPE_PRESS_ATM
    FrmDataGrid.Grid_Display_Data
End Sub
Private Sub MnUnitsPressBar_Click()
    MnUnitsPressClrChecked
    MnUnitsPressBar.Checked = True
    g_unitPress = UNIT_TYPE_PRESS_BAR
    FrmDataGrid.Grid_Display_Data
End Sub
Private Sub MnUnitsPressPa_Click()
    MnUnitsPressClrChecked
    MnUnitsPressPa.Checked = True
    g_unitPress = UNIT_TYPE_PRESS_PA
    FrmDataGrid.Grid_Display_Data
End Sub
Private Sub MnUnitsPressPsi_Click()
    MnUnitsPressClrChecked
    MnUnitsPressPsi.Checked = True
    g_unitPress = UNIT_TYPE_PRESS_PSI
    FrmDataGrid.Grid_Display_Data
End Sub
Private Sub MnUnitsPressTorr_Click()
    MnUnitsPressClrChecked
    MnUnitsPressTorr.Checked = True
    g_unitPress = UNIT_TYPE_PRESS_TORR
    FrmDataGrid.Grid_Display_Data
End Sub
Private Sub MnUnitsPressRaw_Click()
    MnUnitsPressClrChecked
    MnUnitsPressRaw.Checked = True
    g_unitPress = UNIT_TYPE_ALL_RAW
    FrmDataGrid.Grid_Display_Data
End Sub

Private Sub MnUnitsTempClrChecked()
    MnUnitsTempC.Checked = False
    MnUnitsTempF.Checked = False
    MnUnitsTempK.Checked = False
    MnUnitsTempRaw.Checked = False
End Sub
Private Sub MnUnitsTempC_Click()
    MnUnitsTempClrChecked
    MnUnitsTempC.Checked = True
    g_unitTemp = UNIT_TYPE_TEMP_C
    FrmDataGrid.Grid_Display_Data
End Sub
Private Sub MnUnitsTempF_Click()
    MnUnitsTempClrChecked
    MnUnitsTempF.Checked = True
    g_unitTemp = UNIT_TYPE_TEMP_F
    FrmDataGrid.Grid_Display_Data
End Sub
Private Sub MnUnitsTempK_Click()
    MnUnitsTempClrChecked
    MnUnitsTempK.Checked = True
    g_unitTemp = UNIT_TYPE_TEMP_K
    FrmDataGrid.Grid_Display_Data
End Sub
Private Sub MnUnitsTempRaw_Click()
    MnUnitsTempClrChecked
    MnUnitsTempRaw.Checked = True
    g_unitTemp = UNIT_TYPE_ALL_RAW
    FrmDataGrid.Grid_Display_Data
End Sub


Private Sub MnUnitsAccelClrChecked()
    MnUnitsAccelG.Checked = False
    MnUnitsAccelMps.Checked = False
    MnUnitsAccelRaw.Checked = False
End Sub
Private Sub MnUnitsAccelG_Click()
    MnUnitsAccelClrChecked
    MnUnitsAccelG.Checked = True
    g_unitAccel = UNIT_TYPE_ACCEL_G
    FrmDataGrid.Grid_Display_Data
End Sub
Private Sub MnUnitsAccelMps_Click()
    MnUnitsAccelClrChecked
    MnUnitsAccelMps.Checked = True
    g_unitAccel = UNIT_TYPE_ACCEL_MPS2
    FrmDataGrid.Grid_Display_Data
End Sub
Private Sub MnUnitsAccelRaw_Click()
    MnUnitsAccelClrChecked
    MnUnitsAccelRaw.Checked = True
    g_unitAccel = UNIT_TYPE_ALL_RAW
    FrmDataGrid.Grid_Display_Data
End Sub

Private Sub MDIForm_QueryUnload(Cancel As Integer, unloadmode As Integer)
   'Dim Msg   ' Declare variable.
   ' Set the message text.
   'Msg = "Do you really want to exit the application?"
   ' If user clicks the No button, stop QueryUnload.
   'If MsgBox(Msg, vbQuestion + vbYesNo, Me.Caption) = vbYes Then End
   objSQL.Disconnect
   End
End Sub
Private Sub MDIform_Terminate()
' completely terminate the program
    Unload FrmRouteMap
    Unload FrmDataGrid
    End
End Sub

Private Sub MnExit_Click()
'terminate progra
  End
End Sub

'====================================================================
' MnuLoadCfg_Click
'====================================================================
' DESCRIPTION:  Opens file dialog, and loads the selected config file.
'               Much here is replicated from cbOpen_Click and
' HISTORY:      mturon      2004/2/26   Initial version
'
Private Sub MnuLoadCfg_Click()
   ' Grab the user selected filename from the file dialog
    Dim cfgFilename As String
    FrmDBCfg.cfgFileDialog.ShowOpen
    cfgFilename = FrmDBCfg.cfgFileDialog.filename
    If (cfgFilename = "") Then
        MsgBox ("Filename: " + cfgFilename + " not valid.")
        Exit Sub
    End If
    
    ' Load config data from file
    If MoteFileReadCfg(cfgFilename) = True Then
        ' If a reset occurred, repopulate
        'FrmDBCfg.lbQueryList_Populate
        FrmRouteMap.Picture1.Refresh
    End If
    
    ' Update UI from globals after opening config.
    'FrmDBCfg.tbServerName.Text = objSQL.DBServer
    'FrmDBCfg.lbDatabaseList.Text = objSQL.DBName
    'FrmDBCfg.ctSensorsList_Populate
    
    ' Update the date range for the new table!
    TaskInfo.DataTimeStart = objSQL.SampleMinTime
    TaskInfo.DataTimeEnd = objSQL.SampleMaxTime
    FrmDataGrid.Update_TimeScales
    
    Dim nIndex As Integer
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
    
End Sub


Private Sub MnuSaveCfg_Click()
    'save a version of the config file
    If Not bCfgFileOpen Then
        MsgBox ("Err: Need to open a config file first")
    End If
    MoteFileWriteCfg (sCfgFile)
End Sub

Private Sub OpenMoteConfig()
'Open the mote configuration file
Dim sFileName, sStr As String
'Dim mobj As MoteObj
'Dim MoteId As String
   
   On Error GoTo ErrHandler                                      ' CancelError is True.
   CommonDialog1.Filter = "MOTE Files (*.txt)|*.txt"
   CommonDialog1.FilterIndex = 1                                ' Specify default filter.
   CommonDialog1.ShowOpen
   sCfgFile = CommonDialog1.filename
   'If Not (MoteConfigFileRead(sCfgFile)) Then
        ' End
   'End If
   bCfgFileOpen = False

   MoteFileReadCfg (sCfgFile)
   
   bCfgFileOpen = True
 Exit Sub

ErrHandler:
   MsgBox ("Err:Can't open config file")
End Sub


Private Sub Toolbar1_ButtonClick(ByVal Button As ComctlLib.Button)
 Select Case Button.Key
  Case "DataGrid":
     MnWinDataTbl.Checked = True
     FrmDataGrid.Show
     FrmDataGrid.ZOrder
  Case "DataGraph":
     MnWinDataGraph.Checked = True
     FrmDataGraph.Show
     FrmDataGraph.ZOrder
  Case "RouteMap":
     MnWinRouteMap.Checked = True
     FrmRouteMap.Show
     FrmRouteMap.ZOrder
  Case "DBConfig":
     MnWinDBConfig.Checked = True
     FrmDBCfg.Show
     FrmDBCfg.ZOrder
 End Select
End Sub
