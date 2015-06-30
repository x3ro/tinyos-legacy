
import java.util.*;
import java.io.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import net.tinyos.surge.GraphDisplayPanel;
import net.tinyos.surge.Dialog.*;




public class HistoryViewer {

  static javax.swing.JFrame main = new JFrame();
  static javax.swing.JFrame text = new JFrame();
  static javax.swing.JFrame tree = new JFrame();
  static long currentTime;
  static long smooth = 30 * 60 * 1000;
  static TreeClass tree_pan;


  HistoryViewer(String name){
	
	main.setTitle(name);
	main.getContentPane().setLayout(new BorderLayout(0,0));
	main.setSize(700,500);
	main.setVisible(false);
	javax.swing.JPanel MainPanel = new javax.swing.JPanel();
	GraphClass graph = new GraphClass();
	graph.setBounds(0, 0, 700, 500);
	graph.setAutoscrolls(true);
	main.getContentPane().add(BorderLayout.CENTER, graph);
	graph.addMouseListener(graph);
	main.addKeyListener(graph);
	

	text.setTitle("Statistics");
	text.setSize(600, 300);
	TextClass text_pan = new TextClass();
	text_pan.setAutoscrolls(true);
	text.getContentPane().add(BorderLayout.CENTER, text_pan);
	

	//net.tinyos.surge.GraphDisplayPanel g = new net.tinyos.surge.GraphDisplayPanel();

	try{net.tinyos.surge.MainClass m = new net.tinyos.surge.MainClass();}
	catch(Exception e){e.printStackTrace();}

	//tree.setTitle("Routing Tree");
	//tree.setSize(500, 500);
	//tree_pan = new TreeClass();
	//tree_pan.setSize(500, 500);
	//tree_pan.setAutoscrolls(true);
	//tree.getContentPane().add(BorderLayout.CENTER, tree_pan);
	//tree_pan.setSize(500, 500);
	//g.setBounds(0,0,430,270);
	//g.setLayout(null);
	//tree.getContentPane().add(BorderLayout.CENTER, g);

	//tree.setVisible(true); 
	text.setVisible(true); 
	main.setVisible(true); 
  }

  public static int getAvg(int i){
	return (int)(100.0 * data.timeAverage(i, currentTime- smooth, currentTime));
  }

  public static void repaint(int i){
	main.repaint(i);
	tree.repaint(i);
	text.repaint(i);
  }

  static int nodeCount;
  static MoteHistory data = new MoteHistory();

  public static void main(String[] args){
	if(args.length == 0){
		 //System.out.println("Usage: HistoryView <num_nodes>");
		args = new String[1];
		args[0] = "14";
	}
	nodeCount = Integer.parseInt(args[0]);
	HistoryViewer mainFrame = new HistoryViewer("Sensor Network Data");
	InputStreamReader in = new InputStreamReader(System.in);
	BufferedReader read = new BufferedReader(in);	
	try{
        	int count = 0;
		int first = 0;
   		while(in.ready()){
			if(first == 0) {
				read.readLine();
				first = 1;
			}
        		SurgeRecord r = new SurgeRecord(read.readLine());
        		data.add(r);
			HistoryViewer.repaint(1000);
   		}
	}catch(Exception e){
       	 	e.printStackTrace();
  	}

  }
}
