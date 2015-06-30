import java.awt.event.*;
import javax.swing.*;
import java.beans.*;
import java.awt.*;
import java.util.*;

public class GraphClass extends javax.swing.JPanel implements MouseListener, KeyListener{


GraphClass(){
	super();
}

public void update(Graphics g)
{
  paint(g);
}

public void repaint(Graphics g)
{
  paint(g);
}

int mousex = 300;
public void mouseClicked(MouseEvent e){
	 mousex = e.getX();
	HistoryViewer.repaint(50);
}
public void mouseEntered(MouseEvent e){
}
public void mouseExited(MouseEvent e){
}
public void mousePressed(MouseEvent e){
}
public void mouseReleased(MouseEvent e){
}

public void keyPressed(KeyEvent e){ 
	int val = e.getKeyCode();
	if(val == 39) mousex ++;
	if(val == 37) mousex --;
	HistoryViewer.repaint(1);
}
public void keyReleased(KeyEvent e){}
public void keyTyped(KeyEvent e){}

public void paint(Graphics g)
{
  super.paint(g);//first paint the panel normally

  //the following block of code is used
  //if this is the first time being drawn or if the wi
  //Otherwise we don't creat a new buffer
  Dimension d = getSize();

  g.setColor(Color.blue);
  g.fillRect(0, 0, (int)d.getWidth(), (int)d.getHeight());

  int[] rows = new int[HistoryViewer.nodeCount];
  int row_count = 0;
	
  
	long start = HistoryViewer.data.start_time[0];;
	long end = HistoryViewer.data.end_time[0];;
	long step = (end - start)/(int)d.getWidth();
	double height = d.getHeight()/HistoryViewer.nodeCount;
	for(int i = 1; i < 500 && row_count < HistoryViewer.nodeCount; i ++){
  	   g.setColor(Color.white);
	   try{
	    	SurgeRecord r = (SurgeRecord)HistoryViewer.data.data[i].get(0);
		double last = HistoryViewer.data.timeAverage(i, start, HistoryViewer.smooth);
		rows[row_count] = i;
	   double last_val = height * (1.0-last);
	   for(int j = 1; j < d.getWidth(); j ++){
		long time = start + j*step;
		double avg = HistoryViewer.data.timeAverage(i, time- HistoryViewer.smooth, time);
		double val = height * (1.0-avg);
		//g.drawRect(j, (int)(i*height + val), 0, 0);
		g.drawLine(j, (int)(row_count*height + val), j-1, (int)(row_count*height + last_val));
		last_val = val;
	   }
  	   g.setColor(Color.black);
	   g.drawLine(0, (int)(height * i), (int)d.getWidth(), (int)(i*height));
		row_count ++;
	  }catch (Exception e){
	  }	
	}

	long time = start + mousex*step;
	HistoryViewer.currentTime = time;
	for(int i =0; i < HistoryViewer.nodeCount - 1; i ++){
		g.setColor(Color.red);
		int node = rows[i];
		double avg = HistoryViewer.data.timeAverage(node, time- HistoryViewer.smooth, time);
		g.drawString(node + "", mousex - 40, (int)(height * i + height*.7));
		g.drawString((int)(avg * 100.0) + "%", mousex + 40, (int)(height * i + height*.7));
		g.drawLine(mousex, 0, mousex, (int)d.getHeight());


	}
	for(int i = 0; i < 500; i ++){
	    try{update_node_info(i);}catch(Exception e){}
	}
	g.drawString(new Date(time).toString(), 100, 100);

}

	public void update_node_info(int node){
		SurgeRecord rec = HistoryViewer.data.getByTime(node, HistoryViewer.currentTime);
		if(net.tinyos.surge.MainClass.sensorAnalyzer == null) {
			return;
		}
		if(rec == null){
			 return;
		}

		if(net.tinyos.surge.MainClass.objectMaintainer != null)
		net.tinyos.surge.MainClass.objectMaintainer.setParentForNode(node, rec.parent);
		if(net.tinyos.surge.MainClass.locationAnalyzer != null)
		net.tinyos.surge.MainClass.locationAnalyzer.setParentForNode(node, rec.parent);
		net.tinyos.surge.PacketAnalyzer.NodeInfo ni = net.tinyos.surge.MainClass.sensorAnalyzer.GetNodeInfo(new Integer(node));
		if(ni == null){
			 return;
		}


		ni.self_calc = false;
		ni.supplied_yield = HistoryViewer.getAvg(node);
		ni.supplied_yield /= 100.0;
		for(int i = 0;  i < 5; i ++){
			ni.neighbors[i].id = rec.neighbors[i].id;
			ni.neighbors[i].link_quality = rec.neighbors[i].quality * 255.0; 
			ni.neighbors[i].hopcount = rec.neighbors[i].depth;
		}
		ni.link_quality = rec.neighbors[0].quality;
		ni.msgCount = rec.msg_number;
		ni.infoString = "";
		if(ni.link_panel != null) ni.link_panel.get_new_data();

        }


}
