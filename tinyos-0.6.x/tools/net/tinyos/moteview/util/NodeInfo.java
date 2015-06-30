/*
 * NodeInfo.java
 *
 * Created on January 21, 2002, 1:35 PM
 */

package net.tinyos.moteview.util;

import java.awt.*;
import javax.swing.*;

/**
 *
 * @author  Joe Polastre &lt;<a href="mailto:polastre@cs.berkeley.edu">polastre@cs.berkeley.edu</a>&gt;
 */
public class NodeInfo
{
    protected Integer       nodeNumber;
    protected ImageIcon     imageHelper;
    protected Image         image;
    protected Image         imageSelected;
    protected double        imageWidth, imageHeight;
    protected boolean       displayThisNode;
    protected boolean       displayNodeNumber;
    protected boolean       fitOnScreen;
    protected boolean       m_bSelected;
    protected int           x;
    protected int           y;

    public NodeInfo(Integer pNodeNumber)
    {
            nodeNumber = pNodeNumber;
            imageHelper = new ImageIcon("net/tinyos/moteview/images/mote.gif","images/mote.gif");
            image = imageHelper.getImage();
            imageHelper = new ImageIcon ("net/tinyos/moteview/images/mote_selected.gif","images/mote_selected.gif");
            imageSelected = imageHelper.getImage();
            imageWidth = .2;//note that this width and height is in node coordinates (hence it scales automatically with the size of the network, but must be initialized properly)
            imageHeight = .2;
            displayThisNode = true;
            displayNodeNumber = false;
            fitOnScreen = true;
            x = 0;
            y = 0;
    }


    public Integer GetNodeNumber(){return nodeNumber;}
    public int GetX(){return x;}
    public int GetY(){return y;}
    public  ImageIcon GetImageHelper(){ return imageHelper;}
    public  Image GetImage()
    {
        if ( m_bSelected ) { return imageSelected; }
        else { return image; }
    }

    public  double GetImageWidth(){ return imageWidth;}
    public  double GetImageHeight(){ return imageHeight;}
    public  boolean GetDisplayThisNode(){ return displayThisNode;}
    public  boolean GetDisplayNodeNumber(){ return displayNodeNumber;}
    public  boolean GetFitOnScreen(){ return fitOnScreen;}

    public  void SetX(int newx) { x = newx; }
    public  void SetY(int newy) { y = newy; }
    public  void SetImageHelper(ImageIcon pImageHelper){  imageHelper =pImageHelper;}
    public  void SetImage(Image pImage){  image =pImage;}
    public  void SetImageWidth(double w){  imageWidth = w;}
    public  void SetImageHeight(double h){  imageHeight = h;}
    public  void SetDisplayThisNode(boolean pDisplay){  displayThisNode=pDisplay;}
    public  void SetDisplayNodeNumber(boolean pDisplayNumber){  displayNodeNumber=pDisplayNumber;}
    public  void SetFitOnScreen(boolean pFit){  fitOnScreen=pFit;}

    public boolean IsSelected ( ) { return m_bSelected; }
    public void SetSelected ( boolean selected ) { m_bSelected = selected; }


}