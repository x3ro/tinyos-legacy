VERSION 5.00
Object = "{D8D562C3-878C-11D2-943F-444553540000}#1.0#0"; "ctlist.ocx"
Begin VB.Form FrmQuery 
   Caption         =   "TASK Query Control"
   ClientHeight    =   7275
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   6375
   LinkTopic       =   "Form1"
   MDIChild        =   -1  'True
   ScaleHeight     =   7275
   ScaleWidth      =   6375
   Begin VB.ComboBox lbQueryList 
      Height          =   288
      Left            =   2520
      TabIndex        =   5
      Top             =   120
      Width           =   2535
   End
   Begin VB.TextBox tbSamplePeriod 
      Alignment       =   1  'Right Justify
      Height          =   285
      Left            =   2520
      TabIndex        =   4
      Text            =   "2048"
      Top             =   480
      Width           =   1575
   End
   Begin VB.CommandButton cbQueryStart 
      Caption         =   "Start"
      Height          =   375
      Left            =   360
      TabIndex        =   2
      Top             =   6720
      Width           =   850
   End
   Begin VB.CommandButton cbQueryStop 
      Caption         =   "Stop"
      Height          =   375
      Left            =   5040
      TabIndex        =   1
      Top             =   6720
      Width           =   850
   End
   Begin VB.CommandButton cbQueryRestart 
      Caption         =   "Restart"
      Height          =   375
      Left            =   2640
      TabIndex        =   0
      Top             =   6720
      Width           =   972
   End
   Begin CTLISTLibCtl.ctList ctSensorsList 
      Height          =   5535
      Left            =   480
      TabIndex        =   7
      Top             =   960
      Width           =   5355
      _Version        =   65536
      _ExtentX        =   9446
      _ExtentY        =   9763
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
      TitleBackImage  =   "frmQuery.frx":0000
      HeaderPicture   =   "frmQuery.frx":001C
      Picture         =   "frmQuery.frx":0038
      CheckPicDown    =   "frmQuery.frx":0054
      CheckPicUp      =   "frmQuery.frx":0070
      CheckPicDisabled=   "frmQuery.frx":008C
      BackImage       =   "frmQuery.frx":00A8
      TitleText       =   "Sensors to View"
      ArrowAlign      =   0
      ShowTitle       =   -1  'True
      ShowHeader      =   -1  'True
      HorzGridLines   =   -1  'True
      VertGridLines   =   -1  'True
      HeaderData      =   "frmQuery.frx":00C4
      PicArray0       =   "frmQuery.frx":014C
      PicArray1       =   "frmQuery.frx":0168
      PicArray2       =   "frmQuery.frx":0184
      PicArray3       =   "frmQuery.frx":01A0
      PicArray4       =   "frmQuery.frx":01BC
      PicArray5       =   "frmQuery.frx":01D8
      PicArray6       =   "frmQuery.frx":01F4
      PicArray7       =   "frmQuery.frx":0210
      PicArray8       =   "frmQuery.frx":022C
      PicArray9       =   "frmQuery.frx":0248
      PicArray10      =   "frmQuery.frx":0264
      PicArray11      =   "frmQuery.frx":0280
      PicArray12      =   "frmQuery.frx":029C
      PicArray13      =   "frmQuery.frx":02B8
      PicArray14      =   "frmQuery.frx":02D4
      PicArray15      =   "frmQuery.frx":02F0
      PicArray16      =   "frmQuery.frx":030C
      PicArray17      =   "frmQuery.frx":0328
      PicArray18      =   "frmQuery.frx":0344
      PicArray19      =   "frmQuery.frx":0360
      PicArray20      =   "frmQuery.frx":037C
      PicArray21      =   "frmQuery.frx":0398
      PicArray22      =   "frmQuery.frx":03B4
      PicArray23      =   "frmQuery.frx":03D0
      PicArray24      =   "frmQuery.frx":03EC
      PicArray25      =   "frmQuery.frx":0408
      PicArray26      =   "frmQuery.frx":0424
      PicArray27      =   "frmQuery.frx":0440
      PicArray28      =   "frmQuery.frx":045C
      PicArray29      =   "frmQuery.frx":0478
      PicArray30      =   "frmQuery.frx":0494
      PicArray31      =   "frmQuery.frx":04B0
      PicArray32      =   "frmQuery.frx":04CC
      PicArray33      =   "frmQuery.frx":04E8
      PicArray34      =   "frmQuery.frx":0504
      PicArray35      =   "frmQuery.frx":0520
      PicArray36      =   "frmQuery.frx":053C
      PicArray37      =   "frmQuery.frx":0558
      PicArray38      =   "frmQuery.frx":0574
      PicArray39      =   "frmQuery.frx":0590
      PicArray40      =   "frmQuery.frx":05AC
      PicArray41      =   "frmQuery.frx":05C8
      PicArray42      =   "frmQuery.frx":05E4
      PicArray43      =   "frmQuery.frx":0600
      PicArray44      =   "frmQuery.frx":061C
      PicArray45      =   "frmQuery.frx":0638
      PicArray46      =   "frmQuery.frx":0654
      PicArray47      =   "frmQuery.frx":0670
      PicArray48      =   "frmQuery.frx":068C
      PicArray49      =   "frmQuery.frx":06A8
      PicArray50      =   "frmQuery.frx":06C4
      PicArray51      =   "frmQuery.frx":06E0
      PicArray52      =   "frmQuery.frx":06FC
      PicArray53      =   "frmQuery.frx":0718
      PicArray54      =   "frmQuery.frx":0734
      PicArray55      =   "frmQuery.frx":0750
      PicArray56      =   "frmQuery.frx":076C
      PicArray57      =   "frmQuery.frx":0788
      PicArray58      =   "frmQuery.frx":07A4
      PicArray59      =   "frmQuery.frx":07C0
      PicArray60      =   "frmQuery.frx":07DC
      PicArray61      =   "frmQuery.frx":07F8
      PicArray62      =   "frmQuery.frx":0814
      PicArray63      =   "frmQuery.frx":0830
      PicArray64      =   "frmQuery.frx":084C
      PicArray65      =   "frmQuery.frx":0868
      PicArray66      =   "frmQuery.frx":0884
      PicArray67      =   "frmQuery.frx":08A0
      PicArray68      =   "frmQuery.frx":08BC
      PicArray69      =   "frmQuery.frx":08D8
      PicArray70      =   "frmQuery.frx":08F4
      PicArray71      =   "frmQuery.frx":0910
      PicArray72      =   "frmQuery.frx":092C
      PicArray73      =   "frmQuery.frx":0948
      PicArray74      =   "frmQuery.frx":0964
      PicArray75      =   "frmQuery.frx":0980
      PicArray76      =   "frmQuery.frx":099C
      PicArray77      =   "frmQuery.frx":09B8
      PicArray78      =   "frmQuery.frx":09D4
      PicArray79      =   "frmQuery.frx":09F0
      PicArray80      =   "frmQuery.frx":0A0C
      PicArray81      =   "frmQuery.frx":0A28
      PicArray82      =   "frmQuery.frx":0A44
      PicArray83      =   "frmQuery.frx":0A60
      PicArray84      =   "frmQuery.frx":0A7C
      PicArray85      =   "frmQuery.frx":0A98
      PicArray86      =   "frmQuery.frx":0AB4
      PicArray87      =   "frmQuery.frx":0AD0
      PicArray88      =   "frmQuery.frx":0AEC
      PicArray89      =   "frmQuery.frx":0B08
      PicArray90      =   "frmQuery.frx":0B24
      PicArray91      =   "frmQuery.frx":0B40
      PicArray92      =   "frmQuery.frx":0B5C
      PicArray93      =   "frmQuery.frx":0B78
      PicArray94      =   "frmQuery.frx":0B94
      PicArray95      =   "frmQuery.frx":0BB0
      PicArray96      =   "frmQuery.frx":0BCC
      PicArray97      =   "frmQuery.frx":0BE8
      PicArray98      =   "frmQuery.frx":0C04
      PicArray99      =   "frmQuery.frx":0C20
   End
   Begin VB.Label lbMoteInfoTable 
      Caption         =   "Query Name"
      Height          =   252
      Left            =   1320
      TabIndex        =   6
      Top             =   168
      Width           =   1092
   End
   Begin VB.Label lbSampleTime 
      Caption         =   "Sampling Period"
      Height          =   252
      Left            =   1080
      TabIndex        =   3
      Top             =   480
      Width           =   1212
   End
End
Attribute VB_Name = "FrmQuery"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
''====================================================================
'' frmQuery.frm
''====================================================================
'' DESCRIPTION:  Implements the TASKView query configuration screen.
''
'' HISTORY:      mturon      2004/3/29    Initial version
''
'' $Id: frmQuery.frm,v 1.3 2004/03/31 06:51:28 mturon Exp $
''====================================================================

Option Explicit

Function PostQuery(action As String) As Integer
    Dim error As Integer
    Dim serverUrl, result As String
    Dim httpPost As New INXHTTPPost.Poster
    
    serverUrl = "http://" & objSQL.DBServer & ":8080/query"
    
    httpPost.AddParam "submitAction", action
    result = httpPost.Post(serverUrl)
    
    If result = "" Then
        error = 0
    Else
        error = CInt(result)
    End If
     
    If error > 0 Then
        MsgBox ("Error from TASKServer: " & error)
    End If

    PostQuery = error
End Function

Private Sub cbQueryRestart_Click()
    PostQuery ("Resend Query")
End Sub

Private Sub cbQueryStop_Click()
    PostQuery ("Stop Query")
End Sub

Private Sub cbQueryStart_Click()
    Dim error, i As Integer
    Dim serverUrl, result As String
    Dim httpPost As New INXHTTPPost.Poster
    
    serverUrl = "http://" & objSQL.DBServer & ":8080/query"
    
    httpPost.AddParam "submitAction", "Run Query"      ' Query Command
    httpPost.AddParam "textTime", tbSamplePeriod.Text  ' Sample time
    ' Add fixed fields required by all TASKView queries
    httpPost.AddParam "slAttributes", "nodeid"
    httpPost.AddParam "slAttributes", "parent"
    
    ' Add all selected sensors
    For i = 1 To TotalSensors
        If (ctSensorsList.ListColumnCheck(i - 1, 1) = 1) Then
           httpPost.AddParam "slAttributes", SensorInfoTable(i).sensorName
        End If
    Next
        
    ' Tell the server to run the new Query.
    result = httpPost.Post(serverUrl)
    If result = "" Then
        error = 0
    Else
        error = CInt(result)
    End If
    If error > 0 Then
        MsgBox ("Error from TASKServer: " & error)
    End If
End Sub

'====================================================================
' Form_Load
'====================================================================
' DESCRIPTION:  Initializes the query configuration dialog.
' HISTORY:      mturon      2004/3/29    Initial version
'
Private Sub Form_Load()
    ' Not sure why MDIChild sizes need to be hard-coded here...
    ' Width is set way too wide despite form builder settings
    ' without these explicit defaults.
    FrmQuery.Top = 550
    FrmQuery.Left = 3000
    FrmQuery.Width = 6500
    FrmQuery.Height = 8150

    Dim i As Integer
    ctSensorsList.ClearList
    For i = 1 To TotalSensors
        ctSensorsList.AddItem _
            SensorInfoTable(i).sensorName + ";" + _
            SensorInfoTable(i).sensorDesc
    Next
End Sub

Private Sub Form_QueryUnload(Cancel As Integer, unloadmode As Integer)
    'user closed form from menu
    MDIForm1.MnWinQueryControl.Checked = False
End Sub


