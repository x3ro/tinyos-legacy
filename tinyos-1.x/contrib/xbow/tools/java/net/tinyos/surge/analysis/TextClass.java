import javax.swing.table.*;
import java.awt.event.*;
import javax.swing.*;
import java.beans.*;
import java.awt.*;
import java.util.*;

public class TextClass extends javax.swing.JPanel {
	int row_to_node(int row){
		for(int i = 0; i < 500; i ++){
			try{
				SurgeRecord r =  (SurgeRecord)HistoryViewer.data.data[i].get(0);
				if(row == 0) return i;
				row --;
			}catch(Exception e){}
		}
		return 0;		
	}

static String[] c_names = {"Node Id:", "Parent", "Data Yeild", "Parent Quality", "Reading"};

TextClass(){
	super();

	TableModel dataModel  = new AbstractTableModel(){
		public int getColumnCount() {return 5;}
		public int getRowCount() {return HistoryViewer.nodeCount;}
		public Object getValueAt(int row, int col){ 
			int ret_val = 0;
			if(col == 0) ret_val = row_to_node(row);
			else if(col == 1) {
				SurgeRecord r =  (SurgeRecord)HistoryViewer.data.getByTime(row_to_node(row), HistoryViewer.currentTime);
				if(r != null) ret_val = r.parent;
			}else if(col == 2) {
				ret_val = HistoryViewer.getAvg(row_to_node(row));
			}else if(col == 3) {
				SurgeRecord r =  (SurgeRecord)HistoryViewer.data.getByTime(row_to_node(row), HistoryViewer.currentTime);
				if(r != null) ret_val = (int)(r.neighbors[0].quality * 100);
			}else if(col == 4) {
				SurgeRecord r =  (SurgeRecord)HistoryViewer.data.getByTime(row_to_node(row), HistoryViewer.currentTime);
				if(r != null) ret_val = r.reading;
			}
			return new Integer(ret_val);
		}
		public Class getColumnClass(int c) {return new Integer(1).getClass();}
		public String getColumnName(int column){return c_names[column];}
		public boolean isCellEditable(int row, int col) {return false;}
		public void setValueAd(Object aValue, int row, int col){;}
	};
	JTable view = new JTable(dataModel);
	JScrollPane p = new JScrollPane(view);
	add(p);
}


}
