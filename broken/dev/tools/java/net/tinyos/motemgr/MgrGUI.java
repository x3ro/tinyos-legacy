/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
package net.tinyos.motemgr;

import net.tinyos.util.*;
import net.tinyos.message.*;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;

public class MgrGUI extends JPanel implements WindowListener, DBReceiver, MessageListener
{
    JScrollPane visitorPane;
    JTextArea visitorText;
    JPanel panel = new JPanel();
    JPanel panel2 = new JPanel();
    JTextArea logArea = new JTextArea();
    JButton motesButton = new JButton();
    JButton broadcastButton = new JButton();
    JList   moteList ;
    JScrollPane moteScrollPane;
    JButton eventLog ;
    Vector v = new Vector(); 

    int textEnd;
//    net.tinyos.message.MoteIF mote;
    MoteIF moteIf;
    UserDB db;
    static byte gid;
    IdentityReceiver dispatch;
    static byte sequenceNum;


	// constructor 
    MgrGUI(byte group_id, UserDB d ) {
	db = d;
	try {
        dispatch = (IdentityReceiver)d;
	} catch (Exception e) {
	    // do nothing
	}
	gid = group_id;
	sequenceNum=0;
	db.setDBListener(this);
	try {
            //mote = new net.tinyos.message.MoteIF("127.0.0.1", 9000, gid);
            moteIf = new MoteIF("127.0.0.1", 9000,gid);
            moteIf.registerListener(new MoteIdRspMsg(), this);
	    moteIf.start();
        } catch(Exception e){
            System.err.println("couldn't contact serial forwarder");
	   System.exit(0);
               
	}
	// send a mote discovery msg out
	sendMoteIdMsg();
    }

    public void messageReceived(int to, Message m) {
System.out.println("receive a msg\n");
	if (m instanceof MoteIdRspMsg) {
	   MoteIdRspMsg idmsg = (MoteIdRspMsg)m;
	   System.out.println(idmsg.toString()); 
           short id = idmsg.getSource();
           dispatch.identityReceived(id);
	} //else if (m instanceof MoteAgentRspMsg
        
    } 
    void sendMoteIdMsg() {
	    MoteIdMsg  msg = new MoteIdMsg();
        // set addr to 0xffff
        msg.setSeqno(sequenceNum++); 
System.out.println("sequenceNum=" + sequenceNum);
        msg.setHopCnt((byte) 0);
        System.out.println(msg.toString());
	try {
	    System.out.println("Sending mote discovery msg\n");
		moteIf.send(MoteIF.TOS_BCAST_ADDR, msg);
	} catch (Exception ioe) {
	    System.err.println("Got IDException when sending msg"+ioe);
		ioe.printStackTrace();
	}
    }   
    public void open()
    {
      try {
	  jbInit();
      }
      catch(Exception e) {
	  e.printStackTrace();
      }
      JFrame mainFrame = new JFrame("Mote Manager");
      mainFrame.setSize(getPreferredSize());
      mainFrame.getContentPane().add("Center", this);
      mainFrame.show();
      mainFrame.addWindowListener(this);

    }
    public void dbAdd(short id)
    {
        Integer idO = new Integer(id);
        v.addElement(idO.toString());
        
        panel.repaint();
    }
    public void dbRemove(short id)
    {
    Integer idO = new Integer(id);
    v.removeElement(idO.toString());
    panel.repaint();
    }

    public void dbChange(Vector db)
    {
        // do nothing
        //panel.repaint();
    }

    private void jbInit() throws Exception 
    {
	setMinimumSize(new Dimension(520, 460));
	setPreferredSize(new Dimension(520, 460));

	logArea.setFont(new java.awt.Font("Dialog", 1, 10));

	motesButton.addActionListener(new java.awt.event.ActionListener()
	    {
		public void actionPerformed(ActionEvent e)
		{
                    // send moteId msg to all motes
			sendMoteIdMsg();
		}
	    });
	motesButton.setText("Mote Discovery");
        motesButton.setFont(new java.awt.Font("Dialog", 1, 10));

	broadcastButton.addActionListener(new java.awt.event.ActionListener()
	    {
		public void actionPerformed(ActionEvent e)
		{
		    // do nothing for now ;
                    // the goal is to open MessageInjector and allow 
                    // user to edit and send a Bcast msg to all motes
		}
	    });
	broadcastButton.setText("Broadcasting");
        broadcastButton.setFont(new java.awt.Font("Dialog", 1, 10));
        //dbAdd((short)1);
        //dbAdd((short)9);
        moteList = new JList(v);
        
        //moteList = new JList(db.db);
        moteList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        moteScrollPane = new JScrollPane(moteList);

	panel.setLayout(new BorderLayout());
	panel.setMinimumSize(new Dimension(150, 100));
	panel.setPreferredSize(new Dimension(150, 400));
	panel.add(motesButton, BorderLayout.NORTH);
	panel.add(broadcastButton, BorderLayout.SOUTH);
        panel.add(moteScrollPane);
	visitorText = new JTextArea();
	visitorPane = new JScrollPane(visitorText);
        eventLog = new JButton();
        eventLog.setText("Event Logs");

        eventLog.addActionListener(new java.awt.event.ActionListener() 
        {
            public void actionPerformed(ActionEvent e )
            { // do nothing
            }
        });

	panel2.setLayout(new BorderLayout());
        panel2.add(eventLog, BorderLayout.NORTH);
	panel2.add(visitorPane, null);
	panel2.setPreferredSize(new Dimension(340, 400));

	add(panel, BorderLayout.WEST);
	add(panel2, BorderLayout.EAST);
    }



    public void windowClosing(WindowEvent e) {
	System.exit(0); 
    }
    public void windowClosed(WindowEvent e) { }
    public void windowActivated(WindowEvent e) { }
    public void windowIconified(WindowEvent e) { }
    public void windowDeactivated(WindowEvent e) { }
    public void windowDeiconified(WindowEvent e) { }
    public void windowOpened(WindowEvent e) { }



}
