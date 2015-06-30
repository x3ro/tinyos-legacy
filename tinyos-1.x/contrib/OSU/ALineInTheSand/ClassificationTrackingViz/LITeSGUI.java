/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

/*
* FILE NAME
*
*     LITeSGUI.java
*
* DESCRIPTION
*
*   This file contains the main class file that construct LITeSGUI simulator.
* It constructs top level frame and adds all its panels (components) to be
* displayed.  Thus, main thread starts from this class.  Exception of menu item
* and Windows Closed event, all other control of this simulation is controlled 
* by the ButtonPanel.  This panel contains start button, stop button, and others
* that will alter the behavior of simulation.  As noted above, all new 
* functionality should be implemented starting with ButtonPanel.  Otherwise,
* if you are adding additional menu items, implement and handle it here in this
* class.
*
* Author : Mark E. Miyashita - Kent State University
* 
* Modification History
*
* 4-20-2003 Mark E. Miyashita  Removed veriables no longer used and updated command
*                              line options
* 4-28-2003 Mark E. Miyashita  Rewrite the GUI component hiereracy to allow use of
*                              JToolBar
* 6-6-2003  Adnan Vora         Added Menu Items for Zoom etc.
*
*/ 

/* Import required java class files */

import java.awt.*;
import java.awt.event.*;
import java.awt.print.*;
import javax.swing.*;
import javax.swing.JMenuBar;
import java.beans.*;
import javax.swing.border.*;
import javax.swing.plaf.metal.DefaultMetalTheme;
import javax.swing.plaf.metal.MetalLookAndFeel;

/* Main class file LITeSGUI */

public class LITeSGUI extends JPanel {

   private static ButtonPanel buttons;        /* Control panel with buttons */
   private static DisplayPanel display;       /* Text area with Mote message output */
   private GraphicsPanel topology;            /* Panel with Network topology */
   private AggregatePanel summary;            /* Panel with Summary Info */
   JDesktopPane desktop = null;
   static final Integer DISPLAYLAYER = new Integer(5);  /* Display Panel Layer */
   static final Integer TOPOLOGYLAYER = new Integer(5); /* Graphics Panel Layer */
   static final Integer SUMMARYLAYER = new Integer(5);  /* Summary Panel Layer */

   /* Possible Look & Feels */
   private String mac      = "com.sun.java.swing.plaf.mac.MacLookAndFeel";
   private String metal    = "javax.swing.plaf.metal.MetalLookAndFeel";
   private String motif    = "com.sun.java.swing.plaf.motif.MotifLookAndFeel";
   private String windows  = "com.sun.java.swing.plaf.windows.WindowsLookAndFeel";

   /* Debug comman line option */
   public static boolean debugMode = false; /* Prints additional message when set */

   /* Set current (default) Look & Feel */
   private String currentLookAndFeel = metal;

   /* The preferred size of the demo */
   private int PREFERRED_WIDTH = 680;
   private int PREFERRED_HEIGHT = 640;
   
   /* A place to hold on to the visible simulation */
   private MainModule MainPanel = null;
   private JPanel Middle = null;

   /* Status Bar */
   private JTextField statusField = null;

   /* Tool Bar */
   private ButtonPanel toolbar = null;
   private JMenuBar menuBar = new JMenuBar();
   private JMenu menu;
   private JMenuItem menuItem,menuItem1,menuItem2;
   private JMenuItem mi;
   private ButtonGroup themesMenuGroup = new ButtonGroup();
   private ButtonGroup lookandfeelMenuGroup = new ButtonGroup();
   private JMenu themesMenu = null;
   private JMenu lookandfeelMenu = null; 
   private JMenu viewMenu = null;

   /* Used as a top level container for application */ 
   private static JFrame frame = null;

   /* contentPane cache, saved from the application frame */
   Container contentPane = null;


   /**
    * LITeSGUI Constructor
    */
   public LITeSGUI() {
      /* Set Layout */
      setLayout(new BorderLayout());

      /* set the preferred size of the Outter most panel */
      setPreferredSize(new Dimension(PREFERRED_WIDTH,PREFERRED_HEIGHT));

      /* initialize all components making up the GUI */       
      initializeGUI();

      /* display GUI */
      showLITeSGUI();
   }

   /**
    * LITeSGUI Main method. Command line argument is handled here.  Any new
    * command line argument should be implemented here.
    */
   public static void main(String[] argv) {

      /* Handle command line arguments */
      for ( int i = 0; i < argv.length; i++ )
      {
         if (argv[i].equals("-h")) {  /* print out usage message */
            LITeSGUI.usage();
            System.exit(0);
         }
         else if ( argv[i].equals ("-debug") ) /* Can be used to display debug message on display panel */ 
         { 
            debugMode = true; 
         }   
      }

      frame = createFrame();  /* Create top level Frame for this application */
      LITeSGUI litesgui = new LITeSGUI();  /* Call Constructor */
   }
   
   /**
    *  Set up all components which makes up the visualization GUI application
    */
   public void initializeGUI() {

      desktop = new JDesktopPane();       /* Create Desktop Pane to be used for Internal Frame */
      desktop.setDragMode(JDesktopPane.OUTLINE_DRAG_MODE); /* Use Drag mode for Internal Frame */

      JPanel top = new JPanel();          /* Create panel to hold menu items */
      top.setLayout(new BorderLayout());
      add(top, BorderLayout.NORTH);

      summary = new AggregatePanel();
      desktop.add( summary, SUMMARYLAYER );

      topology = new GraphicsPanel( summary );
      desktop.add(topology, TOPOLOGYLAYER);
      try { 
         topology.setSelected(true); 
      } catch (java.beans.PropertyVetoException e2) {}

      menuBar = createMenus();            /* Create menu items for the application */
      top.add(menuBar, BorderLayout.NORTH);

      /* Create JApplet as a top level container to hold Internal Frame */
      MainPanel = new MainModule(this);  
      MainPanel.getMainPanel().add(desktop, BorderLayout.CENTER);
      Middle = new JPanel();
      Middle.setLayout(new BorderLayout());
      Middle.setBorder(new CompoundBorder(new EtchedBorder(), 
                     new EmptyBorder(5,5,5,5)));
      add(Middle, BorderLayout.CENTER);
      Middle.removeAll();
      Middle.add(MainPanel.getMainPanel(), BorderLayout.CENTER);

      /* Add Internal Frame */
      display = new DisplayPanel();
      desktop.add(display, DISPLAYLAYER);
      try { 
         display.setSelected(true); 
      } catch (java.beans.PropertyVetoException e2) {}

      /* Create JToolBar under menu item */
      JPanel toolbarPanel = new JPanel();
      toolbarPanel.setLayout(new BorderLayout());
      toolbar = new ButtonPanel(display, topology, summary);
      toolbarPanel.add(toolbar, BorderLayout.CENTER);
      top.add(toolbarPanel, BorderLayout.SOUTH);

      /* Add status field at the bottom of the application */
      statusField = new JTextField("");
      statusField.setEditable(false);
      add(statusField, BorderLayout.SOUTH);
   }

   /**
    * Create menus used in the application
    */
   public JMenuBar createMenus() {
      /* Create the Menu bar */
      JRadioButtonMenuItem rbmi = null;
      JCheckBoxMenuItem jcbmi = null;
      menu = new JMenu("Simulation");
      menu.setMnemonic(KeyEvent.VK_S);
      menuBar.add(menu);

      /* Create general menu item */
      createMenuItem(menu, "Print", "Print", "menu.print_accessible_description", new PrintAction(this));
      createMenuItem(menu, "Exit", "Exit", "menu.exit_accessible_description", new ExitAction(this));

      /* Create themes menu */
      themesMenu = (JMenu) menuBar.add(new JMenu("Themes"));
      themesMenu.setMnemonic(getMnemonic("Themes"));
      mi = createThemesMenuItem(themesMenu, "default", "default", new DefaultMetalTheme());
      mi.setSelected(true); // This is the default theme
      createThemesMenuItem(themesMenu, "aqua", "aqua", new AquaTheme());
      createThemesMenuItem(themesMenu, "charcoal", "charcoal", new CharcoalTheme());
      createThemesMenuItem(themesMenu, "contrast", "contrast", new ContrastTheme());
      createThemesMenuItem(themesMenu, "demometal", "demometal", new DemoMetalTheme());
      createThemesMenuItem(themesMenu, "emerald", "emerald", new EmeraldTheme());
      createThemesMenuItem(themesMenu, "green", "green", new GreenMetalTheme());
      createThemesMenuItem(themesMenu, "Khaki", "Khaki", new KhakiMetalTheme());
      createThemesMenuItem(themesMenu, "ruby", "ruby", new RubyTheme());

      /* create look and feel menu */ 
      lookandfeelMenu = (JMenu) menuBar.add(new JMenu("look and feel"));
      lookandfeelMenu.setMnemonic(getMnemonic("look and feel"));
      mi = createlookandfeelMenuItem(lookandfeelMenu, "Java", "Java", metal);
      mi.setSelected(true); // this is the default l&f
      createlookandfeelMenuItem(lookandfeelMenu, "mac", "mac", mac);
      createlookandfeelMenuItem(lookandfeelMenu, "motif", "motif", motif);
      createlookandfeelMenuItem(lookandfeelMenu, "window", "windows", windows);

      /* Create View Menu */
      viewMenu = (JMenu) menuBar.add( new JMenu( "View" ) );
      viewMenu.setMnemonic( getMnemonic( "View" ) );

      /* Add the Check Box Menu for Topology */
      jcbmi = new JCheckBoxMenuItem( new String( "Topology" ), true );
      jcbmi.addItemListener( new TopologyCheckBoxListener() );
      viewMenu.add( jcbmi );

      /* Add the Check Box Menu for Motes */
      jcbmi = new JCheckBoxMenuItem( new String( "Motes" ), true );
      jcbmi.addItemListener( new MotesCheckBoxListener() );
      viewMenu.add( jcbmi );

      /* Add the Check Box Menu for Participating Motes */
      jcbmi = new JCheckBoxMenuItem( new String( "Participating Motes" ), true );
      jcbmi.addItemListener( new ParticipatingMotesCheckBoxListener() );
      viewMenu.add( jcbmi );

      /* Add the Check Box Menu for Grid lines */
      jcbmi = new JCheckBoxMenuItem( new String( "Grid Lines" ), false );
      jcbmi.addItemListener( new GridLinesCheckBoxListener() );
      viewMenu.add( jcbmi );

      /* Add the Zoom Sub Menu */
      JMenu zoomSubMenu = new JMenu( "Zoom" );
      ZoomActionListener zoomListener = new ZoomActionListener();
      ButtonGroup group = new ButtonGroup();
      rbmi = new JRadioButtonMenuItem( "50%" );
      rbmi.setSelected( false );
      rbmi.setActionCommand( "0.5" );
      rbmi.addActionListener( zoomListener );
      group.add( rbmi );
      zoomSubMenu.add( rbmi );
      rbmi = new JRadioButtonMenuItem( "100%" );
      rbmi.setSelected( true );
      rbmi.setActionCommand( "1.0" );
      rbmi.addActionListener( zoomListener );
      group.add( rbmi );
      zoomSubMenu.add( rbmi );
      rbmi = new JRadioButtonMenuItem( "200%" );
      rbmi.setSelected( false );
      rbmi.setActionCommand( "2.0" );
      rbmi.addActionListener( zoomListener );
      group.add( rbmi );
      zoomSubMenu.add( rbmi );
      rbmi = new JRadioButtonMenuItem( "500%" );
      rbmi.setSelected( false );
      rbmi.setActionCommand( "5.0" );
      rbmi.addActionListener( zoomListener );
      group.add( rbmi );
      zoomSubMenu.add( rbmi );
      rbmi = new JRadioButtonMenuItem( "1000%" );
      rbmi.setSelected( false );
      rbmi.setActionCommand( "10.0" );
      rbmi.addActionListener( zoomListener );
      group.add( rbmi );
      zoomSubMenu.add( rbmi );
      viewMenu.add( zoomSubMenu );
              
      return menuBar;
   }

   public class TopologyCheckBoxListener implements ItemListener {
      public TopologyCheckBoxListener() {}
      public void itemStateChanged( ItemEvent ie ) {
         if( ie.getStateChange() == ItemEvent.SELECTED ) 
         {
            topology.surf.setShowTopology( true );
         }
         else
         {
            topology.surf.setShowTopology( false );
         }
      }
   }

   public class MotesCheckBoxListener implements ItemListener {
      public MotesCheckBoxListener() {}
      public void itemStateChanged( ItemEvent ie ) {
         if( ie.getStateChange() == ItemEvent.SELECTED ) 
         {
            topology.surf.setShowMotes( true );
         }
         else
         {
            topology.surf.setShowMotes( false );
         }
      }
   }

   public class ParticipatingMotesCheckBoxListener implements ItemListener {
      public ParticipatingMotesCheckBoxListener() {}
      public void itemStateChanged( ItemEvent ie ) {
         if( ie.getStateChange() == ItemEvent.SELECTED ) 
         {
            topology.surf.setShowParticipatingMotes( true );
         }
         else
         {
            topology.surf.setShowParticipatingMotes( false );
         }
      }
   }

   public class GridLinesCheckBoxListener implements ItemListener {
      public GridLinesCheckBoxListener() {}
      public void itemStateChanged( ItemEvent ie ) {
         if( ie.getStateChange() == ItemEvent.SELECTED ) 
         {
            topology.surf.setShowGridLines( true );
         }
         else
         {
            topology.surf.setShowGridLines( false );
         }
      }
   }

   public class ZoomActionListener implements ActionListener {
      public ZoomActionListener() {}
      public void actionPerformed( ActionEvent ae ) {
         double scale = 1.0;
         try {
            scale = Double.parseDouble( ae.getActionCommand() );
         } catch( NumberFormatException nfe ) {
            scale = 1.0;
         }
         topology.surf.setZoomFactor( scale );
      }
   }


   

   /**
    * Creates a generic menu item
    */
   public JMenuItem createMenuItem(JMenu menu, String label, String mnemonic,
               String accessibleDescription, Action action) {
      JMenuItem mi = (JMenuItem) menu.add(new JMenuItem(label));
      mi.setMnemonic(getMnemonic(mnemonic));
      mi.addActionListener(action);
      if(action == null) {
         mi.setEnabled(false);
      }
      return mi;
   }

   /* Creates a JRadioButtonMenuItem for the Look and Feel menu */
   public JMenuItem createlookandfeelMenuItem(JMenu menu, String label, String mnemonic, String lookandfeel) {
      JMenuItem mi = (JRadioButtonMenuItem) menu.add(new JRadioButtonMenuItem(label));
      lookandfeelMenuGroup.add(mi);
      mi.setMnemonic(getMnemonic(mnemonic));
      mi.addActionListener(new ChangeLookAndFeelAction(this, lookandfeel));
      mi.setEnabled(isAvailableLookAndFeel(lookandfeel));

      return mi;
   }

   /* Creates a JRadioButtonMenuItem for the Themes menu */
   public JMenuItem createThemesMenuItem(JMenu menu, String label, String mnemonic,
                                DefaultMetalTheme theme) {

      JRadioButtonMenuItem mi = (JRadioButtonMenuItem) menu.add(new JRadioButtonMenuItem(label));
      themesMenuGroup.add(mi);
      mi.setMnemonic(getMnemonic(mnemonic));
      mi.addActionListener(new ChangeThemeAction(this, theme));

      return mi;
   }

   /* keyboard shortcuts in menu items */
   public char getMnemonic(String key) {
      return (key).charAt(0);
   }

    /* Class used to handle Theme change through Menu item */
   class ChangeThemeAction extends AbstractAction {
      LITeSGUI litesgui;
      DefaultMetalTheme theme;
      protected ChangeThemeAction(LITeSGUI litesgui, DefaultMetalTheme theme) {
         super("ChangeTheme");
         this.litesgui = litesgui;
         this.theme = theme;
      }

      public void actionPerformed(ActionEvent e) {
         MetalLookAndFeel.setCurrentTheme(theme);
         litesgui.updateLookAndFeel();
      }
   }

   /* Class used to handle Look & Feel change through Menu item */
   class ChangeLookAndFeelAction extends AbstractAction {
      LITeSGUI litesgui;
      String lookandfeel;
      protected ChangeLookAndFeelAction(LITeSGUI litesgui, String lookandfeel) {
         super("ChangeTheme");
         this.litesgui = litesgui;
         this.lookandfeel = lookandfeel;
      }

      public void actionPerformed(ActionEvent e) {
         litesgui.setLookAndFeel(lookandfeel);
      }
   }


   /* Returns true if the LookAndFeel is supported. Returns false if the
    * LookAndFeel is not supported and/or if there is any kind of error 
    * checking if the LookAndFeel is supported.
    */
    protected boolean isAvailableLookAndFeel(String lookandfeel) {
       try { 
          Class lnfClass = Class.forName(lookandfeel);
          LookAndFeel newlookandfeel = (LookAndFeel)(lnfClass.newInstance());
          return newlookandfeel.isSupportedLookAndFeel();
       } catch(Exception e) { // If ANYTHING happens, return false
          return false;
       }
   }

   /* Stores the current Look and feel and calls updateLookAndFeel */
   public void setLookAndFeel(String lookandfeel) {
      if(currentLookAndFeel != lookandfeel) {
         currentLookAndFeel = lookandfeel;
         themesMenu.setEnabled(lookandfeel == metal);
         updateLookAndFeel();
      }
   }

   /* Sets the current Look and feel on each component */
   public void updateLookAndFeel() {
      try {
         UIManager.setLookAndFeel(currentLookAndFeel);
         SwingUtilities.updateComponentTreeUI(this);
      } catch (Exception ex) {
         System.out.println("Failed loading Look and feel: " + currentLookAndFeel);
         System.out.println(ex);
      }

      /* update internalFrame */
      SwingUtilities.updateComponentTreeUI(display.getInternalFrame());
      SwingUtilities.updateComponentTreeUI(topology.getInternalFrame());
      SwingUtilities.updateComponentTreeUI(summary.getInternalFrame());
   
   }

   /* Class used to handle print request through Menu item */
   class PrintAction extends AbstractAction {
      LITeSGUI litesgui;
      protected PrintAction(LITeSGUI litesgui) {
         super("PrintAction");
         this.litesgui = litesgui;
      }

      /* Handle Menu item action "print" */

      public void actionPerformed(ActionEvent e) {
         if (e.getActionCommand().equals("Print")) {
            Thread runner = new Thread() {
               public void run(){
                  if (topology.surf != null)
                     printdata();
               }
            };
            runner.start();
         }
      }
   }

   /* Print content of GraphicsPanel (network topology) */
   public void printdata() {
      try {
         PrinterJob prnJob = PrinterJob.getPrinterJob();
         prnJob.setPrintable(topology.surf);
         if (!prnJob.printDialog())
            return;
         setCursor(Cursor.getPredefinedCursor(Cursor.WAIT_CURSOR));
         prnJob.print();
         setCursor(Cursor.getPredefinedCursor(Cursor.DEFAULT_CURSOR));
         JOptionPane.showMessageDialog(this,"Printing completed Successfully","LITeSGUI",
                                           JOptionPane.INFORMATION_MESSAGE);
      } catch (PrinterException e) {
         e.printStackTrace();
      }
   }

   /* Class used to handle exit menu item request */
   class ExitAction extends AbstractAction {
      LITeSGUI litesgui;
      protected ExitAction(LITeSGUI litesgui) {
         super("ExitAction");
         this.litesgui = litesgui;
      }

      /* Handle Menu item action "exit" */
      public void actionPerformed(ActionEvent e) {
         if (e.getActionCommand().equals("Exit")) System.exit(0);
      }
   }

   /**
    * Bring up the LITeSGUI by showing the frame (with all its
    * components defined through method InitializeGUI())
    */
   public void showLITeSGUI() {
      if(getFrame() != null) {
         // put litesgui in a frame and show it
         JFrame f = getFrame();
         f.setTitle("LITeSGUI");
         f.getContentPane().add(this, BorderLayout.CENTER);
         f.pack();
         Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
         getFrame().setLocation(
         screenSize.width/2 - f.getSize().width/2,
         screenSize.height/2 - f.getSize().height/2);
         getFrame().show();
      } 
   }

   /**
    * Returns the frame instance
    */
   public JFrame getFrame() {
      return frame;
   }

   /* Returns the content pane of application */
   public Container getContentPane() {
      if(contentPane == null) {
         if(getFrame() != null) {
            contentPane = getFrame().getContentPane();
         }
      }
      return contentPane;
   }

   /**
    * Create a frame for LITeSGUI to reside in 
    * as an application.
    */
   public static JFrame createFrame() {
      JFrame frame = new JFrame();
      WindowListener l = new WindowAdapter() {
         public void windowClosing(WindowEvent e) {
            System.exit(0);
         }
      };
      frame.addWindowListener(l);
      return frame;
   }

   /* Method used to display command line arguments that could be used with 
    * this app.  Add any addtional command line arguments here to be displayed.
    * Remeber, if you add option, you must implement them in the right place.
    * First, you must pass them into the LITeSGUI constructor.  From there, 
    * handle them accordingly. 
    */
   public static void usage() {
      System.out.println("java LITeSGUI [-<optionflag>]");
      System.out.println("\t -h : Displays this message");
      System.out.println("\t -debug       = display debug messages");
   }
   
   /* Display message on DisplayPanel when debugMode is set to true */
   public static void DEBUG ( String msg )
   {
      if ( LITeSGUI.debugMode ) { display.displayMsg( msg ); }
   }

   /* Class used to hold Internal Frame as its component */
   public class MainModule extends JApplet {
      // The preferred size of this applet
      private int PREFERRED_WIDTH = 680;
      private int PREFERRED_HEIGHT = 600;
   
      private LITeSGUI litesgui = null;
      private JPanel panel = null;

      public MainModule(LITeSGUI litesgui) {
         panel = new JPanel();
         panel.setLayout(new BorderLayout());
         this.litesgui = litesgui;
      }

      public JPanel getMainPanel() {
         return panel;
      }

      public void init() {
         this.getContentPane().setLayout(new BorderLayout());
         this.getContentPane().add(getMainPanel(), BorderLayout.CENTER);
      }
   }
}
