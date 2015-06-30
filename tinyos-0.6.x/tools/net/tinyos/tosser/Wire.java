package net.tinyos.tosser;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;

public class Wire {
    private LinkedList extents;
    private Pinout sourcePin, destPin;
    private Point startPoint, endPoint;
    private boolean signal = false;
    private boolean compatible;

    private static Color wireColor = Color.black;
    private static Color signalColor = Color.green;
    private static Color incompatibleColor = Color.red;

    private class Extent extends Rectangle {
        public static final int HORIZONTAL = 0;
        public static final int VERTICAL = 1;
        private static final int numPaddingPixels = 5;

        private int orientation;

        public Extent(int x, int y) {
            super(x - numPaddingPixels, y - numPaddingPixels, 
                  numPaddingPixels * 2, numPaddingPixels * 2);

            orientation = -1;
        }

        public int getOrientation() {
            return orientation;
        }
        
        public void setOrientation(int orientation) {
            this.orientation = orientation;
        }

        public void growBack() {
            switch (orientation) {
                case HORIZONTAL:
                    x--;
                    width++;
                    break;
                case VERTICAL:
                    y--;
                    height++;
                    break;
            }
        }

        public void growForward() {
            switch (orientation) {
                case HORIZONTAL:
                    width++;
                    break;
                case VERTICAL:
                    height++;
                    break;
            }
        }

        public void paint(Graphics g, boolean signal) {
            if (signal)
                g.setColor(signalColor);
            else
                g.setColor(wireColor);

            if (orientation == HORIZONTAL) {
                g.drawLine(x + numPaddingPixels, y + numPaddingPixels,
                           x + width - numPaddingPixels, 
                           y + numPaddingPixels);
            } else {
                g.drawLine(x + numPaddingPixels, y + numPaddingPixels,
                           x + numPaddingPixels, 
                           y + height - numPaddingPixels);
            }
        }
    }

    public Wire(Pinout sourcePin, Pinout destPin) {
        this.sourcePin = sourcePin;
        this.destPin = destPin;
        this.startPoint = new Point(sourcePin.getHotPoint());
        this.endPoint = new Point(destPin.getHotPoint());
        extents = new LinkedList();

        if (!sourcePin.isTypeCompatible(destPin))
            wireColor = incompatibleColor;
    }

    public Wire(Pinout sourcePin, Pinout destPin, CostPoint dest) {
        this(sourcePin, destPin);

        Extent e = null;
        CostPoint currPoint = dest;
        while (true) {
            CostPoint parent = currPoint.getParent();
            if (currPoint.equals(parent))
                break;
            if (parent == null) {
                System.out.println("null parent of " + currPoint);
            }

            if (e == null)
                e = new Extent(currPoint.x, currPoint.y);

            if (parent.x != currPoint.x) {
                switch (e.getOrientation()) {
                    case Extent.HORIZONTAL:
                        if (parent.x < currPoint.x)
                            e.growBack();
                        else
                            e.growForward();
                        break;
                    case Extent.VERTICAL:
                        extents.addFirst(e);
                        e = null;
                        break;
                    default:
                        e.setOrientation(Extent.HORIZONTAL);
                        break;
                }
            } else {
                switch (e.getOrientation()) {
                    case Extent.HORIZONTAL:
                        extents.addFirst(e);
                        e = null;
                        break;
                    case Extent.VERTICAL:
                        if (parent.y < currPoint.y)
                            e.growBack();
                        else
                            e.growForward();
                        break;
                    default:
                        e.setOrientation(Extent.VERTICAL);
                        break;
                }
            }

            currPoint = parent;
        }

        if (e != null)
            extents.addFirst(e);

        Iterator iter = extents.iterator();

        while (iter.hasNext()) {
            e = (Extent)iter.next();
        }
    }

    public boolean contains(int x, int y) {
        Iterator iter = extents.iterator();

        while (iter.hasNext()) {
            Extent e = (Extent)iter.next();

            if (e.contains(x, y))
                return true;
        }

        return false;
    }

    public void paint(Graphics g) {
        Iterator iter = extents.iterator();

        while (iter.hasNext()) {
            Extent e = (Extent)iter.next();
            
            e.paint(g, signal);
        }
    }

    public LinkedList getExtents() {
        return extents;
    }

    public Pinout getSourcePin() {
        return sourcePin;
    }

    public Pinout getDestPin() {
        return destPin;
    }

    public Point getStartPoint() {
        return startPoint;
    }

    public Point getEndPoint() {
        return endPoint;
    }

    public synchronized void signalOn() {
        signal = true;
    }

    public synchronized void signalOff() {
        signal = false;
    }

    public String toString() {
        return sourcePin.getFullName() + " -> " + destPin.getFullName();
    }
}
