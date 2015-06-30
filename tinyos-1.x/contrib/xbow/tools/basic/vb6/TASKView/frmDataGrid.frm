VERSION 5.00
Object = "{6B7E6392-850A-101B-AFC0-4210102A8DA7}#1.3#0"; "comctl32.ocx"
Object = "{5E9E78A0-531B-11CF-91F6-C2863C385E30}#1.0#0"; "MSFLXGRD.OCX"
Begin VB.Form FrmDataGrid 
   Caption         =   "Data Table"
   ClientHeight    =   6912
   ClientLeft      =   19848
   ClientTop       =   1128
   ClientWidth     =   7104
   LinkTopic       =   "Form1"
   MDIChild        =   -1  'True
   ScaleHeight     =   6912
   ScaleWidth      =   7104
   Begin VB.Frame Frame1 
      Caption         =   "Charts"
      Height          =   1575
      Left            =   120
      TabIndex        =   1
      Top             =   5160
      Width           =   5655
      Begin VB.CheckBox ckLiveUpdate 
         Caption         =   "Live Update"
         Height          =   255
         Left            =   1200
         TabIndex        =   10
         Top             =   1200
         Width           =   255
      End
      Begin VB.TextBox tbEndTime 
         Height          =   285
         Left            =   960
         TabIndex        =   8
         Top             =   840
         Width           =   1815
      End
      Begin VB.TextBox tbStartTime 
         Height          =   285
         Left            =   960
         TabIndex        =   7
         Top             =   360
         Width           =   1815
      End
      Begin ComctlLib.Slider sldEndTime 
         Height          =   255
         Left            =   2880
         TabIndex        =   6
         Top             =   840
         Width           =   1455
         _ExtentX        =   2561
         _ExtentY        =   445
         _Version        =   327682
         Min             =   1
         Max             =   100
         SelectRange     =   -1  'True
         SelStart        =   100
         TickFrequency   =   10
         Value           =   100
      End
      Begin ComctlLib.Slider sldStartTime 
         Height          =   255
         Left            =   2880
         TabIndex        =   5
         Top             =   360
         Width           =   1455
         _ExtentX        =   2561
         _ExtentY        =   445
         _Version        =   327682
         Max             =   99
         SelectRange     =   -1  'True
         TickFrequency   =   10
         Value           =   1
      End
      Begin VB.CommandButton cmdUpdate 
         Caption         =   "Plot Graph"
         Height          =   615
         Left            =   4560
         TabIndex        =   2
         Top             =   360
         Width           =   975
      End
      Begin VB.Label lbLiveUpdate 
         Caption         =   "Live Updates"
         Height          =   255
         Left            =   120
         TabIndex        =   9
         Top             =   1200
         Width           =   1095
      End
      Begin VB.Label Label2 
         Caption         =   "End Time"
         Height          =   255
         Left            =   120
         TabIndex        =   4
         Top             =   840
         Width           =   975
      End
      Begin VB.Label Label1 
         Caption         =   "Start Time"
         Height          =   255
         Left            =   120
         TabIndex        =   3
         Top             =   360
         Width           =   975
      End
   End
   Begin VB.Timer Timer1 
      Enabled         =   0   'False
      Left            =   120
      Top             =   1320
   End
   Begin MSFlexGridLib.MSFlexGrid Grid1 
      Height          =   1200
      Left            =   120
      TabIndex        =   0
      Top             =   0
      Width           =   5115
      _ExtentX        =   9017
      _ExtentY        =   2117
      _Version        =   393216
      Rows            =   5
      Cols            =   5
      FixedRows       =   2
      BackColor       =   -2147483633
      ForeColor       =   0
      BackColorFixed  =   12632256
      ForeColorFixed  =   0
      GridColor       =   8388608
      Redraw          =   -1  'True
      AllowBigSelection=   0   'False
      ScrollTrack     =   -1  'True
      FocusRect       =   2
      HighLight       =   0
      AllowUserResizing=   3
      BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "MS Sans Serif"
         Size            =   7.8
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
   End
End
Attribute VB_Name = "FrmDataGrid"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
''====================================================================
'' frmDataGrid.frm
''====================================================================
'' DESCRIPTION:  Module to control display grid on frmcntrl.
''
'' HISTORY:      mturon      2004/3/3    Initial revision
''
'' $Id: frmDataGrid.frm,v 1.2 2004/05/07 22:28:43 mturon Exp $
''====================================================================
Option Explicit

Const GRID_ROWS = 15                    '# of rows in grid control
Const GRID_COLS = 10                    '# of col in grid control
         
'Const GRID_CELL_COLOR_1 = &H8000000F   ' ToolTip
'Const GRID_CELL_COLOR_2 = &H80000018   ' Button Face
    
Const GRID_CELL_COLOR_1 = &HE0E0E0      ' Light Yellow
Const GRID_CELL_COLOR_2 = &HD0FFFF      ' Light Grey
    
Dim GridLastCol As Integer

Private Sub ckLiveUpdate_Click()

    If ckLiveUpdate.Value = vbChecked Then
        tbEndTime.BackColor = &H8000000F  ' Greyed Out
        tbEndTime.Enabled = False
        sldEndTime.Enabled = False
        Timer1.Interval = TIME_LIVE_UPDATE_GRID
        Timer1.Enabled = False
        Timer1.Enabled = True
    Else
        Update_TimeScales
        sldEndTime.Enabled = True
        tbEndTime.BackColor = &H80000005  ' White
        tbEndTime.Enabled = True
        Timer1.Interval = TIME_UPDATE_GRID
    End If
        
End Sub

Private Sub cmdUpdate_Click()
    ' Do this in the update button
    FrmDataGraph.GraphHistory
    
End Sub
Private Sub Form_Load()
    
    Grid_Add_Motes
 
    Update_TimeScales
    
    'enable timer to update graphs
    Timer1.Interval = 500           'timer interrupt (msec)
    Timer1.Enabled = True
End Sub

Private Sub Form_Resize()
' Bail out on minimized...
'    If FrmDataGrid.Width < Frame1.Width + 300 Then
'        FrmDataGrid.Width = Frame1.Width + 300
'    End If
'    If FrmDataGrid.Height < Frame1.Height Then
'        FrmDataGrid.Height = Frame1.Height
'    End If

'    Grid1.Width = FrmDataGrid.Width - 1700
'    Grid1.Height = FrmDataGrid.Height - 500
End Sub

'====================================================================
' Grid_Add_Motes
'====================================================================
' DESCRIPTION:
' HISTORY:      abroad      2004/1/15    Initial version
'               mturon      2004/2/27    Added units display
'
Sub Grid_Add_Motes()
'Add motes into grid
'This version:
'  - TaskInfo defines number of motes, number of sensors on each mote, sensor name
'  - One row for each mote

Dim moteId As String
Dim i As Integer
Dim s As Variant

Const COL_SIZE = 1000
Const COL_ID_SIZE = 750
  
    FrmDataGrid.Visible = False
    FrmDataGrid.Hide
    
    Grid1.ColWidth(0) = COL_ID_SIZE
    Grid1.Width = Grid1.ColWidth(0)
    Grid1.Cols = TaskInfo.nmb_sensors + 2  ' include Node ID and Time Columns
'    Grid1.Rows = TaskInfo.nmb_motes + Grid1.FixedRows   ' include Header Row
    i = g_MoteInfo.Count
    If (i > 0) Then i = i - 1           ' don't count gateway
    Grid1.Rows = i + Grid1.FixedRows    ' include Header Row
    
    For i = 1 To Grid1.Cols - 2
        Grid1.ColWidth(i) = COL_SIZE
        Grid1.Width = Grid1.Width + COL_SIZE
    Next i

    'Set this up
    GridLastCol = i
    
    'setup time col
    Grid1.ColWidth(GridLastCol) = 2 * COL_SIZE
    Grid1.Width = Grid1.Width + Grid1.ColWidth(GridLastCol)

    'setup window size
    Grid1.Height = Grid1.RowHeight(0) * (Grid1.Rows + 1)
 
    ' Enter Header Text
    Grid1.col = 0
    Grid1.Row = 0
    Grid1.Text = "Node Id"
    For i = 1 To TaskInfo.nmb_sensors
        Grid1.col = i
        Grid1.Text = TaskInfo.sensor(i)
    Next i

    Grid1.col = GridLastCol
    Grid1.Text = "Time"
    
    
    ' Enter Header Text
    Grid1.col = 0
    Grid1.Row = 1
    Grid1.Text = " Units ="

    Grid1.col = GridLastCol
    Grid1.Text = ""
    
    ' Enter Node Ids for each mote except basestation
    'Grid1.col = 0
    'For i = 1 To TaskInfo.nmb_motes
    '    Grid1.Row = i
    '    Grid1.Text = TaskInfo.mote_id(i)
    'Next i

    ' Place Frame below the Data Grid
    Frame1.Top = Grid1.Top + Grid1.Height
 
    ' Recompute Form Height
    FrmDataGrid.Top = 0
    FrmDataGrid.Left = 0
    FrmDataGrid.Height = Grid1.Height + Frame1.Height + 500
    FrmDataGrid.Width = Grid1.Width + 250
    FrmDataGrid.Visible = True
    FrmDataGrid.Show
    

End Sub

Private Sub sldEndTime_Change()
    
    ' Prevent End time from being equal to or lesser than start time
    If sldEndTime.Value <= sldStartTime.Value Then
        sldEndTime.Value = sldStartTime.Value + #12:01:00 AM#
    End If
        
    TaskInfo.GraphPlotEndTime = CDate(g_dbTimeScaledValues(sldEndTime.Value))
    tbEndTime.Text = CStr(TaskInfo.GraphPlotEndTime)

End Sub

Private Sub sldStartTime_Change()

    ' Prevent Start time from being equal to or greater than end time
    If sldStartTime.Value >= sldEndTime.Value Then
        sldStartTime.Value = sldEndTime.Value - #12:01:00 AM#
    End If
    
    If sldStartTime.Value = 0 Then
        tbStartTime.Text = CStr(TaskInfo.DataTimeStart)
        TaskInfo.GraphPlotStartTime = TaskInfo.DataTimeStart
    Else
        TaskInfo.GraphPlotStartTime = CDate(g_dbTimeScaledValues(sldStartTime.Value))
        tbStartTime.Text = CStr(TaskInfo.GraphPlotStartTime)
    End If
 
    
End Sub

'====================================================================
' Grid_Display_Data
'====================================================================
' DESCRIPTION:  Refreshes the data grid with the latest from the database.
' HISTORY:      abroad      2003/?       Initial version
'               mturon      2004/2/27    Added units / interlaced colors
'
Public Sub Grid_Display_Data()
'display all mote data
    Dim i, j As Integer
    Dim nodeid As Integer
    Dim v As Variant
    Dim moteInfo As objMote

    'flash beacon during data base update
    'FrmCntrl.TxtBeacon.BackColor = COLOR_SAMPLING

    FrmDataGrid.MousePointer = vbHourglass
    objSQL.QueryDataFill
    
    'Hide the Grid for faster update
    'FrmDataGrid.Hide
    Grid1.Visible = False
    'Grid1.BackColorSel = &H8000000F
    'Grid1.CellBackColor = &H8000000F
    
    ' Refresh units
    Grid1.Row = 1
    For j = 1 To TaskInfo.nmb_sensors
        Grid1.col = j
        Grid1.Text = UnitEngGetName(TaskInfo.sensor(j))
    Next
    
    ' Insure grid is large enough
    If Grid1.Rows < Grid1.FixedRows + g_MoteInfo.Count Then
        Grid1.Rows = Grid1.FixedRows + g_MoteInfo.Count
    End If
    
    i = 1
    For Each v In g_MoteInfo.Items
'    For i = 1 To TaskInfo.nmb_motes
        Set moteInfo = v
        
        ' Refresh data
        nodeid = moteInfo.m_nodeid
        If (nodeid > 0) And _
            (moteInfo.m_flags And MF_SAVED) Then      'ignore basestation
            ' Inset Node ID
            Grid1.Row = i + Grid1.FixedRows - 1
            Grid1.col = 0
            Grid1.CellAlignment = flexAlignLeftTop
            'Grid1.CellBackColor = &H8000000F
            Grid1.Text = CStr(nodeid) 'moteInfo.m_name
            
            ' Insert Sensor Values
            For j = 1 To TaskInfo.nmb_sensors
                Grid1.col = j
                Grid1.CellAlignment = flexAlignLeftTop
                'Grid1.CellBackColor = &H8000000F
                If Grid1.CellBackColor <> vbWhite Then
                    If Grid1.Row Mod 2 Then
                        Grid1.CellBackColor = GRID_CELL_COLOR_1
                    Else
                        Grid1.CellBackColor = GRID_CELL_COLOR_2
                    End If
                End If
                
                Dim engUnit As Single
                Dim sensorName As String
                sensorName = TaskInfo.sensor(j)  ' Get sensor name
                engUnit = UnitEngConvert(TaskDataArray(nodeid).Value(j), _
                            sensorName, nodeid)
                Grid1.Text = engUnit    'FormatNumber(engUnit, 3)
            Next j
                        
            ' Insert Reading Time
            Grid1.col = GridLastCol
            Grid1.CellAlignment = flexAlignLeftTop
            'Grid1.CellBackColor = &H8000000F
            If Grid1.CellBackColor <> vbWhite Then
                If Grid1.Row Mod 2 Then
                    Grid1.CellBackColor = GRID_CELL_COLOR_1
                Else
                    Grid1.CellBackColor = GRID_CELL_COLOR_2
                End If
            End If
            Grid1.Text = CStr(TaskDataArray(nodeid).Time) 'CStr(moteInfo.m_time)
            i = i + 1
        End If
    Next

    ' Highlight Graph-Plot Selected Cells
    'SensorHistoryList
    
    Grid1.Visible = True
'    FrmDataGrid.Show
    FrmDataGrid.MousePointer = vbDefault
    
    ' Resize Form to show all Motes
    'Grid1.Height = FrmDataGrid.Height - 200
    Grid1.ScrollBars = flexScrollBarVertical
    'FrmCntrl.TxtBeacon.BackColor = COLOR_DEF
    
End Sub

' HISTORY:      jpradha      2003/?    Initial version
Private Function AddToSensorPlotList(nodeNum As Integer, sensorName As String) As Boolean
Dim i, j As Integer
    
    For i = 1 To MAX_GRAPHS
    
        ' First find out if a graph is already present for this "sensorName"
        If (StrComp(sensorName, SensorHistoryList(i).sensorName, vbTextCompare) = 0) Then
            
            ' Now find out if we can plot it in this graph
            ' ie. we are not reached nodeIds=MAX_PLOTS
            If SensorHistoryList(i).numPlots = MAX_PLOTS Then
                AddToSensorPlotList = False
                Exit Function
            End If
            
            ' Max not reached, so add plot for this node
            SensorHistoryList(i).numPlots = SensorHistoryList(i).numPlots + 1
            SensorHistoryList(i).nodeIds(SensorHistoryList(i).numPlots) = nodeNum
            AddToSensorPlotList = True
            Exit Function
        End If
        
        'There isn't a graph with this sensor name
        'So, if there is an empty slot, add this sensor to the list
        If (StrComp(SensorHistoryList(i).sensorName, "") = 0) Then
            'there is an empty spot
            SensorHistoryList(i).numPlots = 1
            SensorHistoryList(i).nodeIds(1) = nodeNum
            SensorHistoryList(i).sensorName = sensorName
            AddToSensorPlotList = True
            Exit Function
        End If
            
    Next i
        
    AddToSensorPlotList = False
    
End Function

' HISTORY:      jpradha      2003/?    Initial version
Private Sub DeleteFromSensorPlotList(nodeNum As Integer, sensorName As String)
Dim i, j, k As Integer
    
    For i = 1 To MAX_GRAPHS
    
        ' First find out if this graph corresponds to this "sensorName"
        If (StrComp(sensorName, SensorHistoryList(i).sensorName, vbTextCompare) = 0) Then
            
            ' Now find out if we can this was the only plot for this graph
            If SensorHistoryList(i).numPlots = 1 Then
                SensorHistoryList(i).numPlots = 0
                SensorHistoryList(i).sensorName = ""
                Exit For
            End If
            
            ' Max not reached, so find this entry in the list and delete it
            For j = 1 To SensorHistoryList(i).numPlots
                If (SensorHistoryList(i).nodeIds(j) = nodeNum) Then
                    SensorHistoryList(i).numPlots = _
                        SensorHistoryList(i).numPlots - 1
                    ' Copy rest of the Node ids one index ahead
                    For k = j To SensorHistoryList(i).numPlots
                        SensorHistoryList(i).nodeIds(k) = _
                            SensorHistoryList(i).nodeIds(k + 1)
                    Next k
                    Exit Sub
                End If
            Next j
        End If
    Next i
    
    ' We have deleted a graph, so we have to copy rest of the stuff
    '   one index down
    
    ' Nothing to do since this was the last graph
    If i = MAX_GRAPHS Then Exit Sub
    
    For j = i To MAX_GRAPHS - 1
        SensorHistoryList(j).sensorName = SensorHistoryList(j + 1).sensorName
        SensorHistoryList(j + 1).sensorName = ""
        SensorHistoryList(j).numPlots = SensorHistoryList(j + 1).numPlots
        For k = 1 To SensorHistoryList(j + 1).numPlots
            SensorHistoryList(j).nodeIds(k) = SensorHistoryList(j + 1).nodeIds(k)
        Next k
    Next j
        
End Sub

Private Sub Grid1_Click()
' Grid mouse click
' If sensor value then plot sensor

Dim iRow, iCol As Integer
Dim nodeNum As Integer
Dim sensorName As String
Dim startTime As Date
Dim endTime As Date
Dim junk As Integer

  
    iRow = Grid1.MouseRow
    iCol = Grid1.MouseCol
           
    'Ignore Header Row
    If (iRow = 0) Then Exit Sub
    
    'Ignore clicks on NodeID and ResultTime columns
    If (iCol = GridLastCol) Then Exit Sub
    If (iCol = 0) Then
        'MDIForm1.MnMotePopup.Tag = nodeNum
        'PopupMenu MDIForm1.MnMotePopup
        Exit Sub
    End If
        
    'Get the SensorName
    sensorName = TaskInfo.sensor(iCol)
    ' Ignore clicks before data is filled in the first time
    If sensorName = "" Then Exit Sub
    
    ' Intercept Clicks on Unit cell
    If (iRow < Grid1.FixedRows) Then
        EngUnitPopup (TaskInfo.sensor(iCol))
        Exit Sub
    End If
              
    'Get the Node Id
    Grid1.Row = iRow
    Grid1.col = 0
    ' Ignore clicks before data is filled in the first time
    If Grid1.Text = "" Then Exit Sub
    
    nodeNum = CInt(Grid1.Text)
        
    'Grid1.Row = iRow
    Grid1.col = iCol
    
    ' If this cell is previously selected for a plot, then remove it
    If Grid1.CellBackColor = vbWhite Then
        DeleteFromSensorPlotList nodeNum, sensorName
        If Grid1.Row Mod 2 Then
            Grid1.CellBackColor = GRID_CELL_COLOR_1
        Else
            Grid1.CellBackColor = GRID_CELL_COLOR_2
        End If
        Exit Sub
    End If
    
    ' else add it for a plot
    If (AddToSensorPlotList(nodeNum, sensorName) = False) Then
        ' Either max plot or max graphs have been reached
        MsgBox "No more plots!", vbOKOnly, "Warning!"
        Exit Sub
    End If
        
    Grid1.CellBackColor = vbWhite
            
End Sub

Public Sub Update_TimeScales()
Dim dbStartTime As Double
Dim dbEndTime As Double
Dim dbDiff As Double
Dim i As Integer

    ' Insert Start and End Times
    tbStartTime.Text = CStr(TaskInfo.DataTimeStart)
    tbEndTime.Text = CStr(TaskInfo.DataTimeEnd)
    sldStartTime.Value = 0
    sldEndTime.Value = 100
    
    TaskInfo.GraphPlotStartTime = TaskInfo.DataTimeStart
    TaskInfo.GraphPlotEndTime = TaskInfo.DataTimeEnd
 
    dbStartTime = CDbl(CDate(tbStartTime.Text))
    dbEndTime = CDbl(CDate(tbEndTime.Text))
    dbDiff = dbEndTime - dbStartTime
    
    For i = 1 To 100
        g_dbTimeScaledValues(i) = dbStartTime + (i / 100 * dbDiff)
    Next i

End Sub

'====================================================================
' EngUnitPopup
'====================================================================
' DESCRIPTION:  Shows the popup menu for unit selection of a given sensor.
' HISTORY:      mturon      2004/2/27    Initial version
'
Public Sub EngUnitPopup(sensorName As String)
        
    Select Case sensorName    ' Jump table of popup menus based on name
        Case "humtemp"
            PopupMenu MDIForm1.MnUnitsTemp
        Case "prtemp"
            PopupMenu MDIForm1.MnUnitsTemp
        Case "humid"
        Case "taosbot"
        Case "toastop"
        Case "hamatop"
        Case "hamabot"
        Case "press"
            PopupMenu MDIForm1.MnUnitsPress

        ' Other sensors
        Case "light"
        Case "accel_x"
            PopupMenu MDIForm1.MnUnitsAccel
        Case "accel_y"
            PopupMenu MDIForm1.MnUnitsAccel
        Case "mag_x"
        Case "mag_y"
        
        ' Malexis sensor reading
        Case "temp"
            PopupMenu MDIForm1.MnUnitsTemp
        Case "thmtemp"
    End Select

End Sub

Private Sub Timer1_Timer()
'update data display grid
    
    'If TaskDBCfg.bDebugLiveUpdates Then
        'TaskInfo.DataTimeEnd = TaskInfo.DataTimeEnd + CDate(1)
        'If TaskInfo.DataTimeEnd > TaskDBCfg.TaskActualEndTime Then
        '    TaskInfo.DataTimeEnd = TaskDBCfg.TaskActualEndTime
        'End If
        'Timer1.Interval = DEBUG_TIME_UPDATE_GRID
    'Else
        'Timer1.Interval = TIME_UPDATE_GRID
    'End If
    
    Grid_Display_Data
    Update_TimeScales
    
    ' If live updates checkbox is selected, plot Live Updates for Graphs
    If ckLiveUpdate.Value = vbChecked Then
        Timer1.Interval = TIME_LIVE_UPDATE_GRID
    Else
        Timer1.Interval = TIME_UPDATE_GRID
    End If
    
End Sub
