/* This plugin sets the rssi value of each mote based on their
 * locations in the mote window. Motes can read their rssi values from the
 * ADC, using ADC Channel PORT_RSSI (Defined below).
 */

import java.lang.*;
import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.plugins.CalamariPlugin;
import net.tinyos.sim.event.*;
import net.tinyos.matlab.*;

public class EvaderPlugin extends MotionPlugin{

    public EvaderPlugin() {
        super();
        leaderAdcChannel=(byte)155;
        color=Color.red;
    }

    public String toString() {
        return "Evader";
    }
}


