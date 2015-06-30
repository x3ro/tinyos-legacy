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

public class Pursuer1Plugin extends MotionPlugin{

    public Pursuer1Plugin() {
        super();
        leaderAdcChannel=(byte)156;
        color=Color.decode("0x00FF00");
//        color=Color.green;
    }

    public String toString() {
        return "Pursuer1";
    }
}


