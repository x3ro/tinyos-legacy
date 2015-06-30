import javax.swing.*;
import javax.swing.tree.*;
import java.awt.*;
import java.net.*;

         import java.awt.event.*;
public class demo{
public static void main(String[] args) {
             try {
                 UIManager.setLookAndFeel(
                     UIManager.getCrossPlatformLookAndFeelClassName());
             } catch (Exception e) { }

        //Create the top-level container and add contents to it.
        JFrame frame = new JFrame("SwingApplication");
        demo app = new demo();
	ImagePanel p = new ImagePanel(new ImageIcon("mote2.jpg").getImage());
        Component contents = app.createComponents(p);
        frame.getContentPane().add(contents, BorderLayout.CENTER);

        //Finish setting up the frame, and show it.
        frame.addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent e) {
                System.exit(0);
            }
        });
        frame.pack();
	frame.setSize(500, 500);
        frame.setVisible(true);
		DatagramSocket sk = null;
	try{
		sk = new DatagramSocket(5001);
	}catch(Exception e){
             System.out.println(e.getMessage());
             e.printStackTrace();
         }

	while(true){
	try{
	byte[] data = new byte[4500];
        DatagramPacket pack = new DatagramPacket(data, 4500);
        sk.receive(pack);
	frame.repaint();
	System.out.println("got update");
	p.update_data(data);
	}catch(Exception e){
             System.out.println(e.getMessage());
             e.printStackTrace();
         }

	}




         }

private static String labelPrefix = "Number of button clicks: ";
    private int numMotes = 0;

public Component createComponents(ImagePanel p) {
        final JLabel label = new JLabel(labelPrefix + "0    ");

        JButton button= new JButton("mote1");
        button.setMnemonic(KeyEvent.VK_I);
        button.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
                numMotes++;
		
                label.setText(labelPrefix + numMotes);
            }
        });
        label.setLabelFor(button);

        /*
         * An easy way to put space between a top-level container
         * and its contents is to put the contents in a JPanel
         * that has an "empty" border.
         */
        JPanel pane = new JPanel();
        pane.setBorder(BorderFactory.createEmptyBorder(
                                        30, //top
                                        30, //left
                                        10, //bottom
                                        30) //right
                                        );
        pane.setLayout(new GridLayout(0, 1));
	pane.add(p);
        return pane;
    }




}

class ImagePanel extends JPanel {
    Image image;

    public void update_data(byte[] data){
	for(int i = 0; i < GRAPH_TABLE_DEPTH; i ++){
		for(int j = 0; j < GRAPH_TABLE_ENTRY_SIZE * GRAPH_TABLE_ENTRIES_PER_LINE; j ++){
			rd_data[i][j] = data[i*GRAPH_TABLE_ENTRY_SIZE * GRAPH_TABLE_ENTRIES_PER_LINE + j];
		}
	}
    }


    public ImagePanel(Image image) {
        this.image = image.getScaledInstance(img_width, img_height, 0);
	rd_data[0][0] = 1;
	rd_data[0][1] = 5;
	rd_data[0][2] = 0;
	rd_data[0][3] = 3;
	rd_data[0][4] = 5;
    }

    public void paintComponent(Graphics g) {
        super.paintComponent(g); //paint background

        //Draw image at its natural size first.
	int width = getWidth();
	int row_num = 0;
	int parent_place = 6;
	int spacing_prev = 0;
	int temp;
	for(int i = 0; i < 25; i ++){
	   int num =  rd_data[i][0];
	   //System.out.println("line: " + i + "has : " + num);
	   int spacing = (width-25)/(num + 1);
	   for(int j = 0; j < num; j ++){
		int parent = rd_data[i][GRAPH_TABLE_ENTRY_SIZE*j + 2];
		System.out.println("vals: " + i + " " + (((int) rd_data[i][GRAPH_TABLE_ENTRY_SIZE*j + 3]) & 0xff) + " " + (((int) rd_data[i][GRAPH_TABLE_ENTRY_SIZE*j + 4]) & 0xff));
		temp = ((int) rd_data[i][GRAPH_TABLE_ENTRY_SIZE*j + 4]) & 0xff;
		temp |= (((int) rd_data[i][GRAPH_TABLE_ENTRY_SIZE*j + 3]) & 0xff) << 8;
		int orig = ((int)rd_data[i][GRAPH_TABLE_ENTRY_SIZE*j + 5]) & 0xff;
		int route = ((int)rd_data[i][GRAPH_TABLE_ENTRY_SIZE*j + 6]) & 0xff;
		drawMote(rd_data[i][GRAPH_TABLE_ENTRY_SIZE*j + 1], spacing * (1 + j), i, spacing_prev*(1+parent), temp, orig, route, g);
	   }
	   spacing_prev = spacing;
	}
	
    }
    static int img_height = 25;
    static int img_width = 25;
    static int spacing = 50;
    static int GRAPH_TABLE_DEPTH = 25;
    static int GRAPH_TABLE_ENTRY_SIZE = 6;
    static int GRAPH_TABLE_ENTRIES_PER_LINE = 30;
    byte[][] rd_data = new byte[GRAPH_TABLE_DEPTH][GRAPH_TABLE_ENTRY_SIZE * GRAPH_TABLE_ENTRIES_PER_LINE];
    void drawMote(int num, int x, int row, int parent_x, int temp, int orig, int route, Graphics g){
	if(parent_x == 0) parent_x = (getWidth()/2) - 25;
	g.drawImage(image, x, row * spacing, this);
        g.drawString("Mote: " + (num / 16) + num % 16, x+img_width, row*spacing + img_height);
        g.drawString(orig + "/"+ route, x+img_width+15, row*spacing + img_height + 15);
		System.out.println("Temp: " + temp);
	temp = temp >> 2;
	if(temp > 255) {
		System.out.println("TEMP ERROR>>>>>>Temp: " + temp);
		temp = 255;
	}
	g.setColor(new Color(temp, temp, temp));
	g.fillRect(x+img_width, row*spacing, 30,  img_height/2);
	g.setColor(new Color(0, 0, 0));
	g.drawRect(x+img_width, row*spacing, 30,  img_height/2);
	if(row != 0)
        	g.drawLine(x + img_width/2, row*spacing, parent_x + img_width/2, (row-1)*spacing + img_height); 
    }
	
}
