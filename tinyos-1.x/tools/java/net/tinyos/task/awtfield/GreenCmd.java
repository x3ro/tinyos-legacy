package net.tinyos.task.awtfield;

import java.awt.*;
import java.awt.event.*;
import java.util.*;
import net.tinyos.message.*;

class GreenCmd extends SimpleCommand {
    GreenCmd(Tool parent) {
	super(parent, "SetLedG");
	cmd8(2);
    }
}
