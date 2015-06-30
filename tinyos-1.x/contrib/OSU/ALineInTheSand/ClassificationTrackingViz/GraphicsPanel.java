/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

/*
*
*   FILE NAME
*
*        GraphicsPanel.java
*
*   DESCRIPTION
*
*      This class implements methods used to display network topology formed by 
the motes 
* communicating among them.  The intial topology is generated on this panel 
based on file 
* input descreption with each mote location. This class implements mouse events 
that can be
* used to modify the topology displayed during the simulation.  
*      Because of custom paint implemented in this panel, all painting request 
will be first
* intiated through method paintComponent which calls method drawTopology.
*
* Author : Mark E. Miyashita  -  Kent State University
* 
* Modifications: Adnan Vora (4/17/03)
*  1. removed ComponentListener and MouseEventListener interfaces (don't need 
them)
*  2. removed code to stretch image when window maximized. May not be ideal 
because
*     sense of proportion may be lost (given our field is long and narrow
*  3. (Aesthetic): Replaced all tabs in code with 3 spaces.
*  4. Added Vector of MoteReading and TargetProperty
*  5. Added method CopyMoteReading and CopyTargetProperty to be called from JMX 
and added to
*     vector created above.  Allow development of pause and playback.
*  6. Added method CopyFieldSize to be called from buttonPanel to set the Field 
Size of 
*     simulation
*  7. Added method CopyBaseStation to be called from buttonPanel to set the Base 
station
*     information
*  8. Added freeze/unfreeze and playback modes
*  9. Added SimulationStarted indicator to avoid infinite calls to the method 
paintComponent()
*     inside DrawTopology() method before and after the simulation
*  10. Removed reference to drawTopology() method from the paintComponent() and 
placed it in
*      run() method.  This change corrected the Window Refresh issue under 
Win2000
*  11. Added "CopyScale()" method to be used for mote scaling and shifting
*  12. Added stuff for User-input Zooming
*  13. Added Dispersion Overlay
*  14. Added timestamp assignment to mote messages
*  15. Revised logic for display of targets
*  16. Adding display for MIR stuff
*  17. Added Entry/Exit points
*  18. Code for arrows to diplay parent-child relations instead of graded lines
*  19. Dispersion overlay tweaked.
*
*/

/* Import required class files */

import java.awt.*;
import java.awt.event.*;
import java.awt.image.*;
import java.awt.print.*;
import java.util.*;
import javax.swing.*;
import javax.swing.event.*;
import javax.swing.border.*;
import java.awt.geom.*;
import edu.umd.cs.jazz.*;
import edu.umd.cs.jazz.util.*;
import edu.umd.cs.jazz.component.*;

/* Create outer panel */

public class GraphicsPanel extends JInternalFrame {
   public surfece surf;
   JDesktopPane desktop = null;
   JCheckBox windowResizable   = null;
   JCheckBox windowClosable    = null;
   JCheckBox windowIconifiable = null;
   JCheckBox windowMaximizable = null;

   /**
   * Dimensions of actual field
   */
   private int fieldHeight = 30;
   private int fieldWidth = 300;

   /**
   * Dimensions of mote and target
   */
   private static int moteHeight = 10;
   private static int moteWidth = 10;
   private static int targetHeight = 16;
   private static int targetWidth = 16;
   private static int exitPointHeight = 20;
   private static int exitPointWidth = 20;
   private static int entryPointHeight = 10;
   private static int entryPointWidth = 10;
   private AggregatePanel apanel;

   public GraphicsPanel( AggregatePanel summary ) {
      /* Setup Internal Frame options */
      windowResizable   = new JCheckBox("Window Resize", true);
      windowIconifiable = new JCheckBox("Window iconfy", true);
      windowMaximizable = new JCheckBox("Window Maximize", true);     
      setTitle("Network Topology");
      setMaximizable(windowMaximizable.isSelected());
      setIconifiable(windowIconifiable.isSelected());
      setResizable(windowResizable.isSelected());

      setSize(getPreferredSize());      
      setBounds(100, 100, 600, 600);

      this.apanel = summary;

      /* Setup Layout for this panel */

      getContentPane().setLayout(new BorderLayout());
      getContentPane().add(surf = new surfece());     

      show();      
   }
   public Dimension getMinimumSize() {
      return getPreferredSize();
   }
    
   public Dimension getPreferredSize() {
      return new Dimension(1200,1200);
   }

   public JInternalFrame getInternalFrame() {
      return this;
   }

   /* Create main panel which will draw topology */
   public class surfece extends ZCanvas implements
             Runnable, Printable
   {
      Image offscreen;
      Dimension offscreensize;
      Graphics2D offgraphics;
      private Vector vctMotes  = new Vector();  /* Vector of Motes */
      private Vector vctReading = new Vector(); /* list of mote reading and 
target property objects */
      private boolean SimulationStarted = false;/* Indicator used to avoid 
infinite paintComponent calls */
      private Scale vScale;                     /* Scale information */

      /**
       * These clones are used whenever the Panel is in freeze mode
       * */
      public Vector vctMotesClone = new Vector();
      public Vector vctReadingClone = new Vector();

      private boolean status = false;
      private Thread thread;
      int maxNumPage = 1;
      public BufferedImage bi;
      private Mote currentMote;
      private long freezeTime;
      private long playbackStartTime;
      private boolean showTopology = true;
      private boolean showMotes = true;
      private boolean showParticipatingMotes = true;
      private boolean showGridLines = false;
      private boolean freeze = false;
      private int playbackInterval = 15;
      private double zoomScale = 1.0;
      private int maxMoteX = 0;
      private int maxMoteY = 0;
      private int minMoteX = 0;
      private int minMoteY = 0;
      private ZImage BackGroundImage;
      private ZImage soldierIcon;
      private ZImage humanIcon;
      private ZImage tankIcon;
      private ZImage carIcon;
      private ZImage undefinedIcon;
      private ZVisualLeaf bgimage;
      private BitSet displayMIR;
      public BitSet displayMIRClone;

      private int margin = moteWidth;

      // This Vector size is essential for giving 
      // 5 minutes worth of playback (50 messages per second)
      // for 300 seconds plus overhead
      private static final int MAX_VECTOR_SIZE = 16384;
      private static final int gridWidth = 5;
      private static final int targetTrailLength = 5;
      private static final long suffInactivityToConsiderExit = 6000;
      private static final long targetDisplayTime = 10000;
      private Color textColor;
      private Color lineColor;
      private Color textBGColor;
      private Color mirColor;
    
      public surfece() {
         super();

         /* Set canvas and make it visible */
         setBackground( Color.white );
         setExcludeMouseMoveEvents( true );
         BackGroundImage = new ZImage("background.jpg");
         bgimage = new ZVisualLeaf( BackGroundImage );
         soldierIcon = new ZImage( "sold4.gif" );
         humanIcon = new ZImage( "human2.gif" );
         tankIcon = new ZImage( "alert.gif" );
         carIcon = new ZImage( "car1.gif" );
         undefinedIcon = new ZImage( "undefined.gif" );
         textColor = Color.black;
         lineColor = Color.black;
         textBGColor = Color.white;
         mirColor = Color.green;
         validate();
      }

      /* Start Graphics Panel as Thread */
      public void start() {
         thread = new Thread(this);
         thread.setPriority(Thread.MIN_PRIORITY);
         SimulationStarted = true;
         thread.start();
      }

      /* Stop Graphics Panel as Thread */
      public synchronized void stop() {
         try {      
            vctReading.removeAllElements();
            getLayer().removeAllChildren(); /* Clear panel */
            SimulationStarted = false;      /* Set indicator to false */
            thread = null;
            notify();
         }catch(Exception e){
            e.printStackTrace();
         }
      }

      /* Execute this Thread */
      public void run() {
         Thread me = Thread.currentThread();
         while (thread == me) {
            try {
               thread.sleep(100);
               if ( SimulationStarted ) drawTopology();
            } catch (InterruptedException e) {
               break;
            }
         }
      }

      public Dimension getMinimumSize() {
         return getPreferredSize();
      }
       
      public Dimension getPreferredSize() {
         return new Dimension(1200,1200);
      }

      /* Setup Mote information such as location read from file to be used here 
*/
      public void CopyMoteInfo(Vector vMote) {
         vctMotes = vMote;
         ListIterator motesIter = vctMotes.listIterator();
         Mote currentMote = null;
         maxMoteX = -1;
         maxMoteY = -1;
         minMoteX = 9999;
         minMoteY = 9999;
         while( motesIter.hasNext() ) {
            currentMote = (Mote) motesIter.next();
            if( currentMote.getMoteX() > maxMoteX ) {
               maxMoteX = currentMote.getMoteX();
            }
            if( currentMote.getMoteY() > maxMoteY ) {
               maxMoteY = currentMote.getMoteY();
            }
            if( currentMote.getMoteX() < minMoteX ) {
               minMoteX = currentMote.getMoteX();
            }
            if( currentMote.getMoteY() < minMoteY ) {
               minMoteY = currentMote.getMoteY();
            }
         }

         displayMIR = new BitSet( vctMotes.size() );

         /**
          * The summary panel should be fed either the actual info
          * or the info from the clones depending on whether we are in
          * freeze mode
          * */
         if( isFreeze() ) {
            apanel.displayMsg( vctMotesClone, null );
         }
         else {
            apanel.displayMsg( vctMotes, null );
         }
      }
     
      private synchronized void checkVectorForSize() {
         while( vctReading.size() >= MAX_VECTOR_SIZE ) {
            vctReading.removeElementAt( 0 );
         }
      }

      public synchronized void CopyMIRMessage(MIRProperty newMIRProperty) {
         if( !isFreeze() ) {
            /**
             * Add the reading to the vector of readings
             * */
            checkVectorForSize();
            newMIRProperty.setTimestamp( System.currentTimeMillis() );
            vctReading.add( newMIRProperty );

            if( newMIRProperty.getMIRType() == MIRProperty.START ) {
               displayMIR.set( newMIRProperty.getID() );
            }
            else {
               displayMIR.clear( newMIRProperty.getID() );
            }
         }
      }

      /* Add latest reading from Mote message */
      public synchronized void CopyMoteReading(MoteReading vReading) {
         if( !isFreeze() ) {
            /**
             * Add the reading to the vector of readings
             * */
            checkVectorForSize();
            vReading.setTimestamp( System.currentTimeMillis() );
            vctReading.add( vReading );

            /**
             * Since this was a mote reading, we must find the corresponding 
mote
             * and make this reading its last reading
             * */
            ListIterator motesIter = vctMotes.listIterator();
            Mote currentMote = null;
            while( motesIter.hasNext() ) {
               currentMote = (Mote)motesIter.next();
               if( currentMote.getMoteID() == vReading.getMoteID() ) {
                  /**
                   * Found the corresponding mote
                   * */
                  vReading.setLastReadingForThisMote( 
currentMote.getLastReading() );
                  currentMote.setLastReading( vReading );

                  /**
                   * Find its latest parent (as mentioned in the latest reading
                   * and fix outdated parent reference
                   * */
                  if( vReading.getParentMoteID() > -1 ) {
                     ListIterator parentMotesIter = vctMotes.listIterator();
                     Mote parentMote = null;
                     currentMote.setParentMote( null );
                     while( parentMotesIter.hasNext() ) {
                        parentMote = (Mote)parentMotesIter.next();
                        if( parentMote.getMoteID() == vReading.getParentMoteID() 
) {
                           currentMote.setParentMote( parentMote );
                           break;
                        }
                     }
                  }
                  else {
                     currentMote.setParentMote( null );
                  }

                  /**
                   * Once we find the corresponding mote, there is no reason to 
keep
                   * the while loop going
                   * */
                  break;
               }
            }
         }
      }

      /* Add latest target property from Mote message */
      public synchronized void CopyTargetProperty(TargetProperty vTarget) {
         if( !isFreeze() ) {
            checkVectorForSize();
            vTarget.setTimestamp( System.currentTimeMillis() );
            vctReading.add( vTarget );
         }
      }

      /* Add latest Base Station property */
      public void CopyBaseStation(BaseStationMote vBaseStationMote) {
      }

      /* Add Field Size */
      public void CopyFieldSize(Field vFieldSize) {
         if( vFieldSize != null ) {
            fieldWidth = vFieldSize.getFieldSizeX();
            fieldHeight = vFieldSize.getFieldSizeY();
            if( fieldWidth == 0 || fieldHeight == 0 ) {
               fieldWidth = 300;
               fieldHeight = 30;
            }
         }
      }

      /* Copy Scale */
      public void CopyScale(Scale cScale) {
           vScale = cScale;
      }

      /* Methos used to print current content of this panel */
      public int print(Graphics g, PageFormat pageFormat, int pageIndex) throws 
PrinterException {
         if (pageIndex >= maxNumPage || offscreen == null)
            return NO_SUCH_PAGE;
         
g.translate((int)pageFormat.getImageableX(),(int)pageFormat.getImageableY());
         int wPage = (int)pageFormat.getImageableWidth();
         int hPage = (int)pageFormat.getImageableHeight();
         int w = offscreen.getWidth(this);
         int h = offscreen.getHeight(this);

         if ( w == 0 || h == 0 )
            return NO_SUCH_PAGE;

         int nCol = Math.max((int)Math.ceil((double)w/wPage),1);
         int nRow = Math.max((int)Math.ceil((double)h/hPage),1);
         maxNumPage = nCol*nRow;
         int iCol = pageIndex % nCol;
         int iRow = pageIndex / nCol;
         int x = iCol * wPage;
         int y = iRow * hPage;
         int wImage = Math.min(wPage,w-x);
         int hImage = Math.min(hPage,h-y);
         g.drawImage(offscreen,0,0,wImage,hImage,x,y,x+wImage,y+hImage,this);
         System.gc();

         return PAGE_EXISTS;
      }

      /* Draw entire network topology */
      public synchronized void drawTopology() {
         /**
         * Get the current dimension
         */
         // Dimension d = getSize();
         Dimension d = new Dimension(600, 120);
         d.width = 1200;
         d.height = 120;

         /**
         * Multiplication factor to scale the actual field coordinates to screen 
size
         */
         int YMultFactor = d.height / fieldHeight;
         int XMultFactor = d.width / fieldWidth;

         int moteX;
         int moteY;
         int actualX;
         int actualY;
         boolean targetChanged = false;
         boolean targetTypeChanged = false;

         /**
          * These vectors will be used for actual display.
          * They will point either to the actual vectors or to 
          * the clones, depending on the freeze mode
          * */
         Vector vctMotesForDisplay = null;
         Vector vctReadingForDisplay = null;
         BitSet bsMIRForDisplay = null;
         Vector vctZLeaves = new Vector();

         if( isFreeze() ) {
            vctMotesForDisplay = (Vector)vctMotesClone.clone();
            vctReadingForDisplay = (Vector)vctReadingClone.clone();
            bsMIRForDisplay = (BitSet)displayMIRClone.clone();
         }
         else {
            vctMotesForDisplay = (Vector)vctMotes.clone();
            vctReadingForDisplay = (Vector)vctReading.clone();
            bsMIRForDisplay = (BitSet)displayMIR.clone();
         }


         /**
          * Start with a brand new canvas
          * */
         getLayer().removeAllChildren();

         /**
          * Send the display vectors to the aggregate panel for calculation
          * of summary info
          * */
         apanel.displayMsg( vctMotesForDisplay, vctReadingForDisplay );

         getCamera().setScale( getZoomFactor() );

         double lowerBoundX = XMultFactor * minMoteX - margin;
         double lowerBoundY = YMultFactor * minMoteY - margin;
         double upperBoundX = XMultFactor * maxMoteX + margin;
         double upperBoundY = YMultFactor * maxMoteY + margin;
         double fieldWidth = upperBoundX - lowerBoundX - ( 2 * margin );
         double fieldHeight = upperBoundY - lowerBoundY - ( 2 * margin );

         vctZLeaves.add( bgimage );

         double gWidth = (double)XMultFactor * gridWidth;

         if( isShowGridLines() ) {
            double lineStartX = 0;
            double lineStartY = 0;

            // Draw vertical lines
            for( double vLineX = lineStartX; 
                              vLineX <= 1200; vLineX += gWidth )
            {
               ZLine gLine = new ZLine( vLineX, lineStartY, vLineX, 1200 );
               gLine.setPenWidth( 0.01);
               gLine.setPenPaint( lineColor );
               ZVisualLeaf gLineLeaf = new ZVisualLeaf( gLine );
               vctZLeaves.add( gLineLeaf );
               String Label = new String( Short.toString( new Double( vLineX / 
XMultFactor).shortValue() ) );
               ZText gridLabel = new ZText( Label, new Font( null, Font.PLAIN, 5 
) );
               gridLabel.setBackgroundColor( textBGColor );
               gridLabel.setPenColor( textColor );
               gridLabel.setTranslation( vLineX + 2, lineStartY + 2 );
               ZVisualLeaf gridLabelLeaf = new ZVisualLeaf( gridLabel );
               vctZLeaves.add( gridLabelLeaf );
            }
            // Draw horizontal lines
            for( double vLineY = lineStartY; 
                              vLineY <= 1200; vLineY += gWidth )
            {
               ZLine gLine = new ZLine( lineStartX, vLineY, 1200, vLineY );
               gLine.setPenWidth( 0.01 );
               gLine.setPenPaint( lineColor );
               ZVisualLeaf gLineLeaf = new ZVisualLeaf( gLine );
               vctZLeaves.add( gLineLeaf );
               String Label = new String( Short.toString( new Double( vLineY / 
XMultFactor).shortValue() ) );
               ZText gridLabel = new ZText( Label, new Font( null, Font.PLAIN, 5 
) );
               gridLabel.setBackgroundColor( textBGColor );
               gridLabel.setPenColor( textColor );
               gridLabel.setTranslation( lineStartX + 2, vLineY + 2 );
               ZVisualLeaf gridLabelLeaf = new ZVisualLeaf( gridLabel );
               vctZLeaves.add( gridLabelLeaf );
            }
         }

         // Show a Bounding box enclosing the entire LITeS
         ZRectangle boundingBox = new ZRectangle( lowerBoundX, lowerBoundY, 
                                 upperBoundX - lowerBoundX, upperBoundY - 
lowerBoundY );
         float[] dash_pattern = new float[2];
         dash_pattern[0] = 3.0f;
         dash_pattern[1] = 3.0f;
         boundingBox.setStroke( new BasicStroke( 0.01f, BasicStroke.CAP_ROUND, 
BasicStroke.JOIN_ROUND,
                                                 1.0f, dash_pattern, 1.5f ) );
         boundingBox.setPenPaint( Color.blue );
         boundingBox.setFillPaint( null );
         ZVisualLeaf bbox = new ZVisualLeaf( boundingBox );
         vctZLeaves.add( bbox );


         // Show the scale legend
         double startScaleLegX = upperBoundX - 10 * XMultFactor;
         double startScaleLegY = upperBoundY + 10 * YMultFactor;
         double midPointX = upperBoundX - ( upperBoundX - startScaleLegX ) / 2;
         ZLine scaleLine = new ZLine( startScaleLegX, startScaleLegY,
                                      upperBoundX, startScaleLegY );
         scaleLine.setPenPaint( lineColor );
         scaleLine.setPenWidth( 0.5 );
         ZVisualLeaf scaleLineLeaf = new ZVisualLeaf( scaleLine );
         vctZLeaves.add( scaleLineLeaf );

         ZLine notchLine = new ZLine( startScaleLegX, startScaleLegY,
                                      startScaleLegX, startScaleLegY - 3 );
         notchLine.setPenPaint( lineColor );
         notchLine.setPenWidth( 0.5 );
         ZVisualLeaf notchLineLeaf = new ZVisualLeaf( notchLine );
         vctZLeaves.add( notchLineLeaf );
         ZText notchLabel = new ZText( "0", new Font( null, Font.PLAIN, 7 ) );
         notchLabel.setPenPaint( textColor );
         notchLabel.setBackgroundColor( textBGColor );
         notchLabel.setTranslation( startScaleLegX, startScaleLegY + 3 );
         ZVisualLeaf notchLabelLeaf = new ZVisualLeaf( notchLabel );
         vctZLeaves.add( notchLabelLeaf );

         notchLine = new ZLine( midPointX, startScaleLegY,
                                midPointX, startScaleLegY - 3 );
         notchLine.setPenPaint( lineColor );
         notchLine.setPenWidth( 0.5 );
         notchLineLeaf = new ZVisualLeaf( notchLine );
         vctZLeaves.add( notchLineLeaf );
         notchLabel = new ZText( "5", new Font( null, Font.PLAIN, 7 ) );
         notchLabel.setPenPaint( textColor );
         notchLabel.setBackgroundColor( textBGColor );
         notchLabel.setTranslation( midPointX, startScaleLegY + 3 );
         notchLabelLeaf = new ZVisualLeaf( notchLabel );
         vctZLeaves.add( notchLabelLeaf );

         notchLine = new ZLine( upperBoundX, startScaleLegY,
                                upperBoundX, startScaleLegY - 3 );
         notchLine.setPenPaint( lineColor );
         notchLine.setPenWidth( 0.5 );
         notchLineLeaf = new ZVisualLeaf( notchLine );
         vctZLeaves.add( notchLineLeaf );
         notchLabel = new ZText( "10 ft", new Font( null, Font.PLAIN, 7 ) );
         notchLabel.setPenPaint( textColor );
         notchLabel.setBackgroundColor( textBGColor );
         notchLabel.setTranslation( upperBoundX, startScaleLegY + 3 );
         notchLabelLeaf = new ZVisualLeaf( notchLabel );
         vctZLeaves.add( notchLabelLeaf );

         Vector vctArrows = new Vector();

         // Show the motes
         ListIterator motesIter = vctMotesForDisplay.listIterator();
         while( motesIter.hasNext() ) {
            currentMote = (Mote)motesIter.next();
            moteX = XMultFactor * currentMote.getMoteX();
            moteY = YMultFactor * currentMote.getMoteY(); 
            actualX = moteX - ( moteWidth / 2 );
            actualY = moteY - ( moteHeight / 2 );

            if( isShowMotes() ) {
              /**
               * Construct a mote display object and add it to the canvas
               * */
               ZRectangle moteBox = new ZRectangle( actualX, actualY, moteWidth, 
moteHeight );
               moteBox.setPenWidth( 0.1 );
               moteBox.setPenPaint( Color.blue );
               if( currentMote.isAlive() ) {
                  moteBox.setFillPaint( Color.blue );
               }
               else {
                  moteBox.setFillPaint( Color.gray );
               }
               ZVisualLeaf leaf = new ZVisualLeaf( moteBox );
               vctZLeaves.add( leaf );
            }
            /**
             * Show lines from child to parent ONLY if topology mode is set on
             * and the current mote actually HAS a parent
             * */
            if( isShowTopology() && currentMote.getParentMote() != null ) {
               /**
                * Draw line from child to parent
                * */
               int parentMoteX = currentMote.getParentMote().getMoteX() * 
XMultFactor;
               int parentMoteY = currentMote.getParentMote().getMoteY() * 
YMultFactor;
               //
               // comment the following six lines to remove arrow heads
               //
               ZPolygon arrow = getArrow( moteX, moteY, parentMoteX, 
parentMoteY, 7, 5, 1 );
               arrow.setPenPaint( Color.green );
               arrow.setFillPaint( Color.green );
               ZVisualLeaf arrowLeaf = new ZVisualLeaf( arrow );
               vctArrows.add( arrowLeaf );
               vctZLeaves.add( arrowLeaf );
               // Uncomment the following block of code to draw graient lines
               // to represent parent child relationship

               /*
               ZPath topPath = new ZPath( new GeneralPath( new Line2D.Float(
                  moteX, moteY, parentMoteX, parentMoteY ) ) );
               topPath.setPenPaint( new GradientPaint( moteX, moteY, Color.blue, 
                                                       parentMoteX, parentMoteY, 
Color.orange ) );
               topPath.setStroke( new BasicStroke( (float)0.5, 
                                 BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND ) 
);
               ZVisualLeaf topLeaf = new ZVisualLeaf( topPath );
               vctZLeaves.add( topLeaf );
               */
            }

            if( isShowMotes() && getCamera().getMagnification() >= 10.0 ) {
               /**
                * If the camera magnification is greater than some threshold,
                * we need to display some detail information about the motes
                * */
               ZText moteDisplay = new ZText( currentMote.toString(), new Font( 
null, Font.PLAIN, 1 ) );
               moteDisplay.setBackgroundColor( textBGColor );
               moteDisplay.setPenColor( textColor );
               moteDisplay.setTranslation( actualX + moteWidth, actualY );
               ZVisualLeaf dispLeaf = new ZVisualLeaf( moteDisplay );
               vctZLeaves.add( dispLeaf );
            }
         }


         /**
          * We now display the target readings
          * */
         ListIterator readingsIter = vctReadingForDisplay.listIterator();

         /**
          * Go all the way to the end of this list
          * */
         while( readingsIter.hasNext() ) {
            readingsIter.next();
         }
         boolean targetMustBeDisplayed = true;
         boolean targetExited = false;
         Vector vctIconLeaves = new Vector();
         Vector vctEntryExitLeaves = new Vector();
         ZVisualLeaf mirLeaf = null;

         /*
         long realClockDifference = 0;
         if( isFreeze() ) {
            realClockDifference = System.currentTimeMillis() - freezeTime + ( 
playbackInterval * 1000 );
         }
         */


         BitSet mirDisplayed = new BitSet( bsMIRForDisplay.size() );
         Vector vctMostRecentTargets = new Vector();
         TargetProperty lastKnownPosition = null;
         boolean showDetails = false;

         /**
         * The second condition in the while loop says that we should not quit
         * unless all the MIRs supposed to be displayed have been displayed
         * */
         while( ( readingsIter.hasPrevious()
                  ) ||
                  !bsMIRForDisplay.equals( mirDisplayed ) ) {
            TargetProperty currentProperty = null;
            Object currentObject = readingsIter.previous();
            if( currentObject.getClass().getName().equals( 
                     TargetProperty.ClassName ) ) {
               currentProperty = (TargetProperty) currentObject;
            }
            long currentTime;
            currentTime = isFreeze() ? 
               ( freezeTime + 
					  ( playbackStartTime > 0 ? 
                     System.currentTimeMillis() 
							- playbackStartTime - ( 
playbackInterval * 1000 )
						 : 0 ) )
               : System.currentTimeMillis();
            lastKnownPosition = null;
            if( currentProperty != null ) {
               int targetX = XMultFactor * currentProperty.getTargetX();
               int targetY = YMultFactor * currentProperty.getTargetY();
               int actualTargetX = targetX - ( targetWidth / 2 );
               int actualTargetY = targetY - ( targetHeight / 2 );
               Color targetColor = Color.red;
					boolean currentPropertyDisplayed = false;

               showDetails = false;

               for( int mostRecentTargetsCtr = 0; 
                        mostRecentTargetsCtr < vctMostRecentTargets.size();
                        mostRecentTargetsCtr++ ) {
                  TargetProperty tempTarget = 
                     (TargetProperty)vctMostRecentTargets.get( 
mostRecentTargetsCtr );
                  if( tempTarget.getTargetID() == currentProperty.getTargetID() 
) {
                     lastKnownPosition = 
                        (TargetProperty)vctMostRecentTargets.get( 
mostRecentTargetsCtr );
                     break;
                  }
               }
               if( lastKnownPosition == null ) {
                  if( currentTime - currentProperty.getTimestamp()
                        < suffInactivityToConsiderExit ) {
                     /* **
                      * Display the target with an icon (this is the
                      * head of the trail)
                      * **/
                     ZVisualLeaf iconLeaf = displayTargetAsIcon( 
                           currentProperty, actualTargetX, actualTargetY );
                     vctZLeaves.add( iconLeaf );
                     vctIconLeaves.add( iconLeaf );
							currentPropertyDisplayed = true;

                     /* **
                      * Add this property to the last Known positions vector
                      * **/
                     vctMostRecentTargets.add( currentProperty );
                  }
                  else {
                     if( currentTime - currentProperty.getTimestamp()
                           < targetDisplayTime ) {
                        /* **
                         * This target has exited. Draw the icon and decorate
                         * with green square.
                         * **/
                        ZVisualLeaf iconLeaf = displayTargetAsIcon( 
                              currentProperty, actualTargetX, actualTargetY );
                        vctZLeaves.add( iconLeaf );
                        vctIconLeaves.add( iconLeaf );
								currentPropertyDisplayed = true;

                        // Draw a green square
                        ZVisualLeaf exitLeaf = displayExit( targetX, targetY );
                        vctEntryExitLeaves.add( exitLeaf );
                        vctZLeaves.add( exitLeaf );

                        showDetails = true;

                        /* **
                         * Add this entry to the last known positions vector
                         * **/
                        vctMostRecentTargets.add( currentProperty );
                     }
                  }
               }
               else {
                  if( lastKnownPosition.getTimestamp() - 
                        currentProperty.getTimestamp() 
                        < suffInactivityToConsiderExit ) {
                     /* **
                      * Show the current property as a dot 
                      * **/
                     ZEllipse targetDot = new ZEllipse( targetX - 2,
                           targetY - 2, 4, 4 );
                     targetDot.setFillPaint( targetColor );
                     targetDot.setPenPaint( targetColor );
                     ZVisualLeaf tLeaf = new ZVisualLeaf( targetDot );
                     vctZLeaves.add( tLeaf );
							currentPropertyDisplayed = true;

                     /* **
                      * Draw the connecting line
                      * **/
                     ZLine connectingLine = new ZLine( targetX, targetY, 
                                                XMultFactor * 
                                                   
lastKnownPosition.getTargetX(), 
                                                YMultFactor * 
                                                   
lastKnownPosition.getTargetY() );
                     connectingLine.setPenWidth( 1.0 );
                     connectingLine.setPenPaint( targetColor );
                     ZVisualLeaf leaf = new ZVisualLeaf( connectingLine );
                     vctZLeaves.add( leaf );

                     /* **
                      * Add current property to the vector
                      * **/
                     vctMostRecentTargets.add( currentProperty );
                  }
                  else {
                     if( lastKnownPosition.getTimestamp() - 
                           currentProperty.getTimestamp() < targetDisplayTime ) 
{
                        /* **
                         * Show current property as an exit point
                         * **/
                        ZVisualLeaf iconLeaf = displayTargetAsIcon( 
                              currentProperty, actualTargetX, actualTargetY );
                        vctZLeaves.add( iconLeaf );
                        vctIconLeaves.add( iconLeaf );
								currentPropertyDisplayed = true;

                        // Draw a green square
                        ZVisualLeaf exitLeaf = displayExit( targetX, targetY );
                        vctEntryExitLeaves.add( exitLeaf );
                        vctZLeaves.add( exitLeaf );

                        /* **
                         * Add current property to the vector
                         * **/
                        vctMostRecentTargets.add( currentProperty );

                        showDetails = true;
                     }
                     /* **
                      * Show last known property as an entry point
                      * **/
                     ZVisualLeaf entryLeaf = displayEntry( lastKnownPosition,
                                                            XMultFactor,
                                                            YMultFactor );
                     vctEntryExitLeaves.add( entryLeaf );
                     vctZLeaves.add( entryLeaf );
                  }
                  /* **
                   * Remove last known property from the vector
                   * **/
                  vctMostRecentTargets.remove( lastKnownPosition );
               }

               if( getCamera().getMagnification() >= 10.0 && showDetails ) {
                  /**
                   * If we are sufficiently zoomed in, display details about the 
target
                   * but only at the head of the target trail
                   * */
                  ZText targDisplay = new ZText( currentProperty.toString(), 
                                                 new Font( null, Font.PLAIN, 1 ) 
);
                  targDisplay.setBackgroundColor( textBGColor );
                  targDisplay.setPenColor( targetColor );
                  targDisplay.setTranslation( actualTargetX + targetWidth, 
actualTargetY );
                  ZVisualLeaf targetDispLeaf = new ZVisualLeaf( targDisplay );
                  vctZLeaves.add( targetDispLeaf );
               }
    
               /* Start of Dispersion Overlay */
               if( isShowMotes() && isShowParticipatingMotes() && 
currentPropertyDisplayed ) {
                  Integer currentMoteID;
                  ListIterator participatingMotes = 
currentProperty.getMoteList().listIterator();
                  boolean moteFound;
                  while( participatingMotes.hasNext() ) {
                     currentMoteID = (Integer)participatingMotes.next();
                     motesIter = vctMotesForDisplay.listIterator();
                     moteFound = false;
                     while( motesIter.hasNext() && !moteFound ) {
                        currentMote = (Mote)motesIter.next();
                        if( currentMote.getMoteID() == currentMoteID.intValue() 
) {

                           // Flash the mote
                           actualX = XMultFactor * currentMote.getMoteX() - ( 
moteWidth / 2 );
                           actualY = YMultFactor * currentMote.getMoteY() - ( 
moteHeight / 2 ); 
                           /**
                           * Construct an LCD light on the mote
                           */
                           ZRectangle moteBox = new ZRectangle( actualX, 
actualY, 
                                                                   moteWidth, 
moteHeight );
                           moteBox.setPenWidth( 0.1 );
                           moteBox.setPenPaint( Color.red );
                           moteBox.setFillPaint( Color.red );           
                           ZVisualLeaf leaf = new ZVisualLeaf( moteBox );
                           vctZLeaves.add( leaf );
                           moteFound = true;
                        }
                     }
                  }
               }
               /* End of Dispersion Overlay */
            }
            /* Start MIR Display */
            if( currentObject.getClass().getName().equals( MIRProperty.ClassName 
) ) {
               MIRProperty currentMIR = (MIRProperty) currentObject;
               if( bsMIRForDisplay.get( currentMIR.getID() ) && 
                   !mirDisplayed.get( currentMIR.getID() ) ) {
                  // Supposed to be displayed but has not yet been displayed
                  if( currentMIR.getMIRType() == MIRProperty.START ) {
                     // Display the MIR Property
                     int mirX = XMultFactor * currentMIR.getMIRX();
                     int mirY = YMultFactor * currentMIR.getMIRY();
                     int mirRadius = XMultFactor * currentMIR.getRadius();
                     int actualMIRX = mirX - mirRadius;
                     int actualMIRY = mirY - mirRadius;

                     ZEllipse mirDot = new ZEllipse( actualMIRX, actualMIRY, mirRadius * 2, 
mirRadius * 2 );
                     mirDot.setFillPaint( mirColor );
                     mirDot.setPenPaint( mirColor );
                     mirLeaf = new ZVisualLeaf( mirDot );

                     // Add this leaf at position 1, because position 0 is either the background 
                     // image or one grid line that will almost never affect the MIR display
                     // and we want the MIR to be below everything else except the background
                     // image
                     vctZLeaves.add( 1, mirLeaf );

                     // Set flag to indicate that the current MIR property has been displayed
                     mirDisplayed.set( currentMIR.getID() );
                  }
               }
            }
            /* End MIR Display */
         }

         for( int mostRecentTargetsCtr = 0;
                  mostRecentTargetsCtr < vctMostRecentTargets.size();
                  mostRecentTargetsCtr++ ) {
            ZVisualLeaf entryLeaf = displayEntry( 
                  (TargetProperty)vctMostRecentTargets.get( mostRecentTargetsCtr 
),
                  XMultFactor, YMultFactor );
            vctEntryExitLeaves.add( entryLeaf );
            vctZLeaves.add( entryLeaf );
         }

         getLayer().addChildren( vctZLeaves );
         // The order of the next three for loops is important
         // in order not to hide something that we want to be
         // on the top.
         for( int iconCtr = 0; iconCtr < vctArrows.size(); iconCtr++ ) {
            ZVisualLeaf temp = (ZVisualLeaf)vctArrows.get( iconCtr );
            temp.raise();
         }
         for( int iconCtr = 0; iconCtr < vctEntryExitLeaves.size(); iconCtr++ ) 
{
            ZVisualLeaf temp = (ZVisualLeaf)vctEntryExitLeaves.get( iconCtr );
            temp.raise();
         }
         for( int iconCtr = 0; iconCtr < vctIconLeaves.size(); iconCtr++ ) {
            ZVisualLeaf temp = (ZVisualLeaf)vctIconLeaves.get( iconCtr );
            temp.raise();
         }
         vctZLeaves.removeAllElements();
			vctIconLeaves.removeAllElements();
         vctMostRecentTargets.removeAllElements();
         System.gc();
      }

      public synchronized ZVisualLeaf displayTargetAsIcon(
            TargetProperty thisProperty,
            int actualTargetX,
            int actualTargetY ) {
         ZImage targetIcon = null;
         if( thisProperty.getTargetType() 
               == TargetProperty.SOLDIER ) {
            targetIcon = new ZImage( soldierIcon.getImage() );
         }
         else if( thisProperty.getTargetType() 
               == TargetProperty.HUMAN ) {
            targetIcon = new ZImage( humanIcon.getImage() );
         }
         else if( thisProperty.getTargetType() 
               == TargetProperty.TANK ) {
            targetIcon = new ZImage( tankIcon.getImage() );
         }
         else if( thisProperty.getTargetType() 
               == TargetProperty.CAR ) {
            targetIcon = new ZImage( carIcon.getImage() );
         }
         else {
            targetIcon = new ZImage( undefinedIcon.getImage() );
         }
         targetIcon.setTranslation( actualTargetX, actualTargetY );
         ZVisualLeaf iconLeaf = new ZVisualLeaf( targetIcon );
         return iconLeaf;
      }
      public synchronized ZVisualLeaf displayExit( 
            int targetX, int targetY ) {
         ZRectangle exitPoint = new ZRectangle( 
                  targetX - ( exitPointWidth / 2.0 ),
                  targetY - ( exitPointHeight / 2.0 ),
                  exitPointWidth, exitPointHeight );
         exitPoint.setPenWidth( 0.1 );
         exitPoint.setPenPaint( Color.green );
         exitPoint.setFillPaint( Color.green );
         ZVisualLeaf exitLeaf = new ZVisualLeaf( exitPoint );
         return exitLeaf;
      }
      public synchronized ZVisualLeaf displayEntry( 
            TargetProperty entryProperty,
            int XMultFactor,
            int YMultFactor ) {
         double xcoords[] = new double[5];
         double ycoords[] = new double[5];
         xcoords[0] = (double)( XMultFactor * 
               entryProperty.getTargetX() );
         xcoords[1] = (double)( XMultFactor * 
               entryProperty.getTargetX() + 
               ( entryPointWidth / 2.0 ) );
         xcoords[2] = (double)( XMultFactor * 
               entryProperty.getTargetX() - 
               ( entryPointWidth / 2.0 ) );
         xcoords[3] = (double)( XMultFactor * 
               entryProperty.getTargetX() + 
               ( entryPointWidth / 2.0 ) );
         xcoords[4] = (double)( XMultFactor * 
               entryProperty.getTargetX() - 
               ( entryPointWidth / 2.0 ) );
         ycoords[0] = (double)( YMultFactor * 
               entryProperty.getTargetY() - 
               ( entryPointHeight / 2.0 ) );
         ycoords[1] = (double)( YMultFactor * 
               entryProperty.getTargetY() + 
               ( entryPointHeight / 2.0 ) );
         ycoords[2] = (double)( YMultFactor * 
               entryProperty.getTargetY() -
               ( entryPointHeight / 4.0 ) );
         ycoords[3] = (double)( YMultFactor * 
               entryProperty.getTargetY()  -
               ( entryPointHeight / 4.0 ) );
         ycoords[4] = (double)( YMultFactor * 
               entryProperty.getTargetY() + 
               ( entryPointHeight / 2.0 ) );
         ZPolygon entryPoint = new ZPolygon( xcoords, ycoords );
         entryPoint.setPenWidth( 0.1 );
         entryPoint.setPenPaint( Color.red );
         entryPoint.setFillPaint( Color.red );
         ZVisualLeaf entryLeaf = new ZVisualLeaf( entryPoint );
         return entryLeaf;
      }
      public synchronized void paintComponent(Graphics g){
         super.paintComponent(g);
      }

      public boolean isShowTopology() {
         return showTopology;
      }
      public void setShowTopology( boolean newShowTopology ) {
         showTopology = newShowTopology;
      }
      public boolean isShowMotes() {
         return showMotes;
      }
      public void setShowMotes( boolean newShowMotes ) {
         showMotes = newShowMotes;
      }
      public boolean isShowParticipatingMotes() {
         return showParticipatingMotes;
      }
      public void setShowParticipatingMotes( boolean newShowParticipatingMotes ) 
{
         showParticipatingMotes = newShowParticipatingMotes;
      }
      public boolean isShowGridLines() {
         return showGridLines;
      }
      public void setShowGridLines( boolean newShowGridLines ) {
         showGridLines = newShowGridLines;
      }
      public void setZoomFactor( double scale ) {
         zoomScale = scale;
      }
      public double getZoomFactor() {
         return zoomScale;
      }

      /*******************Here is the arrow code********/
      /*
      public void drawArrow(Graphics g, int x1, int y1, int x2, int y2) {
         g.drawPolygon(getArrow(x1, y1, x2, y2, 10, 5,0.5));
      }
      */

      public ZPolygon getArrow(int x1, int y1, int x2, int y2, int headsize, int 
difference, double factor) {
         int[] crosslinebase = getArrowHeadLine(x1, y1, x2, y2, headsize);
         int[] headbase = getArrowHeadLine(x1, y1, x2, y2, headsize - 
difference);
         int[] crossline = getArrowHeadCrossLine(crosslinebase[0], 
crosslinebase[1], x2, y2, factor);

         ZPolygon head = new ZPolygon();

         head.add(headbase[0], headbase[1]);
         head.add(crossline[0], crossline[1]);
         head.add(x2, y2);
         head.add(crossline[2], crossline[3]);
         head.add(headbase[0], headbase[1]);
         head.add(x1, y1);

         return head;
      }

      public int[] getArrowHeadLine(int xsource, int ysource,int xdest,int 
ydest, int distance) {
         int[] arrowhead = new int[2];
         int headsize = distance;

         double stretchfactor = 0;
         stretchfactor = 1 - 
            (headsize/(Math.sqrt(((xdest-xsource)*(xdest-xsource))+((ydest-
ysource)*(ydest-ysource)))));
         arrowhead[0] = (int) (stretchfactor*(xdest-xsource))+xsource;
         arrowhead[1] = (int) (stretchfactor*(ydest-ysource))+ysource;

         return arrowhead;
      } 

      public int[] getArrowHeadCrossLine(int x1, int x2, int b1, int b2, double 
factor) {
         int [] crossline = new int[4];

         int x_dest = (int) (((b1-x1)*factor)+x1);
         int y_dest = (int) (((b2-x2)*factor)+x2);

         crossline[0] = (int) ((x1+x2-y_dest));
         crossline[1] = (int) ((x2+x_dest-x1));
         crossline[2] = crossline[0]+(x1-crossline[0])*2;
         crossline[3] = crossline[1]+(x2-crossline[1])*2;
         return crossline;
      }
      /**** End of arrow code ***/

      public void setFreeze( boolean newFreeze ) {
         freeze = newFreeze;
         if( isFreeze() ) {
            freezeTime = System.currentTimeMillis();
            /**
             * Make a copy of the Vectors to be used while
             * freeze mode is on
             * */
            vctMotesClone = (Vector)vctMotes.clone();

            /**
             * We need to deep copy the vectors, otherwise
             * modifications to Motes in the original vector
             * will show up in the cloned vectors as well
             * */
            for( int i = 0; i < vctMotesClone.size(); i++ ) {
               Mote thisMote = (Mote)vctMotesClone.get( i );
               vctMotesClone.set( i, thisMote.clone() );
            }
            vctReadingClone = (Vector)vctReading.clone();
            displayMIRClone = (BitSet)displayMIR.clone();
         }
         else {
            freezeTime = 0;

            /**
             * Destroy copies of the Vectors
             * */
            vctMotesClone.removeAllElements();
            vctReadingClone.removeAllElements();
            displayMIRClone = null;
         }
			playbackStartTime = 0;
      }

      public boolean isFreeze() {
         return freeze;
      }

      /*
      public Vector getReadingClone() {
         return vctReadingClone;
      }

      public Vector getMotesClone() {
         return vctMotesClone;
      }
      */

      public long getFreezeTime() {
         return freezeTime;
      }

      public void setPlaybackTime( int playbackTime ) {
         playbackInterval = playbackTime;
      }
      public int getPlaybackTime() {
         return playbackInterval;
      }
      public void setPlaybackStartTime( long pbStartTime ) {
         playbackStartTime = pbStartTime;
      }
   }
} 

