VERSION 5.00
Object = "{F9043C88-F6F2-101A-A3C9-08002B2F49FB}#1.2#0"; "comdlg32.ocx"
Begin VB.Form FrmRouteMap 
   Caption         =   "Route Map"
   ClientHeight    =   6420
   ClientLeft      =   60
   ClientTop       =   348
   ClientWidth     =   6960
   FillStyle       =   0  'Solid
   LinkTopic       =   "Form1"
   MDIChild        =   -1  'True
   ScaleHeight     =   6420
   ScaleWidth      =   6960
   Begin MSComDlg.CommonDialog bmpFileDialog 
      Left            =   4320
      Top             =   5880
      _ExtentX        =   847
      _ExtentY        =   847
      _Version        =   393216
      Filter          =   "Image Files|*.bmp;*.jpg;*.jpeg"
   End
   Begin VB.Frame Frame1 
      Caption         =   "Network Topology Map"
      Height          =   6132
      Left            =   0
      TabIndex        =   5
      Top             =   0
      Width           =   5220
      Begin VB.PictureBox Picture1 
         BackColor       =   &H00C0C0C0&
         DrawStyle       =   2  'Dot
         DrawWidth       =   3
         FillStyle       =   0  'Solid
         BeginProperty Font 
            Name            =   "MS Sans Serif"
            Size            =   7.8
            Charset         =   0
            Weight          =   700
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         ForeColor       =   &H8000000E&
         Height          =   3132
         Left            =   120
         ScaleHeight     =   3084
         ScaleWidth      =   3444
         TabIndex        =   6
         Top             =   240
         Width           =   3492
         Begin VB.Timer Timer1 
            Left            =   240
            Top             =   1200
         End
         Begin VB.Label MotePopupLabel 
            BackColor       =   &H80000018&
            Caption         =   "Name ="
            Height          =   975
            Left            =   1200
            TabIndex        =   8
            Top             =   1800
            Visible         =   0   'False
            Width           =   2055
         End
         Begin VB.Shape DragShape 
            DrawMode        =   7  'Invert
            FillColor       =   &H00008000&
            FillStyle       =   0  'Solid
            Height          =   375
            Left            =   1920
            Shape           =   3  'Circle
            Top             =   960
            Visible         =   0   'False
            Width           =   375
         End
      End
   End
   Begin VB.PictureBox PictureSrc 
      AutoSize        =   -1  'True
      Height          =   4096
      Left            =   120
      ScaleHeight     =   4044
      ScaleWidth      =   4044
      TabIndex        =   4
      Top             =   2280
      Visible         =   0   'False
      Width           =   4096
   End
   Begin VB.Frame Frame2 
      Caption         =   "Layout Tools"
      Height          =   6132
      Left            =   5280
      TabIndex        =   0
      Top             =   0
      Width           =   1500
      Begin VB.CommandButton rmLoadMapButton 
         Caption         =   "Load"
         Height          =   375
         Left            =   0
         TabIndex        =   7
         Top             =   240
         Width           =   735
      End
      Begin VB.CommandButton rmRefreshMapButton 
         Caption         =   "Refresh"
         Height          =   372
         Left            =   360
         TabIndex        =   2
         Top             =   720
         Width           =   735
      End
      Begin VB.CommandButton rmSaveMapButton 
         Caption         =   "Save"
         Height          =   372
         Left            =   720
         TabIndex        =   1
         Top             =   240
         Width           =   732
      End
      Begin VB.Label Label1 
         Caption         =   "New Motes:"
         Height          =   255
         Left            =   120
         TabIndex        =   3
         Top             =   1200
         Width           =   975
      End
   End
End
Attribute VB_Name = "FrmRouteMap"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
''====================================================================
'' frmRouteMap.frm
''====================================================================
'' DESCRIPTION:  This module displays a facility background picture with
''               superimposed mote icon.  Shows message routing from
''               mote->mote->..->base station
''
'' HISTORY:      mturon      2004/2/13    Initial revision
''
'' $Id: frmRouteMap.frm,v 1.3 2004/03/29 23:07:55 mturon Exp $
''====================================================================
Option Explicit

Const MOTE_NODE_RADIUS = 130
Const MOTE_NODE_COLOR = vbCyan
Const MOTE_NODE_TRACE = vbBlack
Const MOTE_GLOW_RADIUS = 200
Const MOTE_GLOW_COLOR = vbMagenta
Const MOTE_GLOW_TRACE = vbBlack
Const MOTE_LINK_COLOR = vbGreen
Const MOTE_TEXT_COLOR = vbBlue
Const MOTE_FAIL_COLOR = &H4040C0    ' was vbRed, now light red

' Variables of scope: Module
Dim m_scaleX As Single      ' scale factor PictureSrc to Picture1 [horizontal]
Dim m_scaleY As Single      ' scale factor PictureSrc to Picture1 [vertical]
Dim m_dirty As Boolean      ' dirty flag for when user changes mote positions
Dim m_rolltime As Boolean   ' set if waiting for rollover timeout
Dim m_rollover As Integer   ' last nodeid of mouse rollover (for timer)

' Common temporary variables for storing for Mote information
Dim moteInfo As objMote
Dim v As Variant

'################## FrmRouteMap #######################

'====================================================================
' Form_Load
'====================================================================
' DESCRIPTION:  Initializes the Route Map screen.
' HISTORY:      mturon      2004/2/17    Initial revision
'
Private Sub Form_Load()
    'objSQL.GetLastMoteResult
    
    FrmRouteMap.PictureSrc = LoadPicture(g_MapFileName)

    m_scaleX = 1#
    m_scaleY = 1#
    m_dirty = False

    Picture1.Font = "Arial"
    Picture1.FontBold = True
    Picture1.DrawWidth = 2
    Picture1.FillStyle = vbFSSolid
    Picture1.FillColor = MOTE_NODE_COLOR

    'init timer for automatic update of map
    Timer1.Interval = 1000      'Timer interrupt (msec)
    Timer1.Enabled = False      'Test only
    'Timer1.Enabled = True

End Sub

'====================================================================
' Form_Resize
'====================================================================
' DESCRIPTION:  Handle constraints on map form contents during a resize.
' HISTORY:      mturon      2004/2/14    Initial revision
'
Private Sub Form_Resize()
    If FrmRouteMap.WindowState <> 0 Then
        Exit Sub        ' No resizing minimized windows
    End If
    If FrmRouteMap.Width < 3000 Then
        FrmRouteMap.Width = 3000
    End If
    If FrmRouteMap.Width < 1000 Then
        FrmRouteMap.Width = 1000
    End If
    If FrmRouteMap.Height < 2000 Then
        FrmRouteMap.Height = 2000
    End If
    Frame2.Left = FrmRouteMap.Width - 1600
    Frame2.Height = FrmRouteMap.Height - 500
    Frame1.Width = FrmRouteMap.Width - 1700
    Frame1.Height = FrmRouteMap.Height - 500
    Picture1.Width = Frame1.Width - 500
    Picture1.Height = Frame1.Height - 500
End Sub

Private Sub Form_QueryUnload(Cancel As Integer, unloadmode As Integer)
    'user closing menu
    FrmRouteMap.Visible = False
    MDIForm1.MnWinRouteMap.Checked = False
    Cancel = 1
End Sub

Public Function FrmRouteMap_SetBitmap(bmpFilename As String)
    g_MapFileName = bmpFilename
    
    FrmRouteMap.PictureSrc = LoadPicture(g_MapFileName)
    
    Picture1_Resize
    Picture1.Refresh
    FrmRouteMap.Picture1.Refresh
End Function

Private Sub Label2_Click()

End Sub

'################## Picture1 #######################

'====================================================================
' Picture1_Paint
'====================================================================
' DESCRIPTION:  Handles all low-level drawing for the the network
'               topology map.
' HISTORY:      mturon      2004/2/13    Initial version
'               mturon      2004/3/4     Converted to g_moteInfo Dict
'
Private Sub Picture1_Paint()
    Picture1.PaintPicture PictureSrc.Picture, 0, 0, _
        PictureSrc.Width * m_scaleX, PictureSrc.Height * m_scaleY   ' Scaled copy
    
    Dim parentInfo As objMote
    Dim nodeid As Integer
    
    If g_MoteInfo.Count > 0 Then
        For Each v In g_MoteInfo.Items
            Set moteInfo = v
            If (moteInfo.m_parent <> MOTE_NO_PARENT) Then
                Set parentInfo = g_MoteInfo.Item(moteInfo.m_parent)
                Picture1.Line _
                    (moteInfo.m_x * m_scaleX, _
                     moteInfo.m_y * m_scaleY)- _
                    (parentInfo.m_x * m_scaleX, _
                     parentInfo.m_y * m_scaleY), _
                     MOTE_LINK_COLOR
            Else
                Picture1.FillColor = MOTE_FAIL_COLOR
                Picture1.FillStyle = 6
                Picture1.Circle (moteInfo.m_x * m_scaleX, _
                                 moteInfo.m_y * m_scaleY), _
                                 MOTE_GLOW_RADIUS * m_scaleX * 1.5, _
                                 MOTE_FAIL_COLOR
                Picture1.FillStyle = 0
            End If
        Next
    End If
        
    For Each v In g_MoteInfo.Keys
        nodeid = CInt(v)
        Set moteInfo = g_MoteInfo.Item(nodeid)
        ' Draw the outer glow of the mote node.
        Picture1.FillColor = moteInfo.m_color   'MOTE_GLOW_COLOR
        Picture1.ForeColor = moteInfo.m_color   'MOTE_GLOW_COLOR
        Picture1.Circle (moteInfo.m_x * m_scaleX, _
                         moteInfo.m_y * m_scaleY), _
                         MOTE_GLOW_RADIUS * m_scaleX, MOTE_GLOW_TRACE
        
        ' Draw the inner circle of the mote node.
        Picture1.FillColor = MOTE_NODE_COLOR
        Picture1.ForeColor = MOTE_NODE_COLOR
        Picture1.Circle (moteInfo.m_x * m_scaleX, _
                         moteInfo.m_y * m_scaleY), _
                         MOTE_NODE_RADIUS * m_scaleX, MOTE_NODE_TRACE
        
        ' Draw the text label of the mote node.
        Picture1.ForeColor = MOTE_TEXT_COLOR
        Picture1.CurrentX = moteInfo.m_x * m_scaleX _
                                - TextWidth(nodeid) / 2 _
                                - MOTE_NODE_RADIUS * 0.4 * m_scaleX
        Picture1.CurrentY = moteInfo.m_y * m_scaleY _
                                - TextHeight(nodeid) / 2
        If (nodeid = 0) Then
            Picture1.Print "GW"
        Else
            Picture1.Print nodeid
        End If
                              
    Next
    
End Sub

'====================================================================
' Picture1_Resize
'====================================================================
' DESCRIPTION:  Calculates new scale of picture.  This scale factor
'               is global to this module, and is used by the Paint
'               method to correctly render the topology map.  The
'               scale factor is at a fixed 1:1 ratio, so the image
'               is never stretched in either direction.
'
' HISTORY:      mturon      2004/2/17    Initial version
'
Private Sub Picture1_Resize()
    m_scaleX = Picture1.Width / PictureSrc.Width
    m_scaleY = Picture1.Height / PictureSrc.Height
    If (m_scaleX > m_scaleY) Then
        m_scaleX = m_scaleY
    Else
        m_scaleY = m_scaleX
    End If
End Sub

'====================================================================
' Picture1_MouseDown
'====================================================================
' DESCRIPTION:  Initiates a Drag event when the user clicks on the
'               topology map picture.
'
' HISTORY:      mturon      2004/2/17    Initial version
'
Private Sub Picture1_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Dim i, myX, myY As Integer
    Dim mote_clicked As Boolean
    
    ' Disable info rollovers on all mouse clicks (drag or popup)
    MotePopupLabel.Visible = False
    mote_clicked = False
    m_rollover = -1
    g_mouseX = X
    g_mouseY = Y
    
    For Each v In g_MoteInfo.Items
        Set moteInfo = v
        myX = moteInfo.m_x      ' cache mote position for
        myY = moteInfo.m_y      ' comparison below
        
        If ((X > (myX - MOTE_GLOW_RADIUS) * m_scaleX) And _
            (X < (myX + MOTE_GLOW_RADIUS) * m_scaleX)) And _
           ((Y > (myY - MOTE_GLOW_RADIUS) * m_scaleY) And _
            (Y < (myY + MOTE_GLOW_RADIUS) * m_scaleY)) Then
            mote_clicked = True
            If Button And vbRightButton Then
                ' Right-click pop-up menu
                MDIForm1.MnMotePopup.Tag = moteInfo.m_nodeid  'Store mote_id in popup
                PopupMenu MDIForm1.MnMotePopup
            Else
                DragShape.Tag = moteInfo.m_nodeid       'Store mote_id in drag object
                DragShape.Move X, Y                     'Move drag object to mouse
                DragShape.Drag vbBeginDrag              'Begin drag
            End If
        End If
    Next
    
    If (Not mote_clicked) And (Button And vbRightButton) Then
        PopupMenu MDIForm1.MnNewMotePopup
    End If
End Sub

'====================================================================
' Picture1_DragDrop
'====================================================================
' DESCRIPTION:  Handles the end of a DragDrop sequence by storing the
'               new mote position as an unscaled pixel offset relative
'               to the PictureSrc size.
'
' HISTORY:      mturon      2004/2/17    Initial version
'
Private Sub Picture1_DragDrop(Source As Control, X As Single, Y As Single)
    If Source.Name = "DragShape" Then     'Mote moved on picture
        Dim nodeid As Integer
        nodeid = CInt(Source.Tag)                  'Grab mote_id from drag object
        Set moteInfo = g_MoteInfo.Item(nodeid)
        moteInfo.m_x = X / m_scaleX
        moteInfo.m_y = Y / m_scaleY
        
        m_dirty = True
        Picture1.Refresh
    End If
End Sub

'====================================================================
' Picture1_MouseMove
'====================================================================
' DESCRIPTION:  Handles dynamic information popups on mouse rollovers.
'
' HISTORY:      mturon      2004/2/24    Initial version
'
Private Sub Picture1_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Dim found As Boolean
    Dim i, myX, myY As Integer
    found = False
    For Each v In g_MoteInfo.Items
        Set moteInfo = v
        myX = moteInfo.m_x
        myY = moteInfo.m_y
        If ((X > (myX - MOTE_GLOW_RADIUS) * m_scaleX) And _
            (X < (myX + MOTE_GLOW_RADIUS) * m_scaleX)) And _
           ((Y > (myY - MOTE_GLOW_RADIUS) * m_scaleY) And _
            (Y < (myY + MOTE_GLOW_RADIUS) * m_scaleY)) Then
             found = True
            m_rollover = moteInfo.m_nodeid
            Timer1.Enabled = True
        End If
    Next
    If Not found Then
        m_rollover = -1
        MotePopupLabel.Visible = False
    End If
End Sub

'====================================================================
' Picture1_MouseMove
'====================================================================
' DESCRIPTION:  Handles dynamic information popups on mouse rollovers.
'
' HISTORY:      mturon      2004/2/24    Initial version
'
Private Sub Picture1_DrawMoteInfo(nodeid As Integer)
    ' Initialize mote info pop-up display for nodeid = i
    MotePopupLabel.Visible = False
    
    ' Get this mote Object from the Dictionary
    Set moteInfo = g_MoteInfo.Item(nodeid)
    
    MotePopupLabel.Caption = _
        "Node = " & moteInfo.m_nodeid & vbLf & _
        "Name = " & moteInfo.m_name & vbLf & _
        "Parent = " & moteInfo.m_parent & vbLf & _
        "Epoch = " & moteInfo.m_epoch & vbLf & _
        "Time = " & moteInfo.m_time
    
    If (nodeid = 0) Then
        ' Special treatment for Gateway
        MotePopupLabel.Caption = _
            "Name = Gateway" & vbLf & _
            "Status = Started" & vbLf & _
            "Jobs = " & objSQL.DBTable
    End If
    
    ' Default position is lower right of mote
    MotePopupLabel.Left = m_scaleX * _
        (moteInfo.m_x + MOTE_GLOW_RADIUS)
    MotePopupLabel.Top = m_scaleY * _
        (moteInfo.m_y + MOTE_GLOW_RADIUS)
    
    ' Insure mote info display is within bounds
    If (MotePopupLabel.Left + MotePopupLabel.Width) > Picture1.Width Then
        MotePopupLabel.Left = MotePopupLabel.Left - MotePopupLabel.Width _
                            - (2 * MOTE_GLOW_RADIUS * m_scaleX)
    End If
    If (MotePopupLabel.Top + MotePopupLabel.Height) > Picture1.Height Then
        MotePopupLabel.Top = MotePopupLabel.Top - MotePopupLabel.Height _
                           - (2 * MOTE_GLOW_RADIUS * m_scaleY)
    End If
    
    MotePopupLabel.Visible = True
End Sub



'################## Buttons #######################

Private Sub rmRefreshMapButton_Click()
    
    If m_dirty = True Then
        Dim Msg   ' Declare variable.
        ' Set the message text.
        Msg = "Your changes to mote position will be lost." + vbCrLf + _
              "Are you sure you want to continue?"
        ' If user clicks the No button, stop QueryUnload.
        If MsgBox(Msg, vbQuestion + vbYesNo, Me.Caption) = vbNo Then
            Exit Sub
        End If
    End If
   
    'objSQL.Disconnect
    'objSQL.Connect
    
    objSQL.QueryMoteInfo
    Picture1.Refresh
    objSQL.GetLastMoteResult
    Picture1.Refresh
    m_dirty = False
End Sub

Private Sub rmLoadMapButton_Click()
    ' Grab the user selected filename from the file dialog
    Dim bmpFilename As String
    bmpFileDialog.ShowOpen
    bmpFilename = bmpFileDialog.filename
    If (bmpFilename = "") Then
        MsgBox ("Filename: " + bmpFilename + " not valid.")
        Exit Sub
    End If
    
    FrmRouteMap_SetBitmap (bmpFilename)
End Sub

Private Sub rmSaveMapButton_Click()
    objSQL.SaveMotePositions
    m_dirty = False
End Sub

'################## Timer1 #######################

Private Sub Timer1_Timer()
    Timer1.Enabled = False
    If (m_rollover >= 0) And (m_rollover <= TaskInfo.nmb_motes) Then
        Picture1_DrawMoteInfo (m_rollover)
    End If
End Sub
