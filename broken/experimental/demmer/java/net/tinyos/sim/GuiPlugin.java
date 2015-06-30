
package net.tinyos.sim;

import net.tinyos.sim.*;
import java.awt.*;
import javax.swing.*;
import java.util.*;

public abstract class GuiPlugin extends Plugin {
  protected TinyViz tv;
  protected CoordinateTransformer cT;
  protected MotePanel motePanel;
  protected JPanel pluginPanel;

  public void initialize(TinyViz tv, JPanel pluginPanel) {
    super.initialize(tv.getSimDriver());
    this.tv = tv;
    this.cT = tv.getCoordTransformer();
    this.motePanel = tv.getMotePanel();
    this.pluginPanel = pluginPanel;
  }
  
  public abstract void draw(Graphics graphics);
}
