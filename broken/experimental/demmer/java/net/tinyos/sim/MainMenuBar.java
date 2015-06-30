// $Id: MainMenuBar.java,v 1.3 2003/11/17 20:11:33 mikedemmer Exp $

/*									tab:2
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice and the following two paragraphs appear in all copies of
 * this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:	Matt Welsh
 */

/**
 * @author Matt Welsh
 */


package net.tinyos.sim;

import net.tinyos.sim.event.*;
import java.util.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.awt.*;
import java.io.*;
import java.net.URL;

public class MainMenuBar extends JMenuBar implements ActionListener {

  JPanel menuPanel, toolbarPanel;
  JMenu fileMenu;
  TinyViz tv;
  SimDriver driver;
  JButton pausePlayButton;
  Icon pauseIcon, playIcon, connectIcon;
  SimComm simComm;
  SimEventBus eventBus;
  JLabel delayLabel;
  public JLabel timeLabel;

  MainMenuBar(TinyViz tv) {
    this.tv = tv;
    this.driver = tv.getSimDriver();

    //setLayout(new BorderLayout());
    //menuPanel = new JPanel();
    toolbarPanel = new JPanel();
    toolbarPanel.setLayout(new FlowLayout(FlowLayout.RIGHT, 1, 0));
    //add(menuPanel, BorderLayout.WEST);
    //menuPanel.setLayout(new FlowLayout(FlowLayout.LEFT, 1, 0));
    //toolbarPanel.setLayout(new FlowLayout(FlowLayout.RIGHT, 1, 0));

    fileMenu = new JMenu("File");
    fileMenu.setFont(tv.labelFont);

//    JMenuItem runMenuItem = new JMenuItem("Run simulation");
//    runMenuItem.addActionListener(this);
//    runMenuItem.setFont(tv.defaultFont);
//    fileMenu.add(runMenuItem);

    JMenuItem quitMenuItem = new JMenuItem("Quit");
    quitMenuItem.addActionListener(this);
    quitMenuItem.setFont(tv.defaultFont);
    fileMenu.add(quitMenuItem);

    addMenu(fileMenu);
  }

  public void actionPerformed(ActionEvent e) {
    if (e.getActionCommand() == "Quit") {
      driver.exit(0);
    } else if (e.getActionCommand() == "Run simulation") {
      runSimulationDialog();
    }
  }

  public void addMenu(JMenu menu) {
    menu.setFont(tv.labelFont);
    add(menu);
  }

  public JButton addButton(String text) {
    JPanel jp = new JPanel();
    jp.setLayout(new FlowLayout(FlowLayout.RIGHT));
    JButton jbutton = new JButton(text);
    jbutton.setFont(tv.smallFont);
    jp.add(jbutton);
    toolbarPanel.add(jp);
    return jbutton;
  }

  public JButton addIconButton(String text, String icon_filename) {
    JPanel jp = new JPanel();
    jp.setLayout(new FlowLayout(FlowLayout.RIGHT));
    JButton jbutton;

    if (icon_filename == null) {
      jbutton = new JButton(text);
    } else {
      URL icon_res = this.getClass().getResource(icon_filename);
      if (icon_res != null) {
	jbutton = new JButton(new ImageIcon(icon_res));
      } else {
	jbutton = new JButton(text);
      }
    }
    jbutton.setFont(tv.smallFont);
    jp.add(jbutton);
    toolbarPanel.add(jp);
    return jbutton;
  }




  public JLabel addIcon(String text, String icon_filename) {
    JPanel jp = new JPanel();
    jp.setLayout(new FlowLayout(FlowLayout.RIGHT));
    JLabel jlabel;

    if (icon_filename == null) {
      jlabel = new JLabel(text);
    } else {
      URL icon_res = this.getClass().getResource(icon_filename);
      if (icon_res != null) {
	jlabel = new JLabel(new ImageIcon(icon_res));
      } else {
	jlabel = new JLabel(text);
      }
    }
    jlabel.setFont(tv.smallFont);
    jp.add(jlabel);
    toolbarPanel.add(jp);
    return jlabel;
  }

  public Icon getIcon(String icon_filename) {
    URL icon_res = this.getClass().getResource(icon_filename);
    if (icon_res != null) {
      return new ImageIcon(icon_res);
    } else {
      return null;
    }
  }

  void setDelayLabel() {
  }

  // Create toolbar widgets
  void addToolbar() {
    this.simComm = driver.getSimComm();
    this.eventBus = driver.getEventBus();

    timeLabel = new JLabel("0.000",JLabel.LEFT);
    timeLabel.setFont(tv.defaultFont);
    JLabel timeTitle= new JLabel("    Sim Time:  ");
    timeTitle.setFont(tv.defaultFont);
    JLabel units = new JLabel("sec  ");
    units.setFont(tv.defaultFont);
    toolbarPanel.add(timeTitle);
    toolbarPanel.add(timeLabel);
    toolbarPanel.add(units);

    JPanel delayPanel = new JPanel();
    toolbarPanel.add(delayPanel);
    JLabel jl1 = new JLabel("Delay"); jl1.setFont(tv.smallFont);
    delayPanel.add(jl1);
    JSlider simDelay = new JSlider(JSlider.HORIZONTAL, 0, 500, 0);
    simDelay.addChangeListener(new simDelayListener());
    simDelay.setMajorTickSpacing(250);
    simDelay.setMinorTickSpacing(50);
    simDelay.setPaintTicks(false);
    simDelay.setPaintLabels(false);
    simDelay.setFont(tv.smallFont);
    simDelay.setPreferredSize(new Dimension(100, 20));
    delayPanel.add(simDelay);
    delayLabel = new JLabel("0 ms"); 
    delayLabel.setFont(tv.smallFont);
    delayPanel.add(delayLabel);

    // Play/pause button
    pauseIcon = getIcon("ui/pause.gif");
    playIcon = getIcon("ui/play.gif");
    connectIcon = getIcon("ui/connect.gif");
    pausePlayButton = addIconButton("Run", "ui/play.gif");
    pausePlayButton.addActionListener(new pausePlayListener());
    refreshPausePlayButton();

    addIconButton("Toggle grid", "ui/grid.gif").addActionListener(new gridListener());
    addButton("Clear").addActionListener(new clearListener());

    if (driver.getAutoRun() != null) {
      addIconButton("Stop", "ui/cancel.gif").addActionListener(new cancelListener());
    }

    // Logo
    addIcon("TinyViz", "ui/tinyvizlogosmall.gif");

    add(toolbarPanel);
  }

  public void clickPause() {
    if (!simComm.isPaused()) pausePlayButton.doClick();
  }
  
  public void clickResume() {
    if (simComm.isPaused()) pausePlayButton.doClick();
  }

  private void runSimulationDialog() {
    runSimDialog rsd = new runSimDialog(tv.getMainFrame());
    rsd.pack();
    rsd.setVisible(true);
  }

  class runSimDialog extends JDialog {
    public runSimDialog(Frame frame) {
      super(frame);
      JPanel panel = new JPanel();
      setContentPane(panel);
      setDefaultCloseOperation(DO_NOTHING_ON_CLOSE);
      setTitle("Run simulation");

      JTextField exeField = new JTextField();
      exeField.setFont(tv.smallFont);
      JTextField motesField = new JTextField("10", 5);
      motesField.setFont(tv.smallFont);

      panel.setLayout(new GridLayout(2,2));
      panel.add(new JLabel("Executable file"));
      panel.add(exeField);
      panel.add(new JLabel("Number of motes"));
      panel.add(motesField);
    }
  }

  class simDelayListener implements ChangeListener {
    public void stateChanged(ChangeEvent e) {
      JSlider source = (JSlider)e.getSource();
      if (!source.getValueIsAdjusting()) {
	long delay = (long)source.getValue();
	delayLabel.setText(delay+" ms");
	driver.setSimDelay(delay);
      }
    }
  }

  class gridListener implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      tv.getMotePanel().toggleGrid();
    }
  }

  class clearListener implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      driver.getPluginManager().reset();
    }
  }

  class cancelListener implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      driver.stop();
    }
  }

  void refreshPausePlayButton() {
    if (simComm.isStopped()) {
      if (pausePlayButton.getIcon() != null) {
	pausePlayButton.setIcon(connectIcon);
      } else {
	pausePlayButton.setText("Connect");
      }
    } else if (simComm.isPaused()) {
      if (pausePlayButton.getIcon() != null) {
	pausePlayButton.setIcon(playIcon);
      } else {
	pausePlayButton.setText("Run");
      }
    } else {
      if (pausePlayButton.getIcon() != null) {
	pausePlayButton.setIcon(pauseIcon);
      } else {
	pausePlayButton.setText("Pause");
      }
    }
  }

  class pausePlayListener implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      if (simComm.isStopped()) {
	simComm.start();
      } else if (driver.isPaused()) {
	driver.resume();
      } else {
	driver.pause();
      }
      refreshPausePlayButton();
    }
  }


}
