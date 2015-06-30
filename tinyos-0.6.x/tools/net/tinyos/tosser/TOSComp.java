package net.tinyos.tosser;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;
import java.io.*;
import net.tinyos.compparser.*;
import net.tinyos.descparser.*;

public class TOSComp extends Rectangle implements ActionListener {
    /*
        This is approximately how a TOSComp would be drawn that has
        5 accepts, 7 handles, 1 signals, and 2 uses.
       
                 | | | | |
                -----------
              -|H ACCEPTS S|
              -|A         I| 
              -|N         G|
              -|D         N|-
              -|L         A|
              -|E         L|
              -|S   USES  S|
                -----------
                    | |
    */
    
    //
    // Constants
    //

    // The length to add for each pin on a side
    private static final int PINWIDTH = 8; 
    // The length of a pin
    private static final int PINLENGTH = 8; 
    private static final Font pinFont = new Font("Pin Font", Font.PLAIN, 8);

    //
    // Class variables
    //
    private static Color selectionColor = Color.yellow;
    private static Color chipColor = Color.black;
    private static Color pinColor = Color.black;
    private static Color compatiblePinColor = Color.green;
    private static Color textColor = Color.white;
    private static Color nameColor = Color.yellow;

    //
    // Fields
    //
    private int acceptsRadius, handlesRadius, signalsRadius, usesRadius;
    private int fontHeight;
    private int chipWidth, chipHeight, edgeWidth;
    private int minChipWidth, minChipHeight;
    private boolean selected;
    private String name;
    private ToolTipRegion toolTips[];
    private int numTips;
    private Vector accepts, handles, uses, signals, internal, allPins;
    private Vector drawnAccepts, drawnHandles, drawnUses, drawnSignals;
    private JPopupMenu popup;
    private Component parent;
    private DescParser.Description description;
    private File descFile = null;
    private int level;
    private FontMetrics fm;
    private boolean onlyShowConnectedPins = false;

    private void setupPopup() {
        popup = new JPopupMenu();

        JMenuItem menuItem;

        menuItem = new JMenuItem("Add ACCEPTS...");
        menuItem.setActionCommand("ACCEPTS");
        menuItem.addActionListener(this);
        popup.add(menuItem);

        menuItem = new JMenuItem("Add HANDLES...");
        menuItem.setActionCommand("HANDLES");
        menuItem.addActionListener(this);
        popup.add(menuItem);
        
        menuItem = new JMenuItem("Add USES...");
        menuItem.setActionCommand("USES");
        menuItem.addActionListener(this);
        popup.add(menuItem);
        
        menuItem = new JMenuItem("Add SIGNALS...");
        menuItem.setActionCommand("SIGNALS");
        menuItem.addActionListener(this);
        popup.add(menuItem);

        menuItem = new JMenuItem("Add INTERNAL...");
        menuItem.setActionCommand("INTERNAL");
        menuItem.addActionListener(this);
        popup.add(menuItem);

        popup.addSeparator();

        JMenu internalMenu = new JMenu("INTERNAL Pins");
        popup.add(internalMenu);

        if (internal.size() == 0) {
            menuItem = new JMenuItem("(None)");
            menuItem.setEnabled(false);
            internalMenu.add(menuItem);
        } else {
            Iterator iter = internal.iterator();

            while (iter.hasNext()) {
                Pinout po = (Pinout)iter.next();
                JMenu pinMenu = po.getMenu();
                internalMenu.add(pinMenu);
            }
        }

        popup.addSeparator();

        if (onlyShowConnectedPins) {
            menuItem = new JMenuItem("Show all pins");
            menuItem.setActionCommand("SHOW ALL PINS");
        } else {
            menuItem = new JMenuItem("Only show connected pins");
            menuItem.setActionCommand("ONLY SHOW CONNECTED PINS");
        }
        menuItem.addActionListener(this);
        popup.add(menuItem);
    }

    public TOSComp(Component parent, String name, int level) {
        super();

        this.parent = parent;
        this.level = level;

        fm = parent.getFontMetrics(pinFont);

        minChipWidth = fm.stringWidth("H ACCEPTS S") + 2 * PINLENGTH;
        minChipHeight = fm.getHeight() * ("SIGNALS".length()) + 2 * PINLENGTH;
        chipWidth = minChipWidth;
        chipHeight = minChipHeight;
        width = chipWidth + 2 * PINLENGTH;
        height = chipHeight + 2 * PINLENGTH;

        fontHeight = fm.getHeight();
        
        edgeWidth = fm.stringWidth("H  S") + 2 * PINLENGTH;

        acceptsRadius = fm.stringWidth("ACCEPTS") / 2;
        handlesRadius = fm.getHeight() * ("HEIGHT".length()) / 2;
        signalsRadius = fm.getHeight() * ("SIGNALS".length()) / 2;
        usesRadius = fm.stringWidth("USES") / 2;

        accepts = new Vector();
        uses = new Vector();
        handles = new Vector();
        signals = new Vector();
        internal = new Vector();

        this.name = name;

        setupPopup();
    }

    public TOSComp(Component parent, String name, 
                   int xInit, int yInit, int level) {
        this(parent, name, level);

        x = xInit;
        y = yInit;
    }

    public TOSComp(Component parent, File dotcomp, 
                   int xInit, int yInit, int level) { 
        this(parent, "", xInit, yInit, level);
        load(dotcomp);
    }

    private Vector getConnectedPins(Vector v) {
        Vector connectedPins = new Vector(v);
        Iterator iter = connectedPins.iterator();
        while (iter.hasNext()) {
            Pinout po = (Pinout)iter.next();
            if (po.getConnections().size() == 0)
                iter.remove();
        }

        return connectedPins;
    }

    private void resize() {
        int minSize;
        Vector acceptsPins, usesPins, handlesPins, signalsPins;

        if (onlyShowConnectedPins) {
            acceptsPins = getConnectedPins(accepts);
            usesPins = getConnectedPins(uses);
            handlesPins = getConnectedPins(handles);
            signalsPins = getConnectedPins(signals);
        } else {
            acceptsPins = accepts;
            usesPins = uses;
            handlesPins = handles;
            signalsPins = signals;
        }

        minSize = Math.max(acceptsPins.size(), usesPins.size()) * PINWIDTH;
        if (minSize > minChipWidth)
            chipWidth = minSize;
        else
            chipWidth = minChipWidth;
        
        width = chipWidth + 2 * PINLENGTH;

        minSize = Math.max(handlesPins.size(), signalsPins.size()) * PINWIDTH;
        if (minSize > minChipHeight)
            chipHeight = minSize;
        else
            chipHeight = minChipHeight;

        height = chipHeight + 2 * PINLENGTH;
    }

    private void addAccepts(Pinout p) {
        accepts.add(p);
        resize();
    }

    private void addUses(Pinout p) {
        uses.add(p);
        resize();
    }

    private void addHandles(Pinout p) {
        handles.add(p);
        resize();
    }

    private void addSignals(Pinout p) {
        signals.add(p);
        resize();
    }

    private void addInternal(Pinout p) {
        internal.add(p);
        setupPopup();
    }

    public void addPinout(Pinout p) {
        switch (p.getType()) {
            case Pinout.ACCEPTS:
                addAccepts(p);
                break;
            case Pinout.HANDLES:
                addHandles(p);
                break;
            case Pinout.USES:
                addUses(p);
                break;
            case Pinout.SIGNALS:
                addSignals(p);
                break;
            case Pinout.INTERNAL:
                addInternal(p);
                break;
        }
    }

    private void removeAccepts(Pinout p) {
        accepts.remove(p);
        resize();
    }

    private void removeUses(Pinout p) {
        uses.remove(p);
        resize();
    }

    private void removeHandles(Pinout p) {
        handles.remove(p);
        resize();
    }

    private void removeSignals(Pinout p) {
        signals.remove(p);
        resize();
    }

    private void removeInternal(Pinout p) {
        internal.remove(p);
        setupPopup();
    }

    public void removePinout(Pinout p) {
        switch (p.getType()) {
            case Pinout.ACCEPTS:
                removeAccepts(p);
                break;
            case Pinout.HANDLES:
                removeHandles(p);
                break;
            case Pinout.USES:
                removeUses(p);
                break;
            case Pinout.SIGNALS:
                removeSignals(p);
                break;
            case Pinout.INTERNAL:
                removeInternal(p);
                break;
        }
    }


    private void drawVerticalString(Graphics g, String s, int x, int yStart) {
        int y = yStart;

        for (int i = 0; i < s.length(); i++) {
            g.drawString(s.substring(i, i+1), x, y);
            y += fontHeight;
        }
    }

    private void drawHorizontalPins(Graphics g, Pinout sourcePin) {
        int spread, i;
        Vector acceptsPins, usesPins;

        if (onlyShowConnectedPins) {
            acceptsPins = getConnectedPins(accepts);
            usesPins = getConnectedPins(uses);
        } else {
            acceptsPins = accepts;
            usesPins = uses;
        }
        
        spread = (chipWidth - acceptsPins.size() * PINWIDTH) / 
                 (acceptsPins.size() + 1);
        for (i = 1; i < acceptsPins.size() + 1; i++) {
            g.setColor(pinColor);
            Pinout po = (Pinout)acceptsPins.get(i-1);
            if (sourcePin != null && sourcePin.isTypeCompatible(po))
                g.setColor(compatiblePinColor);
            g.drawLine(x + i*(PINWIDTH + spread) + PINWIDTH/2, y, 
                       x + i*(PINWIDTH + spread) + PINWIDTH/2, y + PINLENGTH);
            toolTips[numTips++] = new ToolTipRegion(po.getName(),
                                                    x + i*(PINWIDTH + spread), 
                                                    y, PINWIDTH, PINLENGTH);
            po.setRect(x + i*(PINWIDTH + spread), y, PINWIDTH, PINLENGTH);
            po.setHotPoint(x + i*(PINWIDTH + spread) + PINWIDTH/2, y);
        }

        spread = (chipWidth - usesPins.size() * PINWIDTH) / 
                 (usesPins.size() + 1);
        for (i = 1; i < usesPins.size() + 1; i++) {
            g.setColor(pinColor);
            Pinout po = (Pinout)usesPins.get(i-1);
            if (sourcePin != null && sourcePin.isTypeCompatible(po))
                g.setColor(compatiblePinColor);
            g.drawLine(x + i*(PINWIDTH + spread) + PINWIDTH/2, y + height, 
                       x + i*(PINWIDTH + spread) + PINWIDTH/2, 
                       y + height - PINLENGTH);

            toolTips[numTips++] = new ToolTipRegion(po.getName(),
                                                    x + i*(PINWIDTH + spread), 
                                                    y + height - PINLENGTH,
                                                    PINWIDTH, PINLENGTH);
            po.setRect(x + i*(PINWIDTH + spread), y + height - PINLENGTH, 
                       PINWIDTH, PINLENGTH);
            po.setHotPoint(x + i*(PINWIDTH + spread) + PINWIDTH/2, 
                           y + height);
        }
    }

    private void drawVerticalPins(Graphics g, Pinout sourcePin) {
        int spread, i;
        Vector handlesPins, signalsPins;

        if (onlyShowConnectedPins) {
            handlesPins = getConnectedPins(handles);
            signalsPins = getConnectedPins(signals);
        } else {
            handlesPins = handles;
            signalsPins = signals;
        }

        spread = (chipHeight - handlesPins.size() * PINWIDTH) / 
                 (handlesPins.size()+1);
        for (i = 1; i < handlesPins.size() + 1; i++) {
            g.setColor(pinColor);
            Pinout po = (Pinout)handlesPins.get(i-1);
            if (sourcePin != null && sourcePin.isTypeCompatible(po))
                g.setColor(compatiblePinColor);
            g.drawLine(x, y + i*(PINWIDTH + spread) + PINWIDTH/2,
                       x + PINLENGTH, y + i*(PINWIDTH + spread) + PINWIDTH/2);
            toolTips[numTips++] = new ToolTipRegion(po.getName(),
                                                    x, 
                                                    y + i*(PINWIDTH + spread), 
                                                    PINLENGTH, PINWIDTH);
            po.setRect(x, y + i*(PINWIDTH + spread), PINLENGTH, PINWIDTH);
            po.setHotPoint(x, y + i*(PINWIDTH + spread) + PINWIDTH/2);
        }

        spread = (chipHeight - signalsPins.size() * PINWIDTH) / 
                 (signalsPins.size()+1);
        for (i = 1; i < signalsPins.size() + 1; i++) {
            g.setColor(pinColor);
            Pinout po = (Pinout)signalsPins.get(i-1);
            if (sourcePin != null && sourcePin.isTypeCompatible(po))
                g.setColor(compatiblePinColor);
            g.drawLine(x + width, y + i*(PINWIDTH + spread) + PINWIDTH/2,
                       x + width - PINLENGTH, 
                       y + i*(PINWIDTH + spread) + PINWIDTH/2);
            toolTips[numTips++] = new ToolTipRegion(po.getName(),
                                                    x + width - PINLENGTH, 
                                                    y + i*(PINWIDTH + spread), 
                                                    PINLENGTH, PINWIDTH);
            po.setRect(x + width - PINLENGTH, y + i*(PINWIDTH + spread), 
                       PINLENGTH, PINWIDTH);
            po.setHotPoint(x + width, y + i*(PINWIDTH + spread) + PINWIDTH/2);
        }
    }

    public int getLevel() {
        return level;
    }

    public int getNumPins() {
        return accepts.size() + uses.size() + handles.size() + signals.size();
    }

    public Vector getAllPins() {
        allPins = new Vector();

        allPins.addAll(accepts);
        allPins.addAll(uses);
        allPins.addAll(handles);
        allPins.addAll(signals);
        allPins.addAll(internal);

        return allPins;
    }

    private String findAbbrName(int radius[]) {
        int midSection = width - edgeWidth;
        for (int len = name.length(); len >=0; len--) {
            String abbr = name.substring(0, len);
            int abbrWidth = fm.stringWidth(abbr);
            if (abbrWidth <= midSection) {
                radius[0] = abbrWidth / 2;
                return abbr;
            }
        }

        return "";
    }

    public void paint(Graphics g, Pinout sourcePin) {
        Font holder = g.getFont();
        g.setFont(pinFont);

        g.setColor(chipColor);
        g.fillRoundRect(x + PINLENGTH, y + PINLENGTH, chipWidth, chipHeight, 
                        chipWidth / 20, chipHeight / 20);

        g.setColor(textColor);
        int xCenter = x + (width / 2);
        int yCenter = y + (height / 2);
        g.drawString("ACCEPTS", xCenter - acceptsRadius, y + (PINLENGTH*2));
        g.drawString("USES", xCenter - usesRadius, y + height - (PINLENGTH*2));
        drawVerticalString(g, "HANDLES", 
                     x + 2 * PINLENGTH, yCenter - handlesRadius);
        drawVerticalString(g, "SIGNALS", 
                     x + width - (2 * PINLENGTH), 
                     yCenter - signalsRadius);
        int radius[] = new int[1];
        String abbrName = findAbbrName(radius);
        g.setColor(nameColor);
        g.drawString(abbrName, xCenter - radius[0], yCenter);

        numTips = 0;
        toolTips = new ToolTipRegion[1 + getNumPins()];
        toolTips[numTips++] = new ToolTipRegion(name, x + PINLENGTH, 
                                                y + PINLENGTH, 
                                                chipWidth, chipHeight);
        
        drawHorizontalPins(g, sourcePin);
        drawVerticalPins(g, sourcePin);

        if (selected) {
            g.setColor(selectionColor);
            g.drawRect(x, y, width, height);
        }

        g.setFont(holder);
    }

    public boolean isSelected() {
        return selected;
    }

    public void toggleSelected() {
        selected = !selected;
    }

    public String getName() {
        return name;
    }

    public File getDescFile() {
        return descFile;
    }

    public DescParser.Description getDescription() {
        return description;
    }

    public String getToolTipText(int ttx, int tty) {
        for (int i = 0; i < numTips; i++) {
            if (toolTips[i].contains(ttx, tty)) {
                return toolTips[i].text;
            }
        }

        return null;
    }

    public Pinout getPinoutAtPoint(int poX, int poY) {
        Iterator iter;
        Pinout po;
        
        iter = accepts.iterator();
        while (iter.hasNext()) {
            po = (Pinout)iter.next();
            if (po.contains(poX, poY))
                return po;
        }

        iter = uses.iterator();
        while (iter.hasNext()) {
            po = (Pinout)iter.next();
            if (po.contains(poX, poY))
                return po;
        }

        iter = handles.iterator();
        while (iter.hasNext()) {
            po = (Pinout)iter.next();
            if (po.contains(poX, poY))
                return po;
        }

        iter = signals.iterator();
        while (iter.hasNext()) {
            po = (Pinout)iter.next();
            if (po.contains(poX, poY))
                return po;
        }

        iter = internal.iterator();
        while (iter.hasNext()) {
            po = (Pinout)iter.next();
            if (po.contains(poX, poY))
                return po;
        }

        return null;
    }

    public JPopupMenu getPopupMenu() {
        return popup;
    }

    private class ToolTipRegion extends Rectangle {
        public String text;

        public ToolTipRegion(String s, int x, int y, int w, int h) {
            super(x,y,w,h);
            text = s;
        }
    }

    private void load(File dotcomp) {
        CompParser cp;
        try {
            cp = new CompParser(new FileReader(dotcomp));
        } catch (FileNotFoundException e) {
            return;
        }

        CompParser.CompFile cf = null;
        try {
            cf = cp.File();
        } catch (net.tinyos.compparser.ParseException pe) {
            return;
        }

        Iterator iter;

        iter = cf.getAccepts().iterator();
        while (iter.hasNext()) {
            Pinout po = new Pinout((CompParser.FunctionSignature)iter.next(), 
                                   Pinout.ACCEPTS);
            po.setOwner(this);
            addAccepts(po);
        }

        iter = cf.getHandles().iterator();
        while (iter.hasNext()) {
            Pinout po = new Pinout((CompParser.FunctionSignature)iter.next(), 
                                   Pinout.HANDLES);
            po.setOwner(this);
            addHandles(po);
        }

        iter = cf.getUses().iterator();
        while (iter.hasNext()) {
            Pinout po = new Pinout((CompParser.FunctionSignature)iter.next(), 
                                   Pinout.USES);
            po.setOwner(this);
            addUses(po);
        }

        iter = cf.getSignals().iterator();
        while (iter.hasNext()) {
            Pinout po = new Pinout((CompParser.FunctionSignature)iter.next(), 
                                   Pinout.SIGNALS);
            po.setOwner(this);
            addSignals(po);
        }

        iter = cf.getInternal().iterator();
        while (iter.hasNext()) {
            Pinout po = new Pinout((CompParser.FunctionSignature)iter.next(), 
                                   Pinout.INTERNAL);
            po.setOwner(this);
            addInternal(po);
        }

        name = cf.getName();

        descFile = TOS.findDescFile(dotcomp);

        if (descFile != null) {
            DescParser parser = null;
            try {
                parser = new DescParser(new FileReader(descFile));
            } catch (FileNotFoundException e) {
            }
            try {
                description = parser.File();
            } catch (net.tinyos.descparser.ParseException e) {
            }
        }
    }

    private void getPinoutDeclaration(int pinType, JLabel label) {
        String decl = JOptionPane.showInputDialog(parent, label);
        CompParser.FunctionSignature signature;
        try {
            CompParser cp = new CompParser(new StringReader(decl));
            signature = cp.Function();
            addPinout(new Pinout(decl, signature, this, pinType));
        } catch (net.tinyos.compparser.ParseException pe) {
            int option = JOptionPane.showConfirmDialog(parent,
                    new JLabel("<HTML><CENTER>" +
                        "The declaration entered does not " +
                        "appear to be valid.<BR>Would you like " +
                        "to use it anyway?</CENTER></HTML>"),
                    "Verify Declaration",
                    JOptionPane.YES_NO_OPTION);
            if (option == JOptionPane.YES_OPTION)
                addPinout(new Pinout(decl, null, this, pinType));
        }
   }

    
    // ActionListener methods
    public void actionPerformed(ActionEvent e) {
        JLabel label;
        String actionCommand = e.getActionCommand();
        
        if (actionCommand.equals("ACCEPTS")) {
            label = new JLabel("Enter the declaration for this ACCEPTS pin:");
            getPinoutDeclaration(Pinout.ACCEPTS, label);
        } else if (actionCommand.equals("HANDLES")) {
            label = new JLabel("Enter the declaration for this HANDLES pin:");
            getPinoutDeclaration(Pinout.HANDLES, label);
        } else if (actionCommand.equals("USES")) {
            label = new JLabel("Enter the declaration for this USES pin:");
            getPinoutDeclaration(Pinout.USES, label);
        } else if (actionCommand.equals("SIGNALS")) {
            label = new JLabel("Enter the declaration for this SIGNALS pin:");
            getPinoutDeclaration(Pinout.SIGNALS, label);
        } else if (actionCommand.equals("INTERNAL")) {
            label = new JLabel("Enter the declaration for this INTERNAL pin:");
            getPinoutDeclaration(Pinout.INTERNAL, label);
        } else if (actionCommand.equals("ONLY SHOW CONNECTED PINS")) {
            onlyShowConnectedPins = true;
            resize();
            setupPopup();
        } else if (actionCommand.equals("SHOW ALL PINS")) {
            onlyShowConnectedPins = false;
            resize();
            setupPopup();
        }

        repaint();
    }

    public void repaint() {
        parent.repaint();
    }
}
