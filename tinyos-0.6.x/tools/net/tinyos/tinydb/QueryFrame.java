/*
 * QueryFrame.java
 * Main class to allow users to build and distribute queries over the network...
 * Created on May 21, 2002, 10:16 AM
 */

/**
 *
 * @author  madden
 */

package net.tinyos.tinydb;

import net.tinyos.amhandler.*;

import java.awt.*;
import javax.swing.*;
import java.awt.event.*;
import java.util.*;
import javax.swing.border.*;
import java.io.*;

import net.tinyos.tinydb.awtextra.*;
import net.tinyos.tinydb.topology.*;

public class QueryFrame extends JFrame  {

    /** Creates new form QueryFrame */
    public QueryFrame(TinyDBNetwork nw) {

	this.nw = nw;

	//init ui
	initComponents();
    }

    //construct the UI
    private void initComponents() {
        sendQueryButton = new JButton();
	displayTopologyButton = new JButton();
	magnetDemoButton = new JButton("Mag. Demo");

        selectGroupPanel = new JPanel();

        groupByPanel = new JPanel();
        groupCheckBox = new JCheckBox();
        groupLabel = new JLabel();
        groupBox = new JComboBox();
	groupBox.setLightWeightPopupEnabled(false);
	addFieldsToMenu(groupBox);

	attenuationBox = new JComboBox(attens);
	attenuationBox.setLightWeightPopupEnabled(false);
	aggregateBox = new JComboBox();
	addAggsToMenu(aggregateBox);
	epochBox = new JComboBox();
	epochBox.setLightWeightPopupEnabled(false);
	addEpochsToMenu(epochBox);
        newPredButton = new JButton();
        selectSrcList = new JList();
        selectDestList = new JList();
        removeSelButton = new JButton();
        addSelButton = new JButton();
        selectFieldsLabel = new JLabel();
        selectedLabel = new JLabel();
	sqlString = new JTextArea();
	sqlString.setLineWrap(true);
	sqlString.setEditable(false);
        sqlString.setBorder(new LineBorder(new java.awt.Color(0, 0, 0)));
	logoLabel = new JLabel(new ImageIcon("images/tinydblogo.jpg"));

        jSeparator2 = new JSeparator();

        getContentPane().setLayout(new AbsoluteLayout());

	//        getContentPane().setBackground(java.awt.Color.white);
        addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent evt) {
                exitForm(evt);
            }
        });

        sendQueryButton.setText("Send Query");
        getContentPane().add(sendQueryButton, new AbsoluteConstraints(490, 5, -1, 30));
	sendQueryButton.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent evt) {
		    
		    byte qid = allocateQID();

		    TinyDBQuery curQuery = generateQuery(qid, epochDur);
		    if (curQuery == null)
		      return;
		    updateSQL();
		    curQuery.setSQL(sqlString.getText());
		    if (curQuery != null) {
			ResultFrame rf = new ResultFrame(curQuery, nw);


			TinyDBMain.notifyAddedQuery(curQuery);

			rf.show();
			if (resultWins.size() <= (qid + 1))
			    resultWins.setSize(qid+1);
			resultWins.setElementAt(rf,qid);
			nw.sendQuery(curQuery);
		    }
		}
	    });

        displayTopologyButton.setText("Display Topology");
        getContentPane().add(displayTopologyButton, new AbsoluteConstraints(490, 45, -1, 30));
	final QueryFrame queryFrame = this;
	displayTopologyButton.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent evt) {
		    
		    if (topologyWindowUp)
			return;
		    try
			{
			    topologyFrame = new MainClass(nw, allocateQID());
			}
		    catch (Exception e)
			{
			}
		}
	    });
	

	getContentPane().add(magnetDemoButton, new AbsoluteConstraints(490, 80, -1, 30));
	magnetDemoButton.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    byte qid = allocateQID();
		    MagnetFrame mf = new MagnetFrame(qid, nw);
		    mf.show();
		    if (resultWins.size() <= (qid + 1))
			resultWins.setSize(qid+1);
		    resultWins.setElementAt(mf,qid);

		}
	    });

        selectGroupPanel.setLayout(new java.awt.GridLayout(3, 0, 5, 5));
	//        selectGroupPanel.setBackground(java.awt.Color.white);
        selectGroupPanel.setBorder(new BevelBorder(BevelBorder.LOWERED));

        groupByPanel.setLayout(new AbsoluteLayout());

	//        groupByPanel.setBackground(java.awt.Color.white);

	groupBox.setEnabled(false);
	oldGroup = groupBox.getSelectedItem();
	groupBox.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent evt) {
		  if (oldGroup != groupBox.getSelectedItem()) {
		    if (!checkSelectionConsistency(selectDestList,null)) {
		      groupBox.setSelectedItem(oldGroup);
		    } else {
		      oldGroup = groupBox.getSelectedItem();
		      selectSrcListAction(); //update the possible choices of aggregate functions....
		    }
		  }
		}
	    });

	groupLabel.setEnabled(false);

	//        groupCheckBox.setBackground(java.awt.Color.white);


	groupCheckBox.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent evt) {
		    groupCheckBoxAction(evt);
		}
	    });



        groupByPanel.add(groupCheckBox, new AbsoluteConstraints(10, 0, 20, 30));
	

        groupLabel.setText("GROUP BY");
        groupByPanel.add(groupLabel, new AbsoluteConstraints(30, 0, 100, 30));

        groupByPanel.add(groupBox, new AbsoluteConstraints(130, 0, 120, 30));
	JLabel shiftLabel = new JLabel(">>");
	shiftLabel.setEnabled(false);
	
	attenuationBox.setEnabled(false);
	attenuationBox.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent evt) {
		    updateSQL();
		}
	    });
					 
	groupByPanel.add(shiftLabel,new AbsoluteConstraints(250,5, -1,-1));
	groupByPanel.add(attenuationBox, new AbsoluteConstraints(270,0, 70, 30));

	getContentPane().add(groupByPanel, new AbsoluteConstraints(0,280, 480, 30));

			     //        selectGroupPanel.add(groupByPanel);

        getContentPane().add(selectGroupPanel, new AbsoluteConstraints(0, 320 , 480, 110));

        newPredButton.setText("New Predicate");
        newPredButton.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent evt) {
		    newPredButtonActionPerformed(evt);
		}
	    });
	
        getContentPane().add(newPredButton, new AbsoluteConstraints(490, 320, 130, 30));

        selectSrcList.setBorder(new LineBorder(new java.awt.Color(0, 0, 0)));
        selectSrcList.setMinimumSize(new java.awt.Dimension(100, 100));
		JScrollPane srcScroller = new JScrollPane(selectSrcList);
		selectSrcList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        getContentPane().add(srcScroller, new AbsoluteConstraints(20, 60, 160, 150));
		addSelectChoices(selectSrcList);
		selectSrcList.addMouseListener(new MouseAdapter() {
		public void mouseClicked(MouseEvent evt) {
		    selectSrcListAction();
		}
	    });



        selectDestList.setBorder(new LineBorder(new java.awt.Color(0, 0, 0)));
		JScrollPane destScroller = new JScrollPane(selectDestList);
		selectDestList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        getContentPane().add(destScroller, new AbsoluteConstraints(320, 60, 160, 150));

        removeSelButton.setText("<<<");
        removeSelButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent evt) {
                removeSelButtonActionPerformed(evt);
            }
        });

        getContentPane().add(removeSelButton, new AbsoluteConstraints(210, 155, -1, -1));

        addSelButton.setText(">>>");
        addSelButton.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent evt) {
                addSelButtonActionPerformed(evt);
            }
        });

        getContentPane().add(addSelButton, new AbsoluteConstraints(210, 125, -1, -1));

	getContentPane().add(aggregateBox, new AbsoluteConstraints(190, 90, 120,30));
	

	
	JLabel epochsLabel = new JLabel();
	epochsLabel.setText("Epoch Duration");
	getContentPane().add(epochsLabel, new AbsoluteConstraints(20, 5, 120, 20));
	
	getContentPane().add(epochBox, new AbsoluteConstraints(140 , 5 ,120,30));
	epochBox.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent evt) {
		    epochDur = (short)((Integer)epochBox.getSelectedItem()).intValue();
		    updateSQL();
		}
		
	    });

        selectFieldsLabel.setText("Available Attributes");
        getContentPane().add(selectFieldsLabel, new AbsoluteConstraints(20, 40, 140, 20));

        selectedLabel.setText("Projected Attributes");
        getContentPane().add(selectedLabel, new AbsoluteConstraints(320, 40, 150, 20));
        getContentPane().add(jSeparator2, new AbsoluteConstraints(-10, 30, 600, 0));

	getContentPane().add(sqlString, new AbsoluteConstraints(20, 220, 460, 55));
	updateSQL();

	getContentPane().add(logoLabel, new AbsoluteConstraints(490, 120, 128, 108));
			     

        pack();
    }



    /** Called when the "-" button to remove a where clause is pressed */
    public void removeWhereButtonActionPerformed(ActionEvent evt, int panelId) {
      boolean removed = false;
      for (int i = 0; i < panels.length; i++) {
	if (!removed) {
	  if (panels[i] != null && panels[i].getId() == panelId) {
	    numPanels--;
	    selectGroupPanel.remove(panels[i]);

	    panels[i] = null;
	    removed = true;
	    validate();
	  } 
	} else {
	  if (panels[i] != null) panels[i].setId(panels[i].getId() - 1);
	  panels[i-1] = panels[i];
	  panels[i] = null;
	}
      }
      repaint();
      updateSQL();
    }

    /** Called when the "<<<" to remove a selection attribute is clicked */
    private void removeSelButtonActionPerformed(ActionEvent evt) {
      Object value = selectDestList.getSelectedValue();
      if (value != null) {
	Vector values = new Vector();
	ListModel model = selectDestList.getModel();
	for (int i = 0; i < model.getSize(); i++) {
	  if(model.getElementAt(i) != value)
	    values.addElement(model.getElementAt(i));
	}
	selectDestList.setListData(values);
      }      
      updateSQL();
    }


    /** Called when the ">>>" to add a selection attribute is clicked */
    private void addSelButtonActionPerformed(ActionEvent evt) {
      QueryField value = (QueryField)selectSrcList.getSelectedValue();
      AggOp op;

      if (aggregateBox.getSelectedItem().toString().equals("None"))
	op = null;
      else
	op = (AggOp)aggregateBox.getSelectedItem();
      
      if (value != null) {
	SelectionField sf = new SelectionField(op, value);
	if (op == null || checkSelectionConsistency(selectDestList,sf)) {
	  Vector values = new Vector();
	  ListModel model = selectDestList.getModel();
	  for (int i = 0; i < model.getSize(); i++) {
	    values.addElement(model.getElementAt(i));
	  }
	  values.addElement(sf);
	  selectDestList.setListData(values);
	}
      }
      updateSQL();
    }

    int oldIdx = -1;
    boolean oldGrouping = false;
    int oldGroupIdx = -1;


    /** Called when something happens in the attribute selection list --
	main goal is to constrain the aggregate operations menu so that
	only valid aggregate choices are available.
    */
    private void selectSrcListAction() {
	int idx = selectSrcList.getMinSelectionIndex();
	boolean grouping = groupCheckBox.isSelected();
	int groupIdx = groupBox.getSelectedIndex();

	if (idx != oldIdx || grouping != oldGrouping || oldGroupIdx != groupIdx) {
	    oldIdx = idx;
	    oldGroupIdx = groupIdx;
	    oldGrouping = grouping;

	    updateSQL();

	    constrainAggMenu(aggregateBox, grouping, groupIdx == idx, hasAgg());
	}
    }

    /** Limit the items available in the aggregation menu based
	on whether we're grouping or not
    */
    private void constrainAggMenu(JComboBox menu, boolean grouping, boolean groupbyField,  boolean hasAgg) {
	menu.removeAllItems();

	for (int i = 0; i < aggs.length; i++) {
	    if (grouping && groupbyField) { //must not be an agg
		if (aggs[i] == null) 
		    menu.addItem("None");
	    } else {
		if (hasAgg || grouping) { //must be an agg
		    if (aggs[i] != null)
			menu.addItem(aggs[i]);
		} else {
		    if (aggs[i] == null)
			menu.addItem("None");
		    else
			menu.addItem(aggs[i]);
		}
	    }
	}
    }


    
    /** Called when the grouping check box is selected / deselected
	Have to make sure that this is OK (can't have agg / non agg fields in same
	if not grouping.
    */
    private void groupCheckBoxAction(ActionEvent evt) {
	if (groupCheckBox.isSelected()) { //user selected the box
	  if (checkSelectionConsistency(selectDestList,null)) {
	    groupBox.setEnabled(true);
	    groupLabel.setEnabled(true);
	    attenuationBox.setEnabled(true);
	  } else {
	    groupCheckBox.setSelected(false);
	  }
	} else { //user deselected the box
	  if (checkSelectionConsistency(selectDestList,null)) {
	    groupBox.setEnabled(false);
	    groupLabel.setEnabled(false);
	    attenuationBox.setEnabled(false);
	  } else {
	    groupCheckBox.setSelected(true);
	  }
	}

	//update the aggregate operators available for the current source selection
	selectSrcListAction();

	//refresh the SQL clause to reflect this change
	updateSQL();
    }


    //User added a selection predicate -- create the new panel (if there's a slot for it.)
    private void newPredButtonActionPerformed(ActionEvent evt) {
	JPanel newPanel = null;
	
	if (numPanels < 3) {
	  newPanel = new WherePanel(numPanels, this);
	  panels[numPanels++] = (WherePanel)newPanel;
	} else {
	    setError("At most three selection predicates allowed per query.");
	}

	if (newPanel != null) {
	    selectGroupPanel.add(newPanel);

	    validate();
	}


	repaint();
	updateSQL();
    }


    /** Add the available query fields (from the catalog) to the menu */
    public void addFieldsToMenu(JComboBox menu) {
	for (int i = 0; i < c.numAttrs(); i++) {
	    menu.addItem(c.getAttr(i));
	}
    }

    /** Add the available selection operators to the specified menu */
    public void addOpsToMenu(JComboBox menu) {
	for (int i = 0; i < ops.length; i++) {
	    menu.addItem(ops[i]);
	}
    }

    /** Add the vailable aggregate operators to the specified menu */
    private void addAggsToMenu(JComboBox menu) {
	for (int i = 0; i < aggs.length; i++) {
	    if (aggs[i] == null)
		menu.addItem("None");
	    else
		menu.addItem(aggs[i]);
	}	
    }

    /** Add the available epoch durations to the menu */
    private void addEpochsToMenu(JComboBox menu) {
	int es[] = {64,128,256,512,1024,2048,4096,8192,16384};
	for (int i =0 ; i < es.length; i++)
	    menu.addItem(new Integer(es[i]));
	menu.setSelectedIndex(5);
    }


    /** Add the available selection attributes to the specific list */
    private void addSelectChoices(JList list) {
	Vector fields = new Vector();

	for (int i = 0; i < c.numAttrs(); i++) {
	    fields.add(c.getAttr(i));
	}
	
	list.setListData(fields);

    }

    /** Given a list of current attrs in the query and a (possibly null) attr to add
	to that list, return true iff the addition is OK (or newf == null) AND 
	the current settings (e.g. grouping, group by field, etc) are consistent.
	
	Return false otherwise.
	
	This is used extensively to determine if some user action produces a consistent
	query.  It sets appropriate error messages when consistency checks fail.
    */
    public boolean checkSelectionConsistency(JList list, SelectionField newf) {
	
      //is an agg -- check and see if there are any non-aggs in the list
      //if so, if we aren't grouping by them, ask the user what to do
      //if user wants to remove them, do so
      //otherwise, return false
      
      ListModel model = list.getModel();
      boolean hasAgg = hasAgg();
      boolean newAgg = newf != null && newf.getOp() != null;

      for (int i = 0; i < model.getSize(); i ++) {
	SelectionField sf = (SelectionField)model.getElementAt(i);
	boolean isGroupField = groupCheckBox.isSelected() && groupBox.getSelectedItem() == sf.getField();

	if (groupCheckBox.isSelected() && sf.getOp() == null && !isGroupField) {
	  setError("Can't group if a non-aggregate field is present");
	  return false;
	} else if (hasAgg && sf.getOp() == null && !isGroupField) {
	  setError("Can't have non-aggregate field when other aggregates are present");
	  return false;
	} else if ((!hasAgg && !isGroupField)  && (sf.getOp() != null || newAgg)) {
	  setError("Can't have aggregate field when non-aggregates are present");
	  return false;
	} 
	//else if (hasAgg && newAgg) {
	//	    setError("Only one aggregate allow per query in current implementation.");
	//	    return false;
	//	}
      }
      return true;
    }

  //check and see if there are any aggs in the selection list
  public boolean hasAgg() {
    ListModel model = selectDestList.getModel();
    for (int i = 0; i < model.getSize(); i++) {
      SelectionField sf = (SelectionField)model.getElementAt(i);
      if (sf.getOp() != null) return true;
    }
    return false;
  }

  public void setError(String txt) {
    sqlString.setText(txt);
    setError = true;
  }

    /** Generate a SQL string for the current query */
  public void updateSQL() {
    String sql = "SELECT ";
    boolean first = true;

    if(setError) {
      setError = false;
      return;
    }

    ListModel model = selectDestList.getModel();

    if (model.getSize() == 0) {
      sql = "Query must SELECT at least one attribute.";
    } else {
      for (int i = 0; i < model.getSize(); i++) {
	SelectionField sf = (SelectionField)model.getElementAt(i);
	if (first) {
	  sql += "s." + sf.toString();
	  first = false;
	}      else
	  sql += ", s." + sf.toString();
      }
      sql += " FROM sensors AS s";
      first = true;
      for (int i = 0; i < panels.length; i++) {
	if (panels[i] != null) {
	  if (first) {
	    sql += "\nWHERE s." + panels[i].toString();
	    first = false;
	  } else {
	    sql += " AND s." + panels[i].toString();
	  }
	    
	}
      }
      
      if (groupCheckBox.isSelected()) {
	  Integer atten = (Integer)attenuationBox.getSelectedItem();

	sql += "\nGROUP BY ";
	if (atten.intValue() == 0) 
	    sql += groupBox.getSelectedItem().toString();
	else
	    sql += "(" + groupBox.getSelectedItem().toString() + ">>" + atten + ")";
      }

      sql += "\nEPOCH DURATION " + epochDur;
      
    }
    sqlString.setText(sql);

  }
    

    
    /** Generate a TinyDBQuery to represent the currently selected query
	fields
    */
  TinyDBQuery generateQuery(byte queryId, short epochDur) {
    ListModel model = selectDestList.getModel();
    TinyDBQuery query = new TinyDBQuery(queryId, epochDur);
    HashMap fields = new HashMap();
    boolean grouping = groupCheckBox.isSelected();
    QueryField qf, groupByField = (QueryField)groupBox.getSelectedItem();
    short groupIdx = -1 ;

    if (model.getSize() == 0)
      return null;

    if (!checkSelectionConsistency(selectDestList, null)) return null;


    //all select fields must be presents
    for (int i = 0; i < model.getSize(); i++) {
      SelectionField sf = (SelectionField)model.getElementAt(i);
      if (fields.get(sf.getField().getName()) == null) {
	  fields.put(sf.getField().getName(), sf.getField());
      }
    }
    
    //plus fields used in any where clause
    for (int i = 0; i < panels.length; i++) {
	if (panels[i] != null) {
	    qf = panels[i].getField();
	    if (fields.get(qf.getName()) == null) {
		fields.put(qf.getName(), qf);
	    }
	}
    }

    //plus the field from the group by clause
    if (grouping) {
	if (fields.get(groupByField.getName()) == null) {	    
	    fields.put(groupByField.getName(), groupByField);
	} 
    }

    Iterator fs = fields.values().iterator();
    short idx = 0;
    while (fs.hasNext()) {
	qf = (QueryField)fs.next();
	if (grouping && qf.getName().equals(groupByField.getName())) 
	  groupIdx = idx;
	qf.setIdx(idx++);
	query.addField(qf);
    }

    //add all of the selections
    for (int i = 0; i < panels.length; i++) {
	if (panels[i] != null) {
	    short qfid = ((QueryField)fields.get(panels[i].getField().getName())).getIdx();

	    try {
	      short constant = panels[i].getConstant();

	      SelExpr op = new SelExpr(qfid, panels[i].getOp(), panels[i].getConstant());
	      query.addExpr(op);
	    } catch (NumberFormatException e) {
	      setError ("Selection predicate " + (i + 1) + " is not a valid integer.");
	      return null;
	    }
	}
    }

    //finally, add the aggregate clause, if any
    for (int i = 0; i < model.getSize(); i++) {
      SelectionField sf = (SelectionField)model.getElementAt(i);
      short qfid = ((QueryField)fields.get(sf.getField().getName())).getIdx();
      if (sf.getOp() != null) {
	  AggExpr op = new AggExpr(qfid, sf.getOp(), groupIdx);
	  op.setAttenuation((char)(((Integer)attenuationBox.getSelectedItem()).intValue()));
	  query.addExpr(op);
      }
    }
    
    
    return query;
  }


    /** Exit the Application */
    private void exitForm(WindowEvent evt) {
        System.exit(0);
    }

    /** Allocate a query ID for a new query
	WARNING:  There could be serious problems here 
	on wrap-around.  We aren't dealing with this.
    */
    public byte allocateQID()
    {
	return curId++;
    }
    

    private int numSelects = 0;
    public static boolean topologyWindowUp = false;
    private MainClass topologyFrame;
    
    private JList selectDestList;
    private JPanel groupByPanel;
    
    private JButton removeSelButton;
    private JSeparator jSeparator2;
    private JPanel selectGroupPanel;
    
    private JLabel groupLabel;
    private JLabel logoLabel;
    private JButton newPredButton;
    private JButton sendQueryButton;
    private JButton displayTopologyButton;
    private JButton magnetDemoButton;
    
    private JComboBox groupBox;
    private JComboBox epochBox;
    private JComboBox attenuationBox;

    private JComboBox aggregateBox;
    private JLabel selectedLabel;
    private JButton addSelButton;
    private JLabel selectFieldsLabel;
    private JTextArea sqlString;
    private JList selectSrcList;
    private JCheckBox groupCheckBox;

    private SelOp eq = new SelOp(SelOp.OP_EQ);
    private SelOp neq = new SelOp(SelOp.OP_NEQ);
    private SelOp gt = new SelOp(SelOp.OP_GT);
    private SelOp ge = new SelOp(SelOp.OP_GE);
    private SelOp lt = new SelOp(SelOp.OP_LT);
    private SelOp le = new SelOp(SelOp.OP_LE);

    private AggOp min = new AggOp(AggOp.AGG_MIN);
    private AggOp max = new AggOp(AggOp.AGG_MAX);
    private AggOp sum = new AggOp(AggOp.AGG_SUM);
    private AggOp avg = new AggOp(AggOp.AGG_AVERAGE);
    private AggOp cnt = new AggOp(AggOp.AGG_COUNT);

    private SelOp ops[] = {eq,neq,gt,ge,lt,le};
    private AggOp aggs[] = {null, min,max,sum,avg,cnt};
    private Integer attens[] = {new Integer(0),
				new Integer(1),
				new Integer(2),
				new Integer(3),
				new Integer(4),
				new Integer(5),
				new Integer(6),
				new Integer(7),
				new Integer(8),
				new Integer(9),
				new Integer(10)};

    Catalog c = new Catalog("catalog");
    int numPanels = 0;
    WherePanel panels[] = new WherePanel[3];
    boolean setError = false;
    Object oldGroup;

    short epochDur = 2048;

    byte curId = 0;


    Vector resultWins = new Vector();
    boolean sendingQuery = false;
    
    TinyDBNetwork nw;

}

  class SelectionField {
    public SelectionField(AggOp op, QueryField field) {
      this.op = op;
      this.field = field;
    }
    
    public AggOp getOp() {
      return op;
    }

    public QueryField getField() {
      return field;
    }
    
    public String toString() {
      if (op == null)
	return field.toString();
      else 
	return op.toString() + "(" + field.toString() + ")";
	     
    }

    AggOp op;
    QueryField field;
  }


class WherePanel extends JPanel {
    //build a selection panel
    public WherePanel(int panelId, QueryFrame parent) {

      this.panelId = panelId;
      this.parent = parent;
      constantField = new JTextField();
      innerPanel = new JPanel();
      whereLabel = new JLabel();
      attributeBox = new JComboBox();
      attributeBox.setLightWeightPopupEnabled(false);
      parent.addFieldsToMenu(attributeBox);
      opBox = new JComboBox();
      opBox.setLightWeightPopupEnabled(false);
      parent.addOpsToMenu(opBox);
      removeWhereButton = new JButton();

      setLayout(new AbsoluteLayout());
      
      //      setBackground(java.awt.Color.white);
      innerPanel.setLayout(new AbsoluteLayout());
      
      //      innerPanel.setBackground(java.awt.Color.white);
      whereLabel.setHorizontalAlignment(SwingConstants.CENTER);
      whereLabel.setText("WHERE");
      
      innerPanel.add(whereLabel, new AbsoluteConstraints(30, 10, -1, -1));
      innerPanel.add(attributeBox, new AbsoluteConstraints(80, 0, 120, 30));
      innerPanel.add(opBox, new AbsoluteConstraints(210, 0, 60, 30));
      
      constantField.addActionListener(new ActionListener() {
	  public void actionPerformed(ActionEvent evt) {
	    constantFieldActionPerformed(evt);
	  }
        });
      
      innerPanel.add(constantField, new AbsoluteConstraints(280, 0, 120, 30));
      add(innerPanel, new AbsoluteConstraints(0, 0, 420, 30));
      removeWhereButton.setText("-");
      removeWhereButton.setToolTipText("Delete This Predicate");
      removeWhereButton.addActionListener(new ActionListener() {
	  public void actionPerformed(ActionEvent evt) {
	    removeWhereButton(evt);
	  }
        });
      
      add(removeWhereButton, new AbsoluteConstraints(420, 0, 50, 30));
    }
  
  private void removeWhereButton(ActionEvent evt) {
    parent.removeWhereButtonActionPerformed(evt,this.panelId);
  }

    private void constantFieldActionPerformed(ActionEvent evt) {
	System.out.println("hi there");
    }

  public String toString() {
      return attributeBox.getSelectedItem().toString() + " " + opBox.getSelectedItem().toString() + " " + constantField.getText();
  }


    public QueryField getField() {
	return (QueryField)attributeBox.getSelectedItem();
    }

    public SelOp getOp() {
	return (SelOp)opBox.getSelectedItem();
    }

    public short getConstant() throws NumberFormatException {
      Short constant = new Short(constantField.getText());
      return constant.shortValue();

    }

  public void setId(int id) {
    panelId = id;
  }

  public int getId() {
    return panelId;
  }

  JPanel innerPanel;
  JLabel whereLabel;
  JComboBox opBox;
  JComboBox attributeBox;
  JTextField constantField;
  JButton removeWhereButton;

  int panelId;

  QueryFrame parent;
}
