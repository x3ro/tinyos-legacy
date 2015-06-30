

package net.tinyos.surge.stats;

import javax.swing.table.*;
import java.awt.event.*;
import javax.swing.*;
import java.beans.*;
import java.awt.*;
import java.util.*;
import net.tinyos.surge.PacketAnalyzer.*;
import net.tinyos.surge.stats.*;
import net.tinyos.surge.*;

public class TextClass extends javax.swing.JPanel {

JTable view;
JScrollPane scroll;
static String[] c_names = {"Id", "Rec.", "Sent", "Yield", "Level", "Duty Cycle", "Parent", "Quality", "Voltage", "P1", "P2", "Min Cut"};

     



    public class ColumnHeaderToolTips extends MouseMotionAdapter {
        // Current column whose tooltip is being displayed.
        // This variable is used to minimize the calls to setToolTipText().
        TableColumn curCol;
    
        // Maps TableColumn objects to tooltips
        Map tips = new HashMap();
    
        // If tooltip is null, removes any tooltip text.
        public void setToolTip(TableColumn col, String tooltip) {
            if (tooltip == null) {
                tips.remove(col);
            } else {
                tips.put(col, tooltip);
            }
        }
    
        public void mouseMoved(MouseEvent evt) {
            TableColumn col = null;
            JTableHeader header = (JTableHeader)evt.getSource();
            JTable table = header.getTable();
            TableColumnModel colModel = table.getColumnModel();
            int vColIndex = colModel.getColumnIndexAtX(evt.getX());
    
            // Return if not clicked on any column header
            if (vColIndex >= 0) {
                col = colModel.getColumn(vColIndex);
            }
    
            if (col != curCol) {
                header.setToolTipText((String)tips.get(col));
                curCol = col;
            }
        }
    }


public TextClass(){
	super();
	ColumnHeaderToolTips tips = new ColumnHeaderToolTips();


	TableModel dataModel  = new AbstractTableModel(){
		public int getColumnCount() {return c_names.length;}
		public int getRowCount() {
			return 30;
			//return MainClass.sensorAnalyzer.GetNodeCount();
		}
		public Object getValueAt(int row, int col){ 
			int ret_val = 0;
			NodeInfo ni = null;;

			ni = MainClass.sensorAnalyzer.GetNodeInfoByOrder(row);
			if(ni == null) return null;
			if(ni.msgCount == 0 && col != 0) return null;
			int sent = 1 + ni.seq_no - ni.stats_start_sequence_number;
			if(col == 0) return ni.GetNodeNumber();
			else if(col == 1) {
				return new Integer((int)ni.msgCount);
			}else if(col == 2) {
				return new Integer(sent);
			}else if(col == 3) {
				double yield = (((double)ni.msgCount) / (double)sent);
				return new Double(yield);
			}else if(col == 4) {
				return new Double(ni.averageLevel());
			}else if(col == 5) {
				//duty cycle.
		
				double duty = (100.0 * ((double)ni.value/(double)ni.seq_no)/2.0/180.0*8.0);
				return new Double(duty);
				
			}else if(col == 6) {
				return (MainClass.objectMaintainer.getParent(ni.GetNodeNumber()));
			}else if(col == 7) {
				return new Double(ni.link_quality);
			}else if(col == 8) {
				double batt  = ni.batt;
				return new Double(1.25 * 1023 / batt);
			}else if(col == 9) {
				return new Integer(ni.primary_parent);
			}else if(col == 10) {
				double batt  = ni.batt;
				return new Integer(ni.secondary_parent);
			}else if(col == 11){
				return new Double(MainClass.flowAnalyzer.getFlow(ni.GetNodeNumber().intValue()));
			}
			return new Integer(-1);
		}
		public Class getColumnClass(int c) {

			if(c == 3 || c == 4 || c == 5 || c == 7 || c == 8 || c == 11) return new Double(1.1).getClass();
			return new Integer(1).getClass();

		}
		public String getColumnName(int column){return c_names[column];}
		public boolean isCellEditable(int row, int col) {return false;}
		public void setValueAd(Object aValue, int row, int col){;}
	};
	view = new JTable(dataModel);
	scroll = new JScrollPane(view);
	scroll.setMaximumSize(getSize());
	scroll.setMinimumSize(getSize());
	add(scroll);

	String s0 = "Node Identifier";
	String s1 = "Number of Messages Received";
	String s2 = "Number of Messages Sent";
	String s3 = "Percentage of Messages Received";
	String s4 = "Average number of hops between base station and node";
	String s5 = "Fraction of time the node is active";
	String s6 = "Current Routing Parent";
	String s7 = "Link quality reported to parent";
	String s8 = "Battery Voltage";
	String s9 = "Most Common Parent";
	String s10 = "Second Most Common Parent";
	String s11 = "Number of links that must be broken to separate node from base station.";
	tips.setToolTip(view.getColumnModel().getColumn(0), s0);
	tips.setToolTip(view.getColumnModel().getColumn(1), s1);
	tips.setToolTip(view.getColumnModel().getColumn(2), s2);
	tips.setToolTip(view.getColumnModel().getColumn(3), s3);
	tips.setToolTip(view.getColumnModel().getColumn(4), s4);
	tips.setToolTip(view.getColumnModel().getColumn(5), s5);
	tips.setToolTip(view.getColumnModel().getColumn(6), s6);
	tips.setToolTip(view.getColumnModel().getColumn(7), s7);
	tips.setToolTip(view.getColumnModel().getColumn(8), s8);
	tips.setToolTip(view.getColumnModel().getColumn(9), s9);
	tips.setToolTip(view.getColumnModel().getColumn(10), s10);
	tips.setToolTip(view.getColumnModel().getColumn(11), s11);
	view.getTableHeader().addMouseMotionListener(tips);


}

int old_x;
int  old_y;
public void paint(Graphics g)
{
	if(old_x != getHeight() || old_y != getWidth()){
		scroll.setPreferredSize(getSize());
		scroll.setMaximumSize(getSize());
		scroll.setMinimumSize(getSize());
		old_x = getHeight();
		old_y = getWidth();
		repaint(50);
	}
	super.paint(g);

}


}
