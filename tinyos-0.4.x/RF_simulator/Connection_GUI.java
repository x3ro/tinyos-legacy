import java.util.*;
import java.awt.*;
import java.applet.Applet;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.sql.Time;


public class Connection_GUI extends JPanel implements ActionListener{

    JButton remove= new JButton("Remove");
    JButton add = new JButton("Add");
    JTextField from = new JTextField();
    JTextField to = new JTextField();
	
static Connection_GUI app;
static Frame mainFrame;
    public void actionPerformed(ActionEvent e) {
	Object src = e.getSource();

	if (src == add) {
		System.out.println("add...");
	} else if(src == remove){
		System.out.println("remove...");
	}
   }

Connection_GUI(){
	setLayout(new BorderLayout());
	Panel p = new Panel();
	add("Center", p);
	p.add(remove);
	remove.addActionListener(this);
	p.add(add);
	add.addActionListener(this);
	add(from);
	add(to);


}

public static void main(String[] args) {
    mainFrame = new Frame("Connection Manager");
    app = new Connection_GUI();
    mainFrame.setSize( app.getSize() );
    mainFrame.add("Center", app);
    mainFrame.show();
    mainFrame.repaint(1000);
    mainFrame.addWindowListener
      (
        new WindowAdapter()
        {
          public void windowClosing    ( WindowEvent wevent )
          {
            System.exit(0);
          }
        }
      );
  }
    public Dimension getSize()
    {
	return new Dimension(200, 200);
    }

}


