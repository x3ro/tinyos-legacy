import java.util.*;
import java.awt.*;
import java.applet.Applet;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.sql.Time;

class Node {
    public static Image img= new ImageIcon("mote2.jpg").getImage();

    double x;
    double y;
    Node parent;

    double dx;
    double dy;
    int light = 0x0;
    int temp = 0x0;
    Date time = new Date(); 
    Date start = new Date();
    Date last_updated = new Date();
    int num_msgs = 0;
    int num_forward = 0;

    java.util.List history = new LinkedList();
    

    boolean fixed;

    String lbl;
    int id;
    void paint(Graphics g){

	int w = 30;
	int h = w;
	int img_width = 3*h/4;
	int x_c = (int)this.x- w/2;
	int y_c = (int)this.y - h/2;

	g.setColor(Color.black);
	g.drawString(lbl,(int) x - (w-10)/2, (int)(y - (h)/2));
	//draw the light level;
	g.setColor(new Color(light, light, light));
	g.fillRect(x_c, y_c+3*h/4, w/2,  h/4);
	g.setColor(new Color(0, 0, 0));
	g.drawRect(x_c, y_c+3*h/4, w/2,  h/4);
	//draw the temp level
	g.setColor(new Color(temp, 0, 0xff-temp));
	g.fillRect(x_c+w/2, y_c+3*h/4, w/2,  h/4);
	g.setColor(new Color(0, 0, 0));
	g.drawRect(x_c+w/2, y_c+3*h/4, w/2,  h/4);
	
	g.drawImage(img, (int)x_c, (int)y_c, img_width, img_width, null);
    }

}


class Edge {
    Node from;
    Node to;
    double len = 100;
    Date last_updated;
    int num_on_path = 0;
}
    class PacketCountDE extends DataExtractor{
	public long getX(DataPacket pack){return pack.time.getTime();}
	public long getY(DataPacket pack){return (long)pack.packetNumber;}
    } 
    class TempDE extends DataExtractor{
	public long getX(DataPacket pack){return pack.time.getTime();}
	public long getY(DataPacket pack){return (long)pack.temp() & 0xff;}
    } 
    class LightDE extends DataExtractor{
	public long getX(DataPacket pack){return pack.time.getTime();}
	public long getY(DataPacket pack){
		return (long)pack.light() & 0xff;}
    } 

class ValueGraph extends Panel implements Runnable, MouseMotionListener{
    Node node;
    boolean stop;
    Image offscreen;
    Dimension offscreensize;
    Graphics offgraphics;
    int mouse_x = -1;
    int mouse_y;
    public void run() {
	try{
	    while(!stop){
		Thread.sleep(100);
		repaint();
	    }
	}catch(Exception e){
	    e.printStackTrace();
	}
    }
    public void mouseEntered(MouseEvent e) {
    }

    public void mouseExited(MouseEvent e) {
	mouse_x = -1;
    }

    public void mouseDragged(MouseEvent e) {
    }

    public void mouseMoved(MouseEvent e) {
	mouse_x = e.getX();
	mouse_y = e.getY();
	e.consume();
    }

    Thread t;
    void stop(){
	stop = true;
    }

    ValueGraph(Node n){
	data_ext = new PacketCountDE();
	node = n;
	setBackground(Color.black);
	stop = false;
	t = new Thread(this);
	t.start();
        addMouseMotionListener(this);
    }


    public Dimension getPreferredSize()
    {
	return new Dimension(300, 180);
    }
	
    public DataExtractor data_ext;
    public synchronized void update(Graphics g) {
	Dimension d = getSize();
	if ((offscreen == null) || (d.width != offscreensize.width) || (d.height != offscreensize.height)) {
	    offscreen = createImage(d.width, d.height);
	    offscreensize = d;
	    if (offgraphics != null) {
	        offgraphics.dispose();
	    }
	    offgraphics = offscreen.getGraphics();
	    offgraphics.setFont(getFont());
	}

	offgraphics.setColor(getBackground());
	offgraphics.fillRect(0, 0, d.width, d.height);
	
	offgraphics.setColor(Color.white);
	offgraphics.fillRect(20, 0,d.width, d.height -20);
	
	offgraphics.setColor(Color.green);
	offgraphics.drawString("" + new Time(node.start.getTime()), 10, d.height); 
	offgraphics.drawString("" + new Time(node.time.getTime()), d.width - 60, d.height); 
	offgraphics.setColor(Color.gray);

	int g_height = d.height - 20;
	int g_width = d.width - 20;
	for(int i = 0; i < 10; i ++){
		offgraphics.drawLine(20 + i * g_width/10, 0, 20 + i * g_width/10, g_height);
		offgraphics.drawLine(20, i*g_height/10, 300, i*g_height/10);
	}
	offgraphics.setColor(Color.red);
	long max_y = 0;
	long xstart = 0;
	long xlength = 0;
	synchronized(node.history){
		
		ListIterator li = node.history.listIterator();
		while(li.hasNext()){
			DataPacket cur = (DataPacket)li.next();
			long ty, tx;
			ty = data_ext.getY(cur);
			tx = data_ext.getX(cur);
			
			if(max_y < ty) max_y = ty;
			if(xstart == 0) xstart = tx;
			if(tx < xstart){
			   xlength += xstart - tx;
			   xstart = tx;
			}
			if(tx > xstart + xlength){
				xlength = tx-xstart;
			}
		}
		li = node.history.listIterator();
		while(li.hasNext()){
			DataPacket cur = (DataPacket)li.next();
			long yval = data_ext.getY(cur);
			long xval = data_ext.getX(cur);cur.time.getTime();
			offgraphics.drawRect((int)(20+g_width*((float)(xval-xstart)/(float)xlength)), g_height - (int)((float)yval/(float)max_y * (float)g_height), 1, 1);
		}	
	}
	
	offgraphics.setColor(Color.blue);
	if(20 < mouse_x && mouse_x < 300 && mouse_y < g_height){
		int x = mouse_x + 15;
		if(x > 20+g_width/2) x -=120;
		int y = mouse_y + 15;
		offgraphics.drawString("(" + new Time(xstart + (xlength*(mouse_x - 20))/g_width) + ", " +
					(int)(((float)1 - (float)mouse_y/(float)g_height)*max_y) + ")", x, y); 
		offgraphics.drawLine(mouse_x, 0, mouse_x, g_height); 
		offgraphics.drawLine(20, mouse_y, d.width, mouse_y); 
	}

	g.drawImage(offscreen, 0, 0, null);
    }

}

class MoteDetail extends Panel implements Runnable{
    Node node;
    boolean stop;
    Image offscreen;
    Dimension offscreensize;
    Graphics offgraphics;
    public void run() {
	try{
	    while(!stop){
		Thread.sleep(100);
		repaint();
	    }
	}catch(Exception e){
	    e.printStackTrace();
	}
    }

    Thread t;
    void stop(){
	stop = true;
    }

    MoteDetail(Node n){
	node = n;
	setBackground(Color.white);
	stop = false;
	t = new Thread(this);
	t.start();
    }


    public Dimension getPreferredSize()
    {
	return new Dimension(200, 180);
    }
    public synchronized void update(Graphics g) {
	Dimension d = getSize();
	if ((offscreen == null) || (d.width != offscreensize.width) || (d.height != offscreensize.height)) {
	    offscreen = createImage(d.width, d.height);
	    offscreensize = d;
	    if (offgraphics != null) {
	        offgraphics.dispose();
	    }
	    offgraphics = offscreen.getGraphics();
	    offgraphics.setFont(getFont());
	}

	offgraphics.setColor(getBackground());
	offgraphics.fillRect(0, 0, d.width, d.height);
	int w = 30;
	int h = w;
	int x = 40;
	int y = 40;
	int img_width = 3*h/4;
	int x_c = (int)x- w/2;
	int y_c = (int)y - h/2;
	
	offgraphics.setColor(Color.black);
	offgraphics.drawString("Mote:" + node.lbl,(int) x, (int)(y - 20));
	//draw the light level;
	offgraphics.setColor(new Color(node.light, node.light, node.light));
	offgraphics.fillRect(x_c, y_c+3*h/4, w/2,  h/4);
	offgraphics.setColor(new Color(0, 0, 0));
	offgraphics.drawRect(x_c, y_c+3*h/4, w/2,  h/4);
	//draw the temp level
	offgraphics.setColor(new Color(node.temp, 0, 0xff-node.temp));
	offgraphics.fillRect(x_c+w/2, y_c+3*h/4, w/2,  h/4);
	offgraphics.setColor(new Color(0, 0, 0));
	offgraphics.drawRect(x_c+w/2, y_c+3*h/4, w/2,  h/4);	
	offgraphics.drawImage(node.img, (int)x_c, (int)y_c, img_width, img_width, null);


	offgraphics.drawString("Temp: " + node.temp, x + w, y); 
	offgraphics.drawString("Light: " + node.light, x + w, y + 20); 
	offgraphics.drawString("Time: " + new Time(node.time.getTime()), x + w, y + 40); 
	offgraphics.drawString("Sent: " + node.num_msgs, x + w, y + 60); 
	offgraphics.drawString("Forwarded: " + node.num_forward, x + w, y + 80); 
	if(node.parent != null)
		offgraphics.drawString("Parent: " + node.parent.lbl, x + w, y + 100); 
	g.drawImage(offscreen, 0, 0, null);
    }

}



class GraphPanel extends Panel
    implements Runnable, MouseListener, MouseMotionListener {	
    boolean debug = false;
    Surge graph;
    int nnodes;
    Object nodes_lock = new Object();
    Object edges_lock = new Object();
    Node nodes[] = new Node[100];

    int nedges;
    Edge edges[] = new Edge[200];

    Thread relaxer;
    boolean stats;
    boolean random;

    GraphPanel(Surge graph) {
	setBackground(Color.white);
	this.graph = graph;
	addMouseListener(this);	
	new DataUpdateHandler(this);
    }

    int setEdges(Edge[] new_edges, int num_edges){
	synchronized(nodes_lock){
		synchronized(edges_lock){
	    		edges = new_edges;
	    		nedges = num_edges;
		}
	}
	return 1;
	    
    }

    int findNode(String lbl) {
	for (int i = 0 ; i < nnodes ; i++) {
	    if (nodes[i].lbl.equals(lbl)) {
		return i;
	    }
	}
	return addNode(lbl);
    }
    boolean isNode(String lbl) {
	for (int i = 0 ; i < nnodes ; i++) {
	    if (nodes[i].lbl.equals(lbl)) {
		return true;
	    }
	}
	return false;
    }
    boolean isNode(Node v, Node[] vals, int length) {
	for (int i = 0 ; i < length && i < vals.length ; i++) {
	    if (vals[i] == v){
		return true;
	    }
	}
	return false;
    }
	
    Node getNode(String lbl){
	return nodes[findNode(lbl)];
    }

    int addNode(String lbl) {
	Node n = new Node();
	n.x = 10 + 380*Math.random();
	n.y = 10 + 380*Math.random();
	n.lbl = lbl;
	synchronized(nodes_lock){
		nodes[nnodes] = n;
		return nnodes++;
	}
    }
    void addEdge(String from, String to, int len) {
	Edge e = new Edge();
	e.from = getNode(from);
	e.to = getNode(to);
	e.len = len;
	synchronized(edges_lock){
	    edges[nedges++] = e;
	}
    }
    int graph_speed = 20;
    int setSpeed(int speed){
	return graph_speed = speed;
    }
    float setStability(int stability){
	ratio = (float)stability /100;
	ratio = ratio / 100;
	return ratio * 100;
    }
    float ratio = (float).8;
    synchronized Edge updateEdge(String from, String to, int len, Date time) {
	Edge e;
	int loc = findEdge(getNode(from), getNode(to));
	if(loc != -1){ 
	    	e = edges[loc];
		if(len != -1){
	    		e.len = (float)len * ratio + (float)e.len * ((float)1.0-ratio);
			System.out.println(from + " " + to + " " + ratio);
		}
	}else{
	    synchronized(this){
		e = new Edge();
		e.from = getNode(from);
		e.to = getNode(to);
		edges[nedges++] = e;
		if(len != -1)
			e.len = len;
	    }
	}
	e.last_updated = time;
	return e;
    }

    int findEdge(Node from, Node to){
	synchronized(edges_lock){
	    for(int i = 0; i < nedges; i ++){
		if((edges[i].from == from && edges[i].to == to) ||
		    (edges[i].to == from && edges[i].from == to)){
		    return i;
		}
	    }
	    return -1;
	}
    }

    public void settle(){
	count = 0;
    }
    int count;
    int node_expire = 30000;
    int edge_expire = 20000;
    int first_time_expire = 10000;
    void setExpire(int node, int edge, int first_time){
    	node_expire = node;
    	edge_expire = edge;
    	first_time_expire = first_time;
    }

    void expire_check(){
	Node[] new_nodes = new Node[400];
	int new_nnodes = 0;
	Edge[] new_edges = new Edge[400];
	int new_nedges = 0;
	long now = new Date().getTime();
	synchronized(nodes_lock){
		for(int i = 0; i < nnodes; i ++){
			if((now - nodes[i].last_updated.getTime() < first_time_expire) || 
			   ((now - nodes[i].last_updated.getTime() < node_expire) &&
			    (nodes[i].num_msgs + nodes[i].num_forward > 1))){
				new_nodes[new_nnodes++] = nodes[i];
			}
			else{
				if(debug) System.out.println("expiring node: " +nodes[i].lbl);
			}
		}
		nodes = new_nodes;	
		nnodes = new_nnodes;
	}
	synchronized(edges_lock){
		for(int i = 0; i < nedges; i ++){
			if((now - edges[i].last_updated.getTime() < edge_expire) &&
			   (isNode(edges[i].from, new_nodes, new_nnodes)) &&
			   (isNode(edges[i].to, new_nodes, new_nnodes)) &&
			    edges[i].to.num_msgs + edges[i].to.num_forward > 1 &&
			   edges[i].from.num_msgs + edges[i].from.num_forward > 1){
				new_edges[new_nedges++] = edges[i];
			}
		}
		edges = new_edges;	
		nedges = new_nedges;
	}
	    
    }


    public void run() {
        Thread me = Thread.currentThread();

	while (relaxer == me) {
	    relax();
	    if (random && (Math.random() < 0.03)) {
		Node n = nodes[(int)(Math.random() * nnodes)];
		if (!n.fixed) {
		    n.x += 100*Math.random() - 50;
		    n.y += 100*Math.random() - 50;
		}
	    }
	    try {
		count ++;
		if(count > graph_speed){
		    Thread.sleep(100);
		    expire_check();
		    count = 0;
		
		}
	    } catch (InterruptedException e) {
		break;
	    }
	}
    }


    synchronized void relax() {
	Edge[] local_edges;
	Node[] local_nodes;
	int local_nedges, local_nnodes;
	synchronized(nodes_lock){
		synchronized(edges_lock){
	    		local_edges = this.edges;
	    		local_nedges = this.nedges;
			local_nodes = this.nodes;
			local_nnodes = this.nnodes;
			
	    }
	}
	for (int i = 0 ; i < local_nedges ; i++) {
	    Edge e = local_edges[i];
	    double vx = e.to.x - e.from.x;
	    double vy = e.to.y - e.from.y;
	    double len = Math.sqrt(vx * vx + vy * vy);
            len = (len == 0) ? .0001 : len;
	    double f = (local_edges[i].len - len) / (len * 3);
	    double dx = f * vx;
	    double dy = f * vy;

	    e.to.dx += dx;
	    e.to.dy += dy;
	    e.from.dx += -dx;
	    e.from.dy += -dy;
	}

	for (int i = 0 ; i < local_nnodes ; i++) {
	    Node n1 = local_nodes[i];
	    double dx = 0;
	    double dy = 0;

	    for (int j = 0 ; j < local_nnodes ; j++) {
		if (i == j) {
		    continue;
		}
		Node n2 = local_nodes[j];
		if (findEdge(n1,n2) != -1) {
		    continue;
		}
		if (n2.num_msgs + n2.num_forward == 1) {
		    continue;
		}
		double vx = n1.x - n2.x;
		double vy = n1.y - n2.y;
		double len = vx * vx + vy * vy;
		if (len == 0) {
		    dx += Math.random();
		    dy += Math.random();
		} else if (len < 400*400) {
		    dx += 20 * vx / len;
		    dy += 20 * vy / len;
		}
	    }
	    double dlen = dx * dx + dy * dy;
	    if (dlen > 0) {
		dlen = Math.sqrt(dlen) / 2;
		n1.dx += 20*5*dx / dlen;
		n1.dy += 20*5*dy / dlen;
	    }
	}

	Dimension d = getSize();
	for (int i = 0 ; i < local_nnodes ; i++) {
	    Node n = local_nodes[i];
	    if (!n.fixed) {
		n.x += Math.max(-5, Math.min(5, n.dx));
		n.y += Math.max(-5, Math.min(5, n.dy));
            }
            if (n.x < 0) {
                n.x = 0;
            } else if (n.x > d.width) {
                n.x = d.width;
            }
            if (n.y < 0) {
                n.y = 0;
            } else if (n.y > d.height) {
                n.y = d.height;
            }
	    n.dx /= 2;
	    n.dy /= 2;
	}
	
	repaint();
    }

    Node pick;
    boolean pickfixed;
    Image offscreen;
    Dimension offscreensize;
    Graphics offgraphics;

    final Color fixedColor = Color.red;
    final Color selectColor = Color.pink;
    final Color edgeColor = Color.black;
    final Color nodeColor = new Color(250, 220, 100);
    final Color statsColor = Color.darkGray;
    final Color arcColor1 = Color.black;
    final Color arcColor2 = Color.pink;
    final Color arcColor3 = Color.red;

    public void paintNode(Graphics g, Node n, FontMetrics fm) {
	n.paint(g);	
    }

    public synchronized void update(Graphics g) {
	Dimension d = getSize();
	if ((offscreen == null) || (d.width != offscreensize.width) || (d.height != offscreensize.height)) {
	    offscreen = createImage(d.width, d.height);
	    offscreensize = d;
	    if (offgraphics != null) {
	        offgraphics.dispose();
	    }
	    offgraphics = offscreen.getGraphics();
	    offgraphics.setFont(getFont());
	}

	offgraphics.setColor(getBackground());
	offgraphics.fillRect(0, 0, d.width, d.height);
	for (int i = 0 ; i < nedges ; i++) {
	    Edge e = edges[i];
	    
	    int x1 = (int)e.from.x;
	    int y1 = (int)e.from.y;
	    int x2 = (int)e.to.x;
	    int y2 = (int)e.to.y;
	    int len = (int)Math.abs(Math.sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2)) - e.len);
	    if(e.to.parent == e.from || e.from.parent == e.to){
		offgraphics.setColor(Color.green);
		drawLine(offgraphics,x1, y1, x2, y2, 8);
	    }
	    offgraphics.setColor((len < 10) ? arcColor1 : (len < 20 ? arcColor2 : arcColor3)) ;
	    offgraphics.drawLine(x1, y1, x2, y2);
	    if (stats && e.num_on_path != 0) {
		String lbl = String.valueOf(e.num_on_path);
		offgraphics.setColor(statsColor);
		offgraphics.drawString(lbl, x1 + (x2-x1)/2, y1 + (y2-y1)/2);
		offgraphics.setColor(edgeColor);
	    }
	}

	FontMetrics fm = offgraphics.getFontMetrics();
	for (int i = 0 ; i < nnodes ; i++) {
	    paintNode(offgraphics, nodes[i], fm);
	}
	g.drawImage(offscreen, 0, 0, null);
    }

    //1.1 event handling
    public void mouseClicked(MouseEvent e) {
	
    }

    public void mousePressed(MouseEvent e) {
        addMouseMotionListener(this);
	double bestdist = Double.MAX_VALUE;
	int x = e.getX();
	int y = e.getY();
	for (int i = 0 ; i < nnodes ; i++) {
	    Node n = nodes[i];
	    double dist = (n.x - x) * (n.x - x) + (n.y - y) * (n.y - y);
	    if (dist < bestdist) {
		pick = n;
		bestdist = dist;
	    }
	}
	pickfixed = pick.fixed;
	if(e.getClickCount() == 2){
	    open_details(pick);
	}
	pick.fixed = true;
	
	pick.x = x;
	pick.y = y;
	System.out.println(e);
	    
	repaint();
	e.consume();
	settle();
    }

    public void mouseReleased(MouseEvent e) {
        removeMouseMotionListener(this);
	if (pick != null) {
            pick.x = e.getX();
            pick.y = e.getY();
            pick.fixed = pickfixed;
	    pick = null;
	}
	repaint();
	settle();
	e.consume();
    }

void open_details(Node pick){
    final MoteDetail md = new MoteDetail(pick);
    final ValueGraph vg = new ValueGraph(pick);
    final JFrame f = new JFrame("Details for: " + pick.lbl);
    f.setSize(new Dimension(300,500) );
    JPanel pan = new JPanel();
    //pan.setSize(new Dimension(400,200) );
    //pan.setLayout(new GridLayout(3,3));
    pan.setLayout(new FlowLayout());
    final Node node = pick;
    JCheckBox box = new JCheckBox("fixed", node.fixed);
    box.addItemListener( new ItemListener(){
	public void itemStateChanged(ItemEvent e){
   	     	node.fixed = e.getStateChange() == ItemEvent.SELECTED;
        }});
 
    pan.add(box);
    pan.add(md);
    pan.add(vg);
    String[] options = {"Transmissions", "Temperature", "Light"};
    JComboBox graph_o = new JComboBox(options); 
    graph_o.setSelectedIndex(0);
    graph_o.addItemListener(new ItemListener(){
	public void itemStateChanged(ItemEvent e){
	int source = ((JComboBox)e.getSource()).getSelectedIndex();   
	if(source == 0){
	    vg.data_ext = new PacketCountDE();
	}else if(source == 1){
	    vg.data_ext = new TempDE();
	}else if(source == 2){
	    vg.data_ext = new LightDE();
	}
	
	
	}
    });
    pan.add(graph_o);
    f.getContentPane().add(pan);
    f.repaint();
    //f.pack();
    f.setVisible(true);
    f.addWindowListener
	(
	 new WindowAdapter()
	 {
	     public void windowClosing    ( WindowEvent wevent )
		 {
		     md.stop();
		     vg.stop();
		     f.setVisible(false);
		 }
	 }
	 );
}


    public void mouseEntered(MouseEvent e) {
    }

    public void mouseExited(MouseEvent e) {
    }

    public void mouseDragged(MouseEvent e) {
	pick.x = e.getX();
	pick.y = e.getY();
	repaint();
	e.consume();
    }

    public void mouseMoved(MouseEvent e) {
    }

    public void start() {
	relaxer = new Thread(this);
	relaxer.start();
    }

    public void stop() {
	relaxer = null;
    }
public static void drawLine(Graphics g,
                              int x1, int y1,
                              int x2, int y2,
                              int lineWidth) {
    if (lineWidth == 1)
      g.drawLine(x1, y1, x2, y2);
    else {
      double angle;
      double halfWidth = ((double)lineWidth)/2.0;
      double deltaX = (double)(x2 - x1);
      double deltaY = (double)(y2 - y1);
      if (x1 == x2)
        angle=Math.PI;
      else
        angle=Math.atan(deltaY/deltaX)+Math.PI/2;
      int xOffset = (int)(halfWidth*Math.cos(angle));
      int yOffset = (int)(halfWidth*Math.sin(angle));
      int[] xCorners = { x1-xOffset, x2-xOffset+1,
                         x2+xOffset+1, x1+xOffset };
      int[] yCorners = { y1-yOffset, y2-yOffset,
                         y2+yOffset+1, y1+yOffset+1 };
      g.fillPolygon(xCorners, yCorners, 4);
    }
}
}



public class Surge extends JPanel implements ActionListener, ItemListener, ChangeListener {

    GraphPanel panel;
    Panel controlPanel;

    Button timeout = new Button("Control Panel");
    Button shake = new Button("Shake");
    Checkbox stats = new Checkbox("Show Path Statistics");
    Checkbox random = new Checkbox("Random");

    JSlider node_expire = new JSlider(100, 1000*5*60, 30000);
    JLabel node_expire_val = new JLabel(String.valueOf(30000));
    JSlider edge_expire = new JSlider(100, 1000*5*60, 20000);
    JLabel edge_expire_val = new JLabel(String.valueOf(20000));
    JSlider first_expire = new JSlider(100, 60000, 10000);
    JLabel first_expire_val = new JLabel(String.valueOf(10000));
    JSlider edge_stability = new JSlider(0, 10000, 8000);
    JLabel edge_stability_val = new JLabel("80.0%");
    JFrame timeout_frame;
void create_timeout_frame(){
    final JFrame f = new JFrame("Timeout Control");
    f.setSize(new Dimension(200,200) );
    JPanel pan = new JPanel();
    pan.setSize(new Dimension(200,200) );
    pan.setLayout(new GridLayout(5,3));
	pan.add(new JLabel("Node Timeout:"));
	pan.add(node_expire_val);
	pan.add(node_expire); node_expire.addChangeListener(this);
	pan.add(new JLabel("Edge Timeout:"));
	pan.add(edge_expire_val);
	pan.add(edge_expire); edge_expire.addChangeListener(this);
	pan.add(new JLabel("New Node Timeout:"));
	pan.add(first_expire_val);
	pan.add(first_expire); first_expire.addChangeListener(this);
	pan.add(new JLabel("Edge Stability:"));
	pan.add(edge_stability_val);
	pan.add(edge_stability); edge_stability.addChangeListener(this);
	pan.add(new JLabel("Graph Speed:"));
    final JSlider graph_speed = new JSlider(0, 100, 20);
    final JLabel graph_speed_val = new JLabel("20");
	pan.add(graph_speed_val);
	pan.add(graph_speed); graph_speed.addChangeListener(new ChangeListener(){
    		public void stateChanged(ChangeEvent e){
			if(app == null) System.out.println("PAN_NULL");
			if(graph_speed == null) System.out.println("GRAPH_NULL");
			app.panel.setSpeed(graph_speed.getValue());
			graph_speed_val.setText(String.valueOf(graph_speed.getValue()));
			
		}});
    f.getContentPane().add(pan);
    f.repaint();
    f.pack();
    f.addWindowListener
	(
	 new WindowAdapter()
	 {
	     public void windowClosing    ( WindowEvent wevent )
		 {
		     f.setVisible(!f.isVisible());
		 }
	 }
	 );
    timeout_frame = f;
}
    public void init() {
	setLayout(new BorderLayout());
	create_timeout_frame();
	panel = new GraphPanel(this);
	add("Center", panel);
	controlPanel = new Panel();
	add("South", controlPanel);	
	controlPanel.add(shake); shake.addActionListener(this);
	controlPanel.add(timeout); timeout.addActionListener(this);
	controlPanel.add(stats); stats.addItemListener(this);

	int len = 40;
	panel.addNode(""+5);
	/*
	panel.addNode("324");
	panel.addEdge("23", "5", len, true);
	panel.addEdge("4", "5", len, true);
	panel.addEdge("6", "4", len, true);
	panel.addEdge("2", "5", len, true);
	panel.addEdge("9", "5", len, true);
	panel.addEdge("8", "6", len, true);
	panel.addEdge("32", "6", len, true);
	panel.addEdge("6", "5", len, false);
	panel.addEdge("23", "6", len, false);
	panel.addEdge("4", "8", len, false);
	*/
	Dimension d = getSize();
	Node n = panel.nodes[panel.findNode("5")];
	n.x = d.width / 2;
	n.y = d.height / 2;
	n.fixed = true;


    }

    public void destroy() {
        remove(panel);
        remove(controlPanel);
    }

    public void start() {
	panel.start();
    }

    public void stop() {
	panel.stop();
    }

    public void actionPerformed(ActionEvent e) {
	Object src = e.getSource();

	if (src == shake) {
	    Dimension d = getSize();
	    for (int i = 0 ; i < panel.nnodes ; i++) {
		Node n = panel.nodes[i];
		if (!n.fixed) {
		    n.x += 200*Math.random() - 40;
		    n.y += 200*Math.random() - 40;
		}
	    }
	}
	if (src == timeout) {
		//create_timeout_frame();
		timeout_frame.setVisible(!timeout_frame.isVisible());
		System.err.println("timeout...");
	}
	panel.settle();

    }

    public void itemStateChanged(ItemEvent e) {
	Object src = e.getSource();
	boolean on = e.getStateChange() == ItemEvent.SELECTED;
	if (src == stats) panel.stats = on;
	else if (src == random) panel.random = on;
    }

    public void stateChanged(ChangeEvent e){
	panel.setExpire(node_expire.getValue(),edge_expire.getValue(),first_expire.getValue());
	node_expire_val.setText(String.valueOf(node_expire.getValue()));
	edge_expire_val.setText(String.valueOf(edge_expire.getValue()));
	first_expire_val.setText(String.valueOf(first_expire.getValue()));
	edge_stability_val.setText(String.valueOf(panel.setStability(edge_stability.getValue()) + "%"));
    }

static Surge app;
static Frame mainFrame;
public static void main(String[] args) {
    mainFrame = new Frame("Demo2");
    app = new Surge();
    app.init();
    mainFrame.setSize( app.getSize() );
    mainFrame.add("Center", app);
    mainFrame.show();
    mainFrame.repaint(1000);
    mainFrame.addWindowListener
      (
        new WindowAdapter()
        {
          public void windowClosing    ( WindowEvent wevent )
          {
            System.exit(0);
          }
        }
      );
    app.start();
  }
    public Dimension getSize()
    {
	return new Dimension(600, 600);
    }

}

