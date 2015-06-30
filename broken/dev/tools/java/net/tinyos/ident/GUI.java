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
package net.tinyos.ident;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;

class GUI extends JPanel implements WindowListener, DBReceiver
{
    JScrollPane visitorPane;
    JTextArea visitorText;
    JPanel panel = new JPanel();
    JPanel panel2 = new JPanel();
    JTextField idField = new JTextField();
    JButton setidButton = new JButton();
    JButton clearidButton = new JButton();
    JButton quitButton = new JButton();
    int textEnd;

    UserDB db;
    MoteIF moteIF;

    GUI(MoteIF m, UserDB d)
    {
	db = d;
	moteIF = m;
	db.setDBListener(this);
    }

    public void open()
    {
      try {
	  jbInit();
      }
      catch(Exception e) {
	  e.printStackTrace();
      }
      JFrame mainFrame = new JFrame("Ident");
      mainFrame.setSize(getPreferredSize());
      mainFrame.getContentPane().add("Center", this);
      mainFrame.show();
      mainFrame.addWindowListener(this);
    }

    public void dbChange(Vector db)
    {
	/* Build display string */
	String display = "";
	Enumeration elems = db.elements();

	while (elems.hasMoreElements()) {
	    DBId elem = (DBId)elems.nextElement();

	    display = display + elem.id + ":" + new Date(elem.arrivalTime) + "\n";
	}
	replaceText(display);
    }

    private void jbInit() throws Exception 
    {
	setMinimumSize(new Dimension(520, 160));
	setPreferredSize(new Dimension(520, 160));

	idField.setFont(new java.awt.Font("Dialog", 1, 10));

	setidButton.addActionListener(new java.awt.event.ActionListener()
	    {
		public void actionPerformed(ActionEvent e)
		{
		    String id = validateId(idField.getText());
		    if (id != null)
			moteIF.sendSet(id);
		}
	    });
	setidButton.setText("Set ID");
        setidButton.setFont(new java.awt.Font("Dialog", 1, 10));

	clearidButton.addActionListener(new java.awt.event.ActionListener()
	    {
		public void actionPerformed(ActionEvent e)
		{
		    moteIF.sendClear();
		}
	    });
	clearidButton.setText("Clear IDs");
        clearidButton.setFont(new java.awt.Font("Dialog", 1, 10));

	quitButton.addActionListener(new java.awt.event.ActionListener()
	    {
		public void actionPerformed(ActionEvent e)
		{
		    System.exit(0);
		}
	    });
	quitButton.setText("Exit");
        quitButton.setFont(new java.awt.Font("Dialog", 1, 10));

	panel.setLayout(new GridLayout(4, 1));
	panel.setMinimumSize(new Dimension(150, 100));
	panel.setPreferredSize(new Dimension(150, 100));
	panel.add(idField, null);
	panel.add(setidButton, null);
	panel.add(clearidButton, null);
	panel.add(quitButton, null);

	visitorText = new JTextArea();
	visitorPane = new JScrollPane(visitorText);

	panel2.setLayout(new BorderLayout());
	panel2.add(visitorPane, null);
	panel2.setPreferredSize(new Dimension(340, 100));

	add(panel2, BorderLayout.WEST);
	add(panel, BorderLayout.EAST);
    }

    String validateId(String id)
    {
	if (id.length() > Ident.MAX_ID_LENGTH)
	    return null;
	else
	    return id;
    }

    synchronized void replaceText(String newText)
    {
	visitorText.replaceRange(newText, 0, textEnd);
	textEnd = newText.length();
    }

    public void windowClosing(WindowEvent e) { }
    public void windowClosed(WindowEvent e) { }
    public void windowActivated(WindowEvent e) { }
    public void windowIconified(WindowEvent e) { }
    public void windowDeactivated(WindowEvent e) { }
    public void windowDeiconified(WindowEvent e) { }
    public void windowOpened(WindowEvent e) { }
}
