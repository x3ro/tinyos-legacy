package net.tinyos.tosser;

import javax.swing.*;
import javax.swing.border.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;
import java.io.*;

public class StatusBar extends JPanel {
    private String defaultMainStatusText;
    private JLabel mainStatus, mode;

    public StatusBar(String initialMainStatus, String initialMode) {
        setLayout(new BorderLayout());

        defaultMainStatusText = initialMainStatus;

        mainStatus = new JLabel(initialMainStatus);
        mainStatus.setBorder(new EtchedBorder(EtchedBorder.RAISED));
        mainStatus.setToolTipText("Status");
        add(mainStatus, BorderLayout.CENTER);

        mode = new JLabel(initialMode);
        mode.setBorder(new EtchedBorder(EtchedBorder.RAISED));
        mode.setToolTipText("Mode");
        add(mode, BorderLayout.EAST);
    }

    public void restoreDefaultMainStatusText() {
        setMainStatusText(defaultMainStatusText);
    }

    public void setMainStatusText(String status) {
        mainStatus.setText(status);
    }

    public void setModeText(String status) {
        mode.setText(status);
    }
}
