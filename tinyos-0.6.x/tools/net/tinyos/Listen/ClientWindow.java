/*
 * "Copyright (c) 2001 and The Regents of the University
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * $\Id$
 */

package net.tinyos.Listen;

import java.awt.*;
import javax.swing.*;
import java.awt.event.*;

public class ClientWindow extends JPanel implements WindowListener
{
  Logger client = null;
  JScrollPane           msgPanel      = new JScrollPane();
  JTextArea             msgWndw       = new JTextArea();
  BorderLayout borderLayout1 = new BorderLayout();
  boolean               bCommandReady = false;
  JPanel jPanel1 = new JPanel();
  BorderLayout borderLayout2 = new BorderLayout();
  JTextField fieldLogFile = new JTextField();
  JLabel labelLogFile = new JLabel();
  JPanel buttonPanel = new JPanel();
  GridLayout gridLayout1 = new GridLayout();
  JLabel labelServer = new JLabel();
  JTextField fieldServer = new JTextField();
  JLabel labelPort = new JLabel();
  JTextField fieldPort = new JTextField();
  JLabel labelPackets = new JLabel();
  JLabel labelPacketSize = new JLabel();
  JTextField fieldPacketSize = new JTextField();
  JButton buttonConnect = new JButton();
  JButton bDisconnect = new JButton();
  JButton bClear = new JButton();

  public ClientWindow( ) {
    try {
      jbInit();
    }
    catch(Exception e) {
      e.printStackTrace();
    }
  }
  private void jbInit() throws Exception {

    this.setLayout(borderLayout1);
    msgPanel.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
    msgPanel.setAutoscrolls(true);
    msgWndw.setFont(new java.awt.Font("Courier", 0, 12));
    this.setMinimumSize(new Dimension(200, 400));
    this.setPreferredSize(new Dimension(400, 300));
    jPanel1.setLayout(borderLayout2);
    labelLogFile.setText("Log File:");
    buttonPanel.setLayout(gridLayout1);
    gridLayout1.setRows(10);
    labelServer.setFont(new java.awt.Font("Dialog", 1, 10));
    labelServer.setText("Server:");
    fieldServer.setFont(new java.awt.Font("Dialog", 0, 10));
    fieldServer.setText( InitLogger.server );
    labelPort.setFont(new java.awt.Font("Dialog", 1, 10));
    labelPort.setText("Port:");
    fieldPort.setFont(new java.awt.Font("Dialog", 0, 10));
    fieldPort.setText(Integer.toString( InitLogger.serverPort) );
    labelPackets.setFont(new java.awt.Font("Dialog", 1, 10));
    labelPackets.setToolTipText("");
    labelPackets.setText("Pckts Rcvd: 0");
    buttonPanel.setMinimumSize(new Dimension(100, 170));
    buttonPanel.setPreferredSize(new Dimension(100, 170));
    labelPacketSize.setFont(new java.awt.Font("Dialog", 1, 10));
    labelPacketSize.setText("Packet Size:");
    fieldPacketSize.setText( Integer.toString( InitLogger.PACKET_SIZE ) );
    buttonConnect.setFont(new java.awt.Font("Dialog", 1, 10));
    buttonConnect.setText("Connect");
    buttonConnect.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(ActionEvent e) {
        buttonConnect_actionPerformed(e);
      }
    });
    bDisconnect.setFont(new java.awt.Font("Dialog", 0, 10));
    bDisconnect.setText("Disconnect");
    bDisconnect.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(ActionEvent e) {
        bDisconnect_actionPerformed(e);
      }
    });
    bClear.setFont(new java.awt.Font("Dialog", 0, 10));
    bClear.setText("Clear");
    bClear.addActionListener(new java.awt.event.ActionListener() {
      public void actionPerformed(ActionEvent e) {
        bClear_actionPerformed(e);
      }
    });
    fieldLogFile.setText( InitLogger.strFileName );
    this.add(msgPanel, BorderLayout.CENTER);
    this.add(jPanel1, BorderLayout.SOUTH);
    jPanel1.add(fieldLogFile, BorderLayout.CENTER);
    jPanel1.add(labelLogFile, BorderLayout.WEST);
    this.add(buttonPanel, BorderLayout.EAST);
    buttonPanel.add(labelServer, null);
    buttonPanel.add(fieldServer, null);
    buttonPanel.add(labelPort, null);
    buttonPanel.add(fieldPort, null);
    buttonPanel.add(labelPacketSize, null);
    buttonPanel.add(fieldPacketSize, null);
    buttonPanel.add(labelPackets, null);
    buttonPanel.add(buttonConnect, null);
    buttonPanel.add(bDisconnect, null);
    buttonPanel.add(bClear, null);
    msgPanel.getViewport().add(msgWndw, null);

  }

  public synchronized void windowClosing ( WindowEvent e )
  {
    if ( client != null )
    {
      client.Shutdown();
      try { client.join(); }
      catch ( InterruptedException ex ) { }
    }
    System.out.println ( "Serial Logger Exited Normally\n" );
    System.exit(1);
  }

  public void windowClosed      ( WindowEvent e ) { }
  public void windowActivated   ( WindowEvent e ) { }
  public void windowIconified   ( WindowEvent e ) { }
  public void windowDeactivated ( WindowEvent e ) { }
  public void windowDeiconified ( WindowEvent e ) { }
  public void windowOpened      ( WindowEvent e ) { }

  public synchronized void AddMessage ( String msg )
  {
    msgWndw.append ( msg );
  }

  public synchronized void bClear_actionPerformed(ActionEvent e)
  {
    msgWndw.setText("");
  }

  public String GetCommand ( )
  {
    if ( bCommandReady )
    {
      String command = fieldLogFile.getText();
      fieldLogFile.setText("");
      bCommandReady = false;
      return command;
    }
    else {
      return null;
    }
  }

  public void UpdatePacketsReceived ( int nPackets )
  {
    labelPackets.setText( "Pckts Rcvd: " + nPackets );
  }

  public synchronized void SetClient ( Logger clnt )
  {
    client = clnt;
  }

  void buttonConnect_actionPerformed(ActionEvent e)
  {
    if ( client == null )
    {
      InitLogger.PACKET_SIZE = Integer.parseInt( fieldPacketSize.getText() );
      InitLogger.server = fieldServer.getText();
      InitLogger.serverPort = Integer.parseInt ( fieldPort.getText() );
      InitLogger.strFileName = fieldLogFile.getText();

      client = new Logger ( this );
      client.start();
    }
  }

  void bDisconnect_actionPerformed(ActionEvent e) {
    if ( client != null )
    {
      client.Shutdown ();
      try { client.join(); }
      catch ( InterruptedException ex ) { }
    }
  }
}
