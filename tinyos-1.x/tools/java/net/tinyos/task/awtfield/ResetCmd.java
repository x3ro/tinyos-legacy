package net.tinyos.task.awtfield;

import java.awt.*;
import java.awt.event.*;
import java.util.*;
import net.tinyos.message.*;

class ResetCmd extends SimpleCommand {
    ResetCmd(Tool parent) {
	super(parent, "reset");
	parent.addCommand("reset", this);
    }
}
