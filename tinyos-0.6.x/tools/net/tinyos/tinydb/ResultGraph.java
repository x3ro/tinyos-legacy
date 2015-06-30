package net.tinyos.tinydb;

import ptolemy.plot.*;
import java.util.*;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

public class ResultGraph extends Plot {

    public ResultGraph() {
	setSize(400,400);
	setVisible(true);
    }

    public void addKey(int id, String label) {
      addLegend(id, label);
    }

    public void addPoint(int id, int epoch, int value) {
      addPoint(id, (double)epoch, (double)value, true);
      repaint();
    }

}
