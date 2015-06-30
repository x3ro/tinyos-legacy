package net.tinyos.task.awtfield;

import java.awt.*;
import java.io.*;
import java.awt.event.*;
import net.tinyos.message.*;
import net.tinyos.packet.*;

public class Settings extends Dialog implements WindowListener {
    Setting[] allSettings;
    int nSetting;

    Settings(Frame parent, int count) {
	super(parent, "Settings", true);
	addWindowListener(this);
	setLayout(new GridLayout(0, 2));
	allSettings = new Setting[count];
    }

    void finishDialog() {
	load();

	Button ok = new Button("Ok");
	add(ok);
	ok.addActionListener
	    (new ActionListener() {
		    public void actionPerformed(ActionEvent e) {
			confirm();
		    }
		});

	Button cancel = new Button("Cancel");
	add(cancel);
	cancel.addActionListener
	    (new ActionListener() {
		    public void actionPerformed(ActionEvent e) {
			cancel();
		    }
		});

	pack();
    }

    void add(String name, int[] value, int min, int max) {
	allSettings[nSetting++] = new Setting(this, name, value, min, max);
    }

    void save() {
	try {
	    FileOutputStream sf = new FileOutputStream("field.settings");
	    DataOutputStream sfd = new DataOutputStream(sf);

	    for (int i = 0; i < allSettings.length; i++)
		allSettings[i].write(sfd);
	    sfd.flush();
	    sf.close();
	}
	catch (FileNotFoundException e) { }
	catch (IOException e) { }
    }

    void load() {
	try {
	    FileInputStream sf = new FileInputStream("field.settings");
	    DataInputStream sfd = new DataInputStream(sf);

	    for (int i = 0; i < allSettings.length; i++)
		allSettings[i].read(sfd);
	    sf.close();
	}
	catch (FileNotFoundException e) { }
	catch (IOException e) { }
    }

    void cancel() {
	hide();
	for (int i = 0; i < allSettings.length; i++)
	    allSettings[i].reset();
    }

    void confirm() {
	hide();
	for (int i = 0; i < allSettings.length; i++)
	    allSettings[i].confirm();
	save();
    }

    public void windowClosing(WindowEvent e) {
	cancel();
    }

    public void windowClosed(WindowEvent e) { }
    public void windowActivated(WindowEvent e) { }
    public void windowIconified(WindowEvent e) { }
    public void windowDeactivated(WindowEvent e) { }
    public void windowDeiconified(WindowEvent e) { }
    public void windowOpened(WindowEvent e) { }
}


class Setting
{
    int[] value;
    int min, max;
    TextField tf;

    Setting(Dialog settings, String name, int[] value, int min, int max) {
	this.value = value;
	this.min = min;
	this.max = max;
	tf = new TextField("" + value[0], 10);

 	settings.add(new Label(name));
	settings.add(tf);
    }

    void confirm() {
	try {
	    value[0] = Integer.decode(tf.getText()).intValue();
	    if (value[0] < min)
		value[0] = min;
	    if (value[0] > max)
		value[0] = max;
	}
	catch (NumberFormatException e) {
	}
    }

    void reset() {
	tf.setText("" + value[0]);
    }

    void read(DataInputStream in) throws IOException {
	value[0] = in.readInt();
	reset();
    }

    void write(DataOutputStream out) throws IOException {
	out.writeInt(value[0]);
    }

}
