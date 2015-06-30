/*
 * IMPORTANT:  READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 * By downloading, copying, installing or using the software you agree to this
 * license.  If you do not agree to this license, do not download, install,
 * copy or use the software.
 * 
 * Intel Open Source License 
 * 
 * Copyright (c) 1996-2002 Intel Corporation. All rights reserved. 
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 	Redistributions of source code must retain the above copyright notice,
 * 	this list of conditions and the following disclaimer. 
 * 
 * 	Redistributions in binary form must reproduce the above copyright
 * 	notice, this list of conditions and the following disclaimer in the
 * 	documentation and/or other materials provided with the distribution. 
 * 
 * 	Neither the name of the Intel Corporation nor the names of its
 * 	contributors may be used to endorse or promote products derived from
 * 	this software without specific prior written permission.
 *  
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE INTEL OR ITS  CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package net.tinyos.viz;

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