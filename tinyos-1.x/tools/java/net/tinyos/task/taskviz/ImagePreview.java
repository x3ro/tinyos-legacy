/*
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


package net.tinyos.task.taskviz;

import javax.swing.*;
import java.beans.*;
import java.awt.*;
import java.io.File;

/**
 * This class adds an image preview window to a FileChooser, displaying a thumbnail image of a 
 * selected file, if available
 */
public class ImagePreview extends JComponent implements PropertyChangeListener {
  ImageIcon thumbnail = null;
  File file = null;
  
  /**
   * Constructor that sets the size of the preview image and adds itself as a listener for changes
   * in the file chooser (so it knows when to load a new preview image)
   */
  public ImagePreview(JFileChooser fc) {
    setPreferredSize(new Dimension(100, 50));
    fc.addPropertyChangeListener(this);
  }

  /**
   * This method creates a scaled-down thumbnail
   */
  public void loadImage() {
    if (file == null) {
      return;
    }
 
    ImageIcon tmpIcon = new ImageIcon(file.getPath());
    if (tmpIcon.getIconWidth() > 90) {
      thumbnail = new ImageIcon(tmpIcon.getImage().getScaledInstance(90, -1, Image.SCALE_DEFAULT));
    } 
    else {
      thumbnail = tmpIcon;
    }
  }

  /**
   * When a new file is selected in the file chooser, this method is called to display a new thumbnail
   *
   * @param e The event created when there's a change in the file chooser properties
   */
  public void propertyChange(PropertyChangeEvent e) {
    String prop = e.getPropertyName();
    if (prop.equals(JFileChooser.SELECTED_FILE_CHANGED_PROPERTY)) {
      file = (File) e.getNewValue();
      if (isShowing()) {
        loadImage();
        repaint();
      }
    }
  }

  /**
   * This method renders the thumbnail image
   *
   * @param g The graphics component used to render the image
   */
  public void paintComponent(Graphics g) {
    if (thumbnail == null) {
      loadImage();
    }
    if (thumbnail != null) {
      int x = getWidth()/2 - thumbnail.getIconWidth()/2;
      int y = getHeight()/2 - thumbnail.getIconHeight()/2;

      if (y < 0) {
        y = 0;
      }

      if (x < 5) {
        x = 5;
      }
      thumbnail.paintIcon(this, g, x, y);
    }
  }
}
