package de.tub.eyes.apps.demonstrator;

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.List;

import javax.swing.*;
import javax.swing.border.*;


import com.jgoodies.forms.builder.PanelBuilder;
import com.jgoodies.forms.layout.CellConstraints;
import com.jgoodies.forms.layout.FormLayout;
import com.jgoodies.plaf.plastic.PlasticLookAndFeel;
import com.jgoodies.plaf.plastic.theme.ExperienceBlue;
import com.l2fprod.common.swing.BannerPanel;
import com.l2fprod.common.swing.JButtonBar;

import de.tub.eyes.components.*;
import de.tub.eyes.comm.*;


/**
 * <p>Main Class for the Demonstration. In here all other Components are
 * integrated. This integration is done by making all Components a subclass
 * of {@link de.tub.eyes.components.AbstractComponent AbstractComponent} so the
 * UI and a command button can be obtained in a standardized way.
 * Showing only one Component at a time is achieved simply by using a CardLayout.</p>
 *
 * <p>Additionally this class covers the Communication with a network running
 * TinyOS Applications. Therefore it creates a {@link net.tinyos.message.MoteIF MoteIF}
 * Object and uses it to receive and send Messages on behalf of the loaded Components.
 * On behalf here means that the Demonstrator registers itself at the MoteIF and forwads
 * the received Messages to all registered Listeners.<br>
 * So Components interested in getting messages have to register themselves via the
 * {@link #addListener(String, MessageReceiver) addListener} method and have to implement
 * the {@link de.tub.eyes.MessageReceiver MessageReceiver} Interface.<br>
 * <b>NOTE:</b> Because of the Java inheritance System every Component registered has to check
 * the messages it receives from the Demonstrator if they are of correct type. This is due to the fact
 * that the Demonstrator only receives Message objects, instead of specialized Subclasses of them.
 * (Possibly this can be solved via the AM_TYPE attribute of the Messages, which may allow an identification).
 * </p>
 *
 *
 * @author Joachim Praetorius
 */
public class Demonstrator implements ActionListener {

    private JFrame frame;
    private FormLayout mainLayout;
    private CardLayout cards;
    private PanelBuilder builder;
    private ButtonGroup bGroup;
    private JButtonBar buttonBar;
    private JPanel mainPanel;
    private BannerPanel banner;
    private ImageIcon logo;
    private OutputStream debug;
    private boolean debugToFile = false;
    private static Properties config;
    private static boolean itIsSurge = false;
    private static boolean itIsDrip = false;

    private static MoteComm mc;
    private static ConfigComponent cc;
    
    //private static GraphViewComponent gvc;

    public static GraphViewComponent gvc;
    
    static {     
        readProps();
        
        if (Integer.parseInt(config.getProperty("isSurge","0")) == 1)
            itIsSurge = true;
        
        if (Integer.parseInt(config.getProperty("isDrip","0")) == 1)
            itIsDrip = true;        
    }

    /**
     * Creates a new Demonstrator object. One can specify if a connection to a TinyOS Network should be established
     * (i.e. a MoteIF is instantiated or not). If a connection should be estalbished the Demonstrator tries to connect
     * SerialForwarder running at <code>localhost:9001</code>.
     * @param connectToTinyOS <code>true</code> if a connection to a TinyOS Network should be established, <code>false</code> otherwise
     */
    public Demonstrator() {
        
        frame = new JFrame("Eyes Demonstrator");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.addWindowListener(new WindowAdapter(  ) {
            public void windowClosing(WindowEvent we) {
                
                int ret = JOptionPane.showConfirmDialog(null,"Should I save a snapshot before exiting?",
                        "Snapshot", JOptionPane.YES_NO_OPTION, JOptionPane.QUESTION_MESSAGE);
                    
                if (ret == JOptionPane.OK_OPTION)
                    Snapshot.fireSnapshot(Snapshot.SNAPSHOT_NORMAL);
                
                System.exit(0); 
            }
        });
        frame.setIconImage(new ImageIcon("img/logo.png").getImage());
        frame.getContentPane().add(buildUI());

    }
    
    /**
     * Allows to print out a Message to <code>System.err</code>. Additionally the Message is logged
     * to a file, depending on the value of the <code>debugToFile</code> property of this class, which may
     * be changed by the two Methods mentioned under "see also".
     * @param message The message to print out
     * @see #debugToFile(boolean)
     * @see #debugToFile(boolean, String)
     */
    public void debug(String message) {
        //TODO: Maybe the calling Class should be identified here
        System.err.println(message);
        if (debugToFile) {
            try {
                debug.write(message.getBytes());
                debug.write("\n".getBytes());
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    /**
     * Determines whether calls to debug should be printed to a File or not.
     * If true is passed, the File <code>debug.out</code> is opened, new Messages are
     * appended, if the File already exists. To allow the identification of new Messages a
     * Date Header in the form  dd.MM.yyyy - HH:mm:ss is written as first message.
     * @param b <code>true</code> if debug should be printed to file <code>debug.out</code>, <code>false</code> otherwise
     * @see #debug(String)
     * @see #debugToFile(boolean, String)
     */
    public void debugToFile(boolean b) {
        debugToFile = b;
        if (debugToFile) {
            try {
                debug = new FileOutputStream(config.getProperty("debugFile", "debug.out"), true);
                SimpleDateFormat sdf = new SimpleDateFormat(
                        "dd.MM.yyyy - HH:mm:ss");
                debug.write("\n".getBytes());
                debug.write(sdf.format(new Date()).getBytes());
                debug.write("\n".getBytes());
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    /**
     * Does the same as {@link #debugToFile(boolean) debugToFile()} above. The
     * only difference is that this call allows to provide the name for the file to log to.
     * If the file exists, new messages will be appended.
     * @param b <code>true</code> if debug should be printed to file, <code>false</code> otherwise
     * @param filename The name of the file to print the debug Messages to.
     * @see #debug(String)
     * @see #debugToFile(boolean)
     */
    public void debugToFile(boolean b, String filename) {
        debugToFile = b;
        if (debugToFile) {
            try {
                debug = new FileOutputStream(filename, true);
                SimpleDateFormat sdf = new SimpleDateFormat(
                        "dd.MM.yyyy - HH:mm:ss");
                debug.write("\n".getBytes());
                debug.write(sdf.format(new Date()).getBytes());
                debug.write("\n".getBytes());
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    /**
     * Selects the first Component in the card Layout, enables its button and then <code>pack</code>s and
     * <code>show</code>s the frame.
     */
    public void show() {
        cards.first(mainPanel);
        JToggleButton b = (JToggleButton) bGroup.getElements().nextElement();
        bGroup.setSelected(b.getModel(), true);
        frame.setSize(java.awt.Toolkit.getDefaultToolkit().getScreenSize());
        //frame.setSize(GraphicsEnvironment.getLocalGraphicsEnvironment().getMaximumWindowBounds().width,
        //        GraphicsEnvironment.getLocalGraphicsEnvironment().getMaximumWindowBounds().height);
        //frame.pack();
        frame.show();
    }

    /**
     * Used to add a component to the CardLayout. Given is a subclass of {@link AbstractComponent AbstractComponent}
     * from which the ToggleButton and the UI are taken via the two according Methods {@link AbstractComponent#getButton() getButton()}
     * and {@link AbstractComponent#getUI() getUI()}. These two elements are added to the Button Bar and
     * the card layout respectively.<br>
     * It is <b>required</b> that the Button has an ActionCommand set, as the Component is added to the CardLayout
     * under that String, so this call will fail, if no ActionCommand is available.
     * @param component The Component to add
     * @see AbstractComponent
     */
    public void add(AbstractComponent component) {
        JToggleButton button = component.getButton();
        bGroup.add(button);
        buttonBar.add(button);
        button.addActionListener(this);
        String name = button.getActionCommand();
        mainPanel.add(component.getUI(), name);
//        System.out.println("name = " + name);
    }

    /**
     * Reacts on clicks on the ToggleButtons and show the right Card in the CardLayout
     * @see java.awt.event.ActionListener#actionPerformed(java.awt.event.ActionEvent)
     */
    public void actionPerformed(ActionEvent e) {
        String command = e.getActionCommand();
        if (command == "graphview") gvc.repaint();
        cards.show(mainPanel, command);

    }

    /**
     * Creates the main UserInterface by adding the components to a <a href="http://www.jgoodies.com">FormLayout</a>.
     * @return The JPanel containing the UserInterface
     */
    private Component buildUI() {
        //init components
        //mainLayout = new FormLayout("12dlu,f:p,10dlu,f:max(p;" 
        //        + config.getProperty("sizeX","500dlu") + "dlu):g,12dlu",
        //        "t:p,4dlu,f:max(p;"
        //        + config.getProperty("sizeY","500dlu") + "dlu):g,12dlu");
        mainLayout = new FormLayout("12dlu,c:p, 10dlu, f:0dlu:g, 12dlu", "t:p, 4dlu, f:0dlu:g, 12dlu");
        cards = new CardLayout();

        builder = new PanelBuilder(mainLayout);
        bGroup = new ButtonGroup();
        buttonBar = new JButtonBar(JButtonBar.VERTICAL);
        mainPanel = new JPanel(cards);
        BannerPanel banner = new BannerPanel();
        JPanel bannerPanel = new JPanel();

        bannerPanel.setBackground(Color.CYAN);

        //ImageIcon imageEyes = new ImageIcon("img/eyessmall.png");
        JLabel iconEyes = new JLabel(new ImageIcon("img/test2.png"));
        JLabel iconTub = new JLabel(new ImageIcon("img/tub_tkn-s.png"));
        //JLabel iconTkn = new JLabel(new ImageIcon("img/tkn.png"));
        JLabel iconIfx = new JLabel(new ImageIcon("img/ifx-s.png"));
        bannerPanel.setLayout(new BorderLayout());
        bannerPanel.add(iconTub, BorderLayout.WEST);
        //bannerPanel.add(iconTkn, BorderLayout.SOUTH);
        bannerPanel.add(iconIfx, BorderLayout.EAST);
        bannerPanel.add(iconEyes, BorderLayout.CENTER);


        //finetune components
        banner.setTitle("EYES Demonstrator");
        banner.setSubtitle("Demonstrating Eyes Applications");
        banner.setIcon(logo);
        banner.setBorder(new CompoundBorder(new MatteBorder(0, 0, 1, 0,
                Color.black), new EmptyBorder(10, 10, 10, 10)));
            
        banner.setBackground(Color.cyan);

        //do layout
        CellConstraints cc = new CellConstraints();
        builder.add(bannerPanel, cc.xyw(1, 1, 5));
        builder.add(buttonBar, cc.xy(2, 3));
        builder.add(mainPanel, cc.xy(4, 3));

        return builder.getPanel();

    }

    /**
     * The main method. Creates a new Demonstrator and starts it.<br>
     * <b>NOTE:</b> Currently the configuration of loaded Components and
     * the wiring between different components is currently done in this
     * method. Most possibly it should be done in some external format as well,,
     * but currently this method has to be adjusted to ones needs.
     *
     * @param args Commandline arguments. These are not interpreted by this method.
     */
    public static void main(String[] args) {

        String msgClassName;
        Demonstrator d = new Demonstrator();
        String hostName = config.getProperty("hostName", "localhost");
        int port = Integer.parseInt(config.getProperty("port","9001"));
        int subscriberID = Integer.parseInt(config.getProperty("uartAddr", "126"));
        
        if (itIsSurge) 
            mc = new MoteCommPlain(hostName, port, "net.tinyos.surge.SurgeMsg");            
        else {
            if (itIsDrip)
                mc = new MoteCommDrain(hostName, port, subscriberID);
            else 
                mc = new MoteCommPlain(hostName, port, "net.tinyos.ps.PSNotificationMsg");
        }
        
        try {
            PlasticLookAndFeel.setMyCurrentTheme(new ExperienceBlue());
            UIManager.setLookAndFeel("com.jgoodies.plaf.plastic.PlasticXPLookAndFeel");
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }

        cc = new ConfigComponent();
        
        NetworkViewComponent nvc = new NetworkViewComponent();
        d.add(nvc);
        d.mc.addListener(nvc);
       
        gvc = new GraphViewComponent();
        //gvc = new GraphViewComponent();
        d.add(gvc);
        d.mc.addListener(gvc);       

        SubscriptionTableComponent stc = new SubscriptionTableComponent(d);
        d.add(stc);
        d.mc.addListener(stc);
        
        //********FILTER VIEWS ********//
        nvc.addFilterViewer(gvc);
        
        d.add(cc);
        
        Snapshot.checkIfLocked();

        d.show();
    }

    private static void readProps() {
        try {
            config = new Properties();
            config.load( new FileInputStream("Demonstrator.properties"));
        }
        catch (IOException e) {
            System.err.println(e);
        }
    }
    
    public static Properties getProps() {
        if (config == null)
            readProps();
        return config;
    }
    
    public static ConfigComponent getConfigComponent() {
        return cc;
    }
    
    public static boolean isSurge() { return itIsSurge; }
    
    public static boolean isDrip() { return itIsDrip; }
    
    public static MoteComm getMoteComm() { return mc; }
}
