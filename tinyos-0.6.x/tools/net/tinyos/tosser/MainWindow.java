package net.tinyos.tosser;

import javax.swing.*;
import javax.swing.border.*;
import javax.swing.filechooser.*;
import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.util.*;

public class MainWindow extends JFrame implements ActionListener {
    private JScrollPane scrollPane;
    private Workspace workspace;
    private StatusBar statusBar;
    private File TOSDir;

    private void addMenuBar() {
        JMenuBar menuBar = new JMenuBar();
        setJMenuBar(menuBar);

        JMenu menu;
        JMenuItem menuItem;
        
        // File
        menu = new JMenu("File");
        menu.setMnemonic(KeyEvent.VK_F);
        menuBar.add(menu);

        menuItem = new JMenuItem("Open...", KeyEvent.VK_O);
        menu.add(menuItem);

        menuItem = new JMenuItem("Save...", KeyEvent.VK_S);
        menuItem.setAccelerator(KeyStroke.getKeyStroke(
                    KeyEvent.VK_S, ActionEvent.CTRL_MASK));
        menuItem.setActionCommand("FILE/SAVE");
        menuItem.addActionListener(this);
        menu.add(menuItem);

        menuItem = new JMenuItem("Close", KeyEvent.VK_C);
        menuItem.setAccelerator(KeyStroke.getKeyStroke(
                    KeyEvent.VK_W, ActionEvent.CTRL_MASK));
        menuItem.setActionCommand("FILE/CLOSE");
        menuItem.addActionListener(this);
        menu.add(menuItem);

        menu.addSeparator();

        menuItem = new JMenuItem("Quit", KeyEvent.VK_Q);
        menuItem.setAccelerator(KeyStroke.getKeyStroke(
                    KeyEvent.VK_Q, ActionEvent.CTRL_MASK));
        menuItem.setActionCommand("FILE/QUIT");
        menuItem.addActionListener(this);
        menu.add(menuItem);

        // Components
        menu = new JMenu("Components");
        menu.setMnemonic(KeyEvent.VK_C);
        menuBar.add(menu);

        menuItem = new JMenuItem("Set TOS Directory...", KeyEvent.VK_I);
        menuItem.setActionCommand("COMPONENTS/SET TOS DIRECTORY");
        menuItem.addActionListener(this);
        menu.add(menuItem);
    }
    
    public MainWindow(String name) {
        super(name);

        this.TOSDir = new File(Tosser.getProperties().getProperty("tosdir") + 
                               File.separator + "tos");

        addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent e) {System.exit(0);}
        });

        Container c = getContentPane();
        c.setLayout(new BorderLayout());

        statusBar = new StatusBar("Welcome to Tosser", "Add Component");
        c.add(statusBar, BorderLayout.SOUTH);

        addMenuBar();

        workspace = new Workspace(statusBar);
        scrollPane = new JScrollPane(workspace);
        c.add(scrollPane);

        pack();
    }

    public void actionPerformed(ActionEvent e) {
        String actionCommand = e.getActionCommand();

        if (actionCommand.equals("FILE/QUIT")) {
            System.exit(0);
        } else if (actionCommand.equals("FILE/SAVE")) {
            JFileChooser chooser = new JFileChooser();
            if (chooser.showOpenDialog(this) == JFileChooser.APPROVE_OPTION) {
                File file = chooser.getSelectedFile();
                try {
                    workspace.save(file.getAbsolutePath());
                } catch (IOException ioe) {
                    JLabel label = new JLabel("<HTML><CENTER>" +
                            "There was an error while trying " +
                            "save your file " +
                            file.getAbsolutePath() +
                            "\"" + ioe + "\"" + 
                            "</CENTER></HTML>");
                    JOptionPane.showMessageDialog(this, label, 
                            "Error while saving",
                            JOptionPane.ERROR_MESSAGE);
                }
            }
        } else if (actionCommand.equals("FILE/CLOSE")) {
            Container c = getContentPane();
            c.remove(scrollPane);
            workspace = new Workspace(statusBar);
            scrollPane = new JScrollPane(workspace);
            System.gc();
            repaint();
        } else if (actionCommand.equals("COMPONENTS/SET TOS DIRECTORY")) {
            JFileChooser chooser = new JFileChooser();
            chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
            do {
                if(chooser.showOpenDialog(this) == JFileChooser.APPROVE_OPTION){
                    File dir = chooser.getSelectedFile();
                    if (TOS.isValidTOSDir(dir)) {
                        TOSDir = dir;
                        break;
                    } else {
                        JLabel label = new JLabel("<HTML><CENTER>" +
                                       "The directory you selected:<BR> " + 
                                       dir.getAbsolutePath() + 
                                       "<BR>is not a valid TOS directory.<BR>" +
                                       "Please select another directory." +
                                       "</CENTER></HTML>");
                        JOptionPane.showMessageDialog(this, label,
                                                     "Invalid TOS Directory",
                                                     JOptionPane.ERROR_MESSAGE);
                    }
                } else 
                    break;
            } while (true);
        } else {
        }
    }
}
