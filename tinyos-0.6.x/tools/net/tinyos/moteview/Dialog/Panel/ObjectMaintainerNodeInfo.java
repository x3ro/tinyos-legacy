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
* Authors:   Kamin Whitehouse <kamin@cs.berkeley.edu>
* History:   created 7/22/2001
*/

package net.tinyos.moteview.Dialog.Panel;

              //this file is used for visually creating the panel using VCafe,
              //it is then inserted into another class as an inner class and edited

import Surge.*;
import Surge.Dialog.*;
import java.beans.*;
import java.awt.*;
import javax.swing.JLabel;
import javax.swing.JTextField;
import javax.swing.JCheckBox;

public class ObjectMaintainerNodeInfo extends Surge.Dialog.ActivePanel
{

	public ObjectMaintainerNodeInfo()
	{
		tabTitle = "Node Maintenance";
		//{{INIT_CONTROLS
		setLayout(null);
//		Insets ins = getInsets();
		setSize(307,168);
		JLabel3.setToolTipText("The time in milliseconds that this node was first seen");
		JLabel3.setText("Time Created:");
		add(JLabel3);
		JLabel3.setBounds(12,36,108,24);
		JLabel4.setToolTipText("The time in milliseconds that this node was last seen");
		JLabel4.setText("Time Last Seen");
		add(JLabel4);
		JLabel4.setBounds(12,60,108,24);
		JTextField1.setNextFocusableComponent(JTextField2);
		JTextField1.setToolTipText("The scale of the coordinate system is determined by the user, and scaled automatically by the system to fit to the screen");
		JTextField1.setText("1.5");
		add(JTextField1);
		JTextField1.setBounds(108,36,180,18);
		JTextField2.setNextFocusableComponent(JTextField3);
		JTextField2.setToolTipText("The scale of the coordinate system is determined by the user, and scaled automatically by the system to fit to the screen");
		JTextField2.setText("3.2");
		add(JTextField2);
		JTextField2.setBounds(108,60,180,18);
		JLabel1.setToolTipText("The second to last time seen");
		JLabel1.setText("Time Before");
		add(JLabel1);
		JLabel1.setBounds(12,84,90,18);
		JTextField3.setNextFocusableComponent(JTextField1);
		JTextField3.setToolTipText("The second to last time seen");
		JTextField3.setText("4.5");
		add(JTextField3);
		JTextField3.setBounds(108,84,180,18);
		JLabel2.setText("Node Number:");
		add(JLabel2);
		JLabel2.setFont(new Font("Dialog", Font.BOLD, 16));
		JLabel2.setBounds(48,0,120,39);
		JLabel5.setToolTipText("The number used to identify this node");
		JLabel5.setText("jlabel");
		add(JLabel5);
		JLabel5.setForeground(java.awt.Color.blue);
		JLabel5.setFont(new Font("Dialog", Font.BOLD, 16));
		JLabel5.setBounds(180,0,48,33);
		//}}

		//{{REGISTER_LISTENERS
		//}}
	}

	//{{DECLARE_CONTROLS
	javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
	javax.swing.JLabel JLabel4 = new javax.swing.JLabel();
	javax.swing.JTextField JTextField1 = new javax.swing.JTextField();
	javax.swing.JTextField JTextField2 = new javax.swing.JTextField();
	javax.swing.JLabel JLabel1 = new javax.swing.JLabel();
	javax.swing.JTextField JTextField3 = new javax.swing.JTextField();
	javax.swing.JLabel JLabel2 = new javax.swing.JLabel();
	javax.swing.JLabel JLabel5 = new javax.swing.JLabel();
	//}}

	public void ApplyChanges()
	{
	}

}