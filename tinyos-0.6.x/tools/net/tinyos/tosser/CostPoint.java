package net.tinyos.tosser;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;

public class CostPoint extends Point {
    private int cost, baseCost = 0;
    private CostPoint parent;

    public CostPoint(int x, int y) {
        super(x, y);
        cost = -1;
        parent = null;
    }

    public CostPoint(int x, int y, int cost) {
        this(x, y);
        this.cost = cost;
    }

    public CostPoint(int x, int y, int cost, CostPoint parent) {
        this(x, y, cost);
        this.parent = parent;
    }

    public int getCost() {
        return cost;
    }

    public void setCost(int cost) {
        this.cost = cost + baseCost;
    }

    public void incrementBaseCost(int baseCost) {
        this.baseCost += baseCost;
    }

    public CostPoint getParent() {
        return parent;
    }

    public void setParent(CostPoint parent) {
        this.parent = parent;
    }
}
