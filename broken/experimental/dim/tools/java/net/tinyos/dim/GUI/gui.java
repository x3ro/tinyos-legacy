package net.tinyos.dim.GUI; 

import javax.swing.*;

import javax.swing.event.*; // For using interface ListSelectionListener

// Use borders
import javax.swing.BorderFactory;
import javax.swing.border.Border;
import javax.swing.border.TitledBorder;
import javax.swing.border.EtchedBorder;

// Use AbstractTableModel
import javax.swing.table.AbstractTableModel;

// Set table column width
import javax.swing.table.TableColumn;

// Set table column alignment
import javax.swing.table.DefaultTableCellRenderer;

// Use ArrayList
import java.util.*;

// Use Dialog
import javax.swing.JOptionPane;
import javax.swing.JDialog;

import net.tinyos.tinydb.*;

import java.awt.*;
import java.awt.event.*;

import net.tinyos.util.*;
import java.io.*;
import java.util.Properties;
import net.tinyos.message.*;
import net.tinyos.tools.*;

class DimQueryField {
  QueryField queryField;
  float userMin, userMax;
  boolean selected;
  short attrId;

  public DimQueryField(QueryField queryField, boolean selected) {
    this.queryField = new QueryField(queryField.getName(), 
                                     queryField.getType(), 
                                     (int)(queryField.getMinVal()), 
                                     (int)(queryField.getMaxVal()));
    this.userMin = queryField.getMinVal();
    this.userMax = queryField.getMaxVal();
    this.selected = selected;
  }

  public String toString() {
    return queryField.getName();
  }
}
  
class CreateSubPane extends JPanel {
  JPanel row1, col11, col12, col13, row2;
  
  JLabel availAttrLabel;
  JList availAttrList;
  DefaultListModel availAttrListModel;
  JScrollPane availAttrScroll;

  JLabel indexedAttrLabel;
  JList indexedAttrList;
  DefaultListModel indexedAttrListModel;
  JScrollPane indexedAttrScroll;

  JButton addButton, delButton, createButton, clearButton, dropButton;
  ActionListener createButtonListener = new ActionListener() {
    public void actionPerformed(ActionEvent e) {
      JFrame frame = new JFrame();
      if (e.getActionCommand().equals(">>>")) {
        // addButton
        if (availAttrList.getSelectedIndex() < 0) {
          JOptionPane.showMessageDialog(frame, "No attribute has been seleceted");
        } else {
          //String selectedValue = (String)(availAttrList.getSelectedValue());
          //indexedAttrListModel.addElement(availAttrList.getSelectedValue());
          indexedAttrListModel.addElement(new DimQueryField((QueryField)(availAttrList.getSelectedValue()), false));
          
          //GlobalVar.queryPane = new QueryPane();
          //GlobalVar.queryTableModel.fireTableRowsUpdated(0, GlobalVar.queryTableModel.getRowCount() - 1);
          //GlobalVar.queryTable.setModel(new QueryTableModel());
          TableModelEvent queryTableModelEvent = new TableModelEvent(GlobalVar.queryTableModel);
          GlobalVar.queryTable.tableChanged(queryTableModelEvent);
          
          delButton.setEnabled(true);
          createButton.setEnabled(true);
          clearButton.setEnabled(true);
        }
      } else if (e.getActionCommand().equals("<<<")) {
        // delButton
        if (indexedAttrList.getSelectedIndex() < 0) {
          JOptionPane.showMessageDialog(frame, "No attribute has been selected");
        } else {
          indexedAttrListModel.remove(indexedAttrList.getSelectedIndex());
          
          TableModelEvent queryTableModelEvent = new TableModelEvent(GlobalVar.queryTableModel);
          GlobalVar.queryTable.tableChanged(queryTableModelEvent);

          if (indexedAttrListModel.isEmpty()) {
            delButton.setEnabled(false);
            createButton.setEnabled(false);
            clearButton.setEnabled(false);
          }
        }
      } else if (e.getActionCommand().equals("Create DIM")) {
        // createButton
        // Should set the dialog to be uncloseable until the creation
        // operation has been finished.
        String attrStr = new String();
        int jj = GlobalVar.indexedAttrListModel.getSize();
        for (int i = 0; i < jj; i ++) {
          attrStr = attrStr + GlobalVar.indexedAttrListModel.getElementAt(i).toString();
          if (i < jj - 1) {
            attrStr = attrStr + ", ";
          }
        }

        int dialog = JOptionPane.showConfirmDialog(frame, "Creating DIM Index on attributes: " + attrStr, "DIM Question", JOptionPane.YES_NO_OPTION);
        if (dialog == JOptionPane.YES_OPTION) {
          // Send creation request
          new ConsoleCreate();

          addButton.setEnabled(false);
          delButton.setEnabled(false);
          createButton.setEnabled(false);
          clearButton.setEnabled(false);
        
          dropButton.setEnabled(true);
          GlobalVar.insertSubPane.samplePeriodList.setEnabled(true);
          GlobalVar.insertSubPane.startButton.setEnabled(true);
        }
      } else if (e.getActionCommand().equals("Reset")) {
        // clearButton
        indexedAttrListModel.clear();

        delButton.setEnabled(false);
        createButton.setEnabled(false);
        clearButton.setEnabled(false);
      } else {
        // dropButton
        //JOptionPane.showMessageDialog(frame, "Drop DIM Index");
        int dialog = JOptionPane.showConfirmDialog(frame, "Drop DIM Index?", "DIM Question", JOptionPane.YES_NO_OPTION);
        if (dialog == JOptionPane.YES_OPTION) {

          new ConsoleDrop();
          GlobalVar.curState = "NULL";
        
          indexedAttrListModel.clear();
        
          dropButton.setEnabled(false);
          GlobalVar.insertSubPane.samplePeriodList.setEnabled(false);
          GlobalVar.insertSubPane.startButton.setEnabled(false);
          GlobalVar.insertSubPane.stopButton.setEnabled(false);
        
          addButton.setEnabled(true);
        }
      }
    }
  };

  public CreateSubPane() {
    Border border = BorderFactory.createEtchedBorder(EtchedBorder.LOWERED);
    /*
    TitledBorder titled = BorderFactory.createTitledBorder(border, "Create/Drop DIM");
    titled.setTitleJustification(TitledBorder.CENTER);
    titled.setTitlePosition(TitledBorder.DEFAULT_POSITION);
    */
    Font font = new Font("Default", Font.BOLD, 13);
    TitledBorder titled = BorderFactory.createTitledBorder(border, 
                            "Create/Drop DIM",
                            TitledBorder.CENTER,
                            TitledBorder.DEFAULT_POSITION,
                            font);
    setBorder(titled);

    setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));

    row1 = new JPanel(new FlowLayout(FlowLayout.CENTER));
    /*
    row1 = new JPanel();
    row1.setLayout(new BoxLayout(row1, BoxLayout.X_AXIS));
    */
    add(row1);
    
    col11 = new JPanel();
    row1.add(col11);
    col11.setLayout(new BoxLayout(col11, BoxLayout.Y_AXIS));
    availAttrLabel = new JLabel("Available Attrutes: ", JLabel.LEFT);
    availAttrLabel.setAlignmentX(CENTER_ALIGNMENT);
    //availAttrLabel.setFont(new Font("Default", Font.BOLD, 14));
    availAttrLabel.setFont(new Font("Default", Font.BOLD, 16));
    col11.add(availAttrLabel);
    availAttrListModel = new DefaultListModel();
    // Should be replaced with TinyDB catalog
    /*
    availAttrListModel.addElement("voltage");
    availAttrListModel.addElement("humid");
    availAttrListModel.addElement("hum temp");
    availAttrListModel.addElement("pressure");
    availAttrListModel.addElement("thermo");
    availAttrListModel.addElement("them temp");
    availAttrListModel.addElement("light");
    */
    // Using TinyDB catalog to intialize attribute list
    for (int i = 0; i < GlobalVar.dbCatalog.numAttrs(); i ++) {
      //availAttrListModel.addElement(GlobalVar.dbCatalog.getAttr(i));
      QueryField queryField = GlobalVar.dbCatalog.getAttr(i);
      String attrName = queryField.getName();
      if (!attrName.equalsIgnoreCase("nodeid") &&
          !attrName.equalsIgnoreCase("parent") &&
          !attrName.equalsIgnoreCase("freeram") &&
          !attrName.equalsIgnoreCase("voltage") &&
          !attrName.equalsIgnoreCase("rawtone") &&
          !attrName.equalsIgnoreCase("rawmic") &&
          !attrName.equalsIgnoreCase("name") &&
          !attrName.equalsIgnoreCase("content") &&
          !attrName.equalsIgnoreCase("attrlog")) {
        availAttrListModel.addElement(queryField);
      }
    }

    GlobalVar.availAttrListModel = availAttrListModel;
    
    availAttrList = new JList(availAttrListModel);
    availAttrList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
    availAttrList.setVisibleRowCount(5);
    availAttrList.setFont(new Font("Default", Font.BOLD, 14));
    availAttrScroll = new JScrollPane(availAttrList);
    col11.add(availAttrScroll);

    col12 = new JPanel();
    row1.add(col12);
    //col12.setAlignmentY(BOTTOM_ALIGNMENT);
    
    //col12.setLayout(new BoxLayout(col12, BoxLayout.Y_AXIS));
    col12.setLayout(new GridLayout(3, 1));

    addButton = new JButton(">>>");
    addButton.setFont(new Font("Default", Font.BOLD, 13));
    addButton.addActionListener(createButtonListener);
    col12.add(addButton);
    addButton.setAlignmentX(CENTER_ALIGNMENT);
    if (GlobalVar.curState.equals("NULL")) {
      addButton.setEnabled(true);
    } else {
      addButton.setEnabled(false);
    }
    
    delButton = new JButton("<<<");
    delButton.setFont(new Font("Default", Font.BOLD, 13));
    delButton.addActionListener(createButtonListener);
    delButton.setEnabled(false);
    delButton.setAlignmentX(CENTER_ALIGNMENT);
    col12.add(delButton);
    
    clearButton = new JButton("Reset");
    clearButton.addActionListener(createButtonListener);
    clearButton.setEnabled(false);
    clearButton.setFont(new Font("Defalut", Font.BOLD, 13));
    clearButton.setAlignmentX(CENTER_ALIGNMENT);
    col12.add(clearButton);
    
    col13 = new JPanel();
    row1.add(col13);
    col13.setLayout(new BoxLayout(col13, BoxLayout.Y_AXIS));
    indexedAttrLabel = new JLabel("Indexed Attrutes: ", JLabel.LEFT);
    indexedAttrLabel.setAlignmentX(CENTER_ALIGNMENT);
    indexedAttrLabel.setFont(new Font("Default", Font.BOLD, 16));
    col13.add(indexedAttrLabel);
    if (GlobalVar.curState.equals("NULL")) {
      indexedAttrListModel = new DefaultListModel();

      GlobalVar.indexedAttrListModel = indexedAttrListModel;
    } else {
      indexedAttrListModel = GlobalVar.indexedAttrListModel;
    }
    
    indexedAttrList = new JList(indexedAttrListModel);
    indexedAttrList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
    indexedAttrList.setVisibleRowCount(5);
    indexedAttrList.setFont(new Font("Default", Font.BOLD, 14));
    indexedAttrScroll = new JScrollPane(indexedAttrList);
    indexedAttrScroll.setPreferredSize(new Dimension(availAttrScroll.getPreferredSize()));
    col13.add(indexedAttrScroll);

    row2 = new JPanel(new FlowLayout(FlowLayout.CENTER));
    add(row2);
    createButton = new JButton("Create DIM");
    createButton.addActionListener(createButtonListener);
    createButton.setEnabled(false);
    createButton.setFont(new Font("Default", Font.BOLD, 13));
    row2.add(createButton);
    /* 
    clearButton = new JButton("Clear All");
    clearButton.addActionListener(createButtonListener);
    clearButton.setEnabled(false);
    clearButton.setFont(new Font("Defalut", Font.BOLD, 12));
    row2.add(clearButton);
    */
    dropButton = new JButton("Drop DIM");
    dropButton.addActionListener(createButtonListener);
    if (GlobalVar.curState.equals("NULL")) {
      dropButton.setEnabled(false);
    } else {
      dropButton.setEnabled(true);
    }
    dropButton.setFont(new Font("Default", Font.BOLD, 13));
    row2.add(dropButton);
  }
}

class InsertSubPane extends JPanel {
  JPanel upper, lower;

  JLabel samplePeriodLabel;
  String[] samplePeriodValues = {"4000", "6000", "8000", "10000", "12000", "14000", "16000", "18000", "20000"};
  JComboBox samplePeriodList;
  ActionListener samplePeriodListener = new ActionListener() {
    public void actionPerformed(ActionEvent e) {
      JFrame frame = new JFrame();
      JComboBox comboBox = (JComboBox)(e.getSource());
      String period = (String)(comboBox.getSelectedItem());
      //JOptionPane.showMessageDialog(frame, "Set Sample Perioed to " + period);
    }
  };

  JButton startButton;
  JButton stopButton;
  ActionListener insertButtonListener = new ActionListener() {
    public void actionPerformed(ActionEvent e) {
      JFrame frame = new JFrame();

      if (e.getActionCommand().equals("Start Sampling")) {
        int selectedValue = Integer.parseInt((String)(samplePeriodList.getSelectedItem()));
        GlobalVar.samplePeriod = selectedValue;
        
        //JOptionPane.showMessageDialog(frame, "Start sampling with period " + selectedValue);
        int dialog = JOptionPane.showConfirmDialog(frame, "Start sampling with period " + selectedValue, "DIM Question", JOptionPane.YES_NO_OPTION);
        if (dialog == JOptionPane.YES_OPTION) {
          new ConsoleStart(ConsoleConstant.CONSOLE_START, selectedValue);
          GlobalVar.curState = "START";
        
          startButton.setEnabled(false);
          samplePeriodList.setEnabled(false);
        
          stopButton.setEnabled(true);
        
          //GlobalVar.queryPane.issueButton.setEnabled(true);
          //GlobalVar.queryPane.resetButton.setEnabled(true);
        }
      } else {
        //JOptionPane.showMessageDialog(frame, "Stop Sampling");
        int dialog = JOptionPane.showConfirmDialog(frame, "Stop Sampling?", "DIM Question", JOptionPane.YES_NO_OPTION);
        if (dialog == JOptionPane.YES_OPTION) {
          new ConsoleStart(ConsoleConstant.CONSOLE_STOP, 0);
          GlobalVar.curState = "STOP";
        
          stopButton.setEnabled(false);

          //GlobalVar.queryPane.issueButton.setEnabled(false);
          //GlobalVar.queryPane.resetButton.setEnabled(false);

          startButton.setEnabled(true);
          samplePeriodList.setEnabled(true);
        }
      }
    }
  };

  public InsertSubPane() {
    //setBorder(BorderFactory.createLineBorder(Color.black));
    //setBorder(BorderFactory.createEtchedBorder(EtchedBorder.LOWERED));
    Border border = BorderFactory.createEtchedBorder(EtchedBorder.LOWERED);
    /*
    TitledBorder titled = BorderFactory.createTitledBorder(border, "Start/Stop DIM sampling");
    titled.setTitleJustification(TitledBorder.CENTER);
    titled.setTitlePosition(TitledBorder.DEFAULT_POSITION);
    */
    Font font = new Font("Default", Font.BOLD, 13);
    TitledBorder titled = BorderFactory.createTitledBorder(border, 
                            "Start/Stop DIM sampling",
                            TitledBorder.CENTER,
                            TitledBorder.DEFAULT_POSITION,
                            font);
    setBorder(titled);

    setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
    
    upper = new JPanel();
    upper.setLayout(new FlowLayout(FlowLayout.CENTER));
    add(upper);
    
    samplePeriodLabel = new JLabel("Sampling Period: ", JLabel.LEFT);
    samplePeriodLabel.setFont(new Font("Default", Font.BOLD, 16));
    upper.add(samplePeriodLabel);
    
    samplePeriodList = new JComboBox(samplePeriodValues);
    if (GlobalVar.curState.equals("START") ||
        GlobalVar.curState.equals("STOP")) {
      for (int i = 0; i < 9; i ++) {
        if (Integer.parseInt(samplePeriodValues[i]) == GlobalVar.samplePeriod) {
          samplePeriodList.setSelectedIndex(i);
          break;
        }
      }
    } else {
      samplePeriodList.setSelectedIndex(0);
    }
    samplePeriodList.addActionListener(samplePeriodListener);
    if (GlobalVar.curState.equals("CREATE")) {
      samplePeriodList.setEnabled(true);
    } else {
      samplePeriodList.setEnabled(false);
    }
    samplePeriodList.setFont(new Font("Default", Font.BOLD, 13));
    upper.add(samplePeriodList);

    lower = new JPanel();
    lower.setLayout(new FlowLayout(FlowLayout.CENTER));
    add(lower);
    
    startButton = new JButton("Start Sampling");
    startButton.addActionListener(insertButtonListener);
    if (GlobalVar.curState.equals("CREATE") ||
        GlobalVar.curState.equals("STOP")) {
      startButton.setEnabled(true);
    } else {
      startButton.setEnabled(false);
    }
    startButton.setFont(new Font("Default", Font.BOLD, 13));
    lower.add(startButton);

    stopButton = new JButton("Stop Sampling");
    stopButton.addActionListener(insertButtonListener);
    if (GlobalVar.curState.equals("START")) {
      stopButton.setEnabled(true);
    } else {
      stopButton.setEnabled(false);
    }
    stopButton.setFont(new Font("Default", Font.BOLD, 13));
    lower.add(stopButton);
  }
}

class SetupPane extends JPanel {
  public SetupPane() {
    setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));

    GlobalVar.createSubPane = new CreateSubPane();
    add(GlobalVar.createSubPane);
    
    JPanel dummy = new JPanel();
    add(dummy);

    GlobalVar.insertSubPane = new InsertSubPane();
    add(GlobalVar.insertSubPane);
  }
}

class QueryTableModel extends AbstractTableModel {
  final String columnNames[] = {"Name",
                                "Type",
                                "Min Value",
                                "Max Value",
                                "User Min",
                                "User Max",
                                "Selected"};
  // This array may be replaced later with dynamic arrays.
  //Object[][] data = new Object[GlobalVar.createSubPane.indexedAttrListModel.getSize()][5];
  //DefaultListModel data = GlobalVar.createSubPane.indexedAttrListModel;

  static String[] typeNames = {"",
                               "INT8",
                               "UINT8", 
                               "INT16", 
                               "UINT16", 
                               "INT32", 
                               "UINT32", 
                               "TIMESTAMP", 
                               "STRING", 
                               "BYTES"};

  public QueryTableModel() {
    //super();
    // Fill in Object array with indexedAttrListModel.
    /*
    System.out.println("GlobalVar.availAttrListModel.getSize() = " +
                        GlobalVar.availAttrListModel.getSize());
    System.out.println("GlobalVar.indexedAttrListModel.getSize() = " +
                        GlobalVar.indexedAttrListModel.getSize());
    */

    /*
    for (int i = 0; i < GlobalVar.createSubPane.indexedAttrListModel.getSize(); i ++) {
      QueryField queryField = (QueryField)(GlobalVar.createSubPane.indexedAttrListModel.getElementAt(i));
      data[i][0] = new String(queryField.getName());
      data[i][1] = new String(typeNames[queryField.getType()]);
      data[i][2] = new Float(queryField.getMinVal());
      data[i][3] = new Float(queryField.getMaxVal());
      data[i][4] = new Boolean(false);
    }
    */
  }

  public String getColumnName(int col) {
    return columnNames[col];
  }

  public int getColumnCount() {
    //System.err.println("call getColumnCount(): columnNames.length = " + columnNames.length);

    return columnNames.length;
  }

  public int getRowCount() {
    //System.err.println("call getRowCount(): getSize() = " + GlobalVar.availAttrListModel.getSize());
    //System.err.println("call getRowCount(): getSize() = " + GlobalVar.indexedAttrListModel.getSize());

    //return GlobalVar.availAttrListModel.getSize();
    return GlobalVar.indexedAttrListModel.getSize();
  }
                                                         
  public Object getValueAt(int row, int col) {
    //System.err.println("call getValueAt(" + row + ", " + col +")");
    
    //QueryField queryField = (QueryField)(GlobalVar.availAttrListModel.getElementAt(row));
    DimQueryField dimQueryField = (DimQueryField)(GlobalVar.indexedAttrListModel.getElementAt(row));
    
    Object cellData;

    switch (col) {
    case 0: 
      cellData = new String(dimQueryField.queryField.getName());
      break;
    case 1:
      cellData = new String(typeNames[dimQueryField.queryField.getType()]);
      break;
    case 2: 
      cellData = new Integer((int)dimQueryField.queryField.getMinVal());
      break;
    case 3:
      cellData = new Integer((int)dimQueryField.queryField.getMaxVal());
      break;
    case 4:
      cellData = new Integer((int)dimQueryField.userMin);
      break;
    case 5:
      cellData = new Integer((int)dimQueryField.userMax);
      break;
    case 6:
      cellData = new Boolean(dimQueryField.selected);
      break;
    default:
      cellData = null;
      break;
    }
    return cellData; 
  }

  /*
   * JTable uses this method to determine the default renderer/
   * editor for each cell.  If we didn't implement this method,
   * then the last column would contain text ("true"/"false"),
   * rather than a check box.
   */
  public Class getColumnClass(int c) {
  
    //System.err.println("call getColumnClass(" + c + ")");

    Object object;

    switch (c) {
    case 0:
    case 1:
      object = new String("");
      break;
    case 2:
    case 3:
    case 4:
    case 5:
      object = new Integer(0);
      break;
    case 6:
      object = new Boolean(false);
      break;
    default:
      object = null;
      break;
    }
    return object.getClass();
    //return getValueAt(0, c).getClass();
  }
  
  /*
   * Don't need to implement this method unless your table's
   * editable.
   */
  public boolean isCellEditable(int row, int col) {
    return (col > 3 ? true : false);
    //Note that the data/cell address is constant,
    //no matter where the cell appears onscreen.
  }

  /*
   * Don't need to implement this method unless your table's
   * data can change.
   */
  public void setValueAt(Object value, int row, int col) {

    //System.err.println("call setValueAt(" + row + ", " + col + ")");

    JFrame frame = new JFrame();

    if (row > getRowCount() - 1) {
      // Don't allow user to add new attributes
      JOptionPane.showMessageDialog(frame, "Cannot add new attributes");
    } else {
      DimQueryField dimQueryField = (DimQueryField)(GlobalVar.indexedAttrListModel.getElementAt(row));

      if (col == 4 || col == 5) {
        // Set Min/Max value.
        int sysMin = (int)(dimQueryField.queryField.getMinVal());
        int sysMax = (int)(dimQueryField.queryField.getMaxVal());
        
        if (!(value instanceof Integer)) {
          JOptionPane.showMessageDialog(frame, "Field value must be an positive integer.\n");
        } else {
          if (col == 4) {
            int userMin = ((Integer)value).intValue();
            int userMax = (int)(dimQueryField.userMax);

            if (userMin < sysMin || userMin > sysMax || userMin > userMax) {
              JOptionPane.showMessageDialog(frame, "Minimum value input is out of range.");
            } else {
              dimQueryField.userMin = userMin;
              fireTableCellUpdated(row, col);
            }
          } else {
            int userMin = (int)(dimQueryField.userMin);
            int userMax = ((Integer)value).intValue();
            
            if (userMax < sysMin || userMax > sysMax || userMax < sysMin) {
              JOptionPane.showMessageDialog(frame, "Maximum value input is out of range.");
            } else {
              dimQueryField.userMax = userMax;
              fireTableCellUpdated(row, col);
            }
          }
        }
      } else if (col == 6) {
        // Select/Unselect this attribute
        dimQueryField.selected = ((Boolean)value).booleanValue();
        fireTableCellUpdated(row, col);
      }
    }
  }
}

class QueryPane extends JPanel {
  JLabel queryLabel;
  JScrollPane queryTableScroll;
  JPanel top, upper, lower;
  JButton issueButton, resetButton;
  ActionListener queryButtonListener = new ActionListener() {
    public void actionPerformed(ActionEvent e) {
      final JFrame frame = new JFrame();
      DimQueryField dimQueryField;

      if (e.getActionCommand().equals("Send Query")) {
        //JOptionPane.showMessageDialog(frame, "Issue");
        int queriedNumFields = 0;
        int totalNumFields = GlobalVar.indexedAttrListModel.getSize();
        for (int i = 0; i < totalNumFields; i ++) {
          dimQueryField = (DimQueryField)(GlobalVar.indexedAttrListModel.getElementAt(i));
          if (dimQueryField.selected) {
            queriedNumFields ++;
          }
        }
        if (queriedNumFields > 6) {
          JOptionPane.showMessageDialog(frame, "For now, at most 5 attributes can be queried simultaneously.\n");
        } else {
          ReplyPane replyPane = new ReplyPane();
          GlobalVar.queryArrayList.add(replyPane);

          JButton closeButton = new JButton("close");
          closeButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
              frame.setVisible(false);
              frame.dispose();
            }
          });
          Container contentPane = frame.getContentPane();
        
          frame.setTitle("Query Result Display");
          contentPane.setLayout(new BoxLayout(contentPane, BoxLayout.Y_AXIS));

          JLabel replyLabel = new JLabel("Results for query #" + GlobalVar.queryID);
          replyLabel.setAlignmentX(CENTER_ALIGNMENT);
          replyLabel.setFont(new Font("Default", Font.BOLD, 16));
          contentPane.add(replyLabel);

          contentPane.add(replyPane);
          replyPane.setAlignmentX(CENTER_ALIGNMENT);

          contentPane.add(closeButton);
          closeButton.setAlignmentX(CENTER_ALIGNMENT);
          frame.setVisible(true);
          frame.pack();
          frame.setResizable(true);
          frame.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);

          new ConsoleQuery(GlobalVar.queryID);
          GlobalVar.queryID ++;
          queryLabel.setText("Select attributes and their ranges for query #" + GlobalVar.queryID);
        }
      } else {
        //JOptionPane.showMessageDialog(frame, "Reset");
        for (int i = 0; i < GlobalVar.indexedAttrListModel.getSize(); i ++) {
          dimQueryField = (DimQueryField)(GlobalVar.indexedAttrListModel.getElementAt(i));
          dimQueryField.userMin = dimQueryField.queryField.getMinVal();
          dimQueryField.userMax = dimQueryField.queryField.getMaxVal();
          dimQueryField.selected = false;
        }

        TableModelEvent queryTableModelEvent = new TableModelEvent(GlobalVar.queryTableModel);
        GlobalVar.queryTable.tableChanged(queryTableModelEvent);
      }
    }
  };
  
  public QueryPane() {
    setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));

    top = new JPanel();
    add(top);
    queryLabel = new JLabel("Select attributes and their ranges for query #" + GlobalVar.queryID);
    queryLabel.setAlignmentX(CENTER_ALIGNMENT);
    queryLabel.setFont(new Font("Default", Font.BOLD, 16));
    top.add(queryLabel);

    upper = new JPanel();
    add(upper);

    GlobalVar.queryTableModel = new QueryTableModel();
    GlobalVar.queryTable = new JTable(GlobalVar.queryTableModel); 
    GlobalVar.queryTable.setPreferredScrollableViewportSize(new Dimension(500, 180));
    GlobalVar.queryTable.setFont(new Font("Default", Font.BOLD, 14));
    queryTableScroll = new JScrollPane(GlobalVar.queryTable);
    upper.add(queryTableScroll);

    lower = new JPanel();
    lower.setLayout(new FlowLayout(FlowLayout.CENTER));
    add(lower);
    
    issueButton = new JButton("Send Query");
    issueButton.addActionListener(queryButtonListener);
    //issueButton.setEnabled(false);
    issueButton.setFont(new Font("Default", Font.BOLD, 13));
    // Should be release once debugging is finished.
    //issueButton.setEnabled(false);
    lower.add(issueButton);

    resetButton = new JButton("Reset");
    resetButton.addActionListener(queryButtonListener);
    //resetButton.setEnabled(false);
    resetButton.setFont(new Font("Default", Font.BOLD, 13));
    resetButton.setEnabled(false);
    lower.add(resetButton);
  }
}

class ReplyTableModel extends AbstractTableModel {
  final int columnCount = GlobalVar.indexedAttrListModel.getSize() + 4;
  String[] columnNames = new String[columnCount];
  DimQueryField dimQueryField;
  DefaultListModel dimTupleListModel;
  ArrayList dimTuple;
  
  public ReplyTableModel(DefaultListModel tupleListModel) {
    dimTupleListModel = tupleListModel;  
    
    columnNames[0] = new String("Sender");
    columnNames[1] = new String("Detector");
    columnNames[2] = new String("Timehi");
    columnNames[3] = new String("Timelo");
    for (int i = 0; i < GlobalVar.indexedAttrListModel.getSize(); i ++) {
      dimQueryField = (DimQueryField)(GlobalVar.indexedAttrListModel.getElementAt(i));
      columnNames[i + 4] = new String(dimQueryField.queryField.getName());
    } 
  }

  public String getColumnName(int col) {
    return columnNames[col];
  }

  public int getColumnCount() {
    return columnCount;
  }

  public int getRowCount() {
    return dimTupleListModel.getSize();
  }
                                                         
  public Object getValueAt(int row, int col) {
    // Each dimTuple is just an ArrayList.
    dimTuple = (ArrayList)(dimTupleListModel.getElementAt(row));
    return dimTuple.get(col); 
  }

  public Class getColumnClass(int c) {
    return (new Integer(0)).getClass();
  }
}

class ReplyPane extends JPanel {
  //JPanel top, upper;
  //JPanel top;
  //JLabel replyLabel;
  JTable replyTable;
  JScrollPane replyTableScroll;
  ReplyTableModel replyTableModel;
  DefaultListModel dimTupleListModel;

  public ReplyPane() {
    //setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
    
    //top = new JScrollPanel();
    //add(top);

    /*
    replyLabel = new JLabel("Results for query #" + GlobalVar.queryID);
    replyLabel.setAlignmentX(CENTER_ALIGNMENT);
    replyLabel.setFont(new Font("Default", Font.BOLD, 16));
    top.add(replyLabel);
    */

    //top = new JPanel();
    //add(top);

    dimTupleListModel = new DefaultListModel();
    replyTableModel = new ReplyTableModel(dimTupleListModel);
    replyTable = new JTable(replyTableModel); 
    replyTable.setPreferredScrollableViewportSize(new Dimension(400, 200));
    replyTable.setFont(new Font("Default", Font.BOLD, 14));

    replyTable.setAutoResizeMode(0);

    DefaultTableCellRenderer replyTableRenderer = new DefaultTableCellRenderer();
    replyTableRenderer.setHorizontalAlignment(JLabel.CENTER);

    TableColumn column = null;
    for (int i = 0; i < replyTable.getColumnCount(); i++) {
      column = replyTable.getColumnModel().getColumn(i);
      column.setPreferredWidth(70); //sport column is bigger
      
      column.setCellRenderer(replyTableRenderer);
    }


    replyTableScroll = new JScrollPane(replyTable);
    add(replyTableScroll);
  }
}

class GlobalVar {
  static SetupPane setupPane;
  static CreateSubPane createSubPane;
  static InsertSubPane insertSubPane;
  static QueryPane queryPane;
  static Catalog dbCatalog;
  static QueryTableModel queryTableModel;
  static JTable queryTable;
  static DefaultListModel availAttrListModel;
  static DefaultListModel indexedAttrListModel;
  static int queryID;
  static ArrayList queryArrayList;
  static MoteIF mote;
  static String curState;
  static int samplePeriod;
}

public class gui extends JPanel {
  ImageIcon setupIcon;
  ImageIcon queryIcon;
  JTabbedPane tabbedPane;
  ConsoleListener consoleListener;
  
  public gui() {
    GlobalVar.dbCatalog = new Catalog("/home/xinl/tinyos-1.x/tools/java/net/tinyos/tinydb/catalog.xml");

    ImageIcon setupIcon = new ImageIcon("configure2.png");
    ImageIcon queryIcon = new ImageIcon("find2.png");
        
    tabbedPane = new JTabbedPane();

    GlobalVar.setupPane = new SetupPane();
    tabbedPane.addTab("SETUP", setupIcon, GlobalVar.setupPane, "Configure DIM Index");
    tabbedPane.setSelectedIndex(0);

    GlobalVar.queryPane = new QueryPane();
    tabbedPane.addTab("QUERY", queryIcon, GlobalVar.queryPane, "Issue Queries");

    setLayout(new GridLayout(1, 1)); 
    add(tabbedPane);

    GlobalVar.queryID = 0;
    GlobalVar.queryArrayList = new ArrayList();

    try {
      GlobalVar.mote = new MoteIF(PrintStreamMessenger.err, ConsoleConstant.GROUP_ID);
    } catch (Exception e) {
      e.printStackTrace();
      System.exit(-1);
    }
    
    consoleListener = new ConsoleListener(); 
  }

  public static void main(String[] args) {
    JFrame frame = new JFrame("DIM Demo GUI");
    GlobalVar.curState = new String("NULL");
    GlobalVar.samplePeriod = 0;
    final String fn = "DIM.state";

    frame.addWindowListener(new WindowAdapter() {
      public void windowClosing(WindowEvent e) {
        FileWriter sfw;
        DimQueryField dimQueryField;

        try {
          sfw = new FileWriter(fn);
          
          sfw.write(GlobalVar.curState + "\n");
          if (GlobalVar.curState.equals("CREATE") || 
              GlobalVar.curState.equals("START") || 
              GlobalVar.curState.equals("STOP")) {
            sfw.write(GlobalVar.samplePeriod + "\n");
            int attrNum = GlobalVar.indexedAttrListModel.getSize();
            sfw.write(attrNum + "\n");
            for (int i = 0; i < attrNum; i ++) {
              dimQueryField = (DimQueryField)GlobalVar.indexedAttrListModel.getElementAt(i);
              sfw.write(dimQueryField.queryField.getName() + "\n");
              sfw.write(dimQueryField.queryField.getType() + "\n");
              sfw.write((int)dimQueryField.queryField.getMinVal() + "\n");
              sfw.write((int)dimQueryField.queryField.getMaxVal() + "\n");
              sfw.write((int)dimQueryField.userMin + "\n");
              sfw.write((int)dimQueryField.userMax + "\n");
              sfw.write(dimQueryField.attrId + "\n");
              sfw.write(dimQueryField.selected + "\n");
            }
          }
          sfw.close();
        } catch (IOException ex) {
          System.err.println("Cannot write to file " + fn);
        }
        System.exit(0);
      }
    });

    FileReader sfr;
    BufferedReader br;
    String s;
    
    try {
      sfr = new FileReader(fn);
    } catch (FileNotFoundException ex) {
      sfr = null;
    }

    if (sfr != null) {
      br = new BufferedReader(sfr);
      String attrName;
      byte attrType;
      int min, max, userMin, userMax;
      short attrId;
      boolean selected;
      DimQueryField dimQueryField;

      try {
        GlobalVar.curState = new String(br.readLine());
        if (!GlobalVar.curState.equals("NULL")) {
          GlobalVar.samplePeriod = Integer.parseInt(br.readLine());
          GlobalVar.indexedAttrListModel = new DefaultListModel();
          int attrNum = Integer.parseInt(br.readLine());
          for (int i = 0; i < attrNum; i ++) {
            attrName = br.readLine();
            attrType = (byte)Integer.parseInt(br.readLine());
            min = Integer.parseInt(br.readLine());
            max = Integer.parseInt(br.readLine());
            userMin = Integer.parseInt(br.readLine());
            userMax = Integer.parseInt(br.readLine());
            attrId = (short)Integer.parseInt(br.readLine());
            selected = Boolean.getBoolean(br.readLine());
            dimQueryField = new DimQueryField(new QueryField(attrName, attrType, min, max), selected);
            dimQueryField.userMin = userMin;
            dimQueryField.userMax = userMax;
            dimQueryField.attrId = attrId;
            //dimQueryField.selected = selected;
            GlobalVar.indexedAttrListModel.addElement(dimQueryField);
          }
        }
        sfr.close();
      } catch (IOException ex) {
        System.err.println("Cannot read from file " + fn);
        System.exit(-1);
      }
    }
      
    frame.getContentPane().add(new gui(), 
                               BorderLayout.CENTER);
    //frame.setSize(400, 125);
    frame.pack();
    frame.setVisible(true);
    frame.setResizable(false);
  }
}

class ConsoleConstant {
  public static final byte CONSOLE_QUERY = 2;
  public static final byte CONSOLE_QUERY_REPLY = 3;
  public static final byte CONSOLE_CREATE = 6;
  public static final byte CONSOLE_CREATE_REPLY = 7;
  public static final byte CONSOLE_DROP = 8;
  public static final byte CONSOLE_START = 10;
  public static final byte CONSOLE_STOP = 12;
  public static final short TOS_BCAST_ADDR = (short) 0xffff;
  public static final byte MSG_SIZE = 49; // Consistent with TinyDB's message size
  public static final short MOTE_ID = TOS_BCAST_ADDR;
  public static final byte GROUP_ID = 0x0a;
  public static final short MAX_ATTR_NAME_LEN = 9;
  public static final short ATTR_NUM_PER_MSG = 5;
  public static final int CONSOLE_AM_TYPE = 78;
}

class ConsoleCreate implements Runnable {
  short attrNum;
  ConsoleCreateMsg createMsg;
  ArrayList msgArray;
  Thread thread;
  
  public ConsoleCreate() {
    attrNum = (short)(GlobalVar.indexedAttrListModel.getSize());
    createMsg = new ConsoleCreateMsg();
    msgArray = new ArrayList();
    String attrStr;

    short i = 0;
    byte attrName[][] = new byte[ConsoleConstant.ATTR_NUM_PER_MSG][ConsoleConstant.MAX_ATTR_NAME_LEN];
    
    createMsg.set_mode(ConsoleConstant.CONSOLE_CREATE);
    createMsg.set_totalNum(attrNum);

    while (i < attrNum) {
      createMsg.set_beginNum(i);
      for (; i < createMsg.get_beginNum() + ConsoleConstant.ATTR_NUM_PER_MSG && i < attrNum; i ++) {

        attrStr = new String(GlobalVar.indexedAttrListModel.getElementAt(i).toString());

        System.err.println("Sending attribute " + attrStr + ": " + attrStr.length());

        attrName[i - createMsg.get_beginNum()] = attrStr.getBytes();
      }
      createMsg.set_attrName(attrName);
      createMsg.set_endNum((short)(i - 1));
      msgArray.add(createMsg);
    }
    thread = new Thread(this, "ConsoleCreate");
    thread.start();
  }

  public void run() {
    //ConsoleCreateMsg createMsg;
    try {
      //MoteIF mote = new MoteIF(PrintStreamMessenger.err, ConsoleConstant.GROUP_ID);
      for (int i = 0; i < msgArray.size(); i ++) {
        createMsg = (ConsoleCreateMsg)(msgArray.get(i));
        System.err.print("Sending payload: ");
        for (int j = 0; j < createMsg.dataLength(); j++) {
          System.err.print(Integer.toHexString(createMsg.dataGet()[j] & 0xff)+ " ");
        }
        GlobalVar.mote.send(ConsoleConstant.MOTE_ID, createMsg);
        Thread.sleep(1000);
      }
    } catch (Exception e) {
      e.printStackTrace();
      System.exit(-1);
    }
  }
}

class ConsoleListener implements Runnable, MessageListener {
  Thread thread;
  //MoteIF mote;

  public ConsoleListener() {
    thread = new Thread(this, "ConsoleListener");
    thread.start();
  }

  public void run() {
    //ConsoleCmdInject receiver = new ConsoleCmdInject();
    try {
      //mote = new MoteIF(PrintStreamMessenger.err, ConsoleConstant.GROUP_ID);
      GlobalVar.mote.registerListener(new ConsoleReplyMsg(), this);
      //mote.registerListener(msg, this);
      System.err.println("Message listener registered to group " + ConsoleConstant.GROUP_ID);
    } catch (Exception e) {
      e.printStackTrace();
      System.exit(-1);
    }
  }

  public void messageReceived(int dest_addr, Message msg) {
    System.err.print("Receiving payload: ");
    for (int j = 0; j < msg.dataLength(); j++) {
      System.err.print(Integer.toHexString(msg.dataGet()[j] & 0xff)+ " ");
    }
    System.err.println();

    if (msg instanceof ConsoleReplyMsg) {
      ConsoleReplyMsg reply = (ConsoleReplyMsg)msg;
      if (reply.get_mode() == ConsoleConstant.CONSOLE_CREATE_REPLY) {
        System.err.print("Received create reply: _" + reply.get_sender() + "_ " + "-n " + reply.get_queryId() + " ");
        System.err.print("-a ");
        for (int i = 0; i < reply.get_queryId(); i ++) {
          DimQueryField dimQueryField = (DimQueryField)(GlobalVar.indexedAttrListModel.getElementAt(i));
          dimQueryField.attrId = (short)(reply.getElement_value(i));
          System.err.print(reply.getElement_value(i) + " ");
        }
        System.err.println();
        GlobalVar.curState = "CREATE";
      } else if (reply.get_mode() == ConsoleConstant.CONSOLE_QUERY_REPLY) {
        // A reply message contains a single tuple.
        int attrNum = (short)(GlobalVar.indexedAttrListModel.getSize());
        int queryId = reply.get_queryId();
        ArrayList dimTuple = new ArrayList();
        dimTuple.add(new Integer(reply.get_sender()));
        dimTuple.add(new Integer(reply.get_detector()));
        dimTuple.add(new Long(reply.get_timehi()));
        dimTuple.add(new Long(reply.get_timelo()));
        for (int i = 0; i < attrNum; i ++) {
          dimTuple.add(new Integer(reply.getElement_value(i)));
        }
        ReplyPane replyPane = (ReplyPane)(GlobalVar.queryArrayList.get(queryId));
        replyPane.dimTupleListModel.addElement(dimTuple);
        TableModelEvent replyTableModelEvent = new TableModelEvent(replyPane.replyTableModel);
        replyPane.replyTable.tableChanged(replyTableModelEvent);
      }
      //System.exit(0);
    } else {
      System.err.println("Received unknown message " + msg);
    }
  }
}

class ConsoleDrop implements Runnable {
  ConsoleDropMsg dropMsg;
  Thread thread;
  
  public ConsoleDrop() {
    dropMsg = new ConsoleDropMsg();
    dropMsg.set_mode(ConsoleConstant.CONSOLE_DROP);

    thread = new Thread(this, "ConsoleDrop");
    thread.start();
  }

  public void run() {
    try {
      //MoteIF mote = new MoteIF(PrintStreamMessenger.err, ConsoleConstant.GROUP_ID);
      GlobalVar.mote.send(ConsoleConstant.MOTE_ID, dropMsg);
    } catch (Exception e) {
      e.printStackTrace();
      System.exit(-1);
    }
  }
}

class ConsoleStart implements Runnable {
  ConsoleStartMsg startMsg;
  Thread thread;
  
  public ConsoleStart(byte type, int period) {
    if (type == ConsoleConstant.CONSOLE_START || 
        type == ConsoleConstant.CONSOLE_STOP) {
      startMsg = new ConsoleStartMsg();
      startMsg.set_mode(type);
      startMsg.set_period(period);

      thread = new Thread(this, "ConsoleStart");
      thread.start();
    }
  }

  public void run() {
    try {
      //MoteIF mote = new MoteIF(PrintStreamMessenger.err, ConsoleConstant.GROUP_ID);
      GlobalVar.mote.send(ConsoleConstant.MOTE_ID, startMsg);
    } catch (Exception e) {
      e.printStackTrace();
      System.exit(-1);
    }
  }
}

class ConsoleQuery implements Runnable {
  ConsoleQueryMsg queryMsg;
  short attrNum;
  Thread thread;
  
  public ConsoleQuery(int qid) {
    queryMsg = new ConsoleQueryMsg();
    queryMsg.set_mode(ConsoleConstant.CONSOLE_QUERY);
    queryMsg.set_queryId(qid);
    attrNum = 0;
    
    int indexedAttrNum = GlobalVar.indexedAttrListModel.getSize();
    DimQueryField dimQueryField;
    for (int i = 0; i < indexedAttrNum; i ++) {
      dimQueryField = (DimQueryField)(GlobalVar.indexedAttrListModel.getElementAt(i));
      if (dimQueryField.selected) {
        queryMsg.setElement_queryField_lowerBound(attrNum, (int)(dimQueryField.userMin));
        queryMsg.setElement_queryField_upperBound(attrNum, (int)(dimQueryField.userMax));
        queryMsg.setElement_queryField_attrId(attrNum, dimQueryField.attrId);
        attrNum ++;
      }
    }
    queryMsg.set_attrNum(attrNum);

    thread = new Thread(this, "ConsoleQuery");
    thread.start();
  }

  public void run() {
    //ConsoleCreateMsg createMsg;
    try {
      //MoteIF mote = new MoteIF(PrintStreamMessenger.err, ConsoleConstant.GROUP_ID);
      GlobalVar.mote.send(ConsoleConstant.MOTE_ID, queryMsg);
    } catch (Exception e) {
      e.printStackTrace();
      System.exit(-1);
    }
  }
}
