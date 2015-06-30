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
import javax.swing.*;
import Surge.*;
import Surge.Dialog.*;
import Surge.PacketAnalyzers.*;
import java.awt.event.*;
import javax.swing.event.*;
import java.beans.*;
import java.awt.*;

public class MassSpringsPropertiesPanel extends ActivePanel
{

	public MassSpringsPropertiesPanel()
	{

		tabTitle = "Display Properties";
		modal= true;
		//{{INIT_CONTROLS
		setLayout(null);
		Insets ins = getInsets();
		setSize(286,264);
		add(ApplyButton);
		ApplyButton.setBounds(0,0,0,0);
		add(CancelButton);
		CancelButton.setBounds(0,0,0,0);

		//$$ bevelBorder1.move(0,306);
		JButton1.setToolTipText("Adds noise to X,Y Positions");
		JButton1.setText("Shake");
		add(JButton1);
		JButton1.setBounds(24,12,108,24);
		JButton2.setToolTipText("Centers the relative coordinate system at 0,0");
		JButton2.setText("Recenter");
		add(JButton2);
		JButton2.setBounds(156,12,108,24);
		JCheckBox1.setSelected(true);
		JCheckBox1.setToolTipText("toggle PAINT NODES menu item");
		JCheckBox1.setText("Display Node Coordinates");
		JCheckBox1.setEnabled(false);
		add(JCheckBox1);
		JCheckBox1.setBounds(24,84,204,21);
		JCheckBox2.setSelected(true);
		JCheckBox2.setToolTipText("toggle PAINT EDGES menu item");
		JCheckBox2.setText("Display Edge Lengths");
		JCheckBox2.setEnabled(false);
		add(JCheckBox2);
		JCheckBox2.setBounds(24,108,204,21);
		JLabel1.setToolTipText("Proportion of noise added to coords");
		JLabel1.setText("Shake Factor:");
		add(JLabel1);
		JLabel1.setBounds(24,48,108,21);
		JTextField1.setToolTipText("Proportion of noise to be added");
		JTextField1.setText("0.2");
		add(JTextField1);
		JTextField1.setBounds(156,48,108,21);
		JComboBox1.setToolTipText("Select the Decay Function");
		add(JComboBox1);
		JComboBox1.setBounds(36,156,153,30);
		JComboBox1.setSelectedIndex(0);
		//}}

		//{{REGISTER_LISTENERS
		SymAction lSymAction = new SymAction();
		JButton1.addActionListener(lSymAction);
		JButton2.addActionListener(lSymAction);
		//}}
	}

		//{{DECLARE_CONTROLS
	javax.swing.JButton ApplyButton = new javax.swing.JButton();
	javax.swing.JButton CancelButton = new javax.swing.JButton();
	//com.symantec.itools.javax.swing.borders.BevelBorder bevelBorder1 = new com.symantec.itools.javax.swing.borders.BevelBorder();
	javax.swing.JButton JButton1 = new javax.swing.JButton();
	javax.swing.JButton JButton2 = new javax.swing.JButton();
	javax.swing.JCheckBox JCheckBox1 = new javax.swing.JCheckBox();
	javax.swing.JCheckBox JCheckBox2 = new javax.swing.JCheckBox();
	javax.swing.JLabel JLabel1 = new javax.swing.JLabel();
	javax.swing.JTextField JTextField1 = new javax.swing.JTextField();
	javax.swing.JComboBox JComboBox1 = new javax.swing.JComboBox();
	//}}

              //---------------------------------------------------------------------
              //APPLY CHANGES
	public void ApplyChanges()
	{
	}
              //APPLY CHANGES
              //---------------------------------------------------------------------


              //---------------------------------------------------------------------
              //INITIALIZE DISPLAY VALUES
	public void InitializeDisplayValues()
	{
	}
              //INITIALIZE DISPLAY VALUES
              //---------------------------------------------------------------------


	class SymAction implements java.awt.event.ActionListener
	{
		public void actionPerformed(java.awt.event.ActionEvent event)
		{
			Object object = event.getSource();
			if (object == JButton1)
				JButton1_actionPerformed(event);
			else if (object == JButton2)
				JButton2_actionPerformed(event);
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
			JButton1.setEnabled(false);
		} catch (java.lang.Exception e) {
		}
	}

	void JButton2_actionPerformed(java.awt.event.ActionEvent event)
	{
		// to do: code goes here.

		JButton2_actionPerformed_Interaction1(event);
	}

	void JButton2_actionPerformed_Interaction1(java.awt.event.ActionEvent event)
	{
		try {
			JButton2.setEnabled(false);
		} catch (java.lang.Exception e) {
		}
	}
}