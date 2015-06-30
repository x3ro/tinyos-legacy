/*
import javax.swing.JTabbedPane;
import javax.swing.ImageIcon;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JFrame;
*/
import javax.swing.*;

import javax.swing.event.*; // For using interface ListSelectionListener

import java.awt.*;
import java.awt.event.*;

class GlobalVar {
  static Dimension scrollDimension;
  static int curAttrSelection;
  static JList projAttrList;
  static DefaultListModel projAttrListModel;
}

//class DropPane extends JPanel implements ActionListener {
class DropPane extends JPanel {
  JPanel row1;
  JLabel dropLabel;
  JButton yesButton, noButton;
  ActionListener buttonListener = new ActionListener() {
    public void actionPerformed(ActionEvent e) {
      JFrame frame = new JFrame();

      if (e.getActionCommand().equals("Confirm")) {
        JOptionPane.showMessageDialog(frame, "Confirm Button pressed");
      } else {
        JOptionPane.showMessageDialog(frame, "Cancel Button pressed");
      }
    }
  };

  public DropPane() {
    setLayout(new GridLayout(2, 1));

    dropLabel = new JLabel("Really erase DIM index?", JLabel.CENTER);
    dropLabel.setAlignmentX(CENTER_ALIGNMENT);
    add(dropLabel);

    //row1 = new JPanel(new FlowLayout(FlowLayout.CENTER));
    row1 = new JPanel();
    yesButton = new JButton("Confirm");
    yesButton.addActionListener(buttonListener);
    row1.add(yesButton);
    noButton = new JButton("Cancel");
    noButton.addActionListener(buttonListener);
    row1.add(noButton);
    add(row1);
  }

  /*
  public void actionPerformed(ActionEvent e) {
    JFrame frame = new JFrame();

    if (e.getActionCommand().equals("Confirm")) {
      JOptionPane.showMessageDialog(frame, "Confirm Button pressed");
    } else {
      JOptionPane.showMessageDialog(frame, "Cancel Button pressed");
    }
  }
  */
}

class QueryPane extends JPanel {
  JPanel row0;
  JLabel dummyLabel;
  JPanel row1, column11, column12, column13, row2;
  JLabel projAttrLabel, queryAttrLabel;
  DefaultListModel queryAttrListModel;
  JList projAttrList, queryAttrList;
  JScrollPane projAttrScroll, queryAttrScroll;
  JButton addButton, delButton;
  JButton issueButton, resetButton;

  ActionListener buttonListener = new ActionListener() {
    public void actionPerformed(ActionEvent e) {
      JFrame frame = new JFrame();

      if (e.getActionCommand().equals(">>>")) {
        if (GlobalVar.curAttrSelection < 0) {
          JOptionPane.showMessageDialog(frame, "No attribute selection made");
        } else {
          String selectedValue = (String)(projAttrList.getSelectedValue());
          //JOptionPane.showMessageDialog(frame, "Selected " + selectedValue);
          //int selectedIndex = projAttrList.getSelectedIndex();
          //availAttrListModel.remove(selectedIndex);
          String range = (String)JOptionPane.showInputDialog(frame, "Decide range for attribute " + selectedValue + " ", "Select queried attributes", JOptionPane.PLAIN_MESSAGE);
          queryAttrListModel.addElement(selectedValue + ", " + range);
        }
      } else {
        JOptionPane.showMessageDialog(frame, "[<<<] Button pressed");
      }
    }
  };

  public QueryPane() {
    setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
    
    row0 = new JPanel(new FlowLayout(FlowLayout.LEFT));
   
    //setAlignmentX(Component.LEFT_ALIGNMENT);
    dummyLabel = new JLabel("    ", JLabel.LEFT);
    //samplePeriod.setHorizontalTextPosition(JLabel.LEFT);
    row0.add(dummyLabel);

    add(row0);

    row1 = new JPanel(new FlowLayout(FlowLayout.LEFT));

    column11 = new JPanel();
    column11.setLayout(new BoxLayout(column11, BoxLayout.Y_AXIS));
    projAttrLabel = new JLabel("Projected Attrutes: ", JLabel.LEFT);
    //projAttrLabel.setHorizontalTextPosition(JLabel.LEFT);
    projAttrLabel.setAlignmentX(CENTER_ALIGNMENT);
    column11.add(projAttrLabel);
    
    projAttrList = new JList(GlobalVar.projAttrListModel);
    projAttrList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
    //projAttrList.setLayoutOrientation(JList.VERTICAL);
    projAttrList.setVisibleRowCount(4);
    
    projAttrScroll = new JScrollPane(projAttrList);
    projAttrScroll.setPreferredSize(new Dimension(GlobalVar.scrollDimension));
    column11.add(projAttrScroll);
    row1.add(column11);

    column12 = new JPanel();
    column12.setLayout(new BoxLayout(column12, BoxLayout.Y_AXIS));
    addButton = new JButton(">>>");
    addButton.addActionListener(buttonListener);
    column12.add(addButton);
    delButton = new JButton("<<<");
    delButton.addActionListener(buttonListener);
    column12.add(delButton);
    row1.add(column12);

    column13 = new JPanel();
    column13.setLayout(new BoxLayout(column13, BoxLayout.Y_AXIS));
    queryAttrLabel = new JLabel("Queried Attrutes: ", JLabel.LEFT);
    //availAttrLabel.setHorizontalTextPosition(JLabel.LEFT);
    queryAttrLabel.setAlignmentX(CENTER_ALIGNMENT);
    column13.add(queryAttrLabel);
    queryAttrListModel = new DefaultListModel();
    queryAttrList = new JList(queryAttrListModel);
    queryAttrList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
    queryAttrList.setVisibleRowCount(4);
    queryAttrScroll = new JScrollPane(queryAttrList);
    queryAttrScroll.setPreferredSize(new Dimension(GlobalVar.scrollDimension));
    
    column13.add(queryAttrScroll);
    row1.add(column13);

    add(row1);
    
    row2 = new JPanel(new FlowLayout(FlowLayout.CENTER));
    issueButton = new JButton("Issue");
    row2.add(issueButton);
    resetButton = new JButton("Reset");
    row2.add(resetButton);

    add (row2);
  }
}

class AttrListSelectionHandler implements ListSelectionListener {
  public void valueChanged(ListSelectionEvent e) {
    JFrame frame = new JFrame();
    ListSelectionModel lsm = (ListSelectionModel)e.getSource();

    GlobalVar.curAttrSelection = e.getLastIndex();
    
    /*
    int firstIndex = e.getFirstIndex();
    int lastIndex = e.getLastIndex();
    boolean isAdjusting = e.getValueIsAdjusting();
    JOptionPane.showMessageDialog(frame, "Event for indexes "
                  + firstIndex + " - " + lastIndex
                  + "; isAdjusting is " + isAdjusting
                  + "; selected indexes:");
    */
    /*
    if (lsm.isSelectionEmpty()) {
      output.append(" <none>");
    } else {
      // Find out which indexes are selected.
      int minIndex = lsm.getMinSelectionIndex();
      int maxIndex = lsm.getMaxSelectionIndex();
      for (int i = minIndex; i <= maxIndex; i++) {
        if (lsm.isSelectedIndex(i)) {
          output.append(" " + i);
        }
      }
    }
    output.append(newline);
    */
  }
}

class IndexPane extends JPanel {
  JPanel row1, row2, column21, column22, column23, row3;
  JLabel samplePeriod;
  String[] periods = {"2048", "4096", "8192", "16384"};
  JComboBox periodList;
  JLabel availAttrLabel, projAttrLabel;
  //JList availAttrList, projAttrList;
  JList availAttrList;
  //DefaultListModel availAttrListModel, projAttrListModel;
  DefaultListModel availAttrListModel;
  String[] attributes = {"voltage", "humid", "hum temp", "press", "thermo", "them temp","light"};
  JScrollPane availAttrScroll, projAttrScroll;
  JButton addButton;
  JButton delButton;
  JButton createButton;
  JButton resetButton;

  ActionListener samplePeriodListener = new ActionListener() {
    public void actionPerformed(ActionEvent e) {
      JFrame frame = new JFrame();
      JComboBox comboBox = (JComboBox)(e.getSource());
      String period = (String)(comboBox.getSelectedItem());
      
      JOptionPane.showMessageDialog(frame, "Set Sample Perioed to " + period);
    }
  };

  ActionListener buttonListener = new ActionListener() {
    public void actionPerformed(ActionEvent e) {
      JFrame frame = new JFrame();

      if (e.getActionCommand().equals(">>>")) {
        if (GlobalVar.curAttrSelection < 0) {
          JOptionPane.showMessageDialog(frame, "No attribute selection made");
        } else {
          String selectedValue = (String)(availAttrList.getSelectedValue());
          JOptionPane.showMessageDialog(frame, "Selected " + selectedValue);
          int selectedIndex = availAttrList.getSelectedIndex();
          availAttrListModel.remove(selectedIndex);
          GlobalVar.projAttrListModel.addElement(selectedValue);
        }
      } else {
        JOptionPane.showMessageDialog(frame, "[<<<] Button pressed");
      }
    }
  };

  public IndexPane() {
    //setLayout(new BorderLayout());
    //setLayout(new GridLayout(2, 1));
    setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
    
    row1 = new JPanel(new FlowLayout(FlowLayout.LEFT));
   
    //setAlignmentX(Component.LEFT_ALIGNMENT);
    samplePeriod = new JLabel("Sample Period: ", JLabel.LEFT);
    //samplePeriod.setHorizontalTextPosition(JLabel.LEFT);
    row1.add(samplePeriod);
    periodList = new JComboBox(periods);
    periodList.setSelectedIndex(0);
    periodList.addActionListener(samplePeriodListener);
    row1.add(periodList);

    add(row1);

    row2 = new JPanel(new FlowLayout(FlowLayout.LEFT));

    GlobalVar.curAttrSelection = -1;

    column21 = new JPanel();
    column21.setLayout(new BoxLayout(column21, BoxLayout.Y_AXIS));
    availAttrLabel = new JLabel("Available Attrutes: ", JLabel.LEFT);
    //availAttrLabel.setHorizontalTextPosition(JLabel.LEFT);
    availAttrLabel.setAlignmentX(CENTER_ALIGNMENT);
    column21.add(availAttrLabel);

    availAttrListModel = new DefaultListModel();
    availAttrListModel.addElement("voltage");
    availAttrListModel.addElement("humid");
    availAttrListModel.addElement("hum temp");
    availAttrListModel.addElement("pressure");
    availAttrListModel.addElement("thermo");
    availAttrListModel.addElement("them temp");
    availAttrListModel.addElement("light");
    
    availAttrList = new JList(availAttrListModel);
    availAttrList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);

    availAttrList.getSelectionModel().addListSelectionListener(new AttrListSelectionHandler());
    
    //availAttrList.setLayoutOrientation(JList.VERTICAL);
    availAttrList.setVisibleRowCount(4);

    availAttrScroll = new JScrollPane(availAttrList);
    column21.add(availAttrScroll);
    row2.add(column21);

    column22 = new JPanel();
    column22.setLayout(new BoxLayout(column22, BoxLayout.Y_AXIS));
    addButton = new JButton(">>>");
    addButton.addActionListener(buttonListener);
    column22.add(addButton);
    delButton = new JButton("<<<");
    delButton.addActionListener(buttonListener);
    column22.add(delButton);
    row2.add(column22);

    column23 = new JPanel();
    column23.setLayout(new BoxLayout(column23, BoxLayout.Y_AXIS));
    projAttrLabel = new JLabel("Projected Attrutes: ", JLabel.LEFT);
    //availAttrLabel.setHorizontalTextPosition(JLabel.LEFT);
    projAttrLabel.setAlignmentX(CENTER_ALIGNMENT);
    column23.add(projAttrLabel);

    GlobalVar.projAttrListModel = new DefaultListModel();

    GlobalVar.projAttrList = new JList(GlobalVar.projAttrListModel);
    GlobalVar.projAttrList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
    GlobalVar.projAttrList.setVisibleRowCount(4);
    projAttrScroll = new JScrollPane(GlobalVar.projAttrList);
    projAttrScroll.setPreferredSize(new Dimension(availAttrScroll.getPreferredSize()));

    GlobalVar.scrollDimension = new Dimension(availAttrScroll.getPreferredSize());
    
    column23.add(projAttrScroll);
    row2.add(column23);

    add(row2);
    
    row3 = new JPanel(new FlowLayout(FlowLayout.CENTER));
    createButton = new JButton("Create");
    row3.add(createButton);
    resetButton = new JButton("Reset");
    row3.add(resetButton);

    add (row3);
  }
}
   
public class GUI extends JPanel {
  IndexPane indexPane;
  QueryPane queryPane;
  DropPane dropPane;

  public GUI() {
    ImageIcon createIcon = new ImageIcon("configure2.png");
    ImageIcon queryIcon = new ImageIcon("find2.png");
    ImageIcon dropIcon = new ImageIcon("fileclose.png");
        
    JTabbedPane tabbedPane = new JTabbedPane();

    //Component panel1 = makeTextPanel("Blah");
    indexPane = new IndexPane();
    
    tabbedPane.addTab("CREATE", createIcon, indexPane, "Create a DIM Index");
    tabbedPane.setSelectedIndex(0);

    //Component panel2 = makeTextPanel("Blah blah");
    queryPane = new QueryPane();
    tabbedPane.addTab("QUERY", queryIcon, queryPane, "Issue Queries");

    //Component panel3 = makeTextPanel("Blah blah blah");
    dropPane = new DropPane();
    tabbedPane.addTab("DROP", dropIcon, dropPane, "Drop a DIM Index");

    /*
    Component panel4 = makeTextPanel("Blah blah blah blah");
    tabbedPane.addTab("Four", icon, panel4, "Does nothing at all");
    */

    //Add the tabbed pane to this panel.
    setLayout(new GridLayout(1, 1)); 
    add(tabbedPane);
  }

  protected Component makeTextPanel(String text) {
    JPanel panel = new JPanel(false);
    JLabel filler = new JLabel(text);
    filler.setHorizontalAlignment(JLabel.CENTER);
    panel.setLayout(new GridLayout(1, 1));
    panel.add(filler);
    return panel;
  }

  public static void main(String[] args) {
    JFrame frame = new JFrame("DIM Demo GUI");
    frame.addWindowListener(new WindowAdapter() {
      public void windowClosing(WindowEvent e) {System.exit(0);}
    });

    frame.getContentPane().add(new GUI(), 
                               BorderLayout.CENTER);
    //frame.setSize(400, 125);
    frame.pack();
    frame.setVisible(true);
    frame.setResizable(false);
  }
}
