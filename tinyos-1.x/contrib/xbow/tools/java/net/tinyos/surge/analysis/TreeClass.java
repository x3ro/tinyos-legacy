import javax.swing.tree.*;
import java.awt.event.*;
import javax.swing.*;
import java.beans.*;
import java.awt.*;
import java.util.*;

public class TreeClass extends javax.swing.JPanel {

DefaultMutableTreeNode nodes[] =  new DefaultMutableTreeNode[15];
JTree tree;

TreeClass(){
	super();
	nodes[0] = new DefaultMutableTreeNode("Base Station");
	int i = 0;
	for(i = 1; i < 15; i ++){
		nodes[i] = new DefaultMutableTreeNode("" + i);
	}
	 tree = new JTree(nodes[0]){
		public Insets getInsets(){ return new Insets(15, 15, 15, 15);}
	};
	JScrollPane p = new JScrollPane(tree);
	add(p);
}


int count = 0;
public void update(){

	for(int i = 1; i < 15; i ++) nodes[i].removeAllChildren();
	for(int i = 1; i < 15; i ++){
		SurgeRecord r =  (SurgeRecord)HistoryViewer.data.getByTime(i, HistoryViewer.currentTime);
		if(r != null){
			try{
			nodes[r.parent].add(nodes[i]);
			System.out.println(i + " " + r.parent);
			}catch (Exception e){}
		}
	}
	count ++;
	for(int i = 0 ; i < 15; i ++) tree.collapseRow(i);
	for(int i = 0 ; i < 15; i ++) tree.expandRow(i);
	tree.treeDidChange();
	

}


}
