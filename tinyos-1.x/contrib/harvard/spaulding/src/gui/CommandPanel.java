/*
 * Copyright (c) 2007
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

import java.util.*;
import java.text.*;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;


/**
 * @author Konrad Lorincz
 * @version 1.0
 */
public class CommandPanel extends JPanel implements SessionListener
{
    // =========================== Data Members ================================
    private SpauldingApp spauldingApp;
    private Session currSession = null;

    // gui components
    private JLabel currStateLabel = new JLabel("State: ");
    private JTextField currStateTextField = new JTextField(15);

    private JLabel currStateProgressJLabel = new JLabel("State Progress: ");
    private JProgressBar progressBar = new JProgressBar(0, 100);

    //private SliderElements durationSliderElement;

    private JLabel sessionDateLabel = new JLabel("Session Date: ");
    private JTextField sessionDateField = new JTextField(10);
    private JLabel sessionNameLabel = new JLabel("Session Name: ");
    private JTextField sessionNameField = new JTextField("SessionName", 10);
    private JLabel subjectIDLabel = new JLabel("Subject ID: ");
    private JTextField subjectIDField = new JTextField("0", 10);

    private JButton startButton = new JButton("Start (new session)");
    private JButton stopButton = new JButton("Stop");
    //private JButton downloadButton = new JButton("Download (last session)");

    private JLabel markerLabel = new JLabel("Marker Name: ");
    private JTextField markerTextField = new JTextField(10);
    private JButton insertMarkerButton = new JButton("Insert Marker");

    // =========================== Methods ================================
    public CommandPanel(SpauldingApp spauldingApp)
    {
        assert (spauldingApp != null);
        this.spauldingApp = spauldingApp;

        createGUIAndDoLayout();
        registerEvents();
    }

    public void stateChanged(Session.State state)
    {
        currStateTextField.setText(state.toString());

        switch (state) {
            case READY_TO_SAMPLE:
                this.startButton.setEnabled(true);
                this.stopButton.setEnabled(false);
                break;

            case SAMPLING:
                this.startButton.setEnabled(false);
                this.stopButton.setEnabled(true);
                break;

            case PREPARING_TO_DOWNLOAD:
                this.startButton.setEnabled(true);
                this.stopButton.setEnabled(false);
                break;

            case DONE:
                this.startButton.setEnabled(true);
                this.stopButton.setEnabled(false);
                break;

            default:
                this.startButton.setEnabled(false);
                this.stopButton.setEnabled(false);
                break;
        }

    }

    public void stateElapsedTimeChanged(long timeMS)
    {
        progressBar.setIndeterminate(true);
        progressBar.setString((timeMS/1000) + " sec");
    }

    public void statePercentCompletedChanged(double percent)
    {
        progressBar.setIndeterminate(false);
        progressBar.setString(null);
        progressBar.setValue((int)Math.round(percent));
   }

    private CommandPanel getThis() {return this;}

    private void registerEvents()
    {
        startButton.addMouseListener(new MouseAdapter() {
            public void mouseReleased(MouseEvent e) {
                System.out.println("START button pressed, isEnabled= " + startButton.isEnabled());
                if (startButton.isEnabled()) {
                    SortedSet<Node> nodes = new TreeSet<Node>(spauldingApp.getNodesSorted());
                    Date date = new Date();
                    sessionDateField.setText(spauldingApp.dateToString(date, false));
                    int subjectID = new Integer(subjectIDField.getText());
                    currSession = new Session(spauldingApp, nodes, date, sessionNameField.getText(), subjectID);
                    spauldingApp.addNewSession(currSession);
                    //currSession.registerListener(getThis());
                    currSession.startSampling();
                }
            }
        });

        stopButton.addMouseListener(new MouseAdapter() {
            public void mouseReleased(MouseEvent e) {
                System.out.println("STOP button pressed, isEnabled= " + stopButton.isEnabled());
                if (stopButton.isEnabled()) {
                    currSession.stopSampling();
                }
            }
        });

        insertMarkerButton.addMouseListener(new MouseAdapter() {
            public void mouseReleased(MouseEvent e) {
                spauldingApp.insertMarker(markerTextField.getText());
            }
        });
    }


    private void createGUIAndDoLayout()
    {
        // (1) - Initialize components
        this.setBorder(BorderFactory.createTitledBorder("Command Panel"));
        Font font = new Font("Helvetica", Font.BOLD, 12);
        currStateTextField.setFont(font);
        currStateTextField.setBackground(new Color(255, 251, 240));
        currStateTextField.setForeground(new Color(150, 0, 0));
        currStateTextField.setEditable(false);
        currStateTextField.setText(Session.getInitialState().toString());

        markerTextField.setFont(font);
        markerTextField.setEditable(true);
        markerTextField.setText("markerName");

        progressBar.setValue(0);
        progressBar.setStringPainted(true);

        // (2) - Do the layout
        this.setLayout(new GridBagLayout());
        GridBagConstraints c = new GridBagConstraints();
        c.fill = GridBagConstraints.HORIZONTAL;
        c.anchor = GridBagConstraints.EAST;
        c.insets = new Insets(1,1,1,1);  // padding
        //c.weightx = 1.0;

        // Session
        c.gridx = 0; c.gridy = 0;  this.add(sessionDateLabel, c);
        c.gridx = 1; c.gridy = 0;  this.add(sessionDateField, c); sessionDateField.setEnabled(false);

        c.gridx = 0; c.gridy = 1;  this.add(sessionNameLabel, c);
        c.gridx = 1; c.gridy = 1;  this.add(sessionNameField, c);

        c.gridx = 0; c.gridy = 2;  this.add(subjectIDLabel, c);
        c.gridx = 1; c.gridy = 2;  this.add(subjectIDField, c);

        // State
        c.gridx = 3; c.gridy = 0;  this.add(currStateLabel, c);
        c.gridx = 4; c.gridy = 0;  this.add(currStateTextField, c);

        c.gridx = 3; c.gridy = 1;  this.add(currStateProgressJLabel, c);
        c.gridx = 4; c.gridy = 1;  this.add(progressBar, c);

        // Session Buttons
        c.gridx = 2; c.gridy = 1;  this.add(startButton, c);
        c.gridx = 2; c.gridy = 2;  this.add(stopButton, c);  stopButton.setEnabled(false);

        // Marker label
        c.gridx = 0; c.gridy = 3; this.add(markerLabel, c);
        c.gridx = 1; c.gridy = 3; this.add(markerTextField, c);
        c.gridx = 2; c.gridy = 3; this.add(insertMarkerButton, c);
    }
}
