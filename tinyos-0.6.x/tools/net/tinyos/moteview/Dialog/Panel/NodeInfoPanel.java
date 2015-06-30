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

public class NodeInfoPanel extends Surge.Dialog.ActivePanel
{
	Node node;

	public NodeInfoPanel(Node pNode)
	{
		tabTitle = "General";
		node = pNode;
		//{{INIT_CONTROLS
		setLayout(null);
		Insets ins = getInsets();
		setSize(247,168);
		JLabel1.setText("Node Number:");
		add(JLabel1);
		JLabel1.setFont(new Font("Dialog", Font.BOLD, 16));
		JLabel1.setBounds(36,12,120,39);
		JLabel2.setToolTipText("The number used to identify this node");
		JLabel2.setText("jlabel");
		add(JLabel2);
		JLabel2.setForeground(java.awt.Color.blue);
		JLabel2.setFont(new Font("Dialog", Font.BOLD, 16));
		JLabel2.setBounds(168,12,48,33);
		JLabel3.setText("X Coordinate");
		add(JLabel3);
		JLabel3.setBounds(36,48,84,24);
		JLabel4.setText("Y Coordinate");
		add(JLabel4);
		JLabel4.setBounds(36,72,75,24);
		JTextField1.setNextFocusableComponent(JTextField2);
		JTextField1.setToolTipText("The scale of the coordinate system is determined by the user, and scaled automatically by the system to fit to the screen");
		JTextField1.setText("1.5");
		add(JTextField1);
		JTextField1.setBounds(120,48,87,18);
		JTextField2.setNextFocusableComponent(JCheckBox1);
		JTextField2.setToolTipText("The scale of the coordinate system is determined by the user, and scaled automatically by the system to fit to the screen");
		JTextField2.setText("3.2");
		add(JTextField2);
		JTextField2.setBounds(120,72,87,18);
		JCheckBox1.setNextFocusableComponent(JCheckBox2);
		JCheckBox1.setSelected(true);
		JCheckBox1.setToolTipText("\"Fixed\" means that the user determines the location of the node.  Unfixed allows the system to do it automatically.");
		JCheckBox1.setText("Fixed X,Y Coordinates");
		JCheckBox1.setActionCommand("Fixed X,Y Coordinates");
		add(JCheckBox1);
		JCheckBox1.setForeground(new java.awt.Color(102,102,153));
		JCheckBox1.setBounds(36,96,171,18);
		JCheckBox2.setNextFocusableComponent(JCheckBox3);
		JCheckBox2.setSelected(true);
		JCheckBox2.setToolTipText("If unchecked, the system will not draw this node to the screen.");
		JCheckBox2.setText("Display This Node");
		JCheckBox2.setActionCommand("Display This Node");
		add(JCheckBox2);
		JCheckBox2.setForeground(new java.awt.Color(102,102,153));
		JCheckBox2.setBounds(36,120,171,18);
		JCheckBox3.setNextFocusableComponent(JTextField1);
		JCheckBox3.setSelected(true);
		JCheckBox3.setToolTipText("Uncheck this if the node jumps all over the place and confuses the display");
		JCheckBox3.setText("Fit On Screen");
		add(JCheckBox3);
		JCheckBox3.setForeground(new java.awt.Color(102,102,153));
		JCheckBox3.setBounds(36,144,177,15);
		//}}

		//{{REGISTER_LISTENERS
		//}}
	}

	//{{DECLARE_CONTROLS
	javax.swing.JLabel JLabel1 = new javax.swing.JLabel();
	javax.swing.JLabel JLabel2 = new javax.swing.JLabel();
	javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
	javax.swing.JLabel JLabel4 = new javax.swing.JLabel();
	javax.swing.JTextField JTextField1 = new javax.swing.JTextField();
	javax.swing.JTextField JTextField2 = new javax.swing.JTextField();
	javax.swing.JCheckBox JCheckBox1 = new javax.swing.JCheckBox();
	javax.swing.JCheckBox JCheckBox2 = new javax.swing.JCheckBox();
	javax.swing.JCheckBox JCheckBox3 = new javax.swing.JCheckBox();
	//}}

	public void ApplyChanges()
	{
/*		node.SetX(Double.valueOf(JTextArea1.getText()).doubleValue());
		node.SetY(Double.valueOf(JTextArea2.getText()).doubleValue());
		node.SetFixed(JCheckBox1.isSelected());
		node.SetDisplayThisNode(JCheckBox2.isSelected());*/
	}

}