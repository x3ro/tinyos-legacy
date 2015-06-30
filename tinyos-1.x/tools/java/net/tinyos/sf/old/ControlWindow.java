// $Id: ControlWindow.java,v 1.2 2003/10/07 21:46:03 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


/**
 * File: ControlWindow.java
 *
 * Description:
 * This class displays the GUI that allows the serial forwarder
 * to be more easily configured
 *
 * @author <a href="mailto:bwhull@sourceforge.net">Bret Hull</a>
 */

package net.tinyos.sf.old;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

public class ControlWindow extends JPanel implements WindowListener {
    ListenServer  listenServer          = null;
    JScrollPane   mssgPanel             = new JScrollPane();
    JTextArea     mssgArea              = new JTextArea();
    BorderLayout  toplayout             = new BorderLayout();
    JTabbedPane   pnlTabs               = new JTabbedPane();
    JLabel        labelPacketsSent      = new JLabel();
    JLabel        labelServerPort       = new JLabel();
    JTextField    fieldServerPort       = new JTextField();
    JLabel        labelSerialPort       = new JLabel();
    JLabel        labelPacketsReceived  = new JLabel();
    JLabel        labelPacketSize       = new JLabel();
    JTextField    fieldSerialPort       = new JTextField();
    JTextField    fieldPacketSize       = new JTextField();
    JCheckBox     cbDummyData           = new JCheckBox();
    JCheckBox     cbSerialData          = new JCheckBox();
    JCheckBox     cbNetData             = new JCheckBox();
    JCheckBox     cbNidoSerialData      = new JCheckBox();
    JCheckBox     cbDBData              = new JCheckBox();
    ButtonGroup   bttnGroup             = new ButtonGroup();
    JPanel        pnlMain               = new JPanel();
    GridLayout    gridLayout1           = new GridLayout();
    JLabel        labelNumClients       = new JLabel();
    JCheckBox     cbVerboseMode         = new JCheckBox();
    JButton       bStopServer           = new JButton();
    GridLayout    gridLayout2           = new GridLayout();
    JButton       bQuit                 = new JButton();
    private SerialForward sf;
  public ControlWindow( SerialForward SF) {
      sf=SF;
    try {
      jbInit();
    }
    catch(Exception e) {
      e.printStackTrace();
    }
  }
  private void jbInit() throws Exception {
    this.setLayout(toplayout);

    mssgPanel.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
    mssgPanel.setAutoscrolls(true);
    this.setMinimumSize(new Dimension(400, 300));
    this.setPreferredSize(new Dimension(400, 400));
    labelPacketsSent.setFont(new java.awt.Font("Dialog", 1, 10));
    labelPacketsSent.setHorizontalTextPosition(SwingConstants.LEFT);
    labelPacketsSent.setText("Pckts Read: 0");
    labelServerPort.setFont(new java.awt.Font("Dialog", 1, 10));
    labelServerPort.setText("Server Port:");
    fieldServerPort.setFont(new java.awt.Font("Dialog", 0, 10));
    fieldServerPort.setText(Integer.toString ( sf.serverPort ));
    labelSerialPort.setFont(new java.awt.Font("Dialog", 1, 10));
    labelSerialPort.setText("Serial Port:");

    labelPacketsReceived.setFont(new java.awt.Font("Dialog", 1, 10));
    labelPacketsReceived.setHorizontalTextPosition(SwingConstants.LEFT);
    labelPacketsReceived.setText("Pckts Wrttn: 0");
    labelPacketSize.setFont(new java.awt.Font("Dialog", 1, 10));
    labelPacketSize.setText("Packet Size:");
    fieldSerialPort.setFont(new java.awt.Font("Dialog", 0, 10));
    fieldSerialPort.setText(sf.commPort);
    fieldPacketSize.setFont(new java.awt.Font("Dialog", 0, 10));
    fieldPacketSize.setText(Integer.toString( sf.PACKET_SIZE));

    // Input CheckBoxes
    ActionListener cbal = new ActionListener() {
	public void actionPerformed(ActionEvent e) {
	  UpdateGlobals();
	}
    };

    cbDummyData.setSelected(sf.useDummyData);
    cbDummyData.setText("Dummy Data");
    cbDummyData.setFont(new java.awt.Font("Dialog", 1, 10));
    cbDummyData.addActionListener(cbal);

    cbSerialData.setSelected( !( sf.useDummyData ||
				 sf.bSourceSim ||
				 sf.bSourceDB ||
				 sf.bNidoSerialData) );
    cbSerialData.setText("Serial Port");
    cbSerialData.setFont(new java.awt.Font("Dialog", 1, 10));
    cbSerialData.addActionListener(cbal);
    
    cbNetData.setSelected( sf.bSourceSim );
    cbNetData.setText( "TOSSIM Snoop");
    cbNetData.setFont(new java.awt.Font("Dialog", 1, 10));
    cbNetData.addActionListener(cbal);
    
    cbNidoSerialData.setSelected(sf.bNidoSerialData);
    cbNidoSerialData.setText( "TOSSIM Serial");
    cbNidoSerialData.setFont(new java.awt.Font("Dialog", 1, 10));
    cbNidoSerialData.addActionListener(cbal);


    cbDBData.setSelected ( sf.bSourceDB );
    cbDBData.setText ( "DB" );
    cbDBData.setFont(new java.awt.Font("Dialog", 1, 10));
    cbDBData.addActionListener(cbal);

    bQuit.addActionListener(new java.awt.event.ActionListener()
    {
      public void actionPerformed(ActionEvent e)
      {
        bQuit_actionPerformed(e);
      }
    });
        bQuit.setText("Quit");
        bQuit.setFont(new java.awt.Font("Dialog", 1, 10));
        bttnGroup.add( cbDummyData );
    bttnGroup.add( cbSerialData );
    bttnGroup.add( cbNetData );
    bttnGroup.add( cbNidoSerialData);
    bttnGroup.add( cbDBData );

    pnlMain.setLayout(gridLayout1);
    pnlMain.setMinimumSize(new Dimension(100, 75));
    pnlMain.setPreferredSize(new Dimension(100, 75));
    gridLayout1.setRows(18);
    labelNumClients.setFont(new java.awt.Font("Dialog", 1, 10));
    labelNumClients.setText("Num Clients: 0");
    cbVerboseMode.setSelected(SerialForward.verboseMode);
    cbVerboseMode.setText("Verbose Mode");
    cbVerboseMode.setFont(new java.awt.Font("Dialog", 1, 10));
    cbVerboseMode.addActionListener(cbal);

    bStopServer.setFont(new java.awt.Font("Dialog", 1, 10));
    bStopServer.setText("Stop Server");
    bStopServer.addActionListener(new java.awt.event.ActionListener()
    {
      public void actionPerformed(ActionEvent e)
      {
        bStopServer_actionPerformed(e);
      }
    });
    gridLayout2.setRows(16);
    gridLayout2.setColumns(1);

    toplayout.setHgap(1);
    toplayout.setVgap(1);
    this.add(mssgPanel, BorderLayout.CENTER);
    this.add(pnlTabs, BorderLayout.EAST);
    pnlTabs.add(pnlMain, "Main");

    // Main Panel Setup
    pnlMain.add(labelServerPort, null);
    pnlMain.add(fieldServerPort, null);
    pnlMain.add(labelSerialPort, null);
    pnlMain.add(fieldSerialPort, null);
    pnlMain.add(labelPacketSize, null);
    pnlMain.add(fieldPacketSize, null);
    pnlMain.add(bStopServer, null);

    pnlMain.add( cbDummyData, null);
    pnlMain.add( cbSerialData, null );
    pnlMain.add( cbNetData, null );
    pnlMain.add( cbNidoSerialData, null);
    pnlMain.add( cbDBData, null );
    pnlMain.add( cbVerboseMode, null);

    pnlMain.add( labelPacketsSent, null);
    pnlMain.add( labelPacketsReceived, null);
    pnlMain.add( labelNumClients, null);
        pnlMain.add(bQuit, null);

    mssgPanel.getViewport().add(mssgArea, null);
  }

  public synchronized void AddMessage ( String mssg )
  {
    mssgArea.append(mssg);
  }

  public void UpdatePacketsRead ( int numPackets )
  {
    labelPacketsSent.setText( "Pckts Read: " + numPackets );
  }

  public void UpdatePacketsWritten ( int numPackets )
  {
    labelPacketsReceived.setText( "Pckts Wrttn: " + numPackets );
  }

  public void UpdateNumClients ( int numClients )
  {
    labelNumClients.setText( "Num Clients: " + numClients );
  }

  public synchronized void windowClosing ( WindowEvent e )
  {
    sf.cntrlWndw = null;
    if ( listenServer != null )
    {
      listenServer.Shutdown();
      try { listenServer.join(2000); }
      catch ( InterruptedException ex ) { }
    }
    System.out.println ( "Serial Forwarder Exited Normally\n" );
    System.exit(1);
  }

  public void windowClosed      ( WindowEvent e ) { }
  public void windowActivated   ( WindowEvent e ) { }
  public void windowIconified   ( WindowEvent e ) { }
  public void windowDeactivated ( WindowEvent e ) { }
  public void windowDeiconified ( WindowEvent e ) { }
  public void windowOpened      ( WindowEvent e ) { }

  public void ServerStart ( )
  {
    if ( listenServer == null )
    {
       UpdateGlobals();
      UpdatePacketsWritten ( 0 );
      UpdatePacketsRead ( 0 );
      UpdateNumClients ( 0 );
      listenServer = new ListenServer (sf);
      listenServer.start();
      sf.DEBUG("Starting listen server.");
      bStopServer.setText ("Stop Server");
    }
  }

  public void UpdateGlobals ( )
  {
    // set application/communications defaults
      sf.bSourceSim          = cbNetData.isSelected();
    sf.bNidoSerialData     = cbNidoSerialData.isSelected();
    sf.bSourceDB           = cbDBData.isSelected ();
    sf.useDummyData        = cbDummyData.isSelected();
    sf.verboseMode         = cbVerboseMode.isSelected();
    sf.commPort            = fieldSerialPort.getText();
    sf.serverPort          = Integer.parseInt ( fieldServerPort.getText() );
    sf.PACKET_SIZE         = Integer.parseInt ( fieldPacketSize.getText() );
  }
  void bStopServer_actionPerformed(ActionEvent e)
  {
    if ( listenServer != null )
    {
      listenServer.Shutdown();
      bStopServer.setText( "Start Server" );
      //listenServer = null;
    }
    else {
        ServerStart ();
    }
  }

  public synchronized void ClearListenServer (  )
  {
    listenServer = null;
    bStopServer.setText ( "Start Server" );
  }
    void bQuit_actionPerformed(ActionEvent e)
    {
        sf.cntrlWndw = null;
        if ( listenServer != null )
        {
          listenServer.Shutdown();
          try { listenServer.join(2000); }
          catch ( InterruptedException ex ) { }
        }
        System.out.println ( "Serial Forwarder Exited Normally\n" );
        System.exit(1);
    }
}
