VERSION 5.00
Object = "{6B7E6392-850A-101B-AFC0-4210102A8DA7}#1.3#0"; "comctl32.ocx"
Object = "{F9043C88-F6F2-101A-A3C9-08002B2F49FB}#1.2#0"; "comdlg32.ocx"
Object = "{5E9E78A0-531B-11CF-91F6-C2863C385E30}#1.0#0"; "MSFLXGRD.OCX"
Object = "{D940E4E4-6079-11CE-88CB-0020AF6845F6}#1.6#0"; "cwui.ocx"
Begin VB.Form FrmDataGraph 
   Caption         =   "Data Graph"
   ClientHeight    =   8736
   ClientLeft      =   4272
   ClientTop       =   1116
   ClientWidth     =   10356
   LinkTopic       =   "Form1"
   MDIChild        =   -1  'True
   ScaleHeight     =   8736
   ScaleWidth      =   10356
   Begin ComctlLib.Toolbar Toolbar1 
      Align           =   1  'Align Top
      Height          =   528
      Left            =   0
      TabIndex        =   8
      Top             =   0
      Width           =   10356
      _ExtentX        =   18267
      _ExtentY        =   931
      ButtonWidth     =   820
      ButtonHeight    =   794
      Appearance      =   1
      ImageList       =   "ImageList1"
      _Version        =   327682
      BeginProperty Buttons {0713E452-850A-101B-AFC0-4210102A8DA7} 
         NumButtons      =   4
         BeginProperty Button1 {0713F354-850A-101B-AFC0-4210102A8DA7} 
            Key             =   "ChartToolZoom"
            Object.ToolTipText     =   "Zoom Chart Selection Tool"
            Object.Tag             =   ""
            ImageIndex      =   1
         EndProperty
         BeginProperty Button2 {0713F354-850A-101B-AFC0-4210102A8DA7} 
            Key             =   "ChartToolPan"
            Object.ToolTipText     =   "Pan Chart Tool"
            Object.Tag             =   ""
            ImageIndex      =   2
         EndProperty
         BeginProperty Button3 {0713F354-850A-101B-AFC0-4210102A8DA7} 
            Key             =   "ChartToolZoomOut"
            Object.ToolTipText     =   "Zoom Out / Refresh"
            Object.Tag             =   ""
            ImageIndex      =   3
         EndProperty
         BeginProperty Button4 {0713F354-850A-101B-AFC0-4210102A8DA7} 
            Enabled         =   0   'False
            Key             =   "ChartToolPrint"
            Object.ToolTipText     =   "Print Chart"
            Object.Tag             =   ""
            ImageIndex      =   4
         EndProperty
      EndProperty
      MouseIcon       =   "frmDataGraph.frx":0000
   End
   Begin VB.Timer Timer1 
      Left            =   9600
      Top             =   7680
   End
   Begin CWUIControlsLib.CWGraph strip1 
      Height          =   2055
      Index           =   0
      Left            =   0
      TabIndex        =   1
      Top             =   600
      Visible         =   0   'False
      Width           =   8655
      _Version        =   393218
      _ExtentX        =   15266
      _ExtentY        =   3625
      _StockProps     =   71
      BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "MS Sans Serif"
         Size            =   7.81
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Reset_0         =   0   'False
      CompatibleVers_0=   393218
      Graph_0         =   1
      ClassName_1     =   "CCWGraphFrame"
      opts_1          =   62
      C[0]_1          =   0
      Event_1         =   2
      ClassName_2     =   "CCWGFPlotEvent"
      Owner_2         =   1
      Plots_1         =   3
      ClassName_3     =   "CCWDataPlots"
      Editor_3        =   4
      ClassName_4     =   "CCWGFPlotArrayEditor"
      Owner_4         =   1
      Axes_1          =   5
      ClassName_5     =   "CCWAxes"
      Array_5         =   2
      Editor_5        =   6
      ClassName_6     =   "CCWGFAxisArrayEditor"
      Owner_6         =   1
      Array[0]_5      =   7
      ClassName_7     =   "CCWAxis"
      opts_7          =   1087
      Name_7          =   "XAxis"
      C[3]_7          =   8421504
      C[4]_7          =   10526880
      Orientation_7   =   2944
      format_7        =   8
      ClassName_8     =   "CCWFormat"
      Format_8        =   "mm/dd/yy hh:nn:ss"
      Scale_7         =   9
      ClassName_9     =   "CCWScale"
      opts_9          =   90112
      rMin_9          =   57
      rMax_9          =   663
      dMax_9          =   10
      discInterval_9  =   1
      Radial_7        =   0
      Enum_7          =   10
      ClassName_10    =   "CCWEnum"
      Editor_10       =   11
      ClassName_11    =   "CCWEnumArrayEditor"
      Owner_11        =   7
      Font_7          =   0
      tickopts_7      =   2743
      major_7         =   5
      minor_7         =   2.5
      Caption_7       =   12
      ClassName_12    =   "CCWDrawObj"
      opts_12         =   62
      C[0]_12         =   -2147483640
      Image_12        =   13
      ClassName_13    =   "CCWTextImage"
      style_13        =   16777217
      font_13         =   0
      Animator_12     =   0
      Blinker_12      =   0
      Array[1]_5      =   14
      ClassName_14    =   "CCWAxis"
      opts_14         =   1599
      Name_14         =   "YAxis-1"
      C[3]_14         =   8421504
      C[4]_14         =   8421504
      Orientation_14  =   2067
      format_14       =   15
      ClassName_15    =   "CCWFormat"
      Scale_14        =   16
      ClassName_16    =   "CCWScale"
      opts_16         =   122880
      rMin_16         =   12
      rMax_16         =   141
      dMax_16         =   10
      discInterval_16 =   1
      Radial_14       =   0
      Enum_14         =   17
      ClassName_17    =   "CCWEnum"
      Editor_17       =   18
      ClassName_18    =   "CCWEnumArrayEditor"
      Owner_18        =   14
      Font_14         =   0
      tickopts_14     =   2743
      major_14        =   2
      minor_14        =   1
      Caption_14      =   19
      ClassName_19    =   "CCWDrawObj"
      opts_19         =   62
      C[0]_19         =   -2147483640
      Image_19        =   20
      ClassName_20    =   "CCWTextImage"
      style_20        =   50728656
      font_20         =   0
      Animator_19     =   0
      Blinker_19      =   0
      DefaultPlot_1   =   21
      ClassName_21    =   "CCWDataPlot"
      opts_21         =   4194367
      Name_21         =   "[Template]"
      C[0]_21         =   65280
      C[1]_21         =   255
      C[2]_21         =   16711680
      C[3]_21         =   16776960
      Event_21        =   2
      X_21            =   7
      Y_21            =   14
      LineStyle_21    =   1
      LineWidth_21    =   1
      BasePlot_21     =   0
      DefaultXInc_21  =   1
      DefaultPlotPerRow_21=   -1  'True
      Cursors_1       =   22
      ClassName_22    =   "CCWCursors"
      Editor_22       =   23
      ClassName_23    =   "CCWGFCursorArrayEditor"
      Owner_23        =   1
      TrackMode_1     =   2
      GraphBackground_1=   0
      GraphFrame_1    =   24
      ClassName_24    =   "CCWDrawObj"
      opts_24         =   62
      Image_24        =   25
      ClassName_25    =   "CCWPictImage"
      opts_25         =   1280
      Rows_25         =   1
      Cols_25         =   1
      F_25            =   -2147483633
      B_25            =   -2147483633
      ColorReplaceWith_25=   8421504
      ColorReplace_25 =   8421504
      Tolerance_25    =   2
      Animator_24     =   0
      Blinker_24      =   0
      PlotFrame_1     =   26
      ClassName_26    =   "CCWDrawObj"
      opts_26         =   62
      C[1]_26         =   0
      Image_26        =   27
      ClassName_27    =   "CCWPictImage"
      opts_27         =   1280
      Rows_27         =   1
      Cols_27         =   1
      Pict_27         =   1
      F_27            =   -2147483633
      B_27            =   0
      ColorReplaceWith_27=   8421504
      ColorReplace_27 =   8421504
      Tolerance_27    =   2
      Animator_26     =   0
      Blinker_26      =   0
      Caption_1       =   28
      ClassName_28    =   "CCWDrawObj"
      opts_28         =   62
      C[0]_28         =   -2147483640
      Image_28        =   29
      ClassName_29    =   "CCWTextImage"
      font_29         =   0
      Animator_28     =   0
      Blinker_28      =   0
      DefaultXInc_1   =   1
      DefaultPlotPerRow_1=   -1  'True
      Bindings_1      =   30
      ClassName_30    =   "CCWBindingHolderArray"
      Editor_30       =   31
      ClassName_31    =   "CCWBindingHolderArrayEditor"
      Owner_31        =   1
      Annotations_1   =   32
      ClassName_32    =   "CCWAnnotations"
      Editor_32       =   33
      ClassName_33    =   "CCWAnnotationArrayEditor"
      Owner_33        =   1
      AnnotationTemplate_1=   34
      ClassName_34    =   "CCWAnnotation"
      opts_34         =   63
      Name_34         =   "[Template]"
      Plot_34         =   35
      ClassName_35    =   "CCWDataPlot"
      opts_35         =   4194367
      Name_35         =   "[Template]"
      C[0]_35         =   65280
      C[1]_35         =   255
      C[2]_35         =   16711680
      C[3]_35         =   16776960
      Event_35        =   2
      X_35            =   36
      ClassName_36    =   "CCWAxis"
      opts_36         =   1599
      Name_36         =   "XAxis"
      Orientation_36  =   2944
      format_36       =   37
      ClassName_37    =   "CCWFormat"
      Scale_36        =   38
      ClassName_38    =   "CCWScale"
      opts_38         =   90112
      rMin_38         =   40
      rMax_38         =   555
      dMax_38         =   10
      discInterval_38 =   1
      Radial_36       =   0
      Enum_36         =   39
      ClassName_39    =   "CCWEnum"
      Editor_39       =   40
      ClassName_40    =   "CCWEnumArrayEditor"
      Owner_40        =   36
      Font_36         =   0
      tickopts_36     =   2711
      major_36        =   1
      minor_36        =   0.5
      Caption_36      =   41
      ClassName_41    =   "CCWDrawObj"
      opts_41         =   62
      C[0]_41         =   -2147483640
      Image_41        =   42
      ClassName_42    =   "CCWTextImage"
      font_42         =   0
      Animator_41     =   0
      Blinker_41      =   0
      Y_35            =   43
      ClassName_43    =   "CCWAxis"
      opts_43         =   1599
      Name_43         =   "YAxis-1"
      Orientation_43  =   2067
      format_43       =   44
      ClassName_44    =   "CCWFormat"
      Scale_43        =   45
      ClassName_45    =   "CCWScale"
      opts_45         =   122880
      rMin_45         =   14
      rMax_45         =   95
      dMax_45         =   10
      discInterval_45 =   1
      Radial_43       =   0
      Enum_43         =   46
      ClassName_46    =   "CCWEnum"
      Editor_46       =   47
      ClassName_47    =   "CCWEnumArrayEditor"
      Owner_47        =   43
      Font_43         =   0
      tickopts_43     =   2711
      major_43        =   5
      minor_43        =   2.5
      Caption_43      =   48
      ClassName_48    =   "CCWDrawObj"
      opts_48         =   62
      C[0]_48         =   -2147483640
      Image_48        =   49
      ClassName_49    =   "CCWTextImage"
      font_49         =   0
      Animator_48     =   0
      Blinker_48      =   0
      LineStyle_35    =   1
      LineWidth_35    =   1
      BasePlot_35     =   0
      DefaultXInc_35  =   1
      DefaultPlotPerRow_35=   -1  'True
      Text_34         =   "[Template]"
      TextXPoint_34   =   6.7
      TextYPoint_34   =   6.7
      TextColor_34    =   16777215
      TextFont_34     =   50
      ClassName_50    =   "CCWFont"
      bFont_50        =   -1  'True
      BeginProperty Font_50 {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "MS Sans Serif"
         Size            =   7.8
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ShapeXPoints_34 =   51
      ClassName_51    =   "CDataBuffer"
      Type_51         =   5
      m_cDims;_51     =   1
      m_cElts_51      =   1
      Element[0]_51   =   3.3
      ShapeYPoints_34 =   52
      ClassName_52    =   "CDataBuffer"
      Type_52         =   5
      m_cDims;_52     =   1
      m_cElts_52      =   1
      Element[0]_52   =   3.3
      ShapeFillColor_34=   16777215
      ShapeLineColor_34=   16777215
      ShapeLineWidth_34=   1
      ShapeLineStyle_34=   1
      ShapePointStyle_34=   10
      ShapeImage_34   =   53
      ClassName_53    =   "CCWDrawObj"
      opts_53         =   62
      Image_53        =   54
      ClassName_54    =   "CCWPictImage"
      opts_54         =   1280
      Rows_54         =   1
      Cols_54         =   1
      Pict_54         =   7
      F_54            =   -2147483633
      B_54            =   -2147483633
      ColorReplaceWith_54=   8421504
      ColorReplace_54 =   8421504
      Tolerance_54    =   2
      Animator_53     =   0
      Blinker_53      =   0
      ArrowVisible_34 =   -1  'True
      ArrowColor_34   =   16777215
      ArrowWidth_34   =   1
      ArrowLineStyle_34=   1
      ArrowHeadStyle_34=   1
   End
   Begin MSFlexGridLib.MSFlexGrid Grid1 
      Height          =   1455
      Index           =   0
      Left            =   8760
      TabIndex        =   0
      Top             =   2160
      Visible         =   0   'False
      Width           =   1455
      _ExtentX        =   2561
      _ExtentY        =   2561
      _Version        =   393216
      Rows            =   4
      FixedCols       =   0
      Enabled         =   0   'False
      ScrollBars      =   0
   End
   Begin VB.Timer TimerChartRefresh 
      Left            =   9600
      Top             =   7080
   End
   Begin MSComDlg.CommonDialog CommonDialog1 
      Left            =   8880
      Top             =   7680
      _ExtentX        =   847
      _ExtentY        =   847
      _Version        =   393216
   End
   Begin CWUIControlsLib.CWGraph strip1 
      Height          =   2055
      Index           =   2
      Left            =   0
      TabIndex        =   2
      Top             =   4920
      Visible         =   0   'False
      Width           =   8655
      _Version        =   393218
      _ExtentX        =   15266
      _ExtentY        =   3625
      _StockProps     =   71
      BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "MS Sans Serif"
         Size            =   7.81
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Reset_0         =   0   'False
      CompatibleVers_0=   393218
      Graph_0         =   1
      ClassName_1     =   "CCWGraphFrame"
      opts_1          =   62
      C[0]_1          =   0
      Event_1         =   2
      ClassName_2     =   "CCWGFPlotEvent"
      Owner_2         =   1
      Plots_1         =   3
      ClassName_3     =   "CCWDataPlots"
      Editor_3        =   4
      ClassName_4     =   "CCWGFPlotArrayEditor"
      Owner_4         =   1
      Axes_1          =   5
      ClassName_5     =   "CCWAxes"
      Array_5         =   2
      Editor_5        =   6
      ClassName_6     =   "CCWGFAxisArrayEditor"
      Owner_6         =   1
      Array[0]_5      =   7
      ClassName_7     =   "CCWAxis"
      opts_7          =   1087
      Name_7          =   "XAxis"
      C[3]_7          =   8421504
      C[4]_7          =   10526880
      Orientation_7   =   2944
      format_7        =   8
      ClassName_8     =   "CCWFormat"
      Format_8        =   "mm/dd/yy hh:nn:ss"
      Scale_7         =   9
      ClassName_9     =   "CCWScale"
      opts_9          =   90112
      rMin_9          =   57
      rMax_9          =   663
      dMax_9          =   10
      discInterval_9  =   1
      Radial_7        =   0
      Enum_7          =   10
      ClassName_10    =   "CCWEnum"
      Editor_10       =   11
      ClassName_11    =   "CCWEnumArrayEditor"
      Owner_11        =   7
      Font_7          =   0
      tickopts_7      =   2743
      major_7         =   5
      minor_7         =   2.5
      Caption_7       =   12
      ClassName_12    =   "CCWDrawObj"
      opts_12         =   62
      C[0]_12         =   -2147483640
      Image_12        =   13
      ClassName_13    =   "CCWTextImage"
      style_13        =   16777217
      font_13         =   0
      Animator_12     =   0
      Blinker_12      =   0
      Array[1]_5      =   14
      ClassName_14    =   "CCWAxis"
      opts_14         =   1599
      Name_14         =   "YAxis-1"
      C[3]_14         =   8421504
      C[4]_14         =   8421504
      Orientation_14  =   2067
      format_14       =   15
      ClassName_15    =   "CCWFormat"
      Scale_14        =   16
      ClassName_16    =   "CCWScale"
      opts_16         =   122880
      rMin_16         =   12
      rMax_16         =   141
      dMax_16         =   10
      discInterval_16 =   1
      Radial_14       =   0
      Enum_14         =   17
      ClassName_17    =   "CCWEnum"
      Editor_17       =   18
      ClassName_18    =   "CCWEnumArrayEditor"
      Owner_18        =   14
      Font_14         =   0
      tickopts_14     =   2743
      major_14        =   2
      minor_14        =   1
      Caption_14      =   19
      ClassName_19    =   "CCWDrawObj"
      opts_19         =   62
      C[0]_19         =   -2147483640
      Image_19        =   20
      ClassName_20    =   "CCWTextImage"
      style_20        =   50728656
      font_20         =   0
      Animator_19     =   0
      Blinker_19      =   0
      DefaultPlot_1   =   21
      ClassName_21    =   "CCWDataPlot"
      opts_21         =   4194367
      Name_21         =   "[Template]"
      C[0]_21         =   65280
      C[1]_21         =   255
      C[2]_21         =   16711680
      C[3]_21         =   16776960
      Event_21        =   2
      X_21            =   7
      Y_21            =   14
      LineStyle_21    =   1
      LineWidth_21    =   1
      BasePlot_21     =   0
      DefaultXInc_21  =   1
      DefaultPlotPerRow_21=   -1  'True
      Cursors_1       =   22
      ClassName_22    =   "CCWCursors"
      Editor_22       =   23
      ClassName_23    =   "CCWGFCursorArrayEditor"
      Owner_23        =   1
      TrackMode_1     =   2
      GraphBackground_1=   0
      GraphFrame_1    =   24
      ClassName_24    =   "CCWDrawObj"
      opts_24         =   62
      Image_24        =   25
      ClassName_25    =   "CCWPictImage"
      opts_25         =   1280
      Rows_25         =   1
      Cols_25         =   1
      F_25            =   -2147483633
      B_25            =   -2147483633
      ColorReplaceWith_25=   8421504
      ColorReplace_25 =   8421504
      Tolerance_25    =   2
      Animator_24     =   0
      Blinker_24      =   0
      PlotFrame_1     =   26
      ClassName_26    =   "CCWDrawObj"
      opts_26         =   62
      C[1]_26         =   0
      Image_26        =   27
      ClassName_27    =   "CCWPictImage"
      opts_27         =   1280
      Rows_27         =   1
      Cols_27         =   1
      Pict_27         =   1
      F_27            =   -2147483633
      B_27            =   0
      ColorReplaceWith_27=   8421504
      ColorReplace_27 =   8421504
      Tolerance_27    =   2
      Animator_26     =   0
      Blinker_26      =   0
      Caption_1       =   28
      ClassName_28    =   "CCWDrawObj"
      opts_28         =   62
      C[0]_28         =   -2147483640
      Image_28        =   29
      ClassName_29    =   "CCWTextImage"
      font_29         =   0
      Animator_28     =   0
      Blinker_28      =   0
      DefaultXInc_1   =   1
      DefaultPlotPerRow_1=   -1  'True
      Bindings_1      =   30
      ClassName_30    =   "CCWBindingHolderArray"
      Editor_30       =   31
      ClassName_31    =   "CCWBindingHolderArrayEditor"
      Owner_31        =   1
      Annotations_1   =   32
      ClassName_32    =   "CCWAnnotations"
      Editor_32       =   33
      ClassName_33    =   "CCWAnnotationArrayEditor"
      Owner_33        =   1
      AnnotationTemplate_1=   34
      ClassName_34    =   "CCWAnnotation"
      opts_34         =   63
      Name_34         =   "[Template]"
      Plot_34         =   35
      ClassName_35    =   "CCWDataPlot"
      opts_35         =   4194367
      Name_35         =   "[Template]"
      C[0]_35         =   65280
      C[1]_35         =   255
      C[2]_35         =   16711680
      C[3]_35         =   16776960
      Event_35        =   2
      X_35            =   36
      ClassName_36    =   "CCWAxis"
      opts_36         =   1599
      Name_36         =   "XAxis"
      Orientation_36  =   2944
      format_36       =   37
      ClassName_37    =   "CCWFormat"
      Scale_36        =   38
      ClassName_38    =   "CCWScale"
      opts_38         =   90112
      rMin_38         =   40
      rMax_38         =   555
      dMax_38         =   10
      discInterval_38 =   1
      Radial_36       =   0
      Enum_36         =   39
      ClassName_39    =   "CCWEnum"
      Editor_39       =   40
      ClassName_40    =   "CCWEnumArrayEditor"
      Owner_40        =   36
      Font_36         =   0
      tickopts_36     =   2711
      major_36        =   1
      minor_36        =   0.5
      Caption_36      =   41
      ClassName_41    =   "CCWDrawObj"
      opts_41         =   62
      C[0]_41         =   -2147483640
      Image_41        =   42
      ClassName_42    =   "CCWTextImage"
      font_42         =   0
      Animator_41     =   0
      Blinker_41      =   0
      Y_35            =   43
      ClassName_43    =   "CCWAxis"
      opts_43         =   1599
      Name_43         =   "YAxis-1"
      Orientation_43  =   2067
      format_43       =   44
      ClassName_44    =   "CCWFormat"
      Scale_43        =   45
      ClassName_45    =   "CCWScale"
      opts_45         =   122880
      rMin_45         =   14
      rMax_45         =   95
      dMax_45         =   10
      discInterval_45 =   1
      Radial_43       =   0
      Enum_43         =   46
      ClassName_46    =   "CCWEnum"
      Editor_46       =   47
      ClassName_47    =   "CCWEnumArrayEditor"
      Owner_47        =   43
      Font_43         =   0
      tickopts_43     =   2711
      major_43        =   5
      minor_43        =   2.5
      Caption_43      =   48
      ClassName_48    =   "CCWDrawObj"
      opts_48         =   62
      C[0]_48         =   -2147483640
      Image_48        =   49
      ClassName_49    =   "CCWTextImage"
      font_49         =   0
      Animator_48     =   0
      Blinker_48      =   0
      LineStyle_35    =   1
      LineWidth_35    =   1
      BasePlot_35     =   0
      DefaultXInc_35  =   1
      DefaultPlotPerRow_35=   -1  'True
      Text_34         =   "[Template]"
      TextXPoint_34   =   6.7
      TextYPoint_34   =   6.7
      TextColor_34    =   16777215
      TextFont_34     =   50
      ClassName_50    =   "CCWFont"
      bFont_50        =   -1  'True
      BeginProperty Font_50 {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "MS Sans Serif"
         Size            =   7.8
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ShapeXPoints_34 =   51
      ClassName_51    =   "CDataBuffer"
      Type_51         =   5
      m_cDims;_51     =   1
      m_cElts_51      =   1
      Element[0]_51   =   3.3
      ShapeYPoints_34 =   52
      ClassName_52    =   "CDataBuffer"
      Type_52         =   5
      m_cDims;_52     =   1
      m_cElts_52      =   1
      Element[0]_52   =   3.3
      ShapeFillColor_34=   16777215
      ShapeLineColor_34=   16777215
      ShapeLineWidth_34=   1
      ShapeLineStyle_34=   1
      ShapePointStyle_34=   10
      ShapeImage_34   =   53
      ClassName_53    =   "CCWDrawObj"
      opts_53         =   62
      Image_53        =   54
      ClassName_54    =   "CCWPictImage"
      opts_54         =   1280
      Rows_54         =   1
      Cols_54         =   1
      Pict_54         =   7
      F_54            =   -2147483633
      B_54            =   -2147483633
      ColorReplaceWith_54=   8421504
      ColorReplace_54 =   8421504
      Tolerance_54    =   2
      Animator_53     =   0
      Blinker_53      =   0
      ArrowVisible_34 =   -1  'True
      ArrowColor_34   =   16777215
      ArrowWidth_34   =   1
      ArrowLineStyle_34=   1
      ArrowHeadStyle_34=   1
   End
   Begin CWUIControlsLib.CWGraph strip1 
      Height          =   2055
      Index           =   3
      Left            =   0
      TabIndex        =   3
      Top             =   7080
      Visible         =   0   'False
      Width           =   8655
      _Version        =   393218
      _ExtentX        =   15266
      _ExtentY        =   3625
      _StockProps     =   71
      BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "MS Sans Serif"
         Size            =   7.81
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Reset_0         =   0   'False
      CompatibleVers_0=   393218
      Graph_0         =   1
      ClassName_1     =   "CCWGraphFrame"
      opts_1          =   62
      C[0]_1          =   0
      Event_1         =   2
      ClassName_2     =   "CCWGFPlotEvent"
      Owner_2         =   1
      Plots_1         =   3
      ClassName_3     =   "CCWDataPlots"
      Editor_3        =   4
      ClassName_4     =   "CCWGFPlotArrayEditor"
      Owner_4         =   1
      Axes_1          =   5
      ClassName_5     =   "CCWAxes"
      Array_5         =   2
      Editor_5        =   6
      ClassName_6     =   "CCWGFAxisArrayEditor"
      Owner_6         =   1
      Array[0]_5      =   7
      ClassName_7     =   "CCWAxis"
      opts_7          =   1087
      Name_7          =   "XAxis"
      C[3]_7          =   8421504
      C[4]_7          =   10526880
      Orientation_7   =   2944
      format_7        =   8
      ClassName_8     =   "CCWFormat"
      Format_8        =   "mm/dd/yy hh:nn:ss"
      Scale_7         =   9
      ClassName_9     =   "CCWScale"
      opts_9          =   90112
      rMin_9          =   57
      rMax_9          =   663
      dMax_9          =   10
      discInterval_9  =   1
      Radial_7        =   0
      Enum_7          =   10
      ClassName_10    =   "CCWEnum"
      Editor_10       =   11
      ClassName_11    =   "CCWEnumArrayEditor"
      Owner_11        =   7
      Font_7          =   0
      tickopts_7      =   2743
      major_7         =   5
      minor_7         =   2.5
      Caption_7       =   12
      ClassName_12    =   "CCWDrawObj"
      opts_12         =   62
      C[0]_12         =   -2147483640
      Image_12        =   13
      ClassName_13    =   "CCWTextImage"
      style_13        =   16777217
      font_13         =   0
      Animator_12     =   0
      Blinker_12      =   0
      Array[1]_5      =   14
      ClassName_14    =   "CCWAxis"
      opts_14         =   1599
      Name_14         =   "YAxis-1"
      C[3]_14         =   8421504
      C[4]_14         =   8421504
      Orientation_14  =   2067
      format_14       =   15
      ClassName_15    =   "CCWFormat"
      Scale_14        =   16
      ClassName_16    =   "CCWScale"
      opts_16         =   122880
      rMin_16         =   12
      rMax_16         =   141
      dMax_16         =   10
      discInterval_16 =   1
      Radial_14       =   0
      Enum_14         =   17
      ClassName_17    =   "CCWEnum"
      Editor_17       =   18
      ClassName_18    =   "CCWEnumArrayEditor"
      Owner_18        =   14
      Font_14         =   0
      tickopts_14     =   2743
      major_14        =   2
      minor_14        =   1
      Caption_14      =   19
      ClassName_19    =   "CCWDrawObj"
      opts_19         =   62
      C[0]_19         =   -2147483640
      Image_19        =   20
      ClassName_20    =   "CCWTextImage"
      style_20        =   50728656
      font_20         =   0
      Animator_19     =   0
      Blinker_19      =   0
      DefaultPlot_1   =   21
      ClassName_21    =   "CCWDataPlot"
      opts_21         =   4194367
      Name_21         =   "[Template]"
      C[0]_21         =   65280
      C[1]_21         =   255
      C[2]_21         =   16711680
      C[3]_21         =   16776960
      Event_21        =   2
      X_21            =   7
      Y_21            =   14
      LineStyle_21    =   1
      LineWidth_21    =   1
      BasePlot_21     =   0
      DefaultXInc_21  =   1
      DefaultPlotPerRow_21=   -1  'True
      Cursors_1       =   22
      ClassName_22    =   "CCWCursors"
      Editor_22       =   23
      ClassName_23    =   "CCWGFCursorArrayEditor"
      Owner_23        =   1
      TrackMode_1     =   2
      GraphBackground_1=   0
      GraphFrame_1    =   24
      ClassName_24    =   "CCWDrawObj"
      opts_24         =   62
      Image_24        =   25
      ClassName_25    =   "CCWPictImage"
      opts_25         =   1280
      Rows_25         =   1
      Cols_25         =   1
      F_25            =   -2147483633
      B_25            =   -2147483633
      ColorReplaceWith_25=   8421504
      ColorReplace_25 =   8421504
      Tolerance_25    =   2
      Animator_24     =   0
      Blinker_24      =   0
      PlotFrame_1     =   26
      ClassName_26    =   "CCWDrawObj"
      opts_26         =   62
      C[1]_26         =   0
      Image_26        =   27
      ClassName_27    =   "CCWPictImage"
      opts_27         =   1280
      Rows_27         =   1
      Cols_27         =   1
      Pict_27         =   1
      F_27            =   -2147483633
      B_27            =   0
      ColorReplaceWith_27=   8421504
      ColorReplace_27 =   8421504
      Tolerance_27    =   2
      Animator_26     =   0
      Blinker_26      =   0
      Caption_1       =   28
      ClassName_28    =   "CCWDrawObj"
      opts_28         =   62
      C[0]_28         =   -2147483640
      Image_28        =   29
      ClassName_29    =   "CCWTextImage"
      font_29         =   0
      Animator_28     =   0
      Blinker_28      =   0
      DefaultXInc_1   =   1
      DefaultPlotPerRow_1=   -1  'True
      Bindings_1      =   30
      ClassName_30    =   "CCWBindingHolderArray"
      Editor_30       =   31
      ClassName_31    =   "CCWBindingHolderArrayEditor"
      Owner_31        =   1
      Annotations_1   =   32
      ClassName_32    =   "CCWAnnotations"
      Editor_32       =   33
      ClassName_33    =   "CCWAnnotationArrayEditor"
      Owner_33        =   1
      AnnotationTemplate_1=   34
      ClassName_34    =   "CCWAnnotation"
      opts_34         =   63
      Name_34         =   "[Template]"
      Plot_34         =   35
      ClassName_35    =   "CCWDataPlot"
      opts_35         =   4194367
      Name_35         =   "[Template]"
      C[0]_35         =   65280
      C[1]_35         =   255
      C[2]_35         =   16711680
      C[3]_35         =   16776960
      Event_35        =   2
      X_35            =   36
      ClassName_36    =   "CCWAxis"
      opts_36         =   1599
      Name_36         =   "XAxis"
      Orientation_36  =   2944
      format_36       =   37
      ClassName_37    =   "CCWFormat"
      Scale_36        =   38
      ClassName_38    =   "CCWScale"
      opts_38         =   90112
      rMin_38         =   40
      rMax_38         =   555
      dMax_38         =   10
      discInterval_38 =   1
      Radial_36       =   0
      Enum_36         =   39
      ClassName_39    =   "CCWEnum"
      Editor_39       =   40
      ClassName_40    =   "CCWEnumArrayEditor"
      Owner_40        =   36
      Font_36         =   0
      tickopts_36     =   2711
      major_36        =   1
      minor_36        =   0.5
      Caption_36      =   41
      ClassName_41    =   "CCWDrawObj"
      opts_41         =   62
      C[0]_41         =   -2147483640
      Image_41        =   42
      ClassName_42    =   "CCWTextImage"
      font_42         =   0
      Animator_41     =   0
      Blinker_41      =   0
      Y_35            =   43
      ClassName_43    =   "CCWAxis"
      opts_43         =   1599
      Name_43         =   "YAxis-1"
      Orientation_43  =   2067
      format_43       =   44
      ClassName_44    =   "CCWFormat"
      Scale_43        =   45
      ClassName_45    =   "CCWScale"
      opts_45         =   122880
      rMin_45         =   14
      rMax_45         =   95
      dMax_45         =   10
      discInterval_45 =   1
      Radial_43       =   0
      Enum_43         =   46
      ClassName_46    =   "CCWEnum"
      Editor_46       =   47
      ClassName_47    =   "CCWEnumArrayEditor"
      Owner_47        =   43
      Font_43         =   0
      tickopts_43     =   2711
      major_43        =   5
      minor_43        =   2.5
      Caption_43      =   48
      ClassName_48    =   "CCWDrawObj"
      opts_48         =   62
      C[0]_48         =   -2147483640
      Image_48        =   49
      ClassName_49    =   "CCWTextImage"
      font_49         =   0
      Animator_48     =   0
      Blinker_48      =   0
      LineStyle_35    =   1
      LineWidth_35    =   1
      BasePlot_35     =   0
      DefaultXInc_35  =   1
      DefaultPlotPerRow_35=   -1  'True
      Text_34         =   "[Template]"
      TextXPoint_34   =   6.7
      TextYPoint_34   =   6.7
      TextColor_34    =   16777215
      TextFont_34     =   50
      ClassName_50    =   "CCWFont"
      bFont_50        =   -1  'True
      BeginProperty Font_50 {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "MS Sans Serif"
         Size            =   7.8
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ShapeXPoints_34 =   51
      ClassName_51    =   "CDataBuffer"
      Type_51         =   5
      m_cDims;_51     =   1
      m_cElts_51      =   1
      Element[0]_51   =   3.3
      ShapeYPoints_34 =   52
      ClassName_52    =   "CDataBuffer"
      Type_52         =   5
      m_cDims;_52     =   1
      m_cElts_52      =   1
      Element[0]_52   =   3.3
      ShapeFillColor_34=   16777215
      ShapeLineColor_34=   16777215
      ShapeLineWidth_34=   1
      ShapeLineStyle_34=   1
      ShapePointStyle_34=   10
      ShapeImage_34   =   53
      ClassName_53    =   "CCWDrawObj"
      opts_53         =   62
      Image_53        =   54
      ClassName_54    =   "CCWPictImage"
      opts_54         =   1280
      Rows_54         =   1
      Cols_54         =   1
      Pict_54         =   7
      F_54            =   -2147483633
      B_54            =   -2147483633
      ColorReplaceWith_54=   8421504
      ColorReplace_54 =   8421504
      Tolerance_54    =   2
      Animator_53     =   0
      Blinker_53      =   0
      ArrowVisible_34 =   -1  'True
      ArrowColor_34   =   16777215
      ArrowWidth_34   =   1
      ArrowLineStyle_34=   1
      ArrowHeadStyle_34=   1
   End
   Begin MSFlexGridLib.MSFlexGrid Grid1 
      Height          =   1455
      Index           =   1
      Left            =   8760
      TabIndex        =   4
      Top             =   600
      Visible         =   0   'False
      Width           =   1455
      _ExtentX        =   2561
      _ExtentY        =   2561
      _Version        =   393216
      Rows            =   4
      FixedCols       =   0
      Enabled         =   0   'False
      ScrollBars      =   0
   End
   Begin MSFlexGridLib.MSFlexGrid Grid1 
      Height          =   1455
      Index           =   2
      Left            =   8760
      TabIndex        =   5
      Top             =   5280
      Visible         =   0   'False
      Width           =   1455
      _ExtentX        =   2561
      _ExtentY        =   2561
      _Version        =   393216
      Rows            =   4
      FixedCols       =   0
      Enabled         =   0   'False
      ScrollBars      =   0
   End
   Begin MSFlexGridLib.MSFlexGrid Grid1 
      Height          =   1455
      Index           =   3
      Left            =   8760
      TabIndex        =   6
      Top             =   3720
      Visible         =   0   'False
      Width           =   1455
      _ExtentX        =   2561
      _ExtentY        =   2561
      _Version        =   393216
      Rows            =   4
      FixedCols       =   0
      Enabled         =   0   'False
      ScrollBars      =   0
   End
   Begin CWUIControlsLib.CWGraph strip1 
      Height          =   2055
      Index           =   1
      Left            =   0
      TabIndex        =   7
      Top             =   2760
      Visible         =   0   'False
      Width           =   8655
      _Version        =   393218
      _ExtentX        =   15266
      _ExtentY        =   3625
      _StockProps     =   71
      BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "MS Sans Serif"
         Size            =   7.81
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Reset_0         =   0   'False
      CompatibleVers_0=   393218
      Graph_0         =   1
      ClassName_1     =   "CCWGraphFrame"
      opts_1          =   62
      C[0]_1          =   0
      Event_1         =   2
      ClassName_2     =   "CCWGFPlotEvent"
      Owner_2         =   1
      Plots_1         =   3
      ClassName_3     =   "CCWDataPlots"
      Editor_3        =   4
      ClassName_4     =   "CCWGFPlotArrayEditor"
      Owner_4         =   1
      Axes_1          =   5
      ClassName_5     =   "CCWAxes"
      Array_5         =   2
      Editor_5        =   6
      ClassName_6     =   "CCWGFAxisArrayEditor"
      Owner_6         =   1
      Array[0]_5      =   7
      ClassName_7     =   "CCWAxis"
      opts_7          =   1087
      Name_7          =   "XAxis"
      C[3]_7          =   8421504
      C[4]_7          =   10526880
      Orientation_7   =   2944
      format_7        =   8
      ClassName_8     =   "CCWFormat"
      Format_8        =   "mm/dd/yy hh:nn:ss"
      Scale_7         =   9
      ClassName_9     =   "CCWScale"
      opts_9          =   90112
      rMin_9          =   57
      rMax_9          =   663
      dMax_9          =   10
      discInterval_9  =   1
      Radial_7        =   0
      Enum_7          =   10
      ClassName_10    =   "CCWEnum"
      Editor_10       =   11
      ClassName_11    =   "CCWEnumArrayEditor"
      Owner_11        =   7
      Font_7          =   0
      tickopts_7      =   2743
      major_7         =   5
      minor_7         =   2.5
      Caption_7       =   12
      ClassName_12    =   "CCWDrawObj"
      opts_12         =   62
      C[0]_12         =   -2147483640
      Image_12        =   13
      ClassName_13    =   "CCWTextImage"
      style_13        =   16777217
      font_13         =   0
      Animator_12     =   0
      Blinker_12      =   0
      Array[1]_5      =   14
      ClassName_14    =   "CCWAxis"
      opts_14         =   1599
      Name_14         =   "YAxis-1"
      C[3]_14         =   8421504
      C[4]_14         =   8421504
      Orientation_14  =   2067
      format_14       =   15
      ClassName_15    =   "CCWFormat"
      Scale_14        =   16
      ClassName_16    =   "CCWScale"
      opts_16         =   122880
      rMin_16         =   12
      rMax_16         =   141
      dMax_16         =   10
      discInterval_16 =   1
      Radial_14       =   0
      Enum_14         =   17
      ClassName_17    =   "CCWEnum"
      Editor_17       =   18
      ClassName_18    =   "CCWEnumArrayEditor"
      Owner_18        =   14
      Font_14         =   0
      tickopts_14     =   2743
      major_14        =   2
      minor_14        =   1
      Caption_14      =   19
      ClassName_19    =   "CCWDrawObj"
      opts_19         =   62
      C[0]_19         =   -2147483640
      Image_19        =   20
      ClassName_20    =   "CCWTextImage"
      style_20        =   50728656
      font_20         =   0
      Animator_19     =   0
      Blinker_19      =   0
      DefaultPlot_1   =   21
      ClassName_21    =   "CCWDataPlot"
      opts_21         =   4194367
      Name_21         =   "[Template]"
      C[0]_21         =   65280
      C[1]_21         =   255
      C[2]_21         =   16711680
      C[3]_21         =   16776960
      Event_21        =   2
      X_21            =   7
      Y_21            =   14
      LineStyle_21    =   1
      LineWidth_21    =   1
      BasePlot_21     =   0
      DefaultXInc_21  =   1
      DefaultPlotPerRow_21=   -1  'True
      Cursors_1       =   22
      ClassName_22    =   "CCWCursors"
      Editor_22       =   23
      ClassName_23    =   "CCWGFCursorArrayEditor"
      Owner_23        =   1
      TrackMode_1     =   2
      GraphBackground_1=   0
      GraphFrame_1    =   24
      ClassName_24    =   "CCWDrawObj"
      opts_24         =   62
      Image_24        =   25
      ClassName_25    =   "CCWPictImage"
      opts_25         =   1280
      Rows_25         =   1
      Cols_25         =   1
      F_25            =   -2147483633
      B_25            =   -2147483633
      ColorReplaceWith_25=   8421504
      ColorReplace_25 =   8421504
      Tolerance_25    =   2
      Animator_24     =   0
      Blinker_24      =   0
      PlotFrame_1     =   26
      ClassName_26    =   "CCWDrawObj"
      opts_26         =   62
      C[1]_26         =   0
      Image_26        =   27
      ClassName_27    =   "CCWPictImage"
      opts_27         =   1280
      Rows_27         =   1
      Cols_27         =   1
      Pict_27         =   1
      F_27            =   -2147483633
      B_27            =   0
      ColorReplaceWith_27=   8421504
      ColorReplace_27 =   8421504
      Tolerance_27    =   2
      Animator_26     =   0
      Blinker_26      =   0
      Caption_1       =   28
      ClassName_28    =   "CCWDrawObj"
      opts_28         =   62
      C[0]_28         =   -2147483640
      Image_28        =   29
      ClassName_29    =   "CCWTextImage"
      font_29         =   0
      Animator_28     =   0
      Blinker_28      =   0
      DefaultXInc_1   =   1
      DefaultPlotPerRow_1=   -1  'True
      Bindings_1      =   30
      ClassName_30    =   "CCWBindingHolderArray"
      Editor_30       =   31
      ClassName_31    =   "CCWBindingHolderArrayEditor"
      Owner_31        =   1
      Annotations_1   =   32
      ClassName_32    =   "CCWAnnotations"
      Editor_32       =   33
      ClassName_33    =   "CCWAnnotationArrayEditor"
      Owner_33        =   1
      AnnotationTemplate_1=   34
      ClassName_34    =   "CCWAnnotation"
      opts_34         =   63
      Name_34         =   "[Template]"
      Plot_34         =   35
      ClassName_35    =   "CCWDataPlot"
      opts_35         =   4194367
      Name_35         =   "[Template]"
      C[0]_35         =   65280
      C[1]_35         =   255
      C[2]_35         =   16711680
      C[3]_35         =   16776960
      Event_35        =   2
      X_35            =   36
      ClassName_36    =   "CCWAxis"
      opts_36         =   1599
      Name_36         =   "XAxis"
      Orientation_36  =   2944
      format_36       =   37
      ClassName_37    =   "CCWFormat"
      Scale_36        =   38
      ClassName_38    =   "CCWScale"
      opts_38         =   90112
      rMin_38         =   40
      rMax_38         =   555
      dMax_38         =   10
      discInterval_38 =   1
      Radial_36       =   0
      Enum_36         =   39
      ClassName_39    =   "CCWEnum"
      Editor_39       =   40
      ClassName_40    =   "CCWEnumArrayEditor"
      Owner_40        =   36
      Font_36         =   0
      tickopts_36     =   2711
      major_36        =   1
      minor_36        =   0.5
      Caption_36      =   41
      ClassName_41    =   "CCWDrawObj"
      opts_41         =   62
      C[0]_41         =   -2147483640
      Image_41        =   42
      ClassName_42    =   "CCWTextImage"
      font_42         =   0
      Animator_41     =   0
      Blinker_41      =   0
      Y_35            =   43
      ClassName_43    =   "CCWAxis"
      opts_43         =   1599
      Name_43         =   "YAxis-1"
      Orientation_43  =   2067
      format_43       =   44
      ClassName_44    =   "CCWFormat"
      Scale_43        =   45
      ClassName_45    =   "CCWScale"
      opts_45         =   122880
      rMin_45         =   14
      rMax_45         =   95
      dMax_45         =   10
      discInterval_45 =   1
      Radial_43       =   0
      Enum_43         =   46
      ClassName_46    =   "CCWEnum"
      Editor_46       =   47
      ClassName_47    =   "CCWEnumArrayEditor"
      Owner_47        =   43
      Font_43         =   0
      tickopts_43     =   2711
      major_43        =   5
      minor_43        =   2.5
      Caption_43      =   48
      ClassName_48    =   "CCWDrawObj"
      opts_48         =   62
      C[0]_48         =   -2147483640
      Image_48        =   49
      ClassName_49    =   "CCWTextImage"
      font_49         =   0
      Animator_48     =   0
      Blinker_48      =   0
      LineStyle_35    =   1
      LineWidth_35    =   1
      BasePlot_35     =   0
      DefaultXInc_35  =   1
      DefaultPlotPerRow_35=   -1  'True
      Text_34         =   "[Template]"
      TextXPoint_34   =   6.7
      TextYPoint_34   =   6.7
      TextColor_34    =   16777215
      TextFont_34     =   50
      ClassName_50    =   "CCWFont"
      bFont_50        =   -1  'True
      BeginProperty Font_50 {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "MS Sans Serif"
         Size            =   7.8
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ShapeXPoints_34 =   51
      ClassName_51    =   "CDataBuffer"
      Type_51         =   5
      m_cDims;_51     =   1
      m_cElts_51      =   1
      Element[0]_51   =   3.3
      ShapeYPoints_34 =   52
      ClassName_52    =   "CDataBuffer"
      Type_52         =   5
      m_cDims;_52     =   1
      m_cElts_52      =   1
      Element[0]_52   =   3.3
      ShapeFillColor_34=   16777215
      ShapeLineColor_34=   16777215
      ShapeLineWidth_34=   1
      ShapeLineStyle_34=   1
      ShapePointStyle_34=   10
      ShapeImage_34   =   53
      ClassName_53    =   "CCWDrawObj"
      opts_53         =   62
      Image_53        =   54
      ClassName_54    =   "CCWPictImage"
      opts_54         =   1280
      Rows_54         =   1
      Cols_54         =   1
      Pict_54         =   7
      F_54            =   -2147483633
      B_54            =   -2147483633
      ColorReplaceWith_54=   8421504
      ColorReplace_54 =   8421504
      Tolerance_54    =   2
      Animator_53     =   0
      Blinker_53      =   0
      ArrowVisible_34 =   -1  'True
      ArrowColor_34   =   16777215
      ArrowWidth_34   =   1
      ArrowLineStyle_34=   1
      ArrowHeadStyle_34=   1
   End
   Begin ComctlLib.ImageList ImageList1 
      Left            =   8880
      Top             =   6960
      _ExtentX        =   995
      _ExtentY        =   995
      BackColor       =   -2147483643
      ImageWidth      =   24
      ImageHeight     =   24
      MaskColor       =   12632256
      _Version        =   327682
      BeginProperty Images {0713E8C2-850A-101B-AFC0-4210102A8DA7} 
         NumListImages   =   4
         BeginProperty ListImage1 {0713E8C3-850A-101B-AFC0-4210102A8DA7} 
            Picture         =   "frmDataGraph.frx":031A
            Key             =   ""
         EndProperty
         BeginProperty ListImage2 {0713E8C3-850A-101B-AFC0-4210102A8DA7} 
            Picture         =   "frmDataGraph.frx":0594
            Key             =   ""
         EndProperty
         BeginProperty ListImage3 {0713E8C3-850A-101B-AFC0-4210102A8DA7} 
            Picture         =   "frmDataGraph.frx":080E
            Key             =   ""
         EndProperty
         BeginProperty ListImage4 {0713E8C3-850A-101B-AFC0-4210102A8DA7} 
            Picture         =   "frmDataGraph.frx":09E8
            Key             =   ""
         EndProperty
      EndProperty
   End
End
Attribute VB_Name = "FrmDataGraph"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
''====================================================================
'' frmDataGraph.frm
''====================================================================
'' DESCRIPTION:  This module displays strip charts of mote data.
''
'' HISTORY:      mturon      2004/3/3    Initial revision
''
'' $Id: FrmDataGraph.frm,v 1.6 2004/05/07 22:41:01 mturon Exp $
''====================================================================
Option Explicit

'Graphing parameters
Const NUM_STRIP_CHARTS = 3
Const TIME_UPDATE_GRAPH = 500          '# of msec between graph updates
Const COL_ID_SIZE = 600                'col size for id

Dim bGraphEU As Boolean                'display engineering units
Dim bGraphAdc As Boolean               'display adc units
Dim iNmbGraphs As Integer              'number of strip charts displayed

Dim iTimerCount As Double              ' test incrementing strip-charts
Dim lastTime As Double


Private Sub Form_Load()
 
    'init graph parameters
    bGraphEU = True
    bGraphAdc = False

    'strip1(0).TrackMode = cwGTrackZoomRectXY
    'strip1(1).TrackMode = cwGTrackZoomRectXY
    'strip1(2).TrackMode = cwGTrackZoomRectXY
    'strip1(3).TrackMode = cwGTrackZoomRectXY

    'enable timer to update graphs
    TimerChartRefresh.Interval = TIME_UPDATE_GRAPH           'timer interrupt (msec)
    TimerChartRefresh.Enabled = True
    'TimerChartRefresh.Enabled = False      'for test only
    
    'Timer1.Interval = 10000                 '10 sec timer interrupt (in msec)
    'Timer1.Enabled = True
    Timer1.Enabled = False
    
End Sub

Private Sub Form_Resize()
    Dim i, numGraphs, lStripChartHeights As Integer
    
    If FrmDataGraph.Height < 2000 Then
        FrmDataGraph.Height = 2000
    End If
    
    For i = 1 To MAX_GRAPHS
        If StrComp(SensorHistoryList(i).sensorName, "") = 0 Then
            Exit For
        End If
    Next
    numGraphs = i - 1
    If (numGraphs < 1) Then
        Exit Sub
    End If
    lStripChartHeights = ((FrmDataGraph.Height - Toolbar1.Height - 500) / numGraphs)
    For i = 0 To numGraphs - 1
        
        ' Bring up Legend
        Grid1(i).Top = Toolbar1.Height
        Grid1(i).Left = 0
        Grid1(i).Width = 800
        'AddLegendData (i)
        strip1(i).Height = lStripChartHeights
        strip1(i).Top = Toolbar1.Height
        strip1(i).Left = Grid1(i).Left + Grid1(i).Width
        strip1(i).Width = FrmDataGraph.Width - Grid1(i).Width - 300
        If (i > 0) Then
            strip1(i).Top = strip1(i - 1).Top + strip1(i - 1).Height
            Grid1(i).Top = strip1(i).Top
        End If
    Next i
End Sub

Sub strip1_PlotMouseDown(index As Integer, Button As Integer, Shift As Integer, XData As Variant, YData As Variant, PlotIndex As Integer, PointIndex As Long)
    Dim i As Integer
    i = 0
End Sub

Public Sub GraphUnits(bEU As Boolean)
'Display Engineering Units or ADC counts in graph
  If bEU Then
     bGraphEU = True
     bGraphAdc = False
  Else
     bGraphAdc = True
     bGraphEU = False
  End If
  'GraphInit
End Sub

Private Sub CmdClear_Click()
    Dim i As Integer

    For i = 0 To iNmbGraphs - 1
        strip1(i).ClearAll
        'Strip1(i).LastX = 0
    Next i
End Sub

Private Sub CmdPrint_Click()
    Dim X As Printer
    Dim Y
    Dim pagewidth, pageheight As Long
    
    Printer.Print " ";
    Printer.ScaleMode = 5  'inches
    
    pagewidth = Printer.ScaleWidth
    
    'pagewidth% = Printer.ScaleWidth
    'pageheight% = Printer.ScaleHeight
    
    CommonDialog1.ShowPrinter
    
    'hdc, OffsetX, OffsetY, Width, Height
    'Y = Printer.hDC
    'Strip1.PrintArea Y, 1.5, 1.5, 5, 3
    'Printer.Orientation = i
    'Printer.EndDoc
End Sub

Private Sub Form_QueryUnload(Cancel As Integer, unloadmode As Integer)
    'user closing menu
    FrmDataGraph.Visible = False
    MDIForm1.MnWinDataGraph.Checked = False
    Cancel = 1
End Sub

' The *true* plotting function!
Public Sub GraphHistory()
    Dim i, j As Long
    Dim plota() As Variant
    Dim iGraph As Integer
    Dim iPlot As Integer
    Dim numGraphs As Integer
    Dim lStripChartHeights As Integer
    Dim nodeid As Integer
    Dim moteInfo As objMote
    Dim sensorName As String

    iTimerCount = 0#
    
    FrmDataGraph.MousePointer = vbHourglass
    FrmDataGrid.MousePointer = vbHourglass
    FrmDataGraph.Hide
    
    numGraphs = 0
    For iGraph = 1 To MAX_GRAPHS
        
        If StrComp(SensorHistoryList(iGraph).sensorName, "") = 0 Then
            Exit For
        End If
            
        strip1(iGraph - 1).Plots.RemoveAll
        strip1(iGraph - 1).Visible = True
    
        For iPlot = 1 To SensorHistoryList(iGraph).numPlots
            nodeid = SensorHistoryList(iGraph).nodeIds(iPlot)
            sensorName = SensorHistoryList(iGraph).sensorName
            
            objSQL.QueryHistoryFill nodeid, sensorName, _
                                    TaskInfo.GraphPlotStartTime, _
                                    TaskInfo.GraphPlotEndTime + #12:01:00 AM#
            
            'Copy Values
            i = UBound(TaskHistoryData.Value)
            If i > strip1(iGraph - 1).ChartLength Then
                strip1(iGraph - 1).ChartLength = i
            End If
            ReDim plota(i)
            For j = 0 To i
                plota(j) = CDbl(TaskHistoryData.Time(j))
            Next j

            Set moteInfo = g_MoteInfo.Item(nodeid)
            
            strip1(iGraph - 1).Plots.Add
            strip1(iGraph - 1).Plots(iPlot).LineColor = moteInfo.m_color 'gColors(iPlot)
            
            'Plot this set of Sensor values for the given Mote
            strip1(iGraph - 1).Plots(iPlot).ChartXvsY plota, TaskHistoryData.Value
            'strip1(iGraph - 1).Plots(iPlot).PlotXvsY plota, TaskHistoryData.Value
                    
        Next iPlot
        numGraphs = numGraphs + 1
        
        'Write Caption for Values on the Y Axis - (Item(2)
        strip1(iGraph - 1).Axes.Item(2).Caption = _
            sensorName + " [" + UnitEngGetName(sensorName) + "] "
        
    Next iGraph
    
    
    If numGraphs = 0 Then
        FrmDataGraph.MousePointer = vbDefault
        FrmDataGrid.MousePointer = vbDefault
        Exit Sub
    End If
    
    'create graphs and set screen size,position
    If (FrmDataGraph.WindowState <> 0) Then
        FrmDataGraph.WindowState = 0    ' normal window
    End If
        
    lStripChartHeights = ((FrmDataGraph.Height - Toolbar1.Height - 500) / numGraphs)
    For i = 0 To numGraphs - 1
        ' Bring up Legend
        Grid1(i).Visible = True
        Grid1(i).Top = Toolbar1.Height
        Grid1(i).Left = 0
        Grid1(i).Width = 800
        AddLegendData (i)
        strip1(i).Height = lStripChartHeights
        strip1(i).Top = Toolbar1.Height
        strip1(i).Left = Grid1(i).Left + Grid1(i).Width
        strip1(i).Width = FrmDataGraph.Width - Grid1(i).Width - 300
        If (i > 0) Then
            strip1(i).Top = strip1(i - 1).Top + strip1(i - 1).Height
            Grid1(i).Top = strip1(i).Top
        End If
    Next i
    
    ' Don't show unplotted Graphs and their Legends
    For j = numGraphs To MAX_GRAPHS - 1
        strip1(j).Visible = False
        Grid1(j).Visible = False
    Next j
    
    FrmDataGraph.Show
    FrmDataGraph.MousePointer = vbDefault
    FrmDataGrid.MousePointer = vbDefault
        
 End Sub

Private Sub AddLegendData(iGridNum As Long)
    Dim iNode, nodeid As Integer
    Dim iTotalNodes As Integer
    Dim moteInfo As objMote
    
    Grid1(iGridNum).Row = 0
    Grid1(iGridNum).Cols = 1
    
    'Enter Header Text
    Grid1(iGridNum).ColAlignment(0) = flexAlignLeftTop
    Grid1(iGridNum).ColWidth(0) = 750
    Grid1(iGridNum).col = 0
    Grid1(iGridNum).Text = "Node"
      
    iTotalNodes = SensorHistoryList(iGridNum + 1).numPlots
    Grid1(iGridNum).Rows = iTotalNodes + 1
    For iNode = 1 To iTotalNodes
        Grid1(iGridNum).Row = iNode
        'Enter Node Id
        nodeid = SensorHistoryList(iGridNum + 1).nodeIds(iNode)
        Set moteInfo = g_MoteInfo.Item(nodeid)
        Grid1(iGridNum).col = 0
        Grid1(iGridNum).Text = CStr(nodeid)
        Grid1(iGridNum).CellBackColor = moteInfo.m_color 'gColors(iNode)
    Next iNode
    
    Grid1(iGridNum).Height = Grid1(iGridNum).Rows * 275
    
End Sub

Private Sub Toolbar1_ButtonClick(ByVal Button As ComctlLib.Button)
    Dim i As Integer
    Select Case Button.Key
        Case "ChartToolZoom":
            For i = 0 To NUM_STRIP_CHARTS
                strip1(i).TrackMode = cwGTrackZoomRectXY
            Next
            ' set new mouse icon
            FrmDataGraph.MousePointer = vbCrosshair

        Case "ChartToolPan":
            For i = 0 To NUM_STRIP_CHARTS
                strip1(i).TrackMode = cwGTrackPanPlotAreaXY
            Next
            ' set new mouse icon
            FrmDataGraph.MousePointer = vbSizeAll
        Case "ChartToolZoomOut":
            For i = 0 To NUM_STRIP_CHARTS
                strip1(i).Axes(1).AutoScaleNow
                strip1(i).Axes(2).AutoScaleNow
                strip1(i).TrackMode = cwGTrackAllEvents ' cwGTrackDragCursor
            Next
            FrmDataGraph.MousePointer = vbDefault
            'GraphHistory
        Case "ChartToolPrint":
            'CmdPrint_Click
    End Select
End Sub

Private Sub TimerChartRefresh_Timer()
    'QueryDataFill ' already called by data grid timer...
    ' Grab latest values from data grid, and add them to plots
    If strip1(0).Visible And FrmDataGrid.ckLiveUpdate.Value = vbChecked Then
        Dim nodeid, sensorId, iPlot, iGraph As Integer
        Dim sensorName As String
        Dim times(0), vals(0) As Variant
        Dim graphUpdate As Boolean
        
        graphUpdate = False
        For iGraph = 1 To MAX_GRAPHS
            For iPlot = 1 To SensorHistoryList(iGraph).numPlots
                nodeid = SensorHistoryList(iGraph).nodeIds(iPlot)
                sensorName = SensorHistoryList(iGraph).sensorName
                sensorId = SensorGetGridId(sensorName)
                If sensorId = 0 Then GoTo skipContinue

                vals(0) = UnitEngConvert(TaskDataArray(nodeid).Value(sensorId), _
                                SensorHistoryList(iGraph).sensorName, _
                                SensorHistoryList(iGraph).nodeIds(iPlot))
                
                times(0) = CDate(TaskDataArray(nodeid).Time)
                'CDbl(CDate(TaskDataArray(nodeid).Time))
                If (lastTime < times(0)) Then
                    lastTime = times(0)
                    graphUpdate = True
                End If
                If graphUpdate Then
                    Dim winSize, winSpace, origMin, origMax As Double
                    origMax = strip1(iGraph - 1).Axes(1).Maximum
                    origMin = strip1(iGraph - 1).Axes(1).Minimum
                    winSize = origMax - origMin
                    winSpace = origMax - lastTime
                    If winSpace < 0 Then
                        winSpace = 0
                    End If
                    strip1(iGraph - 1).Plots(iPlot).ChartXvsY times, vals
                    'origMin = strip1(iGraph - 1).Axes(1).Minimum
                    'origMax = strip1(iGraph - 1).Axes(1).Maximum
                    strip1(iGraph - 1).Axes(1).Minimum = lastTime + winSpace - winSize
                    strip1(iGraph - 1).Axes(1).Maximum = lastTime + winSpace
                End If
skipContinue:
            Next
        Next
    End If
    
End Sub

Private Sub Timer1_Timer()
    'If FrmDataGrid.ckLiveUpdate.Value = vbChecked Then
    '    ' A *very* suboptimal strip charting mechanism...
    '    If strip1(0).Visible Then
    '        GraphHistory
    '    End If
    'End If
End Sub

