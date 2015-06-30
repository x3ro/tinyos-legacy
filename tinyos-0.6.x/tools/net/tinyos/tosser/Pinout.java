package net.tinyos.tosser;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;
import java.io.*;
import net.tinyos.compparser.*;

public class Pinout extends Rectangle implements ActionListener {
    public static final int NONE = -1;
    public static final int ACCEPTS = 0;
    public static final int HANDLES = 1;
    public static final int USES = 2;
    public static final int SIGNALS = 3;
    public static final int INTERNAL = 4;

    private String declaration, definition = null;
    private Vector connections = new Vector();
    private TOSComp owner;
    private Point hotPoint;
    private int type;
    private CompParser.FunctionSignature signature;
    private JMenu popup;

    private void setupPopup() {
        popup = new JMenu(getName());

        JMenuItem menuItem;

        // Yes, I do mean == here
        if (definition == declaration || connections.size() == 0) {
            menuItem = new JMenuItem("Edit Definition");
            menuItem.setActionCommand("DEFINE");
            menuItem.addActionListener(this);
            popup.add(menuItem);
        }

        // here, too
        if (type != INTERNAL && definition == declaration) {
            popup.addSeparator();

            if (connections.size() == 0) {
                menuItem = new JMenuItem("No Connections");
                menuItem.setEnabled(false);
                popup.add(menuItem);
            } else {
                JMenu subMenu = new JMenu("Connections");
                popup.add(subMenu);

                Iterator iter = connections.iterator();
                while (iter.hasNext()) {
                    Pinout connection = (Pinout)iter.next();

                    menuItem = new JMenuItem(connection.getDeclaration());
                    subMenu.add(menuItem);
                }
            }
        }
    }

    public Pinout(String decl, CompParser.FunctionSignature sig, TOSComp owner, 
                  int type) {
        signature = sig;
        declaration = decl;
        definition = decl;
        this.owner = owner;
        this.hotPoint = new Point();
        this.type = type;
        setupPopup();
    }

    public Pinout(String decl, CompParser.FunctionSignature sig, TOSComp owner, 
                  int type, Pinout conn) {
        this(decl, sig, owner, type);
        connections.add(conn);
    }

    public Pinout(CompParser.FunctionSignature sig, int type) {
        this(sig.toString(), sig, null, type);
    }

    public void connect(Pinout conn) {
        if (type != INTERNAL) {
            connections.add(conn);
            setupPopup();
        }
    }

    public void disconnect(Pinout conn) {
        if (type != INTERNAL) {
            connections.remove(conn);
            setupPopup();
        }
    }

    public String getDeclaration() {
        return declaration;
    }

    public Vector getConnections() {
        return connections;
    }

    public int getType() {
        return type;
    }

    public String getFullName() {
        return owner.getName() + ":" + signature.getName();
    }

    public String getName() {
        return signature.getName();
    }

    public void setType(int type) {
        this.type = type;
    }

    public void setHotPoint(int x, int y) {
        hotPoint.setLocation(x, y);
    }

    public Point getHotPoint() {
        return hotPoint;
    }

    public void setOwner(TOSComp owner) {
        this.owner = owner;
    }

    public TOSComp getOwner() {
        return owner;
    }

    public JPopupMenu getPopupMenu() {
        return popup.getPopupMenu();
    }

    public JMenu getMenu() {
        return popup;
    }

    public boolean isConnectable() {
        return definition == declaration;
    }

    public boolean isTypeCompatible(Pinout pin) {
        if (type == ACCEPTS && pin.type != USES)
            return false;

        if (type == USES && pin.type != ACCEPTS)
            return false;

        if (type == HANDLES && pin.type != SIGNALS)
            return false;

        if (type == SIGNALS && pin.type != HANDLES)
            return false;

        return signature.isTypeCompatible(pin.signature);
    }

    // ActionListener methods
    public void actionPerformed(ActionEvent e) {
        String actionCommand = e.getActionCommand();
        
        if (actionCommand.equals("DEFINE")) {
            new EditorThread().start();
        }

        if (owner != null)
            owner.repaint();
    }

    private class EditorThread extends Thread {
        public void run() {
            try {
                File editFile = File.createTempFile("tosser", ".c");
                FileWriter fw = new FileWriter(editFile);
                fw.write(definition);
                fw.close();

                String editor = Tosser.getProperties().getProperty("editor");
                Process edit = Runtime.getRuntime().exec(editor + " " + 
                        editFile.getAbsolutePath());
                int status = 0;
                try {
                    status = edit.waitFor();
                } catch (InterruptedException ie) {
                }

                if (status == 0) {
                    char buf[] = new char[(int)editFile.length()];
                    FileReader fr = new FileReader(editFile);
                    fr.read(buf);
                    definition = new String(buf);
                }

                editFile.delete();

                setupPopup();
            } catch (IOException ioe) {
            }
        }
    }
}
