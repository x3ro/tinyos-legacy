// $Id: plotcontrolpanel.java,v 1.5 2003/10/07 21:46:02 idgay Exp $

package net.tinyos.plot;

import java.awt.*;
import java.awt.image.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.io.*;


public class plotcontrolpanel extends JToolBar  implements ActionListener {
	plotpanel p;
    private JToggleButton antiAliasing;
    private JToggleButton fitToScreen;
	private JButton kill;
    private JComboBox cb;
    private TextArea helpText;
    /** Returns an ImageIcon, or null if the path was invalid.
     * this little helper function lets me use relative paths*/

    protected static ImageIcon createImageIcon(String path) {
        java.net.URL imgURL = plotcontrolpanel.class.getResource(path);
        if (imgURL != null) {
            return new ImageIcon(imgURL);
        } else {
            System.err.println("Couldn't find file: " + path);
            return null;
        }
    }


    public plotcontrolpanel(plotpanel p) {
        this(p,null);
    }

	public plotcontrolpanel (plotpanel p, TextArea helpText) {
		//setLayout(new GridLayout(5,1));
		this.p = p;
        this.helpText=helpText;

//		JButton save = new JButton (new ImageIcon ("graphics/filesaveas.gif"));
        JButton save = new JButton (createImageIcon ("graphics/filesaveas.gif"));
		save.setToolTipText("Save PNG");
//      save.setVerticalTextPosition(AbstractButton.BOTTOM);
//		save.setHorizontalTextPosition(AbstractButton.CENTER);

		save.setActionCommand("Save");
		save.addActionListener (this);
		add(save);
//		addSeparator();

		JButton zoomIn = new JButton (createImageIcon ("graphics/zoomin2.gif"));
        zoomIn.setToolTipText("Zoom in");
//		zoomIn.setVerticalTextPosition(AbstractButton.BOTTOM);
//		zoomIn.setHorizontalTextPosition(AbstractButton.CENTER);
		zoomIn.setActionCommand("zoomIn");
		zoomIn.addActionListener (this);
		add (zoomIn);

		JButton zoomOut = new JButton (createImageIcon ("graphics/zoomout2.gif"));
        zoomOut.setToolTipText("Zoom Out");
//		zoomOut.setVerticalTextPosition(AbstractButton.BOTTOM);
//		zoomOut.setHorizontalTextPosition(AbstractButton.CENTER);
		zoomOut.setActionCommand("zoomOut");
		zoomOut.addActionListener (this);
		add (zoomOut);
//		addSeparator();

		JButton toOrigin = new JButton (createImageIcon ("graphics/toorigin2.gif"));
        toOrigin.setToolTipText("To Origin");
//		toOrigin.setVerticalTextPosition(AbstractButton.BOTTOM);
//		toOrigin.setHorizontalTextPosition(AbstractButton.CENTER);
		toOrigin.setActionCommand("(0,0)");
		toOrigin.addActionListener (this);
		add (toOrigin);

//        addSeparator();
        JButton background = new JButton (createImageIcon ("graphics/bg.gif"));
        background.setToolTipText("Background Color");
//		background.setVerticalTextPosition(AbstractButton.BOTTOM);
//		background.setHorizontalTextPosition(AbstractButton.CENTER);
        background.addActionListener (this);
        add(background);

//        addSeparator();
        JButton help = new JButton ("?");
        help.setToolTipText("help");
        help.setFont(new Font("Helvetica", Font.BOLD, 12));
        help.setForeground(Color.blue);
//		background.setVerticalTextPosition(AbstractButton.BOTTOM);
//		background.setHorizontalTextPosition(AbstractButton.CENTER);
        help.setActionCommand("help");
        help.addActionListener (this);
        add(help);

        /*addSeparator();
        JButton fit = new JButton (createImageIcon("graphics/fitscreen.jpg"));
        fit.setToolTipText("Fit To Screen");
//		background.setVerticalTextPosition(AbstractButton.BOTTOM);
//		background.setHorizontalTextPosition(AbstractButton.CENTER);
        fit.setActionCommand("fitscreen");
        fit.addActionListener (this);
        add(fit);      */

        addSeparator();
        fitToScreen= new JToggleButton (createImageIcon ("graphics/fitscreen.jpg"), true);
        fitToScreen.setToolTipText("Fit To Screen");
//		antiAliasing.setVerticalTextPosition(AbstractButton.BOTTOM);
//		antiAliasing.setHorizontalTextPosition(AbstractButton.CENTER);
        p.setFitToScreen(true);
        fitToScreen.setActionCommand("fitscreen");
        fitToScreen.addActionListener (this);
        add(fitToScreen);

//		addSeparator();
		antiAliasing = new JToggleButton (createImageIcon ("graphics/aa2.gif"), true);
        antiAliasing.setToolTipText("Anti-aliasing");
//		antiAliasing.setVerticalTextPosition(AbstractButton.BOTTOM);
//		antiAliasing.setHorizontalTextPosition(AbstractButton.CENTER);
		p.setAntiAliasing(true);
		antiAliasing.setActionCommand("aa");
		antiAliasing.addActionListener (this);
		add(antiAliasing);


        addSeparator();
        JButton addPlot = new JButton (" + ");
        addPlot.setToolTipText("Add Plot");
//		background.setVerticalTextPosition(AbstractButton.BOTTOM);
//		background.setHorizontalTextPosition(AbstractButton.CENTER);
        addPlot.setActionCommand("+");
        addPlot.addActionListener (this);
        add(addPlot);

        JButton removePlot = new JButton (" - ");
        removePlot.setToolTipText("Remove Plot");
//		background.setVerticalTextPosition(AbstractButton.BOTTOM);
//		background.setHorizontalTextPosition(AbstractButton.CENTER);
        removePlot.setActionCommand("-");
        removePlot.addActionListener (this);
        add(removePlot);

        addSeparator();
//        JLabel plotNameLabel = new JLabel("  Plot ");
//        add(plotNameLabel);
        cb=new JComboBox();
        p.setCb(cb);

        add(cb);

/*      addSeparator();
		kill = new JButton ("Delete last", new ImageIcon("graphics/kill.gif"));
		kill.setVerticalTextPosition(AbstractButton.BOTTOM);
		kill.setHorizontalTextPosition(AbstractButton.CENTER);
		kill.setActionCommand("kill");
		kill.addActionListener (this);
		add(kill);
*/
	}

	private void savePlot () {
		JFileChooser jf = new JFileChooser();
		//ExampleFileFilter filter = new ExampleFileFilter();
		javax.swing.filechooser.FileFilter filter = new javax.swing.filechooser.FileFilter() {
			public boolean accept (File f) {
				if (f.getName().endsWith("PNG") || f.getName().endsWith("png"))
					return true;
				return false;
			}
			public String getDescription() {
				return "PNG Files";
			}
			};
		//filter.addExtension("png");
		//filter.setDescription("PNG Images");
		jf.setFileFilter(filter);

		jf.showSaveDialog(this);
		String filename = jf.getSelectedFile().getAbsolutePath();
		if ( !filename.endsWith(".png") && ! filename.endsWith(".PNG"))
			filename += ".png";

		BufferedImage bi = new BufferedImage (p.getWidth(), p.getHeight(), BufferedImage.TYPE_INT_RGB);
		p.paint (bi.getGraphics());
		//GIFOutputStream.writeGIF (new FileOutputStream(jf.getSelectedFile()), bi);
		byte[] pngbytes;
		PngEncoderB png =  new PngEncoderB( bi,
			false,
			PngEncoderB.FILTER_NONE, 1 );

		try
		{
			FileOutputStream outfile = new FileOutputStream( filename );
			pngbytes = png.pngEncode();
			if (pngbytes == null)
			{
				System.out.println("Null image");
			}
			else
			{
				outfile.write( pngbytes );
			}
			outfile.flush();
			outfile.close();
		}
		catch (IOException ee)
		{
			ee.printStackTrace();
		}
	}

	public void actionPerformed (ActionEvent e) {
		try {
		double scale = 1;
		double width = p.getMaxX() - p.getMinX();
		double height = p.getMaxY() - p.getMinY();
		double middleX = p.getMinX() + width/2.0;
		double middleY = p.getMinY() + height/2.0;

		if (e.getActionCommand() == "Save") {
			savePlot();
        } else if (e.getActionCommand() == "aa") {
            p.setAntiAliasing (antiAliasing.isSelected());
        } else if (e.getActionCommand() == "fitscreen") {
            p.setFitToScreen (fitToScreen.isSelected());
            p.FitToScreen();
		} else if (e.getActionCommand() == "(0,0)") {
			p.setMinX(0 - width / 2.0);
			p.setMinY(0 - height / 2.0);
			p.setMaxX(0 + width / 2.0);
			p.setMaxY(0 + height / 2.0);
		} else if(e.getActionCommand() == "Background") {
			Color mycolor = null;
			mycolor = JColorChooser.showDialog(
		              this,
		              "Choose Plot Color",
		              mycolor);
			p.setBackground(mycolor);
/*        } else if(e.getActionCommand() == "fitscreen") {
            p.fitToScreen();*/
        } else if(e.getActionCommand() == "help") {
            if(helpText!=null){
                JDialog dialog = new JDialog();
                dialog.getContentPane().add(helpText);
                dialog.setSize(600,700);
                dialog.setVisible(true);
            }
        } else if(e.getActionCommand() == "kill") {
            p.removeLast();
        } else if(e.getActionCommand() == "+") {
            p.replaceFunction((String)cb.getSelectedItem());
        } else if(e.getActionCommand() == "-") {
            p.removeFunction((String)cb.getSelectedItem());
		} else {
			if (e.getActionCommand() == "zoomIn") {
				scale = 0.5;
			} else if (e.getActionCommand() == "zoomOut") {
				scale = 2.0;
			}

			p.setMinX(middleX - width/2.0 * scale);
			p.setMinY(middleY - height/2.0 * scale);
			p.setMaxX(middleX + width/2.0 * scale);
			p.setMaxY(middleY + height/2.0 * scale);
		}
		p.repaint();
	} catch(Exception ee) {
	}

	}
}