package net.tinyos.tosser;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;
import java.io.*;
import net.tinyos.descparser.*;

public class Workspace extends JPanel implements 
        FocusListener,
        KeyListener,
        MouseListener, 
        MouseMotionListener,
        ActionListener,
        ComponentAddListener {
    // Constants
    static private final int ADD_COMPONENT = 0;
    static private final int ADD_PINOUT = 1;
    static private final int SELECT = 2;
    static private final int CONNECT = 3;
    static private final int SIGNAL = 4;
    static private final int DELETE = 5;

    static private final int componentBorder = 5;
    static private final Cursor defaultCursor = 
        new Cursor(Cursor.DEFAULT_CURSOR);
    static private final Cursor waitCursor = new Cursor(Cursor.WAIT_CURSOR);

    // Fields
    private JPopupMenu popup;
    private JPopupMenu deletePopup;
    private Vector components, wires;
    private int mode = SELECT;
    private boolean showTips = true;
    private CostPoint grid[][] = null;
    private Object gridLock = new Object();
    private Pinout source, dest;
    private StatusBar statusBar;
    private TOSComp compUnderPointer = null;
    private TOSComp draggedComp = null;
    private TOSComp addedComp = null;
    private boolean droppable = false;
    private int origX, origY;
    private int lastX = -1, lastY = -1;
    private int componentPadding = 50;
    private MonitorDialog moduleLoadMonitor;
    private MonitorDialog wireDrawMonitor;
    private JProgressBar wireProgress;
    private EventQueueThread eventQueueThread;
    private LinkedList eventQueue;
    private boolean layingOutComponents = false, drawingWires = false;
    private SimulationControl simCntl;
    private File appDir;

    public Workspace(StatusBar statusBar) {
        super();

        this.statusBar = statusBar;

        setPreferredSize(new Dimension(500, 400));

        components = new Vector();
        wires = new Vector();

        addFocusListener(this);
        addKeyListener(this);
        addMouseListener(this);
        addMouseMotionListener(this);

        moduleLoadMonitor = new MonitorDialog("Loading modules...", null);
        wireProgress = new JProgressBar();
        wireProgress.setStringPainted(true);
        wireDrawMonitor = new MonitorDialog("Drawing wires...", wireProgress);

        SimulationControl simCntl = new SimulationControl();
        JFrame frame = new JFrame();
        frame.getContentPane().add(simCntl);
        frame.pack();
        frame.show();
        
        eventQueue = new LinkedList();
        eventQueueThread = new EventQueueThread(eventQueue, simCntl, this);
        eventQueueThread.start();

        File TOSDir = new File(Tosser.getProperties().getProperty("tosdir") +
                               File.separator + "tos");
        new ComponentSelectionFrame(TOSDir, this).setVisible(true);

        requestFocus();
    }

    private void rebound() {
        Rectangle bound = new Rectangle();
        synchronized(components) {
            Iterator iter = components.iterator();
            while (iter.hasNext()) {
                TOSComp comp = (TOSComp)iter.next();
                bound = bound.union(comp);
            }
            bound.width += componentPadding * 2;
            bound.height += componentPadding * 2;

            Dimension d = getSize();
            if (bound.height > d.height || bound.width > d.width) {
                setSize(bound.getSize());
                setPreferredSize(bound.getSize());
            }
        }
    }

    private void layoutComponents() {
        int maxLevel = 1;
        int widest = 0;
        Dimension bound = new Dimension(0, componentPadding);
        Vector levels[];
        int widths[];
        int heights[];

        Iterator iter;
            
        synchronized(components) {
            iter = components.iterator();
            while (iter.hasNext()) {
                TOSComp comp = (TOSComp)iter.next();
                maxLevel = Math.max(maxLevel, comp.getLevel() + 1);
            }

            widths = new int[maxLevel];
            heights = new int[maxLevel];
            levels = new Vector[maxLevel];

            for (int i = 0; i < levels.length; i++) {
                levels[i] = new Vector();
                widths[i] = componentPadding;
            }

            iter = components.iterator();
            while (iter.hasNext()) {
                TOSComp comp = (TOSComp)iter.next();

                int level = comp.getLevel();
                levels[level].add(comp);
                widths[level] += comp.width + componentPadding;
                heights[level] = Math.max(heights[level], comp.height);
            }

            for (int i = 0; i < maxLevel; i++) {
                bound.height += heights[i] + componentPadding;
                widths[i] += componentPadding * (levels[i].size() + 2);
                if (widths[i] > bound.width) {
                    bound.width = widths[i];
                    widest = i;
                }
            }

            int center = bound.width / 2;

            int x, y = componentPadding;
            for (int i = 0; i < maxLevel; i++) {
                x = componentPadding + center - widths[i] / 2;

                iter = levels[i].iterator();
                while (iter.hasNext()) {
                    TOSComp comp = (TOSComp)iter.next();

                    comp.x = x;
                    comp.y = y;
                    x += comp.width + componentPadding;
                }

                y += heights[i] + componentPadding;
            }
        }

        rebound();
    }

    public void paintComponent(Graphics g) {
        super.paintComponent(g);

        requestFocus();

        ListIterator iter;
        
        Rectangle rect = new Rectangle(getSize());

        /*
        if (grid != null) {
        for (int x = 0; x < rect.width; x++) {
            for (int y = 0; y < rect.height; y++) {
                int cost = grid[x][y].getCost();
                if (cost >= 0) {
                    g.setColor(new Color(Math.min(cost, 255), 0, 0));
                    g.drawRect(x, y, 1, 1);
                }
            }
        }
        }
        */

        Color outlineColor = Color.green;
        droppable = true;

        synchronized(this) {
            if (layingOutComponents)
                return;
        }

        synchronized(components) {
            iter = components.listIterator();
            while (iter.hasNext()) {
                TOSComp tc = (TOSComp)iter.next();

                if (tc != draggedComp && tc != addedComp) {
                    tc.paint(g, source);
                    if (addedComp != null && addedComp.intersects(tc)) {
                        outlineColor = Color.red;
                        droppable = false;
                    }
                    if (draggedComp != null && draggedComp.intersects(tc)) {
                        outlineColor = Color.red;
                        droppable = false;
                    }
                }
            }
        }

        if (draggedComp != null) {
            g.setColor(outlineColor);
            g.drawRect(draggedComp.x, draggedComp.y, 
                       draggedComp.width, draggedComp.height);
        }

        if (addedComp != null) {
            g.setColor(outlineColor);
            g.drawRect(addedComp.x, addedComp.y, 
                       addedComp.width, addedComp.height);
        }

        synchronized(wires) {
            iter = wires.listIterator();
            while (iter.hasNext()) {
                Wire w = (Wire)iter.next();
                if (w.getSourcePin().getOwner() == draggedComp ||
                    w.getDestPin().getOwner() == draggedComp) {
                    continue;
                }
                if (!w.getStartPoint().equals(w.getSourcePin().getHotPoint()) ||
                    !w.getEndPoint().equals(w.getDestPin().getHotPoint())) {
                    w = newWire(w.getSourcePin(), w.getDestPin());
                    iter.set(w);
                }

                w.paint(g);
            }
        }
    }

    private TOSComp getTOSCompAtPoint(int x, int y) {
        Iterator iter = components.iterator();
        while (iter.hasNext()) {
            TOSComp tc = (TOSComp)iter.next();
            if (tc.contains(x, y))
                return tc;
        }

        return null;
    }

    private Vector getWiresAtPoint(int x, int y) {
        Vector wapv = new Vector();
        Iterator iter;
        iter = wires.iterator();
        while (iter.hasNext()) {
            Wire w = (Wire)iter.next();
            if (w.contains(x, y))
                wapv.add(w);
        }

        return wapv;
    }

    private Vector getWiresOnPinout(Pinout po) {
        Vector wopv = new Vector();
        Iterator iter;
        iter = wires.iterator();
        while (iter.hasNext()) {
            Wire w = (Wire)iter.next();
            if (w.getSourcePin() == po || w.getDestPin() == po)
                wopv.add(w);
        }

        return wopv;
    }

    private Pinout findPinoutByName(String name) {
        Iterator iter = components.iterator();
        while (iter.hasNext()) {
            TOSComp c = (TOSComp)iter.next();

            Iterator pIter = c.getAllPins().iterator();
            while (pIter.hasNext()) {
                Pinout p = (Pinout)pIter.next();

                if (p.getName().equalsIgnoreCase(name))
                    return p;
            }
        }

        return null;
    }

    public Vector getWiresOnPinoutByName(String name) {
        return getWiresOnPinout(findPinoutByName(name));
    }

    private class MonitorDialog extends JDialog {
        private JLabel label;

        public MonitorDialog(String title, JComponent extra) {
            super(JOptionPane.getFrameForComponent(Workspace.this));

            setTitle(title);
            setModal(false);

            Container c = getContentPane();
            c.setLayout(new BoxLayout(c, BoxLayout.Y_AXIS));

            JPanel panel;
            panel = new JPanel(new FlowLayout(FlowLayout.LEFT));
            c.add(panel);
            panel.add(new JLabel(title));

            panel = new JPanel(new FlowLayout(FlowLayout.LEFT));
            c.add(panel);
            label = new JLabel();
            panel.add(label);

            if (extra != null)
                c.add(extra);

            Dimension d = getToolkit().getScreenSize();
            setLocation(d.width/2, d.height/2);
            pack();
        }

        public void setText(String modName) {
            label.setText(modName);
            pack();
        }
    }

    private class AppWizard extends JDialog implements ActionListener {
        private JTextField createField, openField;
        private JButton okButton, cancelButton, chooserButton;
        private JRadioButton create, open;
        private File descFile;
        private String name;

        public AppWizard(){
            super(JOptionPane.getFrameForComponent(Workspace.this));

            setTitle("Open an application");
            setModal(true);

            Container c = getContentPane();
            c.setLayout(new BoxLayout(c, BoxLayout.Y_AXIS));

            JPanel panel;

            ButtonGroup radioGroup = new ButtonGroup();
            
            panel = new JPanel(new FlowLayout(FlowLayout.LEFT));
            c.add(panel);

            create = new JRadioButton("Create a new application", true);
            create.setActionCommand("CREATE");
            create.addActionListener(this);
            radioGroup.add(create);
            panel.add(create);
    
            createField = new JTextField(20);
            panel.add(createField);

            panel = new JPanel(new FlowLayout(FlowLayout.LEFT));
            c.add(panel);

            open = new JRadioButton("Open an existing application", false);
            open.setActionCommand("OPEN");
            open.addActionListener(this);
            radioGroup.add(open);
            panel.add(open);

            openField = new JTextField(20);
            openField.setEnabled(false);
            panel.add(openField);

            chooserButton = new JButton("Open...");
            chooserButton.setActionCommand("OPEN CHOOSER");
            chooserButton.addActionListener(this);
            chooserButton.setEnabled(false);
            panel.add(chooserButton);

            panel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
            c.add(panel);

            okButton = new JButton("Ok");
            okButton.setActionCommand("OK");
            okButton.addActionListener(this);
            panel.add(okButton);

            cancelButton = new JButton("Cancel");
            cancelButton.setActionCommand("CANCEL");
            cancelButton.addActionListener(this);
            panel.add(cancelButton);

            pack();
        }

        public File getDescFile() {
            return descFile;
        }

        public String getName() {
            return name;
        }

        public void actionPerformed(ActionEvent e) {
            String actionCommand = e.getActionCommand();

            if (actionCommand.equals("CREATE")) {
                createField.setEnabled(true);
                openField.setEnabled(false);
                chooserButton.setEnabled(false);
            } else if (actionCommand.equals("OPEN")) {
                createField.setEnabled(false);
                openField.setEnabled(true);
                chooserButton.setEnabled(true);
            } else if (actionCommand.equals("OPEN CHOOSER")) {
                JFileChooser chooser = 
                    new JFileChooser(
                            Tosser.getProperties().getProperty("tosdir") +
                            File.separator + "apps");
                chooser.addChoosableFileFilter(TOS.fileChooserAppFilter);
                if (chooser.showOpenDialog(this) == JFileChooser.APPROVE_OPTION)
                    openField.setText(
                            chooser.getSelectedFile().getAbsolutePath());
            } else if (actionCommand.equals("OK")) {
                if (createField.isEnabled()) {
                    descFile = null;
                    name = createField.getText();
                } else {
		    String path = openField.getText();
		    //System.out.println("Selected path : <" + path + ">");
		    if (path == null || path.equals("")) {
			descFile = null;
			return;
		    }
		    File app = new File(openField.getText());
                    if (app.isDirectory()) {
                        name = app.getName();
                        File files[] = app.listFiles(TOS.descFilter);
                        for (int i = 0; i < files.length; i++) {
                            if (files[i].getName().equalsIgnoreCase(
                                        name + ".desc")) {
                                app = files[i];
                                break;
                            }
                        }
                        if (app.isDirectory()) {
                            descFile = null;
                            name = null;
                            return;
                        }
                    } else {
                        descFile = app;
                        name = app.getName();
                    }
                }
                hide();
            } else if (actionCommand.equals("CANCEL")) {
                hide();
            }
        }
    }

    private boolean componentLoaded(TOSComp comp) {
        synchronized(components) {
            Iterator iter = components.iterator();

            while (iter.hasNext()) {
                TOSComp c = (TOSComp)iter.next();

                if (comp.getName().equalsIgnoreCase(c.getName()))
                    return true;
            }
        }

        return false;
    }

    private class WireHolder {
        private DescParser.Pinout source, dest;

        public WireHolder(DescParser.Pinout source, DescParser.Pinout dest){
            this.source = source;
            this.dest = dest;
        }

        public DescParser.Pinout getSource() {
            return source;
        }

        public DescParser.Pinout getDest() {
            return dest;
        }

        public String toString() {
            return source.toString() + " -> " + dest.toString();
        }

        public boolean equals(Object o) {
            WireHolder wh = (WireHolder)o;
            return (wh.source.toString().equals(source.toString()) &&
                    wh.dest.toString().equals(dest.toString()));
        }
    }

    private Vector loadModulesFromDescriptionHelper(String descName,
                                                    DescParser.Description desc,
                                                    Set descsSeen,
                                                    int level) {
        Iterator iter;
        Vector wireHolders = new Vector();
        
        desc.getModules().add(descName);
        iter = desc.getModules().iterator();
        while (iter.hasNext()) {
            int modLevel = level;
            String modName = (String)iter.next();
            System.out.println(modName);
            moduleLoadMonitor.setText(modName);
            File TOSDir = new File(
                    Tosser.getProperties().getProperty("tosdir") +
                    File.separator + "tos");
            File modCompFile = TOS.findTOSSystemModule(TOSDir, modName);

            if (modCompFile == null && appDir.isDirectory()) {
                File files[] = appDir.listFiles(TOS.compFilter);
                for (int i = 0; i < files.length; i++) {
                    if (files[i].getName().equalsIgnoreCase(modName+".comp")) {
                        modCompFile = files[i];
                        modLevel = 0;
                        break;
                    }
                }
            }

            if (modCompFile != null) {
                System.out.println(modCompFile.getAbsolutePath() + " " + modLevel);
                TOSComp module = new TOSComp(this, modCompFile, 0, 0, modLevel);
                if (componentLoaded(module))
                    continue;

                synchronized(components) {
                    components.add(module);
                }
                DescParser.Description modDesc = module.getDescription();
                File descFile = module.getDescFile();

                // Is this an independent component?
                if (modDesc != null && !descsSeen.contains(descFile.getName())){
                    descsSeen.add(descFile.getName());
                    wireHolders.addAll(
                            loadModulesFromDescriptionHelper(descName, 
                                                             modDesc, descsSeen,
                                                             level + 1));
                }
            }
        }

        iter = desc.getConnections().iterator();
        while (iter.hasNext()) {
            Iterator cIter = ((Vector)iter.next()).iterator();
            if (cIter.hasNext()) {
                DescParser.Pinout source = (DescParser.Pinout)cIter.next();

                while (cIter.hasNext()) {
                    DescParser.Pinout po = (DescParser.Pinout)cIter.next();
                    WireHolder wh = new WireHolder(source, po);
                    wireHolders.add(wh);
                }
            }
        }

        return wireHolders;
    } 

    private Vector loadModulesFromDescription(File descFile) {
        DescParser.Description desc = null;
        DescParser parser = null;
        try {
            parser = new DescParser(new FileReader(descFile));
        } catch (FileNotFoundException e) {
        }
        try {
            desc = parser.File();
        } catch (net.tinyos.descparser.ParseException e) {
        }

        appDir = descFile.getParentFile();;
        HashSet descsSeen = new HashSet();
        descsSeen.add(descFile.getName());
        String descName = ExtensionFilter.getFilenameWithoutExtension(descFile);

        return loadModulesFromDescriptionHelper(descName, desc, descsSeen, 1);
    }

    private class LoaderThread extends Thread {
        private File descFile;

        public LoaderThread(File descFile) {
            this.descFile = descFile;
        }

        public void run() {
            moduleLoadMonitor.show();
            synchronized(this) {
                layingOutComponents = true;
            }
            Vector wireHolders = loadModulesFromDescription(descFile);
            layoutComponents();
            synchronized(this) {
                layingOutComponents = false;
            }
            moduleLoadMonitor.hide();

            int numWHs = wireHolders.size();
            int numDone = 0;
            wireProgress.setMaximum(numWHs);
            wireProgress.setValue(0);
            wireDrawMonitor.show();
            Iterator iter = wireHolders.iterator();
            while (iter.hasNext()) {
                WireHolder wh = (WireHolder)iter.next();

                Pinout src = findPinoutByName(wh.getSource().getName());
                Pinout dest = findPinoutByName(wh.getDest().getName());

                if (src == null) {
                    System.out.println("Couldn't find source pin " + 
                            wh.getSource().getName());
                    continue;
                }

                if (dest == null) {
                    System.out.println("Couldn't find dest pin " + 
                            wh.getDest().getName());
                    continue;
                }

                wireDrawMonitor.setText(src.getFullName() + " -> " + 
                                        dest.getFullName());
                wireProgress.setValue(numDone++);
                Wire w = newWire(src, dest);
                if (w != null) synchronized(wires) {
                    wires.add(w);
                }
                repaint();
            }
            wireDrawMonitor.hide();
            repaint();
        }
    }

    private void addComponentAtPoint(int x, int y) {
        AppWizard appWizard = new AppWizard();

        appWizard.show();

        File descFile = appWizard.getDescFile();
        String appName = appWizard.getName();

        if (appName == null && descFile == null) {
            return;
        }
        
        if (descFile == null) {
            TOSComp comp = new TOSComp(this, appName, 0);
            synchronized(components) {
                components.add(comp);
            }
            synchronized(this) {
                layingOutComponents = true;
            }
            layoutComponents();
            synchronized(this) {
                layingOutComponents = false;
            }
        } else {
            Thread loader = new LoaderThread(descFile);
            loader.start();
        }
    }

    // Use Lee's algorithm to find wire path
    private Wire newWire(Pinout source, Pinout dest) {
        synchronized(gridLock) {
            setCursor(waitCursor);
            LinkedList queue = new LinkedList();

            Rectangle rect = new Rectangle(getSize());
            grid = new CostPoint[rect.width][rect.height];
            for (int i = 0; i < rect.width; i++)
                for (int j = 0; j < rect.height; j++)
                    grid[i][j] = new CostPoint(i, j);

            // Block out components
            Iterator iter = components.iterator();
            while (iter.hasNext()) {
                TOSComp comp = (TOSComp)iter.next();
                int iStart = Math.max(comp.x - componentBorder, 0); 
                int jStart = Math.max(comp.y - componentBorder, 0); 
                int iEnd = Math.min(comp.x + comp.width + componentBorder,
                                    rect.width);
                int jEnd = Math.min(comp.y + comp.height + componentBorder,
                                    rect.height);
                for (int i = iStart; i < iEnd; i++) {
                    for (int j = jStart; j < jEnd; j++) {
                        if (comp.contains(i, j)) {
                            grid[i][j].setParent(grid[i][j]);
                            grid[i][j].setCost(Integer.MAX_VALUE);
                        } else {
                            // Make the padding area expensive
                            grid[i][j].incrementBaseCost(componentBorder);
                        }
                    }
                }
            }

            // Make wires expensive
            iter = wires.iterator();
            while (iter.hasNext()) {
                LinkedList extents = ((Wire)iter.next()).getExtents();

                Iterator eIter = extents.iterator();
                while (eIter.hasNext()) {
                    Rectangle e = rect.intersection((Rectangle)eIter.next());
                    for (int x = e.x; x < e.x + e.width; x++)
                        for (int y = e.y; y < e.y + e.height; y++)
                            grid[x][y].incrementBaseCost(5);
                }
            }

            int iStart, iEnd;
            Point hp;
            hp = dest.getHotPoint();
            // Cut a cross out around the hotspot because of padding
            iStart = Math.max(0, hp.x - componentBorder);
            iEnd = Math.min(rect.width, hp.x + componentBorder);
            for (int i = iStart; i < iEnd; i++)
                grid[i][hp.y].setParent(null);

            iStart = Math.max(0, hp.y - componentBorder);
            iEnd = Math.min(rect.height, hp.y + componentBorder);
	    try {
		for (int i = iStart; i < iEnd; i++) {
		    grid[hp.x][i].setParent(null);
		}
	    }
	    catch (ArrayIndexOutOfBoundsException exception) {
		System.err.println("Exception thrown when drawing wire between " + source.getFullName() + " and " + dest.getFullName() +": this wire will not be visualized.");
		return new Wire(source, dest);
	    }
            hp = source.getHotPoint();
            grid[hp.x][hp.y].setCost(0);

            // Cut a cross out around the hotspot because of padding
            iStart = Math.max(0, hp.x - componentBorder);
            iEnd = Math.min(rect.width, hp.x + componentBorder);
            for (int i = iStart; i < iEnd; i++)
                grid[i][hp.y].setParent(null);

            iStart = Math.max(0, hp.y - componentBorder);
            iEnd = Math.min(rect.height, hp.y + componentBorder);
            for (int i = iStart; i < iEnd; i++)
                grid[hp.x][i].setParent(null);

            grid[hp.x][hp.y].setParent(grid[hp.x][hp.y]);

            queue.add(grid[hp.x][hp.y]);
            while(queue.size() > 0) {
                CostPoint top = (CostPoint)queue.remove(0);
                
                if (top.x == dest.getHotPoint().x && top.y == dest.getHotPoint().y)
                    break;
                
                // Only go in 4 directions
                if (top.x != 0) {
                    if (grid[top.x-1][top.y].getParent() == null) {
                        grid[top.x-1][top.y].setCost(top.getCost() + 1);
                        grid[top.x-1][top.y].setParent(top);
                        queue.add(grid[top.x-1][top.y]);
                    } else if (top.getCost() + 1 < grid[top.x-1][top.y].getCost()) {
                        grid[top.x-1][top.y].setCost(top.getCost() + 1);
                        grid[top.x-1][top.y].setParent(top);
                    }
                }

                if (top.x != rect.width-1) {
                    if (grid[top.x+1][top.y].getParent() == null) {
                        grid[top.x+1][top.y].setCost(top.getCost() + 1);
                        grid[top.x+1][top.y].setParent(top);
                        queue.add(grid[top.x+1][top.y]);
                    } else if (top.getCost() + 1 < grid[top.x+1][top.y].getCost()) {
                        grid[top.x+1][top.y].setCost(top.getCost() + 1);
                        grid[top.x+1][top.y].setParent(top);
                    }
                }

                if (top.y != 0) { 
                    if (grid[top.x][top.y-1].getParent() == null) {
                        grid[top.x][top.y-1].setCost(top.getCost() + 1);
                        grid[top.x][top.y-1].setParent(top);
                        queue.add(grid[top.x][top.y-1]);
                    } else if (top.getCost() + 1 < grid[top.x][top.y-1].getCost()) {
                        grid[top.x][top.y-1].setCost(top.getCost() + 1);
                        grid[top.x][top.y-1].setParent(top);
                    }
                }

                if (top.y != rect.height-1) {
                    if (grid[top.x][top.y+1].getParent() == null) {
                        grid[top.x][top.y+1].setCost(top.getCost() + 1);
                        grid[top.x][top.y+1].setParent(top);
                        queue.add(grid[top.x][top.y+1]);
                    } else if (top.getCost() + 1 < grid[top.x][top.y+1].getCost()) {
                        grid[top.x][top.y+1].setCost(top.getCost() + 1);
                        grid[top.x][top.y+1].setParent(top);
                    }
                }
            }

            hp = dest.getHotPoint();
            if (grid[hp.x][hp.y].getParent() == null) {
                return null;
            }

            source.connect(dest);
            Wire w = new Wire(source, dest, grid[hp.x][hp.y]);

            setCursor(defaultCursor);

            return w;
        }
    }

    // MouseListener methods

    public void mouseClicked(MouseEvent e) {
        switch (mode) {
            case ADD_COMPONENT:
                if (compUnderPointer != null)
                    break;
                addComponentAtPoint(e.getX(), e.getY());
                break;
            case SELECT:
                if (compUnderPointer != null)
                    compUnderPointer.toggleSelected();
                break;
        }

        repaint();
    }

    public void mousePressed(MouseEvent e) {
        if (e.isPopupTrigger()) {
            if (compUnderPointer != null) {
                Pinout po = compUnderPointer.getPinoutAtPoint(e.getX(), 
                                                              e.getY());
                if (po == null) {
                    popup = compUnderPointer.getPopupMenu();
                    popup.show(e.getComponent(), e.getX(), e.getY());
                } else {
                    popup = po.getPopupMenu();
                    popup.show(e.getComponent(), e.getX(), e.getY());
                }
                return;
            }
        } else {
            switch (mode) {
                case CONNECT:
                    if (compUnderPointer != null) {
                        source = compUnderPointer.getPinoutAtPoint(e.getX(),
                                                                   e.getY());
                        if (source.isConnectable()) {
                            statusBar.setMainStatusText(source.getName() + 
                                                        " -> ");
                        } else {
                            source = null;
                            statusBar.setMainStatusText(source.getName() + 
                                    " is defined and cannot be connected");
                        }
                    }
                    break;
/*                case SIGNAL:
                    if (compUnderPointer != null) {
                        Pinout po = compUnderPointer.getPinoutAtPoint(e.getX(), 
                                                                      e.getY());

                        Iterator iter;

                        if (po == null) 
                            iter = getWiresAtPoint(e.getX(), 
                                                   e.getY()).iterator();
                        else 
                            iter = getWiresOnPinout(po).iterator();
                        
                        while (iter.hasNext()) {
                            Wire w = (Wire)iter.next();

                            synchronized (eventQueue) {
                                eventQueue.add(new WireSignalEvent(w));
                                eventQueue.notify();
                            }
                        }
                    }
                    break; */
                case SELECT:
                    if (compUnderPointer != null) {
                        draggedComp = compUnderPointer;
                        origX = draggedComp.x;
                        origY = draggedComp.y;
                        lastX = -1;
                        lastY = -1;
                    }

                    break;
            }
            if (addedComp != null && droppable) {
                addedComp = null;
                droppable = false;
            }
        }
    }

    public void mouseReleased(MouseEvent e) {
        if (e.isPopupTrigger()) {
            popup.show(e.getComponent(), e.getX(), e.getY());
            return;
        } else {
            if (draggedComp != null) {
                if (!droppable) {
                    draggedComp.x = origX;
                    draggedComp.y = origY;
                }
                droppable = false;
                draggedComp = null;
                repaint();
            }
            switch (mode) {
                case CONNECT:
                    if (source != null) {
                        if (compUnderPointer != null) {
                            dest = compUnderPointer.getPinoutAtPoint(e.getX(), 
                                                                     e.getY());
                            Wire w = newWire(source, dest);
                            if (w != null) synchronized(wires) {
                                wires.add(w);
                            }
                            repaint();
                        }
                        source = null;
                        dest = null;
                    }
                    break;
                case DELETE:
                    if (compUnderPointer != null) {
                        Pinout po = compUnderPointer.getPinoutAtPoint(e.getX(),
                                                                      e.getY());
                        if (po != null) {
                            Vector wiresOnPin = getWiresOnPinout(po);
                            synchronized(wires) {
                                wires.removeAll(wiresOnPin);
                            }
                            compUnderPointer.removePinout(po);
                        } else {
                            Vector pins = compUnderPointer.getAllPins();
                            synchronized(wires) {
                                Iterator iter = pins.iterator();
                                while (iter.hasNext()) {
                                    Pinout pin = (Pinout)iter.next();
                                    Vector wiresOnPin = getWiresOnPinout(pin);
                                    wires.removeAll(wiresOnPin);
                                }
                            }
                            synchronized(components) {
                                components.remove(compUnderPointer);
                            }
                        }
                    } else {
                        Vector wiresAtPoint = getWiresAtPoint(e.getX(), 
                                                              e.getY());
                        if (wiresAtPoint.size() == 1) {
                            synchronized(wires) {
                                wires.removeAll(wiresAtPoint);
                            }
                        } else {
                            deletePopup = new JPopupMenu();
                            JMenuItem menuItem;

                            Iterator iter = wiresAtPoint.iterator();
                            while (iter.hasNext()) {
                                Wire w = (Wire)iter.next();
                                menuItem = new JMenuItem(w.toString());
                                menuItem.setActionCommand(w.toString());
                                menuItem.addActionListener(this);
                                deletePopup.add(menuItem);
                            }

                            deletePopup.show(e.getComponent(), 
                                             e.getX(), e.getY());
                        }
                    }
                    break;
            }
        }
    }

    public void mouseEntered(MouseEvent e) {
    }

    public void mouseExited(MouseEvent e) {
    }

    // MouseMotionListener methods

    public void mouseMoved(MouseEvent e) {
        if (showTips) {
            compUnderPointer = getTOSCompAtPoint(e.getX(), e.getY());
            if (compUnderPointer != null) {
                setToolTipText(
                        compUnderPointer.getToolTipText(e.getX(), e.getY()));
            } else {
                String s = "<HTML>";

                Iterator iter = getWiresAtPoint(e.getX(), e.getY()).iterator();
                while (iter.hasNext()) {
                    Wire w = (Wire)iter.next();

                    s += w.toString();
                    if (iter.hasNext())
                        s += "<BR>";
                }
                s += "</HTML>";
                setToolTipText(s);
            }
        }
        if (addedComp != null) {
            if (lastX == -1)
                lastX = e.getX();
            if (lastY == -1)
                lastY = e.getY();

            addedComp.x += e.getX() - lastX;
            addedComp.y += e.getY() - lastY;
            lastX = e.getX();
            lastY = e.getY();
            repaint();
        }
    }

    public void mouseDragged(MouseEvent e) {
        if (draggedComp != null) {
            if (lastX == -1)
                lastX = e.getX();
            if (lastY == -1)
                lastY = e.getY();

            draggedComp.x += e.getX() - lastX;
            draggedComp.y += e.getY() - lastY;
            lastX = e.getX();
            lastY = e.getY();
        } else if (source != null) {
            compUnderPointer = getTOSCompAtPoint(e.getX(), e.getY());
            if (compUnderPointer != null) {
                Pinout po = compUnderPointer.getPinoutAtPoint(e.getX(), 
                                                              e.getY());
                if (po != null) {
                    statusBar.setMainStatusText(source.getFullName() + " -> " +
                                                po.getFullName());
                }
            } else {
                statusBar.setMainStatusText(source.getFullName() + " -> ");
            }
        }
        repaint();
    }

    // KeyListener methods
    public void keyTyped(KeyEvent e) {
    }

    private Simulator sim = null;
    public void keyPressed(KeyEvent e) {
        switch (e.getKeyCode()) {
            case KeyEvent.VK_A:
                mode = ADD_COMPONENT;
                statusBar.setModeText("Add Component");
                break;
            case KeyEvent.VK_S:
                mode = SELECT;
                statusBar.setModeText("Select");
                break;
            case KeyEvent.VK_C:
                mode = CONNECT;
                statusBar.setModeText("Connect");
                break;
            case KeyEvent.VK_I:
                mode = SIGNAL;
                statusBar.setModeText("Signal");
                break;
            case KeyEvent.VK_M:
                try {
                    File executable = new File(appDir.getAbsolutePath() + 
                                               File.separator + "binpc" + 
                                               File.separator + "main");

                    System.out.println("running " + executable);
                    sim = new Simulator(executable.getAbsolutePath(),
                                        1, eventQueue, this);
                    sim.start();
                } catch (IOException ioe) {
                    System.out.println("" + ioe);
                }
                break;
            case KeyEvent.VK_D:
                mode = DELETE;
                statusBar.setModeText("Delete");
                break;
        }
    }

    public void keyReleased(KeyEvent e) {
    }

    // FocusListener methods
    public void focusGained(FocusEvent e) {
    }

    public void focusLost(FocusEvent e) {
        requestFocus();
    }

    // ComponentAddListener method
    public void addComponent(TOSComponent component) {
        if (component.isCompound()) {
            new LoaderThread(component.getFile()).start();
        } else {
            TOSComp comp = new TOSComp(this, component.getFile(), 0, 0, 1);
            synchronized(components) {
                components.add(comp);
                addedComp = comp;
                origX = addedComp.x;
                origY = addedComp.y;
                lastX = -1;
                lastY = -1;
            }
            rebound();
            repaint();
        }
    }

    public void actionPerformed(ActionEvent e) {
        String wireToDelete = e.getActionCommand();
        synchronized(wires) {
            Iterator iter = wires.iterator();
            while (iter.hasNext()) {
                Wire w = (Wire)iter.next();
                if (w.toString().equals(wireToDelete)) {
                    iter.remove();
                    break;
                }
            }
        }
        repaint();
    }

    public void save(String filename) throws IOException {
        File file = new File(filename);
        FileWriter writer = new FileWriter(file);

        writer.write("/* .desc file generated by TOSSER */\n");
        writer.write("\n");

        // Write out the header
        writer.write("include modules{\n");

        for (int i = 0; i < components.size(); i++) {
            TOSComp comp = (TOSComp)components.elementAt(i);
            writer.write(comp.getName() + ";\n");
        }

        writer.write("};\n");
        writer.write("\n");

        //Write out the aliases

        for (int i = 0; i < wires.size(); i++) {
            Wire wire = (Wire)wires.elementAt(i);

            Pinout pin = wire.getSourcePin();
            writer.write(pin.getFullName());
            writer.write(" ");

            pin = wire.getDestPin();
            writer.write(pin.getFullName());
            writer.write("\n");
        }

        writer.close();
    }
}
