VERSION 5.00
Object = "{6B7E6392-850A-101B-AFC0-4210102A8DA7}#1.3#0"; "comctl32.ocx"
Begin VB.Form FrmMoteProp 
   Caption         =   "Mote Properties"
   ClientHeight    =   6924
   ClientLeft      =   48
   ClientTop       =   432
   ClientWidth     =   3768
   LinkTopic       =   "Form1"
   MDIChild        =   -1  'True
   ScaleHeight     =   6924
   ScaleWidth      =   3768
   Begin VB.Frame Frame1 
      BorderStyle     =   0  'None
      Height          =   1692
      Index           =   3
      Left            =   0
      TabIndex        =   8
      Top             =   4920
      Width           =   3492
   End
   Begin VB.Frame Frame1 
      BorderStyle     =   0  'None
      Height          =   1692
      Index           =   2
      Left            =   0
      TabIndex        =   3
      Top             =   2880
      Width           =   3612
      Begin VB.Frame Frame1 
         Caption         =   "Color Selected"
         Height          =   1620
         Index           =   0
         Left            =   1800
         TabIndex        =   10
         Top             =   0
         Width           =   1752
         Begin VB.PictureBox PicOver 
            Height          =   576
            Left            =   960
            ScaleHeight     =   528
            ScaleWidth      =   576
            TabIndex        =   12
            Top             =   240
            Width           =   624
         End
         Begin VB.PictureBox PicSelect 
            Height          =   588
            Left            =   120
            ScaleHeight     =   540
            ScaleWidth      =   540
            TabIndex        =   11
            Top             =   240
            Width           =   588
         End
         Begin VB.Label PicCurLabel 
            Caption         =   "FFFFFFh"
            Height          =   252
            Left            =   960
            TabIndex        =   15
            Top             =   1200
            Width           =   732
         End
         Begin VB.Label PicSetLabel 
            AutoSize        =   -1  'True
            BackStyle       =   0  'Transparent
            Caption         =   "FFFFFFh"
            Height          =   192
            Left            =   120
            TabIndex        =   14
            Top             =   1200
            Width           =   660
         End
         Begin VB.Label Label2 
            AutoSize        =   -1  'True
            BackStyle       =   0  'Transparent
            Caption         =   "Color Codes:"
            Height          =   192
            Left            =   120
            TabIndex        =   13
            Top             =   960
            Width           =   936
         End
      End
      Begin VB.PictureBox PicColor 
         AutoSize        =   -1  'True
         Height          =   1560
         Left            =   120
         ScaleHeight     =   1685.393
         ScaleMode       =   0  'User
         ScaleWidth      =   1500
         TabIndex        =   9
         Top             =   120
         Width           =   1560
      End
   End
   Begin VB.Frame Frame1 
      BorderStyle     =   0  'None
      Height          =   1692
      Index           =   1
      Left            =   0
      TabIndex        =   1
      Top             =   600
      Visible         =   0   'False
      Width           =   3612
      Begin VB.TextBox MtPrpNameBox 
         Height          =   288
         Left            =   960
         TabIndex        =   6
         Text            =   "Text1"
         Top             =   120
         Width           =   2652
      End
      Begin VB.Label Label1 
         Caption         =   "Name:"
         BeginProperty Font 
            Name            =   "Arial"
            Size            =   7.8
            Charset         =   0
            Weight          =   400
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         Height          =   252
         Left            =   120
         TabIndex        =   7
         Top             =   120
         Width           =   612
      End
   End
   Begin VB.CommandButton MtPrpCmdApply 
      Caption         =   "Apply"
      BeginProperty Font 
         Name            =   "Arial"
         Size            =   7.8
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   252
      Left            =   2760
      TabIndex        =   5
      Top             =   2520
      Width           =   972
   End
   Begin VB.CommandButton MtPrpCmdClose 
      Caption         =   "Close"
      BeginProperty Font 
         Name            =   "Arial"
         Size            =   7.8
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   252
      Left            =   1440
      TabIndex        =   4
      Top             =   2520
      Width           =   972
   End
   Begin VB.CommandButton MtPrpCmdOk 
      Caption         =   "OK"
      BeginProperty Font 
         Name            =   "Arial"
         Size            =   7.8
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   252
      Left            =   120
      TabIndex        =   2
      Top             =   2520
      Width           =   972
   End
   Begin ComctlLib.TabStrip TabStrip1 
      Height          =   2172
      Left            =   0
      TabIndex        =   0
      Top             =   240
      Width           =   3732
      _ExtentX        =   6583
      _ExtentY        =   3831
      _Version        =   327682
      BeginProperty Tabs {0713E432-850A-101B-AFC0-4210102A8DA7} 
         NumTabs         =   3
         BeginProperty Tab1 {0713F341-850A-101B-AFC0-4210102A8DA7} 
            Caption         =   "Name"
            Key             =   ""
            Object.Tag             =   ""
            Object.ToolTipText     =   "Defines mote name and description"
            ImageVarType    =   2
         EndProperty
         BeginProperty Tab2 {0713F341-850A-101B-AFC0-4210102A8DA7} 
            Caption         =   "Color"
            Key             =   ""
            Object.Tag             =   ""
            Object.ToolTipText     =   "Defines charting color of mote."
            ImageVarType    =   2
         EndProperty
         BeginProperty Tab3 {0713F341-850A-101B-AFC0-4210102A8DA7} 
            Caption         =   "Sensors"
            Key             =   ""
            Object.Tag             =   ""
            Object.ToolTipText     =   "Configure mote sensors"
            ImageVarType    =   2
         EndProperty
      EndProperty
      BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "Arial"
         Size            =   7.8
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
   End
   Begin VB.Label MtPrpNodeidLabel 
      Caption         =   "Label4"
      Height          =   252
      Left            =   2880
      TabIndex        =   17
      Top             =   0
      Width           =   852
   End
   Begin VB.Label Label3 
      Caption         =   "Node ID:"
      Height          =   252
      Left            =   2160
      TabIndex        =   16
      Top             =   0
      Width           =   732
   End
End
Attribute VB_Name = "FrmMoteProp"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
''====================================================================
'' frmMoteProp.frm
''====================================================================
'' DESCRIPTION:  A dialog to configure mote specific properties.
''
'' HISTORY:      mturon      2004/3/5    Initial version
''
'' $Id: FrmMoteProp.frm,v 1.3 2004/03/25 19:53:35 mturon Exp $
''====================================================================
Option Explicit

Private m_nodeid As Integer   ' nodeid of mote being altered
Private m_curTab As Integer   ' Current visible tab
Private m_curColor As Long    ' Current color selection
Private m_setColor As Long    ' Current color selection

Private Sub Form_Load()
    m_curTab = 1
    Frame1(1).ZOrder 0
    Frame1(1).Visible = True
    Frame1(2).Visible = False
    Frame1(3).Visible = False
    Frame1(2).Top = Frame1(1).Top
    Frame1(3).Top = Frame1(1).Top
    FrmMoteProp.Height = 3324
    FrmMoteProp.Width = 3864

    ' Color selector
    PicColor.Picture = LoadPicture(App.Path & "\" & "colors.jpg")
End Sub

'====================================================================
' Form_Activate
'====================================================================
' DESCRIPTION:  Initializes the mote property dialog with updated
'               information about the mote.
' HISTORY:      mturon      2004/3/5    Initial version
'
Private Sub Form_Activate()
    m_nodeid = CInt(FrmMoteProp.Tag)
    
    Dim moteInfo As objMote
    Set moteInfo = g_MoteInfo.Item(m_nodeid)
    MtPrpNameBox.Text = moteInfo.m_name
    MtPrpNodeidLabel.Caption = m_nodeid
    
    m_setColor = moteInfo.m_color
    PicSelect.BackColor = m_setColor
    PicSetLabel.Caption = Hex(m_setColor) & "h"
End Sub


Private Sub MtPrpCmdApply_Click()
    Dim moteInfo As objMote
    Set moteInfo = g_MoteInfo.Item(m_nodeid)
    moteInfo.m_name = MtPrpNameBox.Text
    moteInfo.m_color = m_setColor
End Sub

Private Sub MtPrpCmdOk_Click()
    MtPrpCmdApply_Click
    FrmMoteProp.Hide
End Sub

Private Sub MtPrpCmdClose_Click()
    FrmMoteProp.Hide
End Sub


Private Sub TabStrip1_Click()
   If TabStrip1.SelectedItem.index = m_curTab _
      Then Exit Sub ' No need to change frame.
   ' Otherwise, hide old frame, show new.
   Frame1(TabStrip1.SelectedItem.index).Visible = True
   Frame1(m_curTab).Visible = False
   ' Set m_curTab to new value.
   m_curTab = TabStrip1.SelectedItem.index
End Sub


Private Sub PicColor_Click()
    If m_curColor <> -1 Then
        m_setColor = m_curColor
        PicSelect.BackColor = m_setColor 'Set the back color
        PicSetLabel.Caption = Hex(m_setColor) & "h"
    End If
End Sub

Private Sub PicColor_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    'Get the color
    m_curColor = PicColor.Point(X, Y)
    'Set the color
    If m_curColor <> -1 Then
        PicOver.BackColor = m_curColor
        PicCurLabel.Caption = Hex(m_curColor) & "h"
    End If
End Sub

