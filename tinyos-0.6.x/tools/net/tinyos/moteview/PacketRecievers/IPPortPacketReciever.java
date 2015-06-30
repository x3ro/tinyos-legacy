/* "Copyright (c) 2001 and The Regents of the University
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
* Authors:   Joe Polastre (polastre@cs.berkeley.edu)
* History:   created as ForwarderListen November 4, 2001
*			 Modified by Joe to work with Surge 3.0a 11/04/2001
*/



package net.tinyos.moteview.PacketRecievers;

import net.tinyos.moteview.*;
import net.tinyos.moteview.event.*;
import net.tinyos.moteview.util.*;
import java.util.*;
import java.io.*;
import java.net.*;
import net.tinyos.moteview.Packet.*;
import java.awt.event.*;
import javax.swing.*;
import java.awt.*;
/**
 *  Implements the necessary Packet Reciever functions to interface Surge
 *  with the SerialForwarder serial port reader
 *
 * @author Joe Polastre <a href="mailto:polastre@cs.berkeley.edu">polastre@cs.berkeley.edu</a>
 */
public class IPPortPacketReciever extends PacketReciever
{
        /** determines whether packets that fail their crc check should be discarded
         */
        protected boolean           discardpackets = false;
        protected ControlWindow     window         = null;

        protected int               m_nPacketsReceived = 0;
        /** MenuManager object to manage interactive menu options
         */
        protected MenuManager menuManager;
        private static int MSG_SIZE = SuperPacket.NUMBER_OF_BYTES;  // 4 header bytes, 30 msg bytes, 2 crc bytes, 2 strength bytes

        String strAddr = MainClass.host;
        int nPort = MainClass.port;
        boolean opened = false;
        Socket socket;
        InputStream in;
        OutputStream out;


	/**
         * The constructor opens the ports and spawns a new thread
         */
	public IPPortPacketReciever()
	{
              //register to contribute a panel to the SurgeOptions panel
		menuManager = new MenuManager();


                window = new ControlWindow ( this  );
                JFrame frame = new JFrame ( "IPPortPacketReceiver" );

                frame.setBounds( 720,0, 170,250);
                frame.setContentPane( window );
                frame.setVisible(true );

                MainClass.AddOptionsPanelContributor(this);

                recievePacketsThread = new Thread(this);
		try{
			recievePacketsThread.setPriority(Thread.NORM_PRIORITY);
			recievePacketsThread.start(); //recall that start() calls the run() method defined in this class
		}
		catch(Exception e){e.printStackTrace();}
	}

        private boolean open()
        {
            MainClass.out("Starting packet reciever IPPortPacketReciever");
            try {
                MainClass.out("Connecting to host " + strAddr + ":" + nPort + "");
                socket = new Socket (strAddr, nPort);
                in = socket.getInputStream();
                out = socket.getOutputStream();
            } catch ( IOException e ) {
                MainClass.out("Unable to connect to host");
                return false;
            }

            return true;
        }

        /**
         * writes a string of bytes to the Serial Forwarder
         * @param packet a byte array representing the packet
         * @return true if the operation completes successfully
         **/
        public boolean write(byte[] packet)
        {
            if (opened)
            {
                try {
                    out.write(packet);
                } catch (Exception e)
                {   e.printStackTrace();
                    return false;
                }
                return true;
            }
            else
                return false;
        }

        private boolean killconnection()
        {
            try {
                if (opened)
                {
                    MainClass.out("Closing socket to SerialForwarder");
                    socket.close();
                }
                socket = null;
                in = null;
                out = null;
            }
            catch (IOException e)
            {
                MainClass.out("Unable to close socket");
                return false;
            }
            return true;
        }

        /**
         * Sets up connections and initializes thread.
         */
        public void start()
        {
            recievePacketsThread = new Thread(this);
            recievePacketsThread.start();
        }

        public boolean Opened ( ) { return opened; }

        public void SetHost ( String host ) { strAddr = host; }

        /**
         * Stops connects, kills the thread, and resets values to defaults
         */
        public void stop()
        {
            recievePacketsThread = null;
            opened = !(killconnection());
            MainClass.out("IPPortPacketReciever halted");
        }

	public void run() //throws IOException
	{
          while (recievePacketsThread == Thread.currentThread())
          {

              boolean recentlyclosed = false;

              // see if the port is still open.  If the port was closed on us, no bytes
              // will be available.  If the port was never open or if we closed it, then
              // an exception will be thrown.  By running this try catch we're making sure
              // the socket is closed and thread is halted when the remote side closes connection.
              try{
                if (in.available() == 0)
                      recentlyclosed = true;
                      MainClass.out("Lost connection to SerialForwarder " + strAddr + ":" + nPort);
              }
              catch (Exception e) {
                  // do nothing, the socket was never initialized.
              }

              if ((!opened) && (!recentlyclosed))
                  opened = open();


              // check if the port was openable.  If not, kill the thread.
              if ((!opened) || (recentlyclosed))
              {
                  opened = false;
                  recentlyclosed = false;
                  menuManager.receivePacketsCheckBox.setSelected(false);
              }
              else
              {
                  MainClass.out("listen started " + opened);
              }

              int i;
              int count = 0;
              byte[] packet = new byte[MSG_SIZE];
              try {
                  while (opened && ((i = in.read()) != -1)) {
                    if(i == 0x7e || count != 0){
                       packet[count] = (byte)i;
                       count++;
                        if (count == MSG_SIZE) {
                            //for each new packet recieved, trigger a new packetEvent
                            byte t1 = packet[0];
                            byte t2 = packet[1];
                            //packet[0] = (byte)0xFF;
                            //packet[1] = (byte)0xFF;
                            int crc = SuperPacket.calcrc(packet, SuperPacket.NUMBER_OF_BYTES - 2);
                            //System.out.println ( "crc hi bits: " + ((crc >> 8) & 0xFF) );
                            //System.out.println ( "packet crc hi bits: " + packet[MSG_SIZE - 1] );
                            //System.out.println ( "crc lo bits: " + (crc & 0xFF) );
                            //System.out.println ( "packet crc lo bits: " + packet[MSG_SIZE - 2] );
			    //System.out.println ( "packet: " + Hex.toHex( packet ) );
                            if ((((byte)(crc & 0xFF) == packet[MSG_SIZE - 2]) &&
                                ((byte)((crc >> 8) & 0xFF) == packet[MSG_SIZE - 1]) && discardpackets)
                                || (!discardpackets))
                            {
                                packet[0] = t1;
                                packet[1] = t2;
                                TriggerPacketEvent(
                                  new PacketEvent(this, new Packet(packet), Calendar.getInstance().getTime()));
                                MainClass.outv(Hex.toHex(packet));
                                m_nPacketsReceived++;
                                if ( window != null ) { window.SetPacketsReceived ( m_nPacketsReceived ); }
                            }
                            else
                            {
                                MainClass.out("bad packet");
                            }
                            packet = new byte[MSG_SIZE];
                            count = 0;
                        }
                    }else{
                        MainClass.outv("extra byte " + Hex.toHex(i));
                    }
                  }
              }
              catch (IOException e)
              {
                  // if the socket died on us, close it.
                  if (e instanceof java.net.SocketException)
                  {
                      MainClass.out("Lost connection to SerialForwarder " + strAddr + ":" + nPort);
                      menuManager.receivePacketsCheckBox.setSelected(false);
                      opened = false;
                  }
                  // otherwise just print out the exception
                  else
                  {
                    e.printStackTrace();
                  }
              }
          }
        }

        protected class ControlWindow extends JPanel
        {
            protected IPPortPacketReciever receiver = null;

            protected SymAction   lSymAction     = new SymAction ( );

            protected boolean     m_bConnected   =  false;

            protected JPanel      m_pnlStatus    = new JPanel ( );
            protected JPanel      m_pnlActions   = new JPanel ( );

            protected JLabel      m_lblForwarder = new JLabel ("SerialForwarder Host:");
            protected JLabel      m_lblPckts     = new JLabel ("Packets Received: 0" );

            protected JTextField  m_fldHost      = new JTextField ( MainClass.host );

            protected JButton     m_bttnConnect  = new JButton ( "Disconnect" );

            public ControlWindow ( IPPortPacketReciever recv  )
            {
                receiver = recv;

                setLayout(null);
                this.setVisible(    true);

                m_pnlStatus.setLayout( null );
                m_pnlActions.setLayout( null );

                add ( m_pnlStatus );
                add ( m_pnlActions );

                AddStatusControls ( );
                AddActionControls ( );
            }

            protected void AddStatusControls ( )
            {
                m_pnlStatus.setBorder(BorderFactory.createTitledBorder("Status"));
                m_pnlStatus.setBounds( 0, 0, 160, 125 );

                m_lblForwarder.setBounds ( 10, 15, 140, 20);
                m_pnlStatus.add( m_lblForwarder );

                m_fldHost.setBounds( 10, 35, 120, 20);
                m_pnlStatus.add( m_fldHost );

                m_lblPckts.setBounds( 10, 55, 140, 20);
                m_pnlStatus.add ( m_lblPckts );
            }

            protected void AddActionControls ( )
            {
                m_pnlActions.setBorder(BorderFactory.createTitledBorder("Actions"));
                m_pnlActions.setBounds( 0, 125, 160, 110 );

                m_bttnConnect.setBounds ( 10, 15, 100, 18 );
                m_bttnConnect.addActionListener( lSymAction );
                m_pnlActions.add( m_bttnConnect );
            }

            public void SetHost ( String host )
            {
                m_fldHost.setText( host );
            }

            public void SetPacketsReceived ( int num )
            {
                m_lblPckts.setText( "Packets Received: " + num );
            }

            public void Connect ( ActionEvent event )
            {
                m_bConnected = !m_bConnected;
                UpdateConnectText ( );
                if ( m_bConnected != receiver.Opened() )
                {
                    if ( m_bConnected )
                    {
                        receiver.SetHost ( m_fldHost.getText() );
                        receiver.start();
                    }
                    else
                    {
                        receiver.stop();
                    }
                }
            }

            protected void UpdateConnectText ( )
            {
                if ( m_bConnected ) { m_bttnConnect.setText("Disconnect"); }
                else { m_bttnConnect.setText( "Connect" ); }
            }

            class SymAction implements java.awt.event.ActionListener
            {
                public void actionPerformed(java.awt.event.ActionEvent event)
                {
                    Object object = event.getSource();
                    if ( object == m_bttnConnect ) { Connect ( event ); }
                }
            }

        }

	protected class MenuManager implements /*Serializable,*/ ActionListener, ItemListener
	{
                //{{DECLARE_CONTROLS
		JMenu mainMenu = new JMenu();
		JCheckBoxMenuItem receivePacketsCheckBox = new JCheckBoxMenuItem();
		JCheckBoxMenuItem discardPacketsCheckBox = new JCheckBoxMenuItem();
		JSeparator separator1 = new JSeparator();
		JMenuItem propertiesItem = new JMenuItem();
		//}}

		public MenuManager()
		{
			//{{INIT_CONTROLS
			mainMenu.setText("IP Port Packets");
			mainMenu.setActionCommand("IP Port Packets");
			receivePacketsCheckBox.setSelected(true);
			receivePacketsCheckBox.setText("Receive Packets");
			receivePacketsCheckBox.setActionCommand("Receive Packets");
			discardPacketsCheckBox.setSelected(true);
			discardPacketsCheckBox.setText("Discard Bad Packets");
			discardPacketsCheckBox.setActionCommand("Discard Bad Packets");

			mainMenu.add(receivePacketsCheckBox);
                        mainMenu.add(discardPacketsCheckBox);
			//mainMenu.add(separator1);
			//propertiesItem.setText("Options");
			//propertiesItem.setActionCommand("Options");
			//mainMenu.add(propertiesItem);
			MainClass.mainFrame.PacketReadersMenu.add(mainMenu);//this last command adds this entire menu to the main PacketAnalyzers menu
			//}}

			//{{REGISTER_LISTENERS
			receivePacketsCheckBox.addItemListener(this);
			//propertiesItem.addActionListener(this);
			//}}
		}

		      //----------------------------------------------------------------------
		      //EVENT HANDLERS
		      //The following two functions handle menu events
		      //The functions following this are the event handling functions
		public void actionPerformed(ActionEvent e)
		{
			Object object = e.getSource();
//			if (object == propertiesItem)
//				ShowOptionsDialog();
		}

		public void itemStateChanged(ItemEvent e)
		{
			Object object = e.getSource();
			if (object == receivePacketsCheckBox)
				ToggleReceivePackets();
                        if (object == discardPacketsCheckBox)
                                ToggleDiscardPackets();
		}

                /**
                 * This function will either start or stop the background thread
                 */
		public void ToggleReceivePackets()
		{
			if(receivePacketsCheckBox.isSelected())
			{
				start();
			}
			else
			{
				stop();
			}
		}
		public void ToggleDiscardPackets()
                {
                        if (discardPacketsCheckBox.isSelected())
                            discardpackets = true;
                        else
                            discardpackets = false;
                }

	}

}
