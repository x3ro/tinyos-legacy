package de.tub.eyes.gui.customelements;

import java.awt.*;

import javax.swing.*;
import javax.swing.border.Border;

import com.jgoodies.plaf.plastic.theme.ExperienceBlue;

/**
 * This draws a Border around Components which is built to look similarly to the
 * JGoodies SimpleInternalFrame, as this was not published to the Time this
 * Border was built. It can contain a Title String describing the Component as
 * well as an Icon which will be displayed left of the String. The Drop shadow
 * was first included in a much more simple Form. It was lateron replaced by
 * Code derived from the ShadowPopupBorder of the JGoodies Looks Library. This
 * Code (as well as the original Idea how to construct this Border) is work of
 * Stefan Matthias Aust and Karsten Lentzsch. To find out
 * about Stefan Matthias Aust have a look at <a href="http://www.3plus4.de">http://www.3plus4.de</a> To
 * find out about Karsten Lentzsch and JGoodies, please go to
 * <a href="http://www.jgoodies.com">http://www.jgoodies.com</a>
 * <br>
 * <strong>In order to use this class it has to be able to load the image named "shadow.png", which is
 * supposed to be in a subdirectory called "img". If this is not possible this class will produce
 * exceptions.</strong>
 * 
 * @author Joachim Praetorius
 */
public class CaptionBorder implements Border {
    private String caption;
    private ImageIcon ii;
    private static Image shadowImage = new ImageIcon("img/shadow.png","shadow").getImage();

    public CaptionBorder(String caption) {
        this.caption = caption;
    }

    public CaptionBorder(String caption, ImageIcon ii) {
        this.caption = caption;
        this.ii = ii;
    }

    public boolean isBorderOpaque() {
        return true;
    }

    public void paintBorder(Component c, Graphics g, int x, int y, int width,
            int height) {

        FontMetrics fm = c.getFontMetrics(c.getFont());
        Rectangle viewR = new Rectangle();
        viewR.x = 2;
        viewR.y = 0;
        viewR.width = width - 2;
        viewR.height = fm.getHeight() + 2;
        Rectangle iconR = new Rectangle();
        Rectangle stringR = new Rectangle();

        Color c1 = new ExperienceBlue().getSimpleInternalFrameBackground();
        Color c2 = new ExperienceBlue().getDesktopColor();
        Color frame = new ExperienceBlue().getWindowTitleForeground();
        GradientPaint gp = new GradientPaint(0, height / 2, c1, width - 4,
                height / 2, c2);

        String s = SwingUtilities.layoutCompoundLabel((JComponent) c, fm,
                caption, ii, SwingConstants.CENTER, SwingConstants.LEFT,
                SwingConstants.CENTER, SwingConstants.RIGHT, viewR, iconR,
                stringR, 2);
        g.setColor(frame);
        //draw a Rectangle around the whole Component minus the space I need
        // for the shadow
        g.drawRect(x, y, width - 5, height - 5);
        // draw a Separator Line below the Title of the Border
        g.drawLine(x + 1, y + fm.getHeight() + 3, x + width - 5, y
                + fm.getHeight() + 3);

        //Draw the drop shadow
        g.drawImage(shadowImage, x + 5, y + height - 5, x + 10, y + height, 0,
                6, 5, 11, null, c);
        g.drawImage(shadowImage, x + 10, y + height - 5, x + width - 5, y
                + height, 5, 6, 6, 11, null, c);
        g.drawImage(shadowImage, x + width - 5, y + 6, x + width, y + height
                - 5, 6, 5, 11, 6, null, c);
        g.drawImage(shadowImage, x + width - 5, y + height - 5, x + width, y
                + height, 6, 6, 11, 11, null, c);

        ((Graphics2D) g).setPaint(gp);
        //Fill the Title with the Gradient
        g.fillRect(x + 1, y + 1, width - 6, fm.getHeight() + 2);

        g.setColor(Color.white);

        //Check if an Icon is specified and draw it if so
        if (ii != null) {
            g.drawImage(ii.getImage(), iconR.x, iconR.y, iconR.width,
                    iconR.height, c);
        }

        //Draw the Title String
        g.drawString(s, stringR.x, stringR.y + fm.getAscent());

    }

    public Insets getBorderInsets(Component c) {
        FontMetrics fm = c.getFontMetrics(c.getFont());
        return new Insets(fm.getHeight() + 4, 1, 5, 5);
    }

} //class
