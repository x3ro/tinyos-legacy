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
import javax.swing.JButton;
import javax.swing.JPanel;

public class NodeDisplayInfoPanel extends Surge.Dialog.ActivePanel
{
	Node node;

	public NodeDisplayInfoPanel (Node pNode)
	{
		tabTitle = "General";
		node = pNode;
		//{{INIT_CONTROLS
		setLayout(null);
		Insets ins = getInsets();
		setSize(259,279);
		JLabel3.setToolTipText("The width with which this image will be drawn");
		JLabel3.setText("Image Width");
		add(JLabel3);
		JLabel3.setBounds(36,48,84,24);
		JLabel4.setToolTipText("The height with which this image will be drawn");
		JLabel4.setText("Image Height");
		add(JLabel4);
		JLabel4.setBounds(36,72,75,24);
		JTextField1.setNextFocusableComponent(JTextField2);
		JTextField1.setToolTipText("Remember that this number is in Node coordinates, not screen coordinates");
		JTextField1.setText("1.5");
		add(JTextField1);
		JTextField1.setBounds(120,48,87,18);
		JTextField2.setNextFocusableComponent(JCheckBox1);
		JTextField2.setToolTipText("Remember that this number is in Node coordinates, not screen coordinates");
		JTextField2.setText("3.2");
		add(JTextField2);
		JTextField2.setBounds(120,72,87,18);
		JLabel1.setText("Image");
		add(JLabel1);
		JLabel1.setBounds(36,24,84,24);
		JTextField3.setNextFocusableComponent(JTextField1);
		JTextField3.setText("image/mote2.jpg");
		add(JTextField3);
		JTextField3.setBounds(84,24,162,18);
		JCheckBox1.setNextFocusableComponent(JCheckBox2);
		JCheckBox1.setSelected(true);
		JCheckBox1.setToolTipText("Check this if you want this node to appear on the screen");
		JCheckBox1.setText("Display This Node");
		add(JCheckBox1);
		JCheckBox1.setBounds(36,96,123,21);
		JCheckBox2.setNextFocusableComponent(JTextField3);
		JCheckBox2.setSelected(true);
		JCheckBox2.setToolTipText("This should be checked if you want this node to be fit onto the screen");
		JCheckBox2.setText("Fit To Screen");
		add(JCheckBox2);
		JCheckBox2.setBounds(36,120,123,21);
		JButton1.setToolTipText("Click this button to see the image that is typed above");
		JButton1.setText("Preview");
		add(JButton1);
		JButton1.setBounds(168,108,84,27);
		JPanel1.setLayout(null);
		add(JPanel1);
		JPanel1.setBounds(36,144,153,126);
		//}}

		//{{REGISTER_LISTENERS
		SymAction lSymAction = new SymAction();
		JButton1.addActionListener(lSymAction);
		//}}
	}

	//{{DECLARE_CONTROLS
	javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
	javax.swing.JLabel JLabel4 = new javax.swing.JLabel();
	javax.swing.JTextField JTextField1 = new javax.swing.JTextField();
	javax.swing.JTextField JTextField2 = new javax.swing.JTextField();
	javax.swing.JLabel JLabel1 = new javax.swing.JLabel();
	javax.swing.JTextField JTextField3 = new javax.swing.JTextField();
	javax.swing.JCheckBox JCheckBox1 = new javax.swing.JCheckBox();
	javax.swing.JCheckBox JCheckBox2 = new javax.swing.JCheckBox();
	javax.swing.JButton JButton1 = new javax.swing.JButton();
	javax.swing.JPanel JPanel1 = new javax.swing.JPanel();
	//}}

	public void ApplyChanges()
	{
/*		node.SetX(Double.valueOf(JTextArea1.getText()).doubleValue());
		node.SetY(Double.valueOf(JTextArea2.getText()).doubleValue());
		node.SetFixed(JCheckBox1.isSelected());
		node.SetDisplayThisNode(JCheckBox2.isSelected());*/
	}


	class SymAction implements java.awt.event.ActionListener
	{
		public void actionPerformed(java.awt.event.ActionEvent event)
		{
			Object object = event.getSource();
			if (object == JButton1)
				JButton1_actionPerformed(event);
		}
	}

	void JButton1_actionPerformed(java.awt.event.ActionEvent event)
	{
		// to do: code goes here.

		JButton1_actionPerformed_Interaction1(event);
	}

	void JButton1_actionPerformed_Interaction1(java.awt.event.ActionEvent event)
	{
		try {
			JPanel1.add(new JButton());
		} catch (java.lang.Exception e) {
		}
	}
}