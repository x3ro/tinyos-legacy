using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using System.Windows.Forms;
using System.Data;
using TASKView.lib;

namespace TASKView.app
{
	/**
	 *  The GUI definition for the TASKView application. 
	 * 
	 * @author      Martin Turon
	 * @version     2004/4/9    mturon      Initial version
	 * 
	 * $Id: formMain.cs,v 1.12 2004/05/04 03:32:30 mturon Exp $
	 */
	public class FormMain : System.Windows.Forms.Form
	{
		internal System.Windows.Forms.MainMenu MainMenu1;
		internal System.Windows.Forms.MenuItem MenuItem1;
		internal System.Windows.Forms.MenuItem MenuItem5;
		internal System.Windows.Forms.MenuItem MenuItem6;
		internal System.Windows.Forms.MenuItem MenuItem24;
		internal System.Windows.Forms.MenuItem MenuItem2;
		internal System.Windows.Forms.MenuItem MenuItem7;
		internal System.Windows.Forms.MenuItem MenuItem9;
		internal System.Windows.Forms.MenuItem MenuItem10;
		internal System.Windows.Forms.MenuItem MenuItem11;
		internal System.Windows.Forms.MenuItem MenuItem12;
		internal System.Windows.Forms.MenuItem MenuItem8;
		internal System.Windows.Forms.MenuItem MenuItem13;
		internal System.Windows.Forms.MenuItem MenuItem14;
		internal System.Windows.Forms.MenuItem MenuItem15;
		internal System.Windows.Forms.MenuItem MenuItem16;
		internal System.Windows.Forms.MenuItem MenuItem17;
		internal System.Windows.Forms.MenuItem MenuItem18;
		internal System.Windows.Forms.MenuItem MenuItem19;
		internal System.Windows.Forms.MenuItem MenuItem20;
		internal System.Windows.Forms.MenuItem MenuItem21;
		internal System.Windows.Forms.MenuItem MenuItem22;
		internal System.Windows.Forms.MenuItem MenuItem3;
		internal System.Windows.Forms.MenuItem MenuItem4;
		internal System.Windows.Forms.MenuItem MenuItem23;
		internal System.Windows.Forms.Panel PanelTools;
		internal System.Windows.Forms.ToolBar ToolBar1;
		internal System.Windows.Forms.ToolBarButton ToolBarButton1;
		internal System.Windows.Forms.ToolBarButton ToolBarButton2;
		internal System.Windows.Forms.Panel PanelMsgs;
		internal System.Windows.Forms.Panel PanelMain;
		internal System.Windows.Forms.Panel PanelViews;
		internal System.Windows.Forms.Splitter Splitter1;
		internal System.Windows.Forms.Panel PanelNodes;
		internal System.Windows.Forms.TabControl TabControl1;
		internal System.Windows.Forms.TabPage TabPage1;
		internal System.Windows.Forms.TabPage TabPage4;
		internal System.Windows.Forms.TextBox TextBox5;
		internal System.Windows.Forms.Label Label13;
		internal System.Windows.Forms.Label Label3;
		internal System.Windows.Forms.Button Button6;
		internal System.Windows.Forms.Button Button5;
		internal System.Windows.Forms.Button Button2;
		internal System.Windows.Forms.Button Button1;
		internal System.Windows.Forms.Label Label2;
		internal System.Windows.Forms.CheckedListBox CheckedListBox1;
		internal System.Windows.Forms.Label Label1;
		internal System.Windows.Forms.TextBox TextBox1;
		internal System.Windows.Forms.ListBox ListBox1;
		internal System.Windows.Forms.TabPage TabPage2;
		internal System.Windows.Forms.Panel Panel1;
		internal System.Windows.Forms.Label Label12;
		internal System.Windows.Forms.Label Label11;
		internal System.Windows.Forms.Label Label10;
		internal System.Windows.Forms.TabPage TabPage3;
		internal System.Windows.Forms.TabPage TabPage5;
		internal System.Windows.Forms.Button Button8;
		internal System.Windows.Forms.Button Button7;
		internal System.Windows.Forms.Button Button4;
		internal System.Windows.Forms.Label Label6;
		internal System.Windows.Forms.Label Label5;
		internal System.Windows.Forms.Label Label4;
		internal System.Windows.Forms.TreeView TreeView1;
		internal System.Windows.Forms.Splitter Splitter2;
		private TASKView.lib.NodeList NodeList1;
		private TASKView.lib.DataGrid DataGrid1;
		private TASKView.lib.MoteMap MoteMap1;
		private System.Windows.Forms.RichTextBox StatusWindow1;
		private System.Windows.Forms.Panel panel3;
		internal System.Windows.Forms.ListView ListView1;
		private System.Windows.Forms.Panel panel4;
		private System.Windows.Forms.Button MMapButtonLoad;
		private System.Windows.Forms.Button MMapButtonSave;
		private System.Windows.Forms.Button MMapButtonRefresh;
		private System.Windows.Forms.Panel Panel2;
		internal System.Windows.Forms.TextBox TextBoxPassword;
		internal System.Windows.Forms.TextBox TextBoxUser;
		internal System.Windows.Forms.TextBox TextBoxServer;
		private System.Windows.Forms.Label label9;
		private System.Windows.Forms.TextBox TextBoxPort;
		private System.Windows.Forms.ComboBox ComboBoxClient;
		private System.Windows.Forms.Label label14;
		internal System.Windows.Forms.ComboBox ComboBoxTable;
		internal System.Windows.Forms.Label Label8;
		internal System.Windows.Forms.ComboBox ComboBoxDatabase;
		internal System.Windows.Forms.Label Label7;
		internal System.Windows.Forms.Button ButtonSetupConnect;
		private TASKView.lib.ChartComboBox ComboBoxChart1;
		private TASKView.lib.ChartComboBox ComboBoxChart2;
		private TASKView.lib.ChartComboBox ComboBoxChart3;
		private TASKView.lib.ChartsPanel ChartPanel5;
		private System.Windows.Forms.TabPage TabPage6;
		private System.Windows.Forms.TabPage TabPage7;

		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.Container components = null;

		public FormMain()
		{
			//
			// Required for Windows Form Designer support
			//
			InitializeComponent();

			//
			// TODO: Add any constructor code after InitializeComponent call
			//
			ComboBoxDatabase_Initialize();
			ComboBoxTable_Initialize();
			DataGrid1.Initialize();
			MoteMap1.Initialize();
			NodeList1.Initialize();
			NodeList1.CheckClick +=new AxCTLISTLib._DctListEvents_CheckClickEventHandler(NodeList1_CheckClick); 
		}

		/** The read-only Instance property returns the one and only instance. */
		public RichTextBox OutputLog
		{
			get { return StatusWindow1; }
		}		

		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		protected override void Dispose( bool disposing )
		{
			if( disposing )
			{
				if (components != null) 
				{
					components.Dispose();
				}
			}
			base.Dispose( disposing );
		}

		#region Windows Form Designer generated code
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{
			System.Resources.ResourceManager resources = new System.Resources.ResourceManager(typeof(FormMain));
			this.MainMenu1 = new System.Windows.Forms.MainMenu();
			this.MenuItem1 = new System.Windows.Forms.MenuItem();
			this.MenuItem5 = new System.Windows.Forms.MenuItem();
			this.MenuItem6 = new System.Windows.Forms.MenuItem();
			this.MenuItem24 = new System.Windows.Forms.MenuItem();
			this.MenuItem2 = new System.Windows.Forms.MenuItem();
			this.MenuItem7 = new System.Windows.Forms.MenuItem();
			this.MenuItem9 = new System.Windows.Forms.MenuItem();
			this.MenuItem10 = new System.Windows.Forms.MenuItem();
			this.MenuItem11 = new System.Windows.Forms.MenuItem();
			this.MenuItem12 = new System.Windows.Forms.MenuItem();
			this.MenuItem8 = new System.Windows.Forms.MenuItem();
			this.MenuItem13 = new System.Windows.Forms.MenuItem();
			this.MenuItem14 = new System.Windows.Forms.MenuItem();
			this.MenuItem15 = new System.Windows.Forms.MenuItem();
			this.MenuItem16 = new System.Windows.Forms.MenuItem();
			this.MenuItem17 = new System.Windows.Forms.MenuItem();
			this.MenuItem18 = new System.Windows.Forms.MenuItem();
			this.MenuItem19 = new System.Windows.Forms.MenuItem();
			this.MenuItem20 = new System.Windows.Forms.MenuItem();
			this.MenuItem21 = new System.Windows.Forms.MenuItem();
			this.MenuItem22 = new System.Windows.Forms.MenuItem();
			this.MenuItem3 = new System.Windows.Forms.MenuItem();
			this.MenuItem4 = new System.Windows.Forms.MenuItem();
			this.MenuItem23 = new System.Windows.Forms.MenuItem();
			this.PanelTools = new System.Windows.Forms.Panel();
			this.ToolBar1 = new System.Windows.Forms.ToolBar();
			this.ToolBarButton1 = new System.Windows.Forms.ToolBarButton();
			this.ToolBarButton2 = new System.Windows.Forms.ToolBarButton();
			this.PanelMsgs = new System.Windows.Forms.Panel();
			this.StatusWindow1 = new System.Windows.Forms.RichTextBox();
			this.PanelMain = new System.Windows.Forms.Panel();
			this.PanelViews = new System.Windows.Forms.Panel();
			this.TabControl1 = new System.Windows.Forms.TabControl();
			this.TabPage1 = new System.Windows.Forms.TabPage();
			this.DataGrid1 = new TASKView.lib.DataGrid();
			this.TabPage2 = new System.Windows.Forms.TabPage();
			this.Panel2 = new System.Windows.Forms.Panel();
			this.ChartPanel5 = new TASKView.lib.ChartsPanel();
			this.Panel1 = new System.Windows.Forms.Panel();
			this.ComboBoxChart3 = new TASKView.lib.ChartComboBox();
			this.ComboBoxChart2 = new TASKView.lib.ChartComboBox();
			this.ComboBoxChart1 = new TASKView.lib.ChartComboBox();
			this.Label12 = new System.Windows.Forms.Label();
			this.Label11 = new System.Windows.Forms.Label();
			this.Label10 = new System.Windows.Forms.Label();
			this.TabPage3 = new System.Windows.Forms.TabPage();
			this.panel3 = new System.Windows.Forms.Panel();
			this.panel4 = new System.Windows.Forms.Panel();
			this.MMapButtonRefresh = new System.Windows.Forms.Button();
			this.MMapButtonSave = new System.Windows.Forms.Button();
			this.MMapButtonLoad = new System.Windows.Forms.Button();
			this.ListView1 = new System.Windows.Forms.ListView();
			this.MoteMap1 = new TASKView.lib.MoteMap();
			this.TabPage4 = new System.Windows.Forms.TabPage();
			this.TextBox5 = new System.Windows.Forms.TextBox();
			this.Label13 = new System.Windows.Forms.Label();
			this.Label3 = new System.Windows.Forms.Label();
			this.Button6 = new System.Windows.Forms.Button();
			this.Button5 = new System.Windows.Forms.Button();
			this.Button2 = new System.Windows.Forms.Button();
			this.Button1 = new System.Windows.Forms.Button();
			this.Label2 = new System.Windows.Forms.Label();
			this.CheckedListBox1 = new System.Windows.Forms.CheckedListBox();
			this.Label1 = new System.Windows.Forms.Label();
			this.TextBox1 = new System.Windows.Forms.TextBox();
			this.ListBox1 = new System.Windows.Forms.ListBox();
			this.TabPage6 = new System.Windows.Forms.TabPage();
			this.TabPage7 = new System.Windows.Forms.TabPage();
			this.TabPage5 = new System.Windows.Forms.TabPage();
			this.ComboBoxTable = new System.Windows.Forms.ComboBox();
			this.Label8 = new System.Windows.Forms.Label();
			this.ComboBoxDatabase = new System.Windows.Forms.ComboBox();
			this.Label7 = new System.Windows.Forms.Label();
			this.label14 = new System.Windows.Forms.Label();
			this.ComboBoxClient = new System.Windows.Forms.ComboBox();
			this.label9 = new System.Windows.Forms.Label();
			this.TextBoxPort = new System.Windows.Forms.TextBox();
			this.Button8 = new System.Windows.Forms.Button();
			this.Button7 = new System.Windows.Forms.Button();
			this.Button4 = new System.Windows.Forms.Button();
			this.ButtonSetupConnect = new System.Windows.Forms.Button();
			this.TextBoxPassword = new System.Windows.Forms.TextBox();
			this.TextBoxUser = new System.Windows.Forms.TextBox();
			this.Label6 = new System.Windows.Forms.Label();
			this.Label5 = new System.Windows.Forms.Label();
			this.Label4 = new System.Windows.Forms.Label();
			this.TextBoxServer = new System.Windows.Forms.TextBox();
			this.TreeView1 = new System.Windows.Forms.TreeView();
			this.Splitter1 = new System.Windows.Forms.Splitter();
			this.PanelNodes = new System.Windows.Forms.Panel();
			this.NodeList1 = new TASKView.lib.NodeList();
			this.Splitter2 = new System.Windows.Forms.Splitter();
			this.PanelTools.SuspendLayout();
			this.PanelMsgs.SuspendLayout();
			this.PanelMain.SuspendLayout();
			this.PanelViews.SuspendLayout();
			this.TabControl1.SuspendLayout();
			this.TabPage1.SuspendLayout();
			((System.ComponentModel.ISupportInitialize)(this.DataGrid1)).BeginInit();
			this.TabPage2.SuspendLayout();
			this.Panel2.SuspendLayout();
			this.Panel1.SuspendLayout();
			this.TabPage3.SuspendLayout();
			this.panel3.SuspendLayout();
			this.panel4.SuspendLayout();
			this.TabPage4.SuspendLayout();
			this.TabPage5.SuspendLayout();
			this.PanelNodes.SuspendLayout();
			((System.ComponentModel.ISupportInitialize)(this.NodeList1)).BeginInit();
			this.SuspendLayout();
			// 
			// MainMenu1
			// 
			this.MainMenu1.MenuItems.AddRange(new System.Windows.Forms.MenuItem[] {
																					  this.MenuItem1,
																					  this.MenuItem2,
																					  this.MenuItem3,
																					  this.MenuItem4});
			// 
			// MenuItem1
			// 
			this.MenuItem1.Index = 0;
			this.MenuItem1.MenuItems.AddRange(new System.Windows.Forms.MenuItem[] {
																					  this.MenuItem5,
																					  this.MenuItem6,
																					  this.MenuItem24});
			this.MenuItem1.Text = "File";
			// 
			// MenuItem5
			// 
			this.MenuItem5.Index = 0;
			this.MenuItem5.Text = "Load Config";
			// 
			// MenuItem6
			// 
			this.MenuItem6.Index = 1;
			this.MenuItem6.Text = "Save Config";
			// 
			// MenuItem24
			// 
			this.MenuItem24.Index = 2;
			this.MenuItem24.Text = "Exit";
			// 
			// MenuItem2
			// 
			this.MenuItem2.Index = 1;
			this.MenuItem2.MenuItems.AddRange(new System.Windows.Forms.MenuItem[] {
																					  this.MenuItem7,
																					  this.MenuItem8,
																					  this.MenuItem19});
			this.MenuItem2.Text = "Units";
			// 
			// MenuItem7
			// 
			this.MenuItem7.Index = 0;
			this.MenuItem7.MenuItems.AddRange(new System.Windows.Forms.MenuItem[] {
																					  this.MenuItem9,
																					  this.MenuItem10,
																					  this.MenuItem11,
																					  this.MenuItem12});
			this.MenuItem7.Text = "Temperature";
			// 
			// MenuItem9
			// 
			this.MenuItem9.Index = 0;
			this.MenuItem9.Text = "Celcius (C)";
			// 
			// MenuItem10
			// 
			this.MenuItem10.Index = 1;
			this.MenuItem10.Text = "Fahrenheit (F)";
			// 
			// MenuItem11
			// 
			this.MenuItem11.Index = 2;
			this.MenuItem11.Text = "Kelvin (K)";
			// 
			// MenuItem12
			// 
			this.MenuItem12.Index = 3;
			this.MenuItem12.Text = "Raw sensor data";
			// 
			// MenuItem8
			// 
			this.MenuItem8.Index = 1;
			this.MenuItem8.MenuItems.AddRange(new System.Windows.Forms.MenuItem[] {
																					  this.MenuItem13,
																					  this.MenuItem14,
																					  this.MenuItem15,
																					  this.MenuItem16,
																					  this.MenuItem17,
																					  this.MenuItem18});
			this.MenuItem8.Text = "Pressure";
			// 
			// MenuItem13
			// 
			this.MenuItem13.Index = 0;
			this.MenuItem13.Text = "Atmosphere (atm)";
			// 
			// MenuItem14
			// 
			this.MenuItem14.Index = 1;
			this.MenuItem14.Text = "Bar (bar)";
			// 
			// MenuItem15
			// 
			this.MenuItem15.Index = 2;
			this.MenuItem15.Text = "Pascal (Pa)";
			// 
			// MenuItem16
			// 
			this.MenuItem16.Index = 3;
			this.MenuItem16.Text = "Per mm Hg (torr)";
			// 
			// MenuItem17
			// 
			this.MenuItem17.Index = 4;
			this.MenuItem17.Text = "Pounds per square inch (psi)";
			// 
			// MenuItem18
			// 
			this.MenuItem18.Index = 5;
			this.MenuItem18.Text = "Raw sensor data";
			// 
			// MenuItem19
			// 
			this.MenuItem19.Index = 2;
			this.MenuItem19.MenuItems.AddRange(new System.Windows.Forms.MenuItem[] {
																					   this.MenuItem20,
																					   this.MenuItem21,
																					   this.MenuItem22});
			this.MenuItem19.Text = "Acceleration";
			// 
			// MenuItem20
			// 
			this.MenuItem20.Index = 0;
			this.MenuItem20.Text = "Meters per second squared (m/s^2)";
			// 
			// MenuItem21
			// 
			this.MenuItem21.Index = 1;
			this.MenuItem21.Text = "Relative gravity (g)";
			// 
			// MenuItem22
			// 
			this.MenuItem22.Index = 2;
			this.MenuItem22.Text = "Raw sensor data";
			// 
			// MenuItem3
			// 
			this.MenuItem3.Index = 2;
			this.MenuItem3.Text = "Window";
			// 
			// MenuItem4
			// 
			this.MenuItem4.Index = 3;
			this.MenuItem4.MenuItems.AddRange(new System.Windows.Forms.MenuItem[] {
																					  this.MenuItem23});
			this.MenuItem4.Text = "Help";
			// 
			// MenuItem23
			// 
			this.MenuItem23.Index = 0;
			this.MenuItem23.Text = "About";
			// 
			// PanelTools
			// 
			this.PanelTools.Controls.Add(this.ToolBar1);
			this.PanelTools.Dock = System.Windows.Forms.DockStyle.Top;
			this.PanelTools.Location = new System.Drawing.Point(0, 0);
			this.PanelTools.Name = "PanelTools";
			this.PanelTools.Size = new System.Drawing.Size(727, 24);
			this.PanelTools.TabIndex = 8;
			// 
			// ToolBar1
			// 
			this.ToolBar1.Buttons.AddRange(new System.Windows.Forms.ToolBarButton[] {
																						this.ToolBarButton1,
																						this.ToolBarButton2});
			this.ToolBar1.DropDownArrows = true;
			this.ToolBar1.Location = new System.Drawing.Point(0, 0);
			this.ToolBar1.Name = "ToolBar1";
			this.ToolBar1.ShowToolTips = true;
			this.ToolBar1.Size = new System.Drawing.Size(727, 28);
			this.ToolBar1.TabIndex = 0;
			this.ToolBar1.ButtonClick += new System.Windows.Forms.ToolBarButtonClickEventHandler(this.ToolBar1_ButtonClick);
			// 
			// ToolBarButton1
			// 
			this.ToolBarButton1.ToolTipText = "Tool 1";
			// 
			// ToolBarButton2
			// 
			this.ToolBarButton2.ToolTipText = "Tool 2";
			// 
			// PanelMsgs
			// 
			this.PanelMsgs.Controls.Add(this.StatusWindow1);
			this.PanelMsgs.Dock = System.Windows.Forms.DockStyle.Bottom;
			this.PanelMsgs.Location = new System.Drawing.Point(0, 436);
			this.PanelMsgs.Name = "PanelMsgs";
			this.PanelMsgs.Size = new System.Drawing.Size(727, 65);
			this.PanelMsgs.TabIndex = 9;
			// 
			// StatusWindow1
			// 
			this.StatusWindow1.Dock = System.Windows.Forms.DockStyle.Fill;
			this.StatusWindow1.Location = new System.Drawing.Point(0, 0);
			this.StatusWindow1.Name = "StatusWindow1";
			this.StatusWindow1.Size = new System.Drawing.Size(727, 65);
			this.StatusWindow1.TabIndex = 0;
			this.StatusWindow1.Text = "Server Messages:";
			// 
			// PanelMain
			// 
			this.PanelMain.Controls.Add(this.PanelViews);
			this.PanelMain.Controls.Add(this.Splitter1);
			this.PanelMain.Controls.Add(this.PanelNodes);
			this.PanelMain.Dock = System.Windows.Forms.DockStyle.Fill;
			this.PanelMain.Location = new System.Drawing.Point(0, 24);
			this.PanelMain.Name = "PanelMain";
			this.PanelMain.Size = new System.Drawing.Size(727, 412);
			this.PanelMain.TabIndex = 10;
			// 
			// PanelViews
			// 
			this.PanelViews.Controls.Add(this.TabControl1);
			this.PanelViews.Dock = System.Windows.Forms.DockStyle.Fill;
			this.PanelViews.Location = new System.Drawing.Point(200, 0);
			this.PanelViews.Name = "PanelViews";
			this.PanelViews.Size = new System.Drawing.Size(527, 412);
			this.PanelViews.TabIndex = 4;
			// 
			// TabControl1
			// 
			this.TabControl1.Controls.Add(this.TabPage1);
			this.TabControl1.Controls.Add(this.TabPage2);
			this.TabControl1.Controls.Add(this.TabPage3);
			this.TabControl1.Controls.Add(this.TabPage4);
			this.TabControl1.Controls.Add(this.TabPage6);
			this.TabControl1.Controls.Add(this.TabPage7);
			this.TabControl1.Controls.Add(this.TabPage5);
			this.TabControl1.Dock = System.Windows.Forms.DockStyle.Fill;
			this.TabControl1.Location = new System.Drawing.Point(0, 0);
			this.TabControl1.Name = "TabControl1";
			this.TabControl1.SelectedIndex = 0;
			this.TabControl1.Size = new System.Drawing.Size(527, 412);
			this.TabControl1.TabIndex = 2;
			// 
			// TabPage1
			// 
			this.TabPage1.Controls.Add(this.DataGrid1);
			this.TabPage1.Location = new System.Drawing.Point(4, 25);
			this.TabPage1.Name = "TabPage1";
			this.TabPage1.Size = new System.Drawing.Size(519, 383);
			this.TabPage1.TabIndex = 2;
			this.TabPage1.Text = "Data";
			// 
			// DataGrid1
			// 
			this.DataGrid1.AlternatingBackColor = System.Drawing.Color.Lavender;
			this.DataGrid1.BackColor = System.Drawing.Color.WhiteSmoke;
			this.DataGrid1.BackgroundColor = System.Drawing.Color.LightGray;
			this.DataGrid1.BorderStyle = System.Windows.Forms.BorderStyle.None;
			this.DataGrid1.CaptionBackColor = System.Drawing.Color.LightSteelBlue;
			this.DataGrid1.CaptionForeColor = System.Drawing.Color.MidnightBlue;
			this.DataGrid1.CaptionText = "Data Grid";
			this.DataGrid1.DataMember = "";
			this.DataGrid1.Dock = System.Windows.Forms.DockStyle.Fill;
			this.DataGrid1.FlatMode = true;
			this.DataGrid1.Font = new System.Drawing.Font("Tahoma", 8F);
			this.DataGrid1.ForeColor = System.Drawing.Color.MidnightBlue;
			this.DataGrid1.GridLineColor = System.Drawing.Color.Gainsboro;
			this.DataGrid1.GridLineStyle = System.Windows.Forms.DataGridLineStyle.None;
			this.DataGrid1.HeaderBackColor = System.Drawing.Color.MidnightBlue;
			this.DataGrid1.HeaderFont = new System.Drawing.Font("Tahoma", 8F, System.Drawing.FontStyle.Bold);
			this.DataGrid1.HeaderForeColor = System.Drawing.Color.WhiteSmoke;
			this.DataGrid1.LinkColor = System.Drawing.Color.Teal;
			this.DataGrid1.Location = new System.Drawing.Point(0, 0);
			this.DataGrid1.Name = "DataGrid1";
			this.DataGrid1.ParentRowsBackColor = System.Drawing.Color.Gainsboro;
			this.DataGrid1.ParentRowsForeColor = System.Drawing.Color.MidnightBlue;
			this.DataGrid1.ReadOnly = true;
			this.DataGrid1.SelectionBackColor = System.Drawing.Color.CadetBlue;
			this.DataGrid1.SelectionForeColor = System.Drawing.Color.WhiteSmoke;
			this.DataGrid1.Size = new System.Drawing.Size(519, 383);
			this.DataGrid1.TabIndex = 1;
			// 
			// TabPage2
			// 
			this.TabPage2.Controls.Add(this.Panel2);
			this.TabPage2.Controls.Add(this.Panel1);
			this.TabPage2.Location = new System.Drawing.Point(4, 25);
			this.TabPage2.Name = "TabPage2";
			this.TabPage2.Size = new System.Drawing.Size(519, 383);
			this.TabPage2.TabIndex = 0;
			this.TabPage2.Text = "Charts";
			this.TabPage2.Visible = false;
			// 
			// Panel2
			// 
			this.Panel2.Controls.Add(this.ChartPanel5);
			this.Panel2.Dock = System.Windows.Forms.DockStyle.Fill;
			this.Panel2.Location = new System.Drawing.Point(0, 40);
			this.Panel2.Name = "Panel2";
			this.Panel2.Size = new System.Drawing.Size(519, 343);
			this.Panel2.TabIndex = 2;
			// 
			// ChartPanel5
			// 
			this.ChartPanel5.Dock = System.Windows.Forms.DockStyle.Fill;
			this.ChartPanel5.Location = new System.Drawing.Point(0, 0);
			this.ChartPanel5.Name = "ChartPanel5";
			this.ChartPanel5.Size = new System.Drawing.Size(519, 343);
			this.ChartPanel5.TabIndex = 0;
			// 
			// Panel1
			// 
			this.Panel1.Controls.Add(this.ComboBoxChart3);
			this.Panel1.Controls.Add(this.ComboBoxChart2);
			this.Panel1.Controls.Add(this.ComboBoxChart1);
			this.Panel1.Controls.Add(this.Label12);
			this.Panel1.Controls.Add(this.Label11);
			this.Panel1.Controls.Add(this.Label10);
			this.Panel1.Dock = System.Windows.Forms.DockStyle.Top;
			this.Panel1.Location = new System.Drawing.Point(0, 0);
			this.Panel1.Name = "Panel1";
			this.Panel1.Size = new System.Drawing.Size(519, 40);
			this.Panel1.TabIndex = 1;
			// 
			// ComboBoxChart3
			// 
			this.ComboBoxChart3.Items.AddRange(new object[] {
																"(none)",
																"thmtemp",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"taosbot",
																"qual",
																"timelo",
																"hamatop",
																"qlen",
																"depth",
																"voltage",
																"freeram",
																"mhqlen",
																"press",
																"taostop",
																"prcalib",
																"(none)",
																"thmtemp",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"taosbot",
																"qual",
																"timelo",
																"hamatop",
																"qlen",
																"depth",
																"voltage",
																"freeram",
																"mhqlen",
																"press",
																"taostop",
																"prcalib",
																"(none)",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x"});
			this.ComboBoxChart3.Location = new System.Drawing.Point(336, 9);
			this.ComboBoxChart3.Name = "ComboBoxChart3";
			this.ComboBoxChart3.Size = new System.Drawing.Size(106, 24);
			this.ComboBoxChart3.TabIndex = 16;
			this.ComboBoxChart3.Text = "(none)";
			this.ComboBoxChart3.SelectedIndexChanged += new System.EventHandler(this.ComboBoxChart3_SelectedIndexChanged);
			// 
			// ComboBoxChart2
			// 
			this.ComboBoxChart2.Items.AddRange(new object[] {
																"(none)",
																"thmtemp",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"taosbot",
																"qual",
																"timelo",
																"hamatop",
																"qlen",
																"depth",
																"voltage",
																"freeram",
																"mhqlen",
																"press",
																"taostop",
																"prcalib",
																"(none)",
																"thmtemp",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"taosbot",
																"qual",
																"timelo",
																"hamatop",
																"qlen",
																"depth",
																"voltage",
																"freeram",
																"mhqlen",
																"press",
																"taostop",
																"prcalib",
																"(none)",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x"});
			this.ComboBoxChart2.Location = new System.Drawing.Point(182, 9);
			this.ComboBoxChart2.Name = "ComboBoxChart2";
			this.ComboBoxChart2.Size = new System.Drawing.Size(116, 24);
			this.ComboBoxChart2.TabIndex = 15;
			this.ComboBoxChart2.Text = "(none)";
			this.ComboBoxChart2.SelectedIndexChanged += new System.EventHandler(this.ComboBoxChart2_SelectedIndexChanged);
			// 
			// ComboBoxChart1
			// 
			this.ComboBoxChart1.Items.AddRange(new object[] {
																"(none)",
																"thmtemp",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"taosbot",
																"qual",
																"timelo",
																"hamatop",
																"qlen",
																"depth",
																"voltage",
																"freeram",
																"mhqlen",
																"press",
																"taostop",
																"prcalib",
																"(none)",
																"thmtemp",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"taosbot",
																"qual",
																"timelo",
																"hamatop",
																"qlen",
																"depth",
																"voltage",
																"freeram",
																"mhqlen",
																"press",
																"taostop",
																"prcalib",
																"(none)",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x",
																"(none)",
																"mag_y",
																"light",
																"humtemp",
																"prtemp",
																"hamabot",
																"nodeid",
																"thermo",
																"humid",
																"parent",
																"timehi",
																"thmtemp",
																"rawmic",
																"qual",
																"accel_y",
																"accel_x",
																"timelo",
																"hamatop",
																"qlen",
																"temp",
																"taosbot",
																"depth",
																"rawtone",
																"tones",
																"voltage",
																"freeram",
																"mhqlen",
																"noise",
																"press",
																"taostop",
																"prcalib",
																"mag_x"});
			this.ComboBoxChart1.Location = new System.Drawing.Point(29, 9);
			this.ComboBoxChart1.Name = "ComboBoxChart1";
			this.ComboBoxChart1.Size = new System.Drawing.Size(115, 24);
			this.ComboBoxChart1.TabIndex = 14;
			this.ComboBoxChart1.Text = "(none)";
			this.ComboBoxChart1.SelectedIndexChanged += new System.EventHandler(this.ComboBoxChart1_SelectedIndexChanged);
			// 
			// Label12
			// 
			this.Label12.Location = new System.Drawing.Point(304, 8);
			this.Label12.Name = "Label12";
			this.Label12.Size = new System.Drawing.Size(24, 23);
			this.Label12.TabIndex = 5;
			this.Label12.Text = "Y3:";
			// 
			// Label11
			// 
			this.Label11.Location = new System.Drawing.Point(152, 8);
			this.Label11.Name = "Label11";
			this.Label11.Size = new System.Drawing.Size(24, 16);
			this.Label11.TabIndex = 3;
			this.Label11.Text = "Y2";
			// 
			// Label10
			// 
			this.Label10.Location = new System.Drawing.Point(0, 8);
			this.Label10.Name = "Label10";
			this.Label10.Size = new System.Drawing.Size(24, 16);
			this.Label10.TabIndex = 2;
			this.Label10.Text = "Y1:";
			// 
			// TabPage3
			// 
			this.TabPage3.Controls.Add(this.panel3);
			this.TabPage3.Controls.Add(this.MoteMap1);
			this.TabPage3.Location = new System.Drawing.Point(4, 25);
			this.TabPage3.Name = "TabPage3";
			this.TabPage3.Size = new System.Drawing.Size(519, 383);
			this.TabPage3.TabIndex = 1;
			this.TabPage3.Text = "Network Map";
			this.TabPage3.Visible = false;
			// 
			// panel3
			// 
			this.panel3.Controls.Add(this.panel4);
			this.panel3.Controls.Add(this.ListView1);
			this.panel3.Dock = System.Windows.Forms.DockStyle.Right;
			this.panel3.Location = new System.Drawing.Point(447, 0);
			this.panel3.Name = "panel3";
			this.panel3.Size = new System.Drawing.Size(72, 383);
			this.panel3.TabIndex = 6;
			// 
			// panel4
			// 
			this.panel4.Controls.Add(this.MMapButtonRefresh);
			this.panel4.Controls.Add(this.MMapButtonSave);
			this.panel4.Controls.Add(this.MMapButtonLoad);
			this.panel4.Dock = System.Windows.Forms.DockStyle.Top;
			this.panel4.Location = new System.Drawing.Point(0, 0);
			this.panel4.Name = "panel4";
			this.panel4.Size = new System.Drawing.Size(72, 104);
			this.panel4.TabIndex = 8;
			// 
			// MMapButtonRefresh
			// 
			this.MMapButtonRefresh.Location = new System.Drawing.Point(8, 72);
			this.MMapButtonRefresh.Name = "MMapButtonRefresh";
			this.MMapButtonRefresh.Size = new System.Drawing.Size(64, 23);
			this.MMapButtonRefresh.TabIndex = 8;
			this.MMapButtonRefresh.Text = "Refresh";
			this.MMapButtonRefresh.Click += new System.EventHandler(this.MMapButtonRefresh_Click);
			// 
			// MMapButtonSave
			// 
			this.MMapButtonSave.Location = new System.Drawing.Point(8, 40);
			this.MMapButtonSave.Name = "MMapButtonSave";
			this.MMapButtonSave.Size = new System.Drawing.Size(64, 23);
			this.MMapButtonSave.TabIndex = 7;
			this.MMapButtonSave.Text = "Save";
			this.MMapButtonSave.Click += new System.EventHandler(this.MMapButtonSave_Click);
			// 
			// MMapButtonLoad
			// 
			this.MMapButtonLoad.Location = new System.Drawing.Point(8, 8);
			this.MMapButtonLoad.Name = "MMapButtonLoad";
			this.MMapButtonLoad.Size = new System.Drawing.Size(64, 24);
			this.MMapButtonLoad.TabIndex = 6;
			this.MMapButtonLoad.Text = "Load";
			// 
			// ListView1
			// 
			this.ListView1.Dock = System.Windows.Forms.DockStyle.Fill;
			this.ListView1.Location = new System.Drawing.Point(0, 0);
			this.ListView1.Name = "ListView1";
			this.ListView1.Size = new System.Drawing.Size(72, 383);
			this.ListView1.TabIndex = 2;
			// 
			// MoteMap1
			// 
			this.MoteMap1.AllowDrop = true;
			this.MoteMap1.Dock = System.Windows.Forms.DockStyle.Fill;
			this.MoteMap1.Location = new System.Drawing.Point(0, 0);
			this.MoteMap1.Name = "MoteMap1";
			this.MoteMap1.Size = new System.Drawing.Size(519, 383);
			this.MoteMap1.SizeMode = System.Windows.Forms.PictureBoxSizeMode.StretchImage;
			this.MoteMap1.TabIndex = 2;
			this.MoteMap1.TabStop = false;
			// 
			// TabPage4
			// 
			this.TabPage4.Controls.Add(this.TextBox5);
			this.TabPage4.Controls.Add(this.Label13);
			this.TabPage4.Controls.Add(this.Label3);
			this.TabPage4.Controls.Add(this.Button6);
			this.TabPage4.Controls.Add(this.Button5);
			this.TabPage4.Controls.Add(this.Button2);
			this.TabPage4.Controls.Add(this.Button1);
			this.TabPage4.Controls.Add(this.Label2);
			this.TabPage4.Controls.Add(this.CheckedListBox1);
			this.TabPage4.Controls.Add(this.Label1);
			this.TabPage4.Controls.Add(this.TextBox1);
			this.TabPage4.Controls.Add(this.ListBox1);
			this.TabPage4.Location = new System.Drawing.Point(4, 25);
			this.TabPage4.Name = "TabPage4";
			this.TabPage4.Size = new System.Drawing.Size(519, 383);
			this.TabPage4.TabIndex = 3;
			this.TabPage4.Text = "Query";
			this.TabPage4.Visible = false;
			// 
			// TextBox5
			// 
			this.TextBox5.Location = new System.Drawing.Point(288, 32);
			this.TextBox5.Name = "TextBox5";
			this.TextBox5.Size = new System.Drawing.Size(192, 22);
			this.TextBox5.TabIndex = 11;
			this.TextBox5.Text = "2500";
			// 
			// Label13
			// 
			this.Label13.Location = new System.Drawing.Point(128, 32);
			this.Label13.Name = "Label13";
			this.Label13.Size = new System.Drawing.Size(144, 25);
			this.Label13.TabIndex = 10;
			this.Label13.Text = "Sample Period (msec):";
			// 
			// Label3
			// 
			this.Label3.Location = new System.Drawing.Point(8, 8);
			this.Label3.Name = "Label3";
			this.Label3.Size = new System.Drawing.Size(112, 24);
			this.Label3.TabIndex = 9;
			this.Label3.Text = "Query List:";
			// 
			// Button6
			// 
			this.Button6.Location = new System.Drawing.Point(400, 344);
			this.Button6.Name = "Button6";
			this.Button6.Size = new System.Drawing.Size(80, 32);
			this.Button6.TabIndex = 8;
			this.Button6.Text = "Delete";
			// 
			// Button5
			// 
			this.Button5.Location = new System.Drawing.Point(312, 344);
			this.Button5.Name = "Button5";
			this.Button5.Size = new System.Drawing.Size(80, 32);
			this.Button5.TabIndex = 7;
			this.Button5.Text = "Stop";
			// 
			// Button2
			// 
			this.Button2.Location = new System.Drawing.Point(224, 344);
			this.Button2.Name = "Button2";
			this.Button2.Size = new System.Drawing.Size(80, 32);
			this.Button2.TabIndex = 6;
			this.Button2.Text = "Resend";
			// 
			// Button1
			// 
			this.Button1.Location = new System.Drawing.Point(136, 344);
			this.Button1.Name = "Button1";
			this.Button1.Size = new System.Drawing.Size(80, 32);
			this.Button1.TabIndex = 5;
			this.Button1.Text = "Start";
			// 
			// Label2
			// 
			this.Label2.Location = new System.Drawing.Point(128, 57);
			this.Label2.Name = "Label2";
			this.Label2.Size = new System.Drawing.Size(152, 23);
			this.Label2.TabIndex = 4;
			this.Label2.Text = "Enabled Sensors:";
			// 
			// CheckedListBox1
			// 
			this.CheckedListBox1.Items.AddRange(new object[] {
																 "temperature",
																 "voltage",
																 "intersema temperature",
																 "intersema humidity",
																 "accel_x",
																 "accel_y",
																 "magno_x",
																 "magno_y",
																 "gps"});
			this.CheckedListBox1.Location = new System.Drawing.Point(136, 88);
			this.CheckedListBox1.Name = "CheckedListBox1";
			this.CheckedListBox1.Size = new System.Drawing.Size(344, 208);
			this.CheckedListBox1.TabIndex = 3;
			// 
			// Label1
			// 
			this.Label1.Location = new System.Drawing.Point(128, 8);
			this.Label1.Name = "Label1";
			this.Label1.Size = new System.Drawing.Size(48, 24);
			this.Label1.TabIndex = 2;
			this.Label1.Text = "Query:";
			// 
			// TextBox1
			// 
			this.TextBox1.Location = new System.Drawing.Point(192, 8);
			this.TextBox1.Name = "TextBox1";
			this.TextBox1.Size = new System.Drawing.Size(288, 22);
			this.TextBox1.TabIndex = 1;
			this.TextBox1.Text = "query1_results";
			// 
			// ListBox1
			// 
			this.ListBox1.ItemHeight = 16;
			this.ListBox1.Location = new System.Drawing.Point(8, 32);
			this.ListBox1.Name = "ListBox1";
			this.ListBox1.Size = new System.Drawing.Size(112, 324);
			this.ListBox1.TabIndex = 0;
			// 
			// TabPage6
			// 
			this.TabPage6.Location = new System.Drawing.Point(4, 25);
			this.TabPage6.Name = "TabPage6";
			this.TabPage6.Size = new System.Drawing.Size(519, 383);
			this.TabPage6.TabIndex = 5;
			this.TabPage6.Text = "Command";
			// 
			// TabPage7
			// 
			this.TabPage7.Location = new System.Drawing.Point(4, 25);
			this.TabPage7.Name = "TabPage7";
			this.TabPage7.Size = new System.Drawing.Size(519, 383);
			this.TabPage7.TabIndex = 6;
			this.TabPage7.Text = "Alerts";
			// 
			// TabPage5
			// 
			this.TabPage5.Controls.Add(this.ComboBoxTable);
			this.TabPage5.Controls.Add(this.Label8);
			this.TabPage5.Controls.Add(this.ComboBoxDatabase);
			this.TabPage5.Controls.Add(this.Label7);
			this.TabPage5.Controls.Add(this.label14);
			this.TabPage5.Controls.Add(this.ComboBoxClient);
			this.TabPage5.Controls.Add(this.label9);
			this.TabPage5.Controls.Add(this.TextBoxPort);
			this.TabPage5.Controls.Add(this.Button8);
			this.TabPage5.Controls.Add(this.Button7);
			this.TabPage5.Controls.Add(this.Button4);
			this.TabPage5.Controls.Add(this.ButtonSetupConnect);
			this.TabPage5.Controls.Add(this.TextBoxPassword);
			this.TabPage5.Controls.Add(this.TextBoxUser);
			this.TabPage5.Controls.Add(this.Label6);
			this.TabPage5.Controls.Add(this.Label5);
			this.TabPage5.Controls.Add(this.Label4);
			this.TabPage5.Controls.Add(this.TextBoxServer);
			this.TabPage5.Controls.Add(this.TreeView1);
			this.TabPage5.Location = new System.Drawing.Point(4, 25);
			this.TabPage5.Name = "TabPage5";
			this.TabPage5.Size = new System.Drawing.Size(519, 383);
			this.TabPage5.TabIndex = 4;
			this.TabPage5.Text = "Setup";
			this.TabPage5.Visible = false;
			// 
			// ComboBoxTable
			// 
			this.ComboBoxTable.Location = new System.Drawing.Point(248, 240);
			this.ComboBoxTable.Name = "ComboBoxTable";
			this.ComboBoxTable.Size = new System.Drawing.Size(240, 24);
			this.ComboBoxTable.TabIndex = 24;
			this.ComboBoxTable.Text = "query1_results";
			// 
			// Label8
			// 
			this.Label8.Location = new System.Drawing.Point(160, 240);
			this.Label8.Name = "Label8";
			this.Label8.Size = new System.Drawing.Size(72, 25);
			this.Label8.TabIndex = 23;
			this.Label8.Text = "Table:";
			// 
			// ComboBoxDatabase
			// 
			this.ComboBoxDatabase.Location = new System.Drawing.Point(248, 200);
			this.ComboBoxDatabase.Name = "ComboBoxDatabase";
			this.ComboBoxDatabase.Size = new System.Drawing.Size(240, 24);
			this.ComboBoxDatabase.TabIndex = 22;
			this.ComboBoxDatabase.Text = "task";
			// 
			// Label7
			// 
			this.Label7.Location = new System.Drawing.Point(160, 200);
			this.Label7.Name = "Label7";
			this.Label7.Size = new System.Drawing.Size(80, 24);
			this.Label7.TabIndex = 21;
			this.Label7.Text = "Database:";
			// 
			// label14
			// 
			this.label14.Location = new System.Drawing.Point(160, 280);
			this.label14.Name = "label14";
			this.label14.Size = new System.Drawing.Size(72, 23);
			this.label14.TabIndex = 20;
			this.label14.Text = "Client:";
			// 
			// ComboBoxClient
			// 
			this.ComboBoxClient.Location = new System.Drawing.Point(248, 280);
			this.ComboBoxClient.Name = "ComboBoxClient";
			this.ComboBoxClient.Size = new System.Drawing.Size(240, 24);
			this.ComboBoxClient.TabIndex = 19;
			this.ComboBoxClient.Text = "TASKView";
			// 
			// label9
			// 
			this.label9.Location = new System.Drawing.Point(160, 48);
			this.label9.Name = "label9";
			this.label9.Size = new System.Drawing.Size(72, 24);
			this.label9.TabIndex = 18;
			this.label9.Text = "Port:";
			// 
			// TextBoxPort
			// 
			this.TextBoxPort.Location = new System.Drawing.Point(248, 48);
			this.TextBoxPort.Name = "TextBoxPort";
			this.TextBoxPort.Size = new System.Drawing.Size(240, 22);
			this.TextBoxPort.TabIndex = 17;
			this.TextBoxPort.Text = "5432";
			// 
			// Button8
			// 
			this.Button8.Location = new System.Drawing.Point(400, 336);
			this.Button8.Name = "Button8";
			this.Button8.Size = new System.Drawing.Size(88, 24);
			this.Button8.TabIndex = 16;
			this.Button8.Text = "Delete";
			// 
			// Button7
			// 
			this.Button7.Location = new System.Drawing.Point(288, 336);
			this.Button7.Name = "Button7";
			this.Button7.Size = new System.Drawing.Size(96, 24);
			this.Button7.TabIndex = 15;
			this.Button7.Text = "Cancel";
			// 
			// Button4
			// 
			this.Button4.Location = new System.Drawing.Point(168, 336);
			this.Button4.Name = "Button4";
			this.Button4.Size = new System.Drawing.Size(96, 24);
			this.Button4.TabIndex = 14;
			this.Button4.Text = "Apply";
			// 
			// ButtonSetupConnect
			// 
			this.ButtonSetupConnect.Location = new System.Drawing.Point(392, 152);
			this.ButtonSetupConnect.Name = "ButtonSetupConnect";
			this.ButtonSetupConnect.Size = new System.Drawing.Size(96, 25);
			this.ButtonSetupConnect.TabIndex = 11;
			this.ButtonSetupConnect.Text = "Connect";
			this.ButtonSetupConnect.Click += new System.EventHandler(this.ButtonSetupConnect_Click);
			// 
			// TextBoxPassword
			// 
			this.TextBoxPassword.Location = new System.Drawing.Point(248, 112);
			this.TextBoxPassword.Name = "TextBoxPassword";
			this.TextBoxPassword.Size = new System.Drawing.Size(240, 22);
			this.TextBoxPassword.TabIndex = 6;
			this.TextBoxPassword.Text = "tiny";
			// 
			// TextBoxUser
			// 
			this.TextBoxUser.Location = new System.Drawing.Point(248, 80);
			this.TextBoxUser.Name = "TextBoxUser";
			this.TextBoxUser.Size = new System.Drawing.Size(240, 22);
			this.TextBoxUser.TabIndex = 5;
			this.TextBoxUser.Text = "tele";
			// 
			// Label6
			// 
			this.Label6.Location = new System.Drawing.Point(160, 112);
			this.Label6.Name = "Label6";
			this.Label6.Size = new System.Drawing.Size(72, 23);
			this.Label6.TabIndex = 4;
			this.Label6.Text = "Password:";
			// 
			// Label5
			// 
			this.Label5.Location = new System.Drawing.Point(160, 80);
			this.Label5.Name = "Label5";
			this.Label5.Size = new System.Drawing.Size(72, 24);
			this.Label5.TabIndex = 3;
			this.Label5.Text = "User:";
			// 
			// Label4
			// 
			this.Label4.Location = new System.Drawing.Point(160, 16);
			this.Label4.Name = "Label4";
			this.Label4.Size = new System.Drawing.Size(72, 24);
			this.Label4.TabIndex = 2;
			this.Label4.Text = "Server:";
			// 
			// TextBoxServer
			// 
			this.TextBoxServer.Location = new System.Drawing.Point(248, 16);
			this.TextBoxServer.Name = "TextBoxServer";
			this.TextBoxServer.Size = new System.Drawing.Size(240, 22);
			this.TextBoxServer.TabIndex = 1;
			this.TextBoxServer.Text = "localhost";
			// 
			// TreeView1
			// 
			this.TreeView1.ImageIndex = -1;
			this.TreeView1.Location = new System.Drawing.Point(8, 16);
			this.TreeView1.Name = "TreeView1";
			this.TreeView1.Nodes.AddRange(new System.Windows.Forms.TreeNode[] {
																				  new System.Windows.Forms.TreeNode("localhost", new System.Windows.Forms.TreeNode[] {
																																										 new System.Windows.Forms.TreeNode("task", new System.Windows.Forms.TreeNode[] {
																																																														   new System.Windows.Forms.TreeNode("query1_results"),
																																																														   new System.Windows.Forms.TreeNode("query2_results")}),
																																										 new System.Windows.Forms.TreeNode("labapp_task")}),
																				  new System.Windows.Forms.TreeNode("mturon.xbow.com")});
			this.TreeView1.SelectedImageIndex = -1;
			this.TreeView1.Size = new System.Drawing.Size(144, 360);
			this.TreeView1.TabIndex = 0;
			// 
			// Splitter1
			// 
			this.Splitter1.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
			this.Splitter1.Location = new System.Drawing.Point(192, 0);
			this.Splitter1.Name = "Splitter1";
			this.Splitter1.Size = new System.Drawing.Size(8, 412);
			this.Splitter1.TabIndex = 2;
			this.Splitter1.TabStop = false;
			// 
			// PanelNodes
			// 
			this.PanelNodes.Controls.Add(this.NodeList1);
			this.PanelNodes.Dock = System.Windows.Forms.DockStyle.Left;
			this.PanelNodes.Location = new System.Drawing.Point(0, 0);
			this.PanelNodes.Name = "PanelNodes";
			this.PanelNodes.Size = new System.Drawing.Size(192, 412);
			this.PanelNodes.TabIndex = 1;
			// 
			// NodeList1
			// 
			this.NodeList1.ContainingControl = this;
			this.NodeList1.Dock = System.Windows.Forms.DockStyle.Fill;
			this.NodeList1.Location = new System.Drawing.Point(0, 0);
			this.NodeList1.Name = "NodeList1";
			this.NodeList1.OcxState = ((System.Windows.Forms.AxHost.State)(resources.GetObject("NodeList1.OcxState")));
			this.NodeList1.Size = new System.Drawing.Size(192, 412);
			this.NodeList1.TabIndex = 1;
			// 
			// Splitter2
			// 
			this.Splitter2.Dock = System.Windows.Forms.DockStyle.Bottom;
			this.Splitter2.Location = new System.Drawing.Point(0, 428);
			this.Splitter2.Name = "Splitter2";
			this.Splitter2.Size = new System.Drawing.Size(727, 8);
			this.Splitter2.TabIndex = 11;
			this.Splitter2.TabStop = false;
			// 
			// FormMain
			// 
			this.AutoScaleBaseSize = new System.Drawing.Size(6, 15);
			this.ClientSize = new System.Drawing.Size(727, 501);
			this.Controls.Add(this.Splitter2);
			this.Controls.Add(this.PanelMain);
			this.Controls.Add(this.PanelMsgs);
			this.Controls.Add(this.PanelTools);
			this.Menu = this.MainMenu1;
			this.Name = "FormMain";
			this.Text = "TASKView";
			this.PanelTools.ResumeLayout(false);
			this.PanelMsgs.ResumeLayout(false);
			this.PanelMain.ResumeLayout(false);
			this.PanelViews.ResumeLayout(false);
			this.TabControl1.ResumeLayout(false);
			this.TabPage1.ResumeLayout(false);
			((System.ComponentModel.ISupportInitialize)(this.DataGrid1)).EndInit();
			this.TabPage2.ResumeLayout(false);
			this.Panel2.ResumeLayout(false);
			this.Panel1.ResumeLayout(false);
			this.TabPage3.ResumeLayout(false);
			this.panel3.ResumeLayout(false);
			this.panel4.ResumeLayout(false);
			this.TabPage4.ResumeLayout(false);
			this.TabPage5.ResumeLayout(false);
			this.PanelNodes.ResumeLayout(false);
			((System.ComponentModel.ISupportInitialize)(this.NodeList1)).EndInit();
			this.ResumeLayout(false);

		}
		#endregion

		/// <summary>
		/// The main entry point for the application.
		/// </summary>
		[STAThread]
		static void Main() 
		{
			FormMain mainForm = theMainForm.Instance;
			Application.Run(mainForm);
			//Application.Run(new FormMain());
		}

		private void ToolBar1_ButtonClick(object sender, System.Windows.Forms.ToolBarButtonClickEventArgs e)
		{
			theOdbcManager.Instance.ErrorLog("\nTesting: " + new Random().Next());
		}

		private void MMapButtonSave_Click(object sender, System.EventArgs e)
		{
			theOdbcManager.Instance.SaveMotePositions();
		}

		private void MMapButtonRefresh_Click(object sender, System.EventArgs e)
		{
			theMoteTable.Instance.Load();
			MoteMap1.Refresh();
		}

		private void ComboBoxChart1_SelectedIndexChanged(object sender, System.EventArgs e)
		{
			this.ChartPanel5.ChartSensor(0, ComboBoxChart1.Text);
		}

		private void ComboBoxChart2_SelectedIndexChanged(object sender, System.EventArgs e)
		{
			this.ChartPanel5.ChartSensor(1, ComboBoxChart2.Text);
		}

		private void ComboBoxChart3_SelectedIndexChanged(object sender, System.EventArgs e)
		{
			this.ChartPanel5.ChartSensor(2, ComboBoxChart3.Text);
		}

		private void NodeList1_CheckClick(object sender, AxCTLISTLib._DctListEvents_CheckClickEvent e)
		{
			this.ChartPanel5.ChartUpdate(0);
			this.ChartPanel5.ChartUpdate(1);
			this.ChartPanel5.ChartUpdate(2);
			this.ChartPanel5.BuildLegend();
			this.ChartPanel5.Refresh();
		}

		private void ButtonSetupConnect_Click(object sender, System.EventArgs e)
		{
			OdbcManager db = theOdbcManager.Instance;
			db.Server		= TextBoxServer.Text;
			db.m_Port		= TextBoxPort.Text;
			db.m_User		= TextBoxUser.Text;
			db.m_Password	= TextBoxPassword.Text;
			db.Database		= ComboBoxDatabase.Text;
			db.m_Table		= ComboBoxTable.Text;
			db.m_Client		= ComboBoxClient.Text;
			NodeList1.Initialize();
			DataGrid1.Initialize();
			MoteMap1.Initialize();
			ComboBoxDatabase_Initialize();
			ComboBoxTable_Initialize();
		}


		private void ComboBoxDatabase_Initialize() 
		{
			OdbcManager db = theOdbcManager.Instance;
			db.Connect();
			DataSet dSet = db.CreateDataSet(db.GetDatabasesCommand());	
			db.Disconnect();

			if (null == dSet) return;

			ComboBoxDatabase.Items.Clear();
			foreach (DataRow dRow in dSet.Tables[0].Rows)
			{
				ComboBoxDatabase.Items.Add(dRow["datname"].ToString());
			}
		}

		private void ComboBoxTable_Initialize() 
		{
			OdbcManager db = theOdbcManager.Instance;
			db.Connect();
			DataSet dSet = db.CreateDataSet(db.GetTablesCommand());	
			db.Disconnect();

			if (null == dSet) return;

			this.ComboBoxTable.Items.Clear();
			foreach (DataRow dRow in dSet.Tables[0].Rows)
			{
				ComboBoxTable.Items.Add(dRow["table_name"].ToString());
			}
		}

		private void ComboBoxChart1_SelectedIndexChanged_1(object sender, System.EventArgs e)
		{
		
		}
	}

	/** 
	 * Singleton version of FormMain
	 * 
	 * @version    2004/4/14    mturon      Initial version
	 */
	public sealed class theMainForm : FormMain
	{
		/** The internal singular instance of the OdbcManager. */
		private static readonly theMainForm instance = new theMainForm();
		private theMainForm() {}

		/** The read-only Instance property returns the one and only instance. */
		public static theMainForm Instance
		{
			get { return instance; }
		}
	} // class theMainForm
}
