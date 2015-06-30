/*
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
package net.tinyos.task.taskviz;

/*
 * 1.1+Swing version.
 */

import javax.swing.*;
import javax.swing.event.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;
import java.text.NumberFormat;

public class ConversionPanel extends JPanel {
    TextField textField;
    JSlider slider;
    DefaultBoundedRangeModel sliderModel;
    String title;
    final static boolean DEBUG = false;
    final static boolean COLORS = false;
    final static int MAX = 10000;

    ConversionPanel(String myTitle, DefaultBoundedRangeModel myModel, int startValue) {
        if (COLORS) {
            setBackground(Color.cyan);
        }
        setBorder(BorderFactory.createCompoundBorder(
                        BorderFactory.createTitledBorder(myTitle),
                        BorderFactory.createEmptyBorder(5,5,5,5)));

        //Save arguments in instance variables.
        title = myTitle;
        sliderModel = myModel;

        //Add the text field.  It initially displays "0" and needs
        //to be at least 10 columns wide.
        NumberFormat numberFormat = NumberFormat.getNumberInstance();
        numberFormat.setMaximumFractionDigits(0);
        textField = new TextField(" " +startValue, 10); 
//        textField.setEditable(false);
        textField.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                sliderModel.setValue(Integer.parseInt(textField.getText().trim()));
            }
        });

        //Add the slider.
        slider = new JSlider(sliderModel);
        sliderModel.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(ChangeEvent e) {
                textField.setText(Integer.toString(sliderModel.getValue()));
            }
        });

        //Make the textfield/slider group a fixed size.
        JPanel unitGroup = new JPanel() {
            public Dimension getMinimumSize() {
                return getPreferredSize();
            }
            public Dimension getPreferredSize() {
                return new Dimension(150,
                                     super.getPreferredSize().height);
            }
            public Dimension getMaximumSize() {
                return getPreferredSize();
            }
        };
        if (COLORS) {
            unitGroup.setBackground(Color.blue);
        }
        unitGroup.setBorder(BorderFactory.createEmptyBorder(
                                                0,0,0,5));
        unitGroup.setLayout(new BoxLayout(unitGroup, 
                                          BoxLayout.Y_AXIS));
        unitGroup.add(textField);
        unitGroup.add(slider);

        setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
        add(unitGroup);
        unitGroup.setAlignmentY(TOP_ALIGNMENT);
    }

    /** 
     * Returns the multiplier (units/meter) for the currently
     * selected unit of measurement.
     */

    public int getValue() {
        return sliderModel.getValue();
    }

    public int getTextValue() {
        return Integer.parseInt(textField.getText().trim());
    }
}
