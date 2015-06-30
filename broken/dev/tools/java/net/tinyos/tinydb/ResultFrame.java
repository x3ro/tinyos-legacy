package net.tinyos.tinydb;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;
import javax.swing.table.*;
import net.tinyos.amhandler.*;

/** ResultFrame displays a scrolling list with
    results from queries in it, side-by-side with a graph
    of query results when such results are available.
*/
public class ResultFrame extends JFrame implements ResultListener{


    /** Constructor 
	@param query The query this frame represents (used to determine column headings, result format)
	@param nw The TinyDBNetwork object used to retransmit & cancel queries
    */
    public ResultFrame(TinyDBQuery query, TinyDBNetwork nw) {
	this.query = query;
	this.nw = nw;

	initUI();
	nw.addResultListener(this, true, query.getId());
	//	addKeyListener(nw);
    }

    public ResultFrame() { //for subclasses
	
    }

    private void setupGraph(ResultGraph graph) {
	graph.setYRange(0d,1024d);
	graph.setXLabel("Time (s)");
	graph.setYLabel(plotChoices.elementAt(curPlotChoice).toString() + "(Raw Units)");
	graph.setTitle("Time vs. " + plotChoices.elementAt(curPlotChoice).toString());
	graph.setTitleFont("helvetica-bold-24");
	graph.setLabelFont("serif-18");
    }

    /* Create the UI */
    private void initUI() {
	Vector headings = query.getColumnHeadings();

	setTitle ("Query " + query.getId());
	
	getContentPane().setLayout(new BorderLayout());
	getContentPane().setBackground(java.awt.Color.white);

	
	addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent evt) {
                exitForm(evt);
            }
        });

	// determine if we should display a graph
	// graph appears if:
	// 1) nodeid is available as an attribute or
	// 2) query is grouped
	boolean shouldGraph = query.isAgg()?true:false;
	//	if (headings.size() == 3) {	    
	
	for (int i = 1; i < headings.size(); i++) {
	  String h = (String)headings.elementAt(i);

	  System.out.println("headings = " + headings);
	  System.out.println("h = " + h);
	  System.out.println("query = " + query);


	  if ((h.equals("nodeid") && query.numFields() > 1) || query.grouped() && h.equals(query.groupColName())) {
	    nodeIdCol = i;
	    shouldGraph = true;
	  } else {
	    PlotChoice pc = new PlotChoice();
	    
	    pc.idx = i;
	    pc.name = (String)headings.elementAt(i);
	    plotCol = i;
	    curPlotChoice = plotChoices.size();
	    plotChoices.addElement(pc);
	  }
	}
	//	}

	graphing = shouldGraph;
	
	tableModel = new DefaultTableModel(headings, 0);
	resultTable = new JTable(tableModel);
	resultTable.setSize(200,150);
	resultTable.setFont(Font.decode("serif-16"));
	resultTable.getTableHeader().setFont(Font.decode("helvetica-bold-18"));
	scroller = new JScrollPane(resultTable);

	if (shouldGraph) {
	    graphPanel = new JPanel();
	    graphPanel.setLayout(new BorderLayout());
	    
	    graphControlPanel = new JPanel(new GridLayout(1,3));
	    resetButton = new JButton("Reset Graph");
	    resetButton.addActionListener( new ActionListener() {
		    public void actionPerformed(ActionEvent evt) {
			graph.clear(true);
			setupGraph(graph);
			nodeids = new Hashtable();

		    }
		});
	    
	    clearButton = new JButton("Clear Graph");
	    clearButton.addActionListener( new ActionListener() {
		    public void actionPerformed(ActionEvent evt) {
			graph.clear(false);
			graph.setYRange(0d,1024d);
			//nodeids = new Hashtable();
		    }
		});


	    graphOptions = new JComboBox();
	    graphOptions.setLightWeightPopupEnabled(false);
	    graph = new ResultGraph(2);
	    setupGraph(graph);
	    
	    for (int i = 0; i < plotChoices.size(); i++) {
		graphOptions.addItem(plotChoices.elementAt(i));
	    }

	    graphOptions.setSelectedIndex(curPlotChoice);

	    
	    
	    graphControlPanel.add(graphOptions);

	    graphOptions.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent evt) {
		  PlotChoice pc = (PlotChoice)graphOptions.getSelectedItem();
		  if (pc.idx != plotCol) {
		      plotCol = pc.idx;
		      curPlotChoice = graphOptions.getSelectedIndex();
		      graph.clear(true);
		      setupGraph(graph);
		      nodeids = new Hashtable();
		  }
		}
	      });
	    graphOptions.setSize(100,100);

	    graphControlPanel.add(resetButton);
	    graphControlPanel.add(clearButton);


	    graphPanel.add(graphControlPanel, "South");
	    graphPanel.add(graph, "Center");

	    split = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, true);
	    getContentPane().add(split, "Center");
	    
	    split.setTopComponent(scroller);
	    split.setBottomComponent(graphPanel);
	    split.setDividerLocation(350);
	    
	} else {
	    getContentPane().add(scroller, "Center");
	}


	
	bottomPanel = new JPanel(new GridLayout(1,5));
	stopQueryButton = new JButton("Stop Query");

	//stop the query from running
	stopQueryButton.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent evt) {
		    aborted = false; //do this everytime
		    abortQuery();
		}
	    });
	bottomPanel.add(stopQueryButton);
	
	//retransmit the query
	resendQueryButton = new JButton("Resend Query");
	resendQueryButton.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent evt) {
			nw.sendQuery(query);
		}
	    });
	bottomPanel.add(resendQueryButton);
     
	getContentPane().add(bottomPanel, "South");

	JTextArea sqlString = new JTextArea(query.getSQL());
	sqlString.setFont(Font.decode("serif-16"));
	sqlString.setLineWrap(true);
	sqlString.setEditable(false);
	getContentPane().add(sqlString,"North");

	pack();
	
    }

    /** ResultListener method called when a new result for
	this frame's query arrives 
    */
    public void addResult(QueryResult qr) {
	Vector resultVector = qr.resultVector();

	if (qr.epochNo() > epochNo)
	    epochNo = qr.epochNo(); //monotonically increasing

	tableModel.addRow(qr.resultVector());
	resultTable.setRowSelectionInterval(tableModel.getRowCount()-1,tableModel.getRowCount()-1);

	JScrollBar bar = scroller.getVerticalScrollBar();	
	if (bar != null) {
	    bar.setValue(bar.getMaximum() + 128);
	}

	//update the graph with the new result (if we are graphing)
	if (graphing) {

	    try { //add the label for the result to the graph key
	    Integer idx = null; 
	    if (nodeIdCol != -1) {
	      String nodeIdStr = (String)resultVector.elementAt(nodeIdCol);
	      idx = (Integer)nodeids.get(nodeIdStr);
	      if (idx == null) {
		idx = new Integer(nextId);
		graph.addKey(nextId++, nodeIdStr);
		nodeids.put(nodeIdStr, idx);
	      }
	      
	    }
	  

	    String str = (String)resultVector.elementAt(plotCol);
	    if (str != null) { //if this result has a sensor id appended to it, strip it away
	      if (str.indexOf("(") != -1) {
		str = str.substring(0, str.indexOf("(")).trim();
	      }
	      try {
		graph.addPoint(idx == null?0:idx.intValue(), (double)qr.epochNo() * ((double)query.epochDur / 1000.0), new Integer(str).intValue());
	      } catch (NumberFormatException e) {
	      }
	    }
	  } catch (ArrayIndexOutOfBoundsException e) {
	  }
	  
	}

    }

    public void paint(Graphics g) {
	super.paint(g);
    }

    protected void exitForm(WindowEvent evt) {
	isRunning = false;
	abortQuery();
	TinyDBMain.notifyRemovedQuery(query);
    }

    //Cancel the currently running query 
    private void abortQuery() {
	if (!aborted) {
	    try {
		isRunning = false;
		aborted = true;
		nw.abortQuery(query);
	    } catch (Exception e) {
	    }
	}
    }
			

    public int getEpoch() {
	return epochNo;
    }

    JTable resultTable;
    DefaultTableModel tableModel;
    JPanel bottomPanel;
    JPanel graphPanel;
    JPanel graphControlPanel;
    JButton stopQueryButton;
    JButton resendQueryButton;
    JScrollPane scroller;
    ResultGraph graph = null;
    JComboBox graphOptions;
    JButton resetButton;
    JButton clearButton;

    protected TinyDBQuery query;
    TinyDBNetwork nw;

    boolean aborted = false;

    JSplitPane split;
boolean graphing = false;
    int nodeIdCol = -1;
    Hashtable nodeids = new Hashtable();
  int plotCol;
  int curPlotChoice;
Vector plotChoices = new Vector();
    int nextId = 0;

    boolean isRunning = true;
    
    int epochNo = 0;

    static final byte QUERY_MSG_ID = 101;
}

class PlotChoice {
  String name;
  int idx;

    public String toString() {
	return name;
    }
}
