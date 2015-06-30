/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

/**
 *
 * FILE NAME
 *
 *     MoteMessage.java
 *
 * DESCRIPTION
 *
 * The "MoteMessage" standard MBean expose attributes and  
 * operations for management by implementing its corresponding  
 * "MoteMessageMBean" management interface. This MBean has one
 * attribute and five operations exposed for management by a JMX
 * agent:
 *       - the read/write "message" attribute,
 *	   - the "printMoteMessage()",
 *       - the "start()",
 *       - the "stop()",
 *       - the "run()" operation.
 *
 * Author :  Mark E. Miyashita  -  Kent State Univerisity
 *
 * Modification history:
 *
 * 04/18/2003 Mark E. Miyashita - Created the intial interface
 * 05/03/2003 Mark E. Miyashita - Modified to use socket instead of file read
 *                                per OSU request
 * 06/08/2003 Mark E. Miyashita - Modified to read file input "Mote_list.dat" for
 *                                OSU demonstration of modified TargetProperty usage
 * 06/14/2003 Vinayak Naik - Modified to read from SerialForward. Dilated Routing version.
 * 06/18/2003 and ever since : Vinod Krishnan -Integrated new HLDL
 *
 */

// RI imports

import javax.management.*;

// java imports

import java.net.*;
import java.io.*;
import java.util.Calendar;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

// Serial Forward imports
import net.tinyos.util.*;
import net.tinyos.message.*;

public class MoteMessage extends NotificationBroadcasterSupport implements MoteMessageMBean,Runnable,MessageListener

{
 /*
  * ------------------------------------------
  *  CONSTRUCTORS
  * ------------------------------------------
  */

  public MoteMessage()
  {
    this.message = "MoteMessage Constructor Called";
  }

  public MoteMessage( String message )
  {
    this.message = message;
  }

 /*
  * -----------------------------------------------------
  * IMPLEMENTATION OF THE MoteMessageMBean INTERFACE
  * -----------------------------------------------------
  */

 /** 
  * Setter: set the "message" attribute of the "MoteMessage" MBean.
  *
  * @param <VAR>s</VAR> the new value of the "message" attribute.
  */

  public void setMoteDisplayMessage( String message )
  {
    this.message = message;
    Notification notification = new Notification( "setMoteDisplayMessage", this, -1, System.currentTimeMillis(), message );
    sendNotification( notification );
  }

 /**
  * Getter: set the "message" attribute of the "MoteMessage" MBean.
  *
  * @return the current value of the "message" attribute.
  */

  public String getMoteDisplayMessage()
  {
    return message;
  }

 /**
  * Operation: print the current values of "message" attributes of the 
  * "MoteMessage" MBean.
  */

  public void printMoteDisplayMessage()
  {
    System.out.println( message );
  }

  public void start()
  {
    try
    {
      stop = false;
      hldl_stop=false;
      if (!Exists) 
      {
	System.out.println("Making new thread");
	Thread t1 = new Thread( this, "hldl" );
	t1.start();
	Thread t2 = new Thread( this, "mir_hldl" );
	t2.start();
	Exists=true;
      }
    }
    catch( Exception e )
    {
      e.printStackTrace();
    }
  }
  
  public void stop()
  {
    stop = true;
    hldl_stop=true;
    System.out.println("Killing " + Thread.currentThread().getName());

    timer1.stop();

   timer2.stop();

 }

 /**
  * Operation: read the mote message through socket
  */
  public void run()
  {
   /**
    * Initialize networking stuff
    */
    System.out.println(Thread.currentThread().getName());
    if (((Thread.currentThread().getName()).equals("hldl")))
    {
    try {
		mote = new MoteIF("127.0.0.1", 9000, GROUP_ID);
		mote.registerListener(new UpdateMsg(), this);
		mote.registerListener(new ReportedMsg(),this);

		mote.start();
	} catch(Exception e){
		//e.printStackTrace();
		setMoteDisplayMessage("Couldn't create new Socket");
		System.exit(-1);
	}

	/* Hldl Stuff */

	System.out.println("Calling Hldl ");

	for (int i=0; i <= n_motes ; i++)
	{
           	for (int j=0; j <= num_intervals ; j++)
                    {
                        event_active[i][j] = 0;
                        moteupdate[i][j] = 0;
	  }

	}
	

        	Llinfo.storelocations(hldl_mote, n_motes, num_intervals);

	timer1 = new Timer(450, new ActionListener () { public void actionPerformed(ActionEvent evt) { hldl();}});

	timer1.start();
    }
    if (((Thread.currentThread().getName()).equals("mir_hldl")) && (process_mir_flag))
    {
	for (int i=0; i <= n_motes ; i++)
	{
           	for (int j=0; j <= num_intervals ; j++)
                    {
                        		mir_event_active[i][j]=0;
	     		mir_update[i][j]=0;

			mir_up[i]=false;
			mir_start_timer[i]=0;
                    }
	}

	//System.out.println("Calling MIR Hldl ");

	
	if (process_mir_flag) 
	{
		timer2 = new Timer(450, new ActionListener () { public void actionPerformed(ActionEvent evt) { mir_hldl();}});

		timer2.start();
	}
    }
    
  }

public void mir_hldl() 
{

   //System.out.println("MiR thread time is : " + System.currentTimeMillis()/1000);

  int num_mirs=0;

    
    for (int i=0; i<=n_motes; i++)
    {
    if (mir_up[i])
    {

	
	check_time_for_mir=System.currentTimeMillis();
	if ((check_time_for_mir - mir_start_timer[i]) > mir_timeout)
	{
		
	MIRProperty NewMIR = new MIRProperty(i, mir_x, mir_y, 1, 3);

	/* Create notification */  
           	Notification notification = new Notification( "readMirMessage", this, -1, System.currentTimeMillis(), "MIR Message read" );

               	/* Allow receiver of notification to access vector of mote object */
                 notification.setUserData( NewMIR );

        	/* Send Notification */
               	sendNotification( notification );
                    
                 System.out.println("I have sent MIR circle erase message");

	mir_up[i]=false;
	}

	if ((check_time_for_mir - mir_start_timer[i]) < mir_msg_interval)
	{

		num_mirs++;

	}
	
    }
    }

     if (num_mirs >= 3)
     {

	// Human detected. will plot at the center of the field
	if (mbit==0)
	{
	TargetProperty NewTarget = new TargetProperty(mir_ids, 150, 60, mir_curr_interval, 9, 0);

				// Send participating mote list

				for (int k=1;k<=n_motes;k++)
				{
				 if ((check_time_for_mir - mir_start_timer[k]) < mir_msg_interval)
				{
					NewTarget.addMoteList(k);
				}
				}

			
               
             		      //  Create notification 
           		      Notification notification = new Notification( "readTargetMessage", this, -1, System.currentTimeMillis(), "Target Message read" );

               		       // Allow receiver of notification to access vector of mote object 
                 		       notification.setUserData( NewTarget );

               		       // Send Notification 
               		       sendNotification( notification );
                    
                 		        System.out.println("I have sent MIR target");
	}

	if (mbit==1)
	{

		
		TargetProperty NewTarget2 = new TargetProperty(mir_ids, 150, 60, mir_curr_interval, 3, 0);

				// Send participating mote list

				for (int k=1;k<=n_motes;k++)
				{
				 if ((check_time_for_mir - mir_start_timer[k]) < mir_msg_interval)
				{
					NewTarget2.addMoteList(k);
				}
				}

			
               
             		      //  Create notification 
           		      Notification notification = new Notification( "readTargetMessage", this, -1, System.currentTimeMillis(), "Target Message read" );

               		       // Allow receiver of notification to access vector of mote object 
                 		       notification.setUserData( NewTarget2 );

               		       // Send Notification 
               		       sendNotification( notification );
                    
                 		        System.out.println("I have sent MIR target 2");
	}

	
	mbit = ((mbit+1) % 2);



		


      }
    







	// GOD PLEASE HELP!

   /*if ((mir_event_active_flag) && (process_mir_flag))
   {      

                int num_activemotes=0;
                int [] namotes=new int[3];
                
                int [] region_size = new int[3];

                int [] curr_target=new int[3];
	
                int [] curr_target_type = new int[3];
        
                int total_votes=0;
                int totalx=0;
                int totaly=0;
                int meanx=0;
                int meany=0;
                int [] mx=new int[3];
                int [] my=new int[3];
                int done=0;
                boolean outlier = false;
                boolean multiple=false;
                boolean noise=false;
            
                int outlier_count = 0;

                curr_target[1]=curr_target[2]=curr_target_type[1]=curr_target_type[2]=0;
         
                mx[1]=mx[2]=my[1]=my[2]=namotes[1]=namotes[2]=region_size[1]=region_size[2]=0;
            
      if (mir_waiting_to_fire) 
      {

	System.out.println("Inside MIR Hldl...First call for this event .. I think ! ");

	mir_waiting_to_fire=false;

	for (int i=0;i<=n_motes;i++)
		{
			timeout_mir[i]=30;
			
		}

	mir_ids++;
      }

      if (!mir_waiting_to_fire)
      {
        System.out.println("MIR Current Interval: " + mir_curr_interval);

       if ((mir_max_ts-mir_currproc_time)>mir_max_jitter+2*32768)
       {
	long difff = mir_max_ts-(mir_currproc_time+mir_max_jitter);
	
	long diff_ints = difff/(jiffies_per_interval);

	mir_curr_interval += (int)diff_ints;

	if (mir_curr_interval >= num_intervals) 
		mir_curr_interval -= num_intervals;
	
	mir_currproc_time=mir_max_ts - mir_max_jitter;
	System.out.println("Max ts is : " + mir_max_ts);
	System.out.println("Event seen in the future, have to catch up, so resetting current interval : " + mir_curr_interval);

       }

       // Initialization

        
        for (int i=0; i<nrows; i++)
        {
	xbucketcount[i]=0;
	for (int j=0; j<=ncols;j++)
	{
		xbucket[i][j]=0;
	}
        }

        for (int i=0; i<ncols; i++)
        {
	ybucketcount[i]=0;
	for (int j=0; j<=nrows;j++)
	{
		ybucket[i][j]=0;
	}
        }

	
       // Disruption zone and outlier detection

       int moterow=0;
       int motecol=0;
       int pp=0;
       int xbc,ybc;

        for (int i=0;i<=n_motes;i++)
        {
	  counted[i]=false;
	  if ((mir_event_active[i][mir_curr_interval]==1))  
	   {
			num_activemotes++;
			moterow = i%nrows;
			// System.out.println("For mote no. " + i + " Mote row is " +  moterow);
			xbucketcount[moterow]++;
			xbc=xbucketcount[moterow];
			// System.out.println("xbc is " +  xbc);
			xbucket[moterow][xbc]=i;
	   }
		
         }

         int startset=0;
         int endset=0;
         int maxstartset=0;
         int maxendset=0;
         int maxsofar=-1;

         int max2startset=0;
         int max2endset=0;
         int max2sofar=0;

	System.out.print("Row buckets : ");
	for (int i=0;i<nrows;i++)
         	{
		System.out.print(xbucketcount[i]);
	}
	System.out.println(" ");

         for (int i=2;i<nrows;i++)
         {
	if (xbucketcount[i-1]==0 && xbucketcount[i-2]==0 && xbucketcount[i]!=0)
	{

		// System.out.println(i + "Case 1 for x ");
		startset=i;
		endset=i;

		if (i==nrows-1)
		{
				endset=i;
				if ((endset-startset) > maxsofar)
				{
					max2sofar=maxsofar;
					max2startset=maxstartset;
					max2endset=maxendset;

					maxsofar=endset-startset;
					maxstartset=startset;
					maxendset=endset;
				}
				else
				if ((endset-startset) > max2sofar)
				{
					max2sofar=endset-startset;
					max2startset=startset;
					max2endset=endset;
				}

		}
	}

	if (xbucketcount[i-2]!=0 && xbucketcount[i-1]==0 && xbucketcount[i]==0)
	{
		endset=i-2;
		// System.out.println(i + "Case 2 for x ");
		if ((endset-startset) > maxsofar)
		{
			max2sofar=maxsofar;
			max2startset=maxstartset;
			max2endset=maxendset;

			maxsofar=endset-startset;
			maxstartset=startset;
			maxendset=endset;
		}
		else
		if ((endset-startset) > max2sofar)
		{
			max2sofar=endset-startset;
			max2startset=startset;
			max2endset=endset;
		}
	}
	if  ((xbucketcount[i-1]!=0) || (xbucketcount[i-2]!=0 && xbucketcount[i]!=0))
	{
		// System.out.println(i + "Case 3 for x ");
		if (i==nrows-1)
		{
				endset=i;
				if ((endset-startset) > maxsofar)
				{
					max2sofar=maxsofar;
					max2startset=maxstartset;
					max2endset=maxendset;

					maxsofar=endset-startset;
					maxstartset=startset;
					maxendset=endset;
				}
				else
				if ((endset-startset) > max2sofar)
				{
					max2sofar=endset-startset;
					max2startset=startset;
					max2endset=endset;
				}

		}
		
	}
          }

	System.out.println("Maxstartset " +  maxstartset + " Maxendset: " + maxendset);
	System.out.println("Max2startset " +  max2startset + " Max2endset: " + max2endset);

          for (int i=maxstartset; i<=maxendset; i++)
          {
		for (int j=1;j<=xbucketcount[i];j++)
		{
			pp=xbucket[i][j];
			
			motecol=pp/nrows;
			// System.out.println("For mote no. " + pp + " Mote col is " +  motecol);
			ybucketcount[motecol]++;
			ybc=ybucketcount[motecol];
			// System.out.println("ybc : " + ybc);
			ybucket[motecol][ybc]=pp;
		}
        }
        

         //int ystartset=0;
         //int yendset=0;
         int ymaxstartset=0;
         int ymaxendset=5;
         //int ymaxsofar=-1;

	System.out.print("Column buckets : ");
	for (int i=0;i<ncols;i++)
         	{
		System.out.print(ybucketcount[i]);
	}
	System.out.println(" ");

        for (int i=2;i<ncols;i++)
         {
	if (ybucketcount[i-1]==0 && ybucketcount[i-2]==0 && ybucketcount[i]!=0)
	{

		// System.out.println(i + " case 1 for y");
		ystartset=i;
		yendset=i;
		if (i==ncols-1)
		{
				yendset=i;
				if ((yendset-ystartset) > ymaxsofar)
				{
					ymaxsofar=yendset-ystartset;
					ymaxstartset=ystartset;
					ymaxendset=yendset;
				}
		}
	}

	if (ybucketcount[i-2]!=0 && ybucketcount[i-1]==0 && ybucketcount[i]==0)
	{
		yendset=i-2;
		// System.out.println(i + " case 2 for y");
		if ((yendset-ystartset) > ymaxsofar)
		{
			ymaxsofar=yendset-ystartset;
			ymaxstartset=ystartset;
			ymaxendset=yendset;
		}
	}
	if  ((ybucketcount[i-1]!=0) || (ybucketcount[i-2]!=0 && ybucketcount[i]!=0))
	{
		// System.out.println(i + " case 3 for y");
		if (i==ncols-1)
		{
				yendset=i;
				if ((yendset-ystartset) > ymaxsofar)
				{
					ymaxsofar=yendset-ystartset;
					ymaxstartset=ystartset;
					ymaxendset=yendset;
				}
		}
		
	}

          }	


	System.out.println("yMaxstartset " +  ymaxstartset + " yMaxendset: " + ymaxendset);

          int min_xregion=0;
          int min_yregion=0;
          int max_xregion=0;
          int max_yregion=0;

          System.out.print("Region 1 : ");
          for (int i=ymaxstartset; i<=ymaxendset; i++)
          {
		for (int j=1;j<=ybucketcount[i];j++)
		{
			pp=ybucket[i][j];
			System.out.print(pp + "  ");
			counted[pp]=true;
			namotes[1]++;
			if (max_xregion==0) max_xregion=hldl_mote[pp].getx();
			if (min_xregion==0) min_xregion=hldl_mote[pp].getx();
			if (max_yregion==0) max_yregion=hldl_mote[pp].gety();
			if (min_yregion==0) min_yregion=hldl_mote[pp].gety();
			if (hldl_mote[pp].getx() > max_xregion)
				max_xregion=hldl_mote[pp].getx();
			if (hldl_mote[pp].getx() < min_xregion)
				min_xregion=hldl_mote[pp].getx();
			if (hldl_mote[pp].gety() > max_yregion)
				max_yregion=hldl_mote[pp].gety();
			if (hldl_mote[pp].gety() < min_yregion)
				min_yregion=hldl_mote[pp].gety();

		}
         }
         System.out.println(" ");

          mx[1]=(min_xregion+max_xregion)/2;
          my[1]=(min_yregion+max_yregion)/2;

	  region_size[1]=(maxendset-maxstartset+1)*(ymaxendset-ymaxendset+1);

        System.out.println("In region 1, number of active motes is " + namotes[1]);
	System.out.println("x : " + mx[1] + "  y: " + my[1]);
	System.out.println("Region size: "+ region_size[1]);

         for (int i=0; i<ncols; i++)
         {
	ybucketcount[i]=0;
	for (int j=0; j<=nrows;j++)
	{
		ybucket[i][j]=0;
	}
         }


          if (max2startset!=maxstartset)
          {
          for (int i=max2startset; i<=max2endset; i++)
          {
		for (int j=1;j<=xbucketcount[i];j++)
		{
			pp=xbucket[i][j];
			motecol=pp/nrows;
			// System.out.println("For mote no. " + pp + " Mote col is " +  motecol);
			ybucketcount[motecol]++;
			ybc=ybucketcount[motecol];
			//System.out.println("ybc : " + ybc);
			ybucket[motecol][ybc]=pp;
		}
        }
        

        // ystartset=0;
        // yendset=0;
         ymaxstartset=0;
         ymaxendset=5;
        // ymaxsofar=-1;

         for (int i=2;i<ncols;i++)
         {
	if (ybucketcount[i-1]==0 && ybucketcount[i-2]==0 && ybucketcount[i]!=0)
	{
		ystartset=i;
		yendset=i;

		if (i==ncols-1)
		{
				yendset=i;
				if ((yendset-ystartset) > ymaxsofar)
				{
					ymaxsofar=yendset-ystartset;
					ymaxstartset=ystartset;
					ymaxendset=yendset;
				}
		}
	}

	if (ybucketcount[i-2]!=0 && ybucketcount[i-1]==0 && ybucketcount[i]==0)
	{
		yendset=i-2;
		if ((yendset-ystartset) > ymaxsofar)
		{
			ymaxsofar=yendset-ystartset;
			ymaxstartset=ystartset;
			ymaxendset=yendset;
		}
	}
	if  ((ybucketcount[i-1]!=0) || (ybucketcount[i-2]!=0 && ybucketcount[i]!=0))
	{
		if (i==ncols-1)
		{
				yendset=i;
				if ((yendset-ystartset) > ymaxsofar)
				{
					ymaxsofar=yendset-ystartset;
					ymaxstartset=ystartset;
					ymaxendset=yendset;
				}
		}
		
	}

          }	

          min_xregion=0;
          min_yregion=0;
          max_xregion=0;
          max_yregion=0;

          System.out.print("Region 2 : ");
          System.out.println("yMaxstartset " +  ymaxstartset + " yMaxendset: " + ymaxendset);
          for (int i=ymaxstartset; i<=ymaxendset; i++)
          {
		for (int j=1;j<=ybucketcount[i];j++)
		{
			pp=ybucket[i][j];
			System.out.print(pp + "  ");
			counted[pp]=true;
			namotes[2]++;
			if (max_xregion==0) max_xregion=hldl_mote[pp].getx();
			if (min_xregion==0) min_xregion=hldl_mote[pp].getx();
			if (max_yregion==0) max_yregion=hldl_mote[pp].gety();
			if (min_yregion==0) min_yregion=hldl_mote[pp].gety();
			if (hldl_mote[pp].getx() > max_xregion)
				max_xregion=hldl_mote[pp].getx();
			if (hldl_mote[pp].getx() < min_xregion)
				min_xregion=hldl_mote[pp].getx();
			if (hldl_mote[pp].gety() > max_yregion)
				max_yregion=hldl_mote[pp].gety();
			if (hldl_mote[pp].gety() < min_yregion)
				min_yregion=hldl_mote[pp].gety();

		}
         }

         System.out.println(" ");

          mx[2]=(min_xregion+max_xregion)/2;
          my[2]=(min_yregion+max_yregion)/2;

	  region_size[2]=(max2endset-max2startset+1)*(ymaxendset-ymaxendset+1);


        } // end if maxtsrtset neq max2startset

	
        System.out.println("In region 2, number of active mirs is " + namotes[2]);
	System.out.println("x : " + mx[2] + "  y: " + my[2]);
	System.out.println("Region size: "+region_size[2]);

        for (int i=0;i<=n_motes;i++)
        {
	  if ((mir_event_active[i][mir_curr_interval]==1))  
	   {
		if (!counted[i])
		{
			System.out.println("Mote " + i + "is an outlier");
			outlier_count++;
		}
	   }
          }

          // Adjust disruption zone if end received but no start... dont use this for tracking

	System.out.print("Start missed and end received for  ");
	for (int i=0;i<=n_motes;i++)
	{
		if (hldl_mote[i].get_quality_health() > 5)
	                 	{
                   		 if (mir_update[i][mir_curr_interval]==1)
		                   {
                             			
			     		if (mir_event_active[i][mir_curr_interval]==0) 
			     		{
					 mir_event_active[i][mir_curr_interval]=1;    // i missed the start
				 	  //hldl_mote[i].add_lost(1);
					
					
					int irow=i % nrows;

					System.out.print(" :  node " + i + "row  " + irow);
					if ((irow<=maxendset) && (irow>=maxstartset))  
						namotes[1]++;
					else
					if ((irow<=max2endset) && (irow>=max2startset))  
						namotes[2]++;
					
		                    	 	}
			}
		}
	}

	System.out.println();

	// output stage 1

      int num_objects=1;

      if (namotes[2] > mir_min_limit) num_objects=2;

      System.out.println("Number of objects: " +  num_objects);






      for (int obj=1; obj<=num_objects; obj++)
      {

       num_activemotes=namotes[obj];
       meanx=mx[obj];
       meany=my[obj];

       // Filter noise!

       if ( (num_activemotes<=mir_min_limit) && (num_activemotes>0))   
       {
	  System.out.print("False positive detected by:  ");
	  for (int i=0;i<=n_motes;i++)
	  if ((mir_event_active[i][mir_curr_interval]==1))  
          	{
	     //event_active[i][curr_interval]=0;
	     System.out.print(i + " ");
	  }
	  System.out.println(" ");
                     num_activemotes=0;
                     noise=true;
    
        }

         if (num_activemotes==0) 
                    {
                        meanx=0;
                        meany=0;
	      		noise=true;
                    }
	
            
         System.out.println("Number of outliers: " + outlier_count);            
         if (!noise) 
         {
		System.out.println("Number of motes shouting minus the outliers if any: " + num_activemotes);

		


				TargetProperty NewTarget = new TargetProperty(mir_ids, mx[obj], my[obj], mir_curr_interval, 9, 0);

				// Send participating mote list

				for (int i=1;i<=n_motes;i++)
				{
				if (mir_event_active[i][mir_curr_interval]==1)
				{
					NewTarget.addMoteList(i);
				}
				}

			
               
             		      //  Create notification 
           		         Notification notification = new Notification( "readTargetMessage", this, -1, System.currentTimeMillis(), "Target Message read" );

               		       // Allow receiver of notification to access vector of mote object 
                 		  notification.setUserData( NewTarget );

               		       // Send Notification 
               		          sendNotification( notification );
                    
                 		 System.out.println("I have sent MIR target");
                    


	 }

        } // for obj


	for (int i=0; i<=n_motes;i++)
	{
        		boolean reset_eventactive=false;
			if (timeout_mir[i]==0) reset_eventactive=true;

                           
	    
		        if ((mir_event_active[i][mir_curr_interval]==1) && (mir_update[i][mir_curr_interval]==0) && (!reset_eventactive))
			    {
				if (mir_curr_interval<num_intervals-1)
				{
				    mir_event_active[i][mir_curr_interval+1]=1;
				    timeout_mir[i]--;
				}
				else
				{
				    mir_event_active[i][0]=1;
				    timeout_mir[i]--;
			        }
			    }
	}






	for (int i=0;i<=n_motes;i++)
            {
                    mir_event_active[i][mir_curr_interval]=0; 
                    mir_update[i][mir_curr_interval]=0;
                
            }

                    mir_curr_interval++;
                    if (mir_curr_interval==num_intervals) mir_curr_interval=0;
	 mir_currproc_time+=jiffies_per_interval;
	
	
	if (((mir_currproc_time) >( mir_max_ts)))
	{
		mir_event_active_flag=false;

		for (int i=0;i<=n_motes;i++)
		for (int ss=0;ss<num_intervals;ss++)
            		{
              		       mir_event_active[i][ss]=0; 
        		       mir_update[i][ss]=0;
                
        		}
		

		

		System.out.println(" MIR Event Ended... System reset ");
		
	}


    } // waiting to fire 

}*/
   
} // end mir_hldl
			
	
	


  /* Hldl */

public void hldl() 
{

   System.out.println("Mag HLDL thread time is : " + System.currentTimeMillis()/1000);

   
    if ((event_active_flag))
   {      

                int num_activemotes=0;
                int [] namotes=new int[3];
                
                int [] region_size = new int[3];

                int [] curr_target=new int[3];
	
                int [] curr_target_type = new int[3];
        
                int total_votes=0;
                int totalx=0;
                int totaly=0;
                int meanx=0;
                int meany=0;
                int [] mx=new int[3];
                int [] my=new int[3];
                int done=0;
                boolean outlier = false;
                boolean multiple=false;
                boolean noise=false;
            
                int outlier_count = 0;

                curr_target[1]=curr_target[2]=curr_target_type[1]=curr_target_type[2]=0;
         
                mx[1]=mx[2]=my[1]=my[2]=namotes[1]=namotes[2]=region_size[1]=region_size[2]=0;
            
      if (waiting_to_fire) 
      {

	System.out.println("Inside Hldl...First call for this event .. I think ! ");

	waiting_to_fire=false;

	for (int i=0;i<=n_motes;i++)
		{
			timeout_mote[i]=max_timeout;
			timeout_upgraded_to_car[i]=false;
		}
      }

      if (!waiting_to_fire)
      {
        System.out.println("Current Interval: " + curr_interval);

       if ((max_ts-currproc_time)>max_jitter+2*32768)
       {
	long difff = max_ts-(currproc_time+max_jitter);
	
	long diff_ints = difff/(jiffies_per_interval);

	curr_interval += (int)diff_ints;

	if (curr_interval >= num_intervals) 
		curr_interval -= num_intervals;
	
	currproc_time=max_ts - max_jitter;
	System.out.println("Max ts is : " + max_ts);
	System.out.println("Event seen in the future, have to catch up, so resetting current interval : " + curr_interval);

       }

       // Initialization

        for (int j=1;j<=num_types;j++)
        {
            stage1_op_prob[j]=0;
            stage2_op_prob[j]=0;
            type_votes[j]=0;
        }

        for (int i=0; i<nrows; i++)
        {
	xbucketcount[i]=0;
	for (int j=0; j<=ncols;j++)
	{
		xbucket[i][j]=0;
	}
        }

        for (int i=0; i<ncols; i++)
        {
	ybucketcount[i]=0;
	for (int j=0; j<=nrows;j++)
	{
		ybucket[i][j]=0;
	}
        }

	
       // Disruption zone and outlier detection

       int moterow=0;
       int motecol=0;
       int pp=0;
       int xbc,ybc;

        for (int i=0;i<=n_motes;i++)
        {
	  counted[i]=false;
	  if ((event_active[i][curr_interval]==1))  
	   {
			num_activemotes++;
			moterow = i%nrows;
			// System.out.println("For mote no. " + i + " Mote row is " +  moterow);
			xbucketcount[moterow]++;
			xbc=xbucketcount[moterow];
			// System.out.println("xbc is " +  xbc);
			xbucket[moterow][xbc]=i;
	   }
		
         }

         int startset=0;
         int endset=0;
         int maxstartset=0;
         int maxendset=0;
         int maxsofar=-1;

         int max2startset=0;
         int max2endset=0;
         int max2sofar=0;

	System.out.print("Row buckets : ");
	for (int i=0;i<nrows;i++)
         	{
		System.out.print(xbucketcount[i]);
	}
	System.out.println(" ");

         for (int i=2;i<nrows;i++)
         {
	if (xbucketcount[i-1]==0 && xbucketcount[i-2]==0 && xbucketcount[i]!=0)
	{

		// System.out.println(i + "Case 1 for x ");
		startset=i;
		endset=i;

		if (i==nrows-1)
		{
				endset=i;
				if ((endset-startset) > maxsofar)
				{
					max2sofar=maxsofar;
					max2startset=maxstartset;
					max2endset=maxendset;

					maxsofar=endset-startset;
					maxstartset=startset;
					maxendset=endset;
				}
				else
				if ((endset-startset) > max2sofar)
				{
					max2sofar=endset-startset;
					max2startset=startset;
					max2endset=endset;
				}

		}
	}

	if (xbucketcount[i-2]!=0 && xbucketcount[i-1]==0 && xbucketcount[i]==0)
	{
		endset=i-2;
		// System.out.println(i + "Case 2 for x ");
		if ((endset-startset) > maxsofar)
		{
			max2sofar=maxsofar;
			max2startset=maxstartset;
			max2endset=maxendset;

			maxsofar=endset-startset;
			maxstartset=startset;
			maxendset=endset;
		}
		else
		if ((endset-startset) > max2sofar)
		{
			max2sofar=endset-startset;
			max2startset=startset;
			max2endset=endset;
		}
	}
	if  ((xbucketcount[i-1]!=0) || (xbucketcount[i-2]!=0 && xbucketcount[i]!=0))
	{
		// System.out.println(i + "Case 3 for x ");
		if (i==nrows-1)
		{
				endset=i;
				if ((endset-startset) > maxsofar)
				{
					max2sofar=maxsofar;
					max2startset=maxstartset;
					max2endset=maxendset;

					maxsofar=endset-startset;
					maxstartset=startset;
					maxendset=endset;
				}
				else
				if ((endset-startset) > max2sofar)
				{
					max2sofar=endset-startset;
					max2startset=startset;
					max2endset=endset;
				}

		}
		
	}
          }

	System.out.println("Maxstartset " +  maxstartset + " Maxendset: " + maxendset);
	System.out.println("Max2startset " +  max2startset + " Max2endset: " + max2endset);

          for (int i=maxstartset; i<=maxendset; i++)
          {
		for (int j=1;j<=xbucketcount[i];j++)
		{
			pp=xbucket[i][j];
			
			motecol=pp/nrows;
			// System.out.println("For mote no. " + pp + " Mote col is " +  motecol);
			ybucketcount[motecol]++;
			ybc=ybucketcount[motecol];
			// System.out.println("ybc : " + ybc);
			ybucket[motecol][ybc]=pp;
		}
        }
        

         int ystartset=0;
         int yendset=0;
         int ymaxstartset=0;
         int ymaxendset=0;
         int ymaxsofar=-1;

	System.out.print("Column buckets : ");
	for (int i=0;i<ncols;i++)
         	{
		System.out.print(ybucketcount[i]);
	}
	System.out.println(" ");

         for (int i=2;i<ncols;i++)
         {
	if (ybucketcount[i-1]==0 && ybucketcount[i-2]==0 && ybucketcount[i]!=0)
	{

		// System.out.println(i + " case 1 for y");
		ystartset=i;
		yendset=i;
		if (i==ncols-1)
		{
				yendset=i;
				if ((yendset-ystartset) > ymaxsofar)
				{
					ymaxsofar=yendset-ystartset;
					ymaxstartset=ystartset;
					ymaxendset=yendset;
				}
		}
	}

	if (ybucketcount[i-2]!=0 && ybucketcount[i-1]==0 && ybucketcount[i]==0)
	{
		yendset=i-2;
		// System.out.println(i + " case 2 for y");
		if ((yendset-ystartset) > ymaxsofar)
		{
			ymaxsofar=yendset-ystartset;
			ymaxstartset=ystartset;
			ymaxendset=yendset;
		}
	}
	if  ((ybucketcount[i-1]!=0) || (ybucketcount[i-2]!=0 && ybucketcount[i]!=0))
	{
		// System.out.println(i + " case 3 for y");
		if (i==ncols-1)
		{
				yendset=i;
				if ((yendset-ystartset) > ymaxsofar)
				{
					ymaxsofar=yendset-ystartset;
					ymaxstartset=ystartset;
					ymaxendset=yendset;
				}
		}
		
	}

          }	
	System.out.println("yMaxstartset " +  ymaxstartset + " yMaxendset: " + ymaxendset);

          int min_xregion=0;
          int min_yregion=0;
          int max_xregion=0;
          int max_yregion=0;

          System.out.print("Region 1 : ");
          for (int i=ymaxstartset; i<=ymaxendset; i++)
          {
		for (int j=1;j<=ybucketcount[i];j++)
		{
			pp=ybucket[i][j];
			System.out.print(pp + "  ");
			counted[pp]=true;
			namotes[1]++;
			if (max_xregion==0) max_xregion=hldl_mote[pp].getx();
			if (min_xregion==0) min_xregion=hldl_mote[pp].getx();
			if (max_yregion==0) max_yregion=hldl_mote[pp].gety();
			if (min_yregion==0) min_yregion=hldl_mote[pp].gety();
			if (hldl_mote[pp].getx() > max_xregion)
				max_xregion=hldl_mote[pp].getx();
			if (hldl_mote[pp].getx() < min_xregion)
				min_xregion=hldl_mote[pp].getx();
			if (hldl_mote[pp].gety() > max_yregion)
				max_yregion=hldl_mote[pp].gety();
			if (hldl_mote[pp].gety() < min_yregion)
				min_yregion=hldl_mote[pp].gety();

		}
         }
         System.out.println(" ");

          mx[1]=(min_xregion+max_xregion)/2;
          my[1]=(min_yregion+max_yregion)/2;

	  region_size[1]=(maxendset-maxstartset+1)*(ymaxendset-ymaxendset+1);

        System.out.println("In region 1, number of active motes is " + namotes[1]);
	System.out.println("x : " + mx[1] + "  y: " + my[1]);
	System.out.println("Region size: "+ region_size[1]);

         for (int i=0; i<ncols; i++)
         {
	ybucketcount[i]=0;
	for (int j=0; j<=nrows;j++)
	{
		ybucket[i][j]=0;
	}
         }


          if (max2startset!=maxstartset)
          {
          for (int i=max2startset; i<=max2endset; i++)
          {
		for (int j=1;j<=xbucketcount[i];j++)
		{
			pp=xbucket[i][j];
			motecol=pp/nrows;
			// System.out.println("For mote no. " + pp + " Mote col is " +  motecol);
			ybucketcount[motecol]++;
			ybc=ybucketcount[motecol];
			//System.out.println("ybc : " + ybc);
			ybucket[motecol][ybc]=pp;
		}
        }
        

         ystartset=0;
         yendset=0;
         ymaxstartset=0;
         ymaxendset=0;
         ymaxsofar=-1;

         for (int i=2;i<ncols;i++)
         {
	if (ybucketcount[i-1]==0 && ybucketcount[i-2]==0 && ybucketcount[i]!=0)
	{
		ystartset=i;
		yendset=i;

		if (i==ncols-1)
		{
				yendset=i;
				if ((yendset-ystartset) > ymaxsofar)
				{
					ymaxsofar=yendset-ystartset;
					ymaxstartset=ystartset;
					ymaxendset=yendset;
				}
		}
	}

	if (ybucketcount[i-2]!=0 && ybucketcount[i-1]==0 && ybucketcount[i]==0)
	{
		yendset=i-2;
		if ((yendset-ystartset) > ymaxsofar)
		{
			ymaxsofar=yendset-ystartset;
			ymaxstartset=ystartset;
			ymaxendset=yendset;
		}
	}
	if  ((ybucketcount[i-1]!=0) || (ybucketcount[i-2]!=0 && ybucketcount[i]!=0))
	{
		if (i==ncols-1)
		{
				yendset=i;
				if ((yendset-ystartset) > ymaxsofar)
				{
					ymaxsofar=yendset-ystartset;
					ymaxstartset=ystartset;
					ymaxendset=yendset;
				}
		}
		
	}

          }	

          min_xregion=0;
          min_yregion=0;
          max_xregion=0;
          max_yregion=0;

          System.out.print("Region 2 : ");
          System.out.println("yMaxstartset " +  ymaxstartset + " yMaxendset: " + ymaxendset);
          for (int i=ymaxstartset; i<=ymaxendset; i++)
          {
		for (int j=1;j<=ybucketcount[i];j++)
		{
			pp=ybucket[i][j];
			System.out.print(pp + "  ");
			counted[pp]=true;
			namotes[2]++;
			if (max_xregion==0) max_xregion=hldl_mote[pp].getx();
			if (min_xregion==0) min_xregion=hldl_mote[pp].getx();
			if (max_yregion==0) max_yregion=hldl_mote[pp].gety();
			if (min_yregion==0) min_yregion=hldl_mote[pp].gety();
			if (hldl_mote[pp].getx() > max_xregion)
				max_xregion=hldl_mote[pp].getx();
			if (hldl_mote[pp].getx() < min_xregion)
				min_xregion=hldl_mote[pp].getx();
			if (hldl_mote[pp].gety() > max_yregion)
				max_yregion=hldl_mote[pp].gety();
			if (hldl_mote[pp].gety() < min_yregion)
				min_yregion=hldl_mote[pp].gety();

		}
         }

         System.out.println(" ");

          mx[2]=(min_xregion+max_xregion)/2;
          my[2]=(min_yregion+max_yregion)/2;

	  region_size[2]=(max2endset-max2startset+1)*(ymaxendset-ymaxendset+1);


        } // end if maxtsrtset neq max2startset

	
        System.out.println("In region 2, number of active motes is " + namotes[2]);
	System.out.println("x : " + mx[2] + "  y: " + my[2]);
	System.out.println("Region size: "+region_size[2]);

        for (int i=0;i<=n_motes;i++)
        {
	  if ((event_active[i][curr_interval]==1))  
	   {
		if (!counted[i])
		{
			System.out.println("Mote " + i + "is an outlier");
			outlier_count++;
		}
	   }
          }

          // Adjust disruption zone if end received but no start... dont use this for tracking

	System.out.print("Start missed and end received for  ");
	for (int i=0;i<=n_motes;i++)
	{
		if (hldl_mote[i].get_quality_health() > 5)
	                 	{
                   		 if (moteupdate[i][curr_interval]==1)
		                   {
                             			end_included=true;
			     		if (event_active[i][curr_interval]==0) 
			     		{
					 event_active[i][curr_interval]=1;    // i missed the start
				 	  //hldl_mote[i].add_lost(1);
					
					
					int irow=i % nrows;

					System.out.print(" :  node " + i + "row  " + irow);
					if ((irow<=maxendset) && (irow>=maxstartset))  
						namotes[1]++;
					else
					if ((irow<=max2endset) && (irow>=max2startset))  
						namotes[2]++;
					
		                    	 	}
			}
		}
	}

	System.out.println();

	// output stage 1

      int num_objects=1;

      if (namotes[2] > min_limit) num_objects=2;

      System.out.println("Number of objects: " +  num_objects);

      // Processing for at most 2 intruders at a time. Both should be soldiers.

      for (int obj=1; obj<=num_objects; obj++)
      {

       num_activemotes=namotes[obj];
       meanx=mx[obj];
       meany=my[obj];

       if  ((num_activemotes<=min_limit)) {stage1_op_prob[0]=1; stage1_optype=0;}
       else if (num_activemotes<=type1_limit) {stage1_op_prob[1]=1.0; stage1_optype=1;}
       else if (num_activemotes<=type2_limit) {stage1_op_prob[2]=1.0; stage1_optype=2;}
       else {stage1_op_prob[3]=1.0; stage1_optype=3;}

        // Filter noise!

       if ( (num_activemotes<=min_limit) && (num_activemotes>0))   
       {
	  System.out.print("False positive detected by:  ");
	  for (int i=0;i<=n_motes;i++)
	  if ((event_active[i][curr_interval]==1))  
          	{
	     //event_active[i][curr_interval]=0;
	     System.out.print(i + " ");
	  }
	  System.out.println(" ");
                     num_activemotes=0;
                     noise=true;
    
        }

         if (num_activemotes==0) 
                    {
                        meanx=0;
                        meany=0;
	      noise=true;
                    }
	
            
         System.out.println("Number of outliers: " + outlier_count);            
         if (!noise) 
         {
		System.out.println("Number of motes shouting minus the outliers if any: " + num_activemotes);

		magactive=true;

		
		process_mir_flag = false;

	}

                      
                                  
                    // Finding the majority

                    int max_type=0;
                    int max_prob=0;
                    stage2_op_prob[max_prob]=0;
            
            
                    for (int j=1;j<=num_types;j++)
                    {
                                if ((stage1_optype==max_type) || (total_votes==0)) stage2_op_prob[j]=stage1_op_prob[j];
                                else stage2_op_prob[j]=((double) type_votes[j])/total_votes;
                
                                if (stage2_op_prob[j]>stage2_op_prob[max_prob]) max_prob=j;
                    }
            
                    System.out.println("optype: " + max_prob);
	  System.out.println("meanx : " + meanx + "  y: " + meany);
            
            

                    // History based Corrector

	done=0;
            
                    if (num_targets>0)
                    {

                        for (int k=1;k<=num_targets;k++)
                        {
                                if ((max_prob==target[k].expected_type()) && (meanx < target[k].max_x()) && (meanx > target[k].min_x()) && (meany < target[k].max_y()) && (meany > target[k].min_y()) && (target[k].active()!=0))
                    
                                {
                                    // All is well, we found a perfect match
                                    System.out.println("All is well, we found a perfect match");
                                    target[k].set_type(max_prob);
                                    if (end_included || target[k].confidence()==2) target[k].set_confidence(2);
                                        else target[k].set_confidence(1);
                                    target[k].inc_num_correct_pred();
				    target[k].inc_iteration();
                                    target[k].setx(meanx);
                                    target[k].sety(meany);
                                    done=1;
                                    curr_target[obj]=k;
				curr_target_type[obj]=max_prob;
                                       break;
                                }
                        }


	     if (done==0)
                        {

                                for (int k=1;k<=num_targets;k++)
                                {
                                    if ((meanx < target[k].max_x()) && (meanx > target[k].min_x()) && (meany < target[k].max_y()) && (meany > target[k].min_y()) && (target[k].active()!=0)  && (max_prob!=0) && (max_prob<target[k].expected_type()))

					{

							target[k].set_type(target[k].expected_type());
                                                        target[k].set_confidence(1);
                                                        target[k].inc_num_correct_pred();
							target[k].inc_iteration();
                                                        target[k].setx(meanx);
                                                        target[k].sety(meany);
                                                        System.out.println("Has been a stronger one for long enough");
                                                        done=1;
                                                        curr_target[obj]=k;
			curr_target_type[obj]=target[k].expected_type();
                                                        break;
                                        }
	               		}
                        }
		

                        if (done==0)
                        {

                                for (int k=1;k<=num_targets;k++)
                                {
                                    if ((meanx < target[k].max_x()) && (meanx > target[k].min_x()) && (meany < target[k].max_y()) && (meany > target[k].min_y()) && (target[k].active()!=0)  && (max_prob!=0))

                                    {

                                            for (int j=1;j<=num_types;j++)
                                            {   

                                                if (stage2_op_prob[j]!=0 && j==target[k].expected_type())
                                                {
                                    
                                                        target[k].set_type(j);
                                                        target[k].set_confidence(1);
                                                        target[k].inc_num_correct_pred();
							target[k].inc_iteration();
                                                        target[k].setx(meanx);
                                                        target[k].sety(meany);
                                                        System.out.println("Minority type matches with history..so history");
                                                        done=1;
                                                        curr_target[obj]=k;
			curr_target_type[obj]=j;
                                                        break;
                                                }
                                            }

                                    }

                                }

                        }

                        if (done==0)

                        {

                                for (int k=1;k<=num_targets;k++)
                                {
                                    if ((meanx < target[k].max_x()) && (meanx > target[k].min_x()) && (meany < target[k].max_y()) && (meany > target[k].min_y()) && (target[k].active()!=0) && (max_prob!=0))

                                    {

                                            // Curr confidence high

                                            if (stage2_op_prob[max_prob]>0.75)
                            
                                            {
                                                System.out.println("No types match but curr_confidence is high");
                                                target[k].set_type(max_prob);
		          			target[k].inc_iteration();
                                                if (end_included) target[k].set_confidence(2);
                                                else target[k].set_confidence(0);
                                                target[k].setx(meanx);
                                                target[k].sety(meany);
                                                done=1;
                                                curr_target[obj]=k;
		           curr_target_type[obj]=max_prob;
                                                break;

                                            }

                                            else

                                            {
                                                System.out.println("No types match but history is strong");
                                                target[k].set_type(target[k].expected_type());
		           			target[k].inc_iteration();
                                                target[k].set_confidence(0);
                                                target[k].setx(meanx);
                                                target[k].sety(meany);
                                                done=1;
                                                curr_target[obj]=k;
		           curr_target_type[obj]=target[k].expected_type();
                                                break;
                                            }

                                    } // end-if

                                } // end-for

                        } // end if-done==0

                        if (done==0)

                        {

                                // Have to believe that this is a new intruder
                                if ((num_activemotes!=0)&&(max_prob!=0)&&(meanx!=0))
                                {
                                    num_targets++; 
                                    if (num_targets>max_targets) num_targets=1;

                                    target[num_targets]= new Targetinfo(max_prob,meanx,meany);

				    target[num_targets].inc_iteration();
                        
                                    System.out.println("New intruder detected: iteration no. is : " + target[num_targets].get_iteration());
                        
                                    curr_target[obj]=num_targets;

		curr_target_type[obj]=max_prob;
                        
                                    done=1;
                                }
                        }

                    } // end if num_targets>0

                    else

                    {
                        if (((num_activemotes!=0)&&(max_prob!=0)&&(meanx!=0)))
                        {
                                num_targets++;
                        	if (num_targets>max_targets) num_targets=1;

                                target[num_targets]= new Targetinfo(max_prob,meanx,meany);

	              		target[num_targets].inc_iteration();

				System.out.println("New intruder detected: iteration no. is : " + target[num_targets].get_iteration());
                                // target[num_targets].display();
                
                                curr_target[obj]=num_targets;

	             curr_target_type[obj]=max_prob;
                
                                done=1;
                    
                        }

                    }

	} // end-for 1 to num_objects

	
	 // If current object is a car which is abt to leave network, dont track as it is likely to jump around.

	 if (((curr_target_type[1]==2) || (curr_target_type[2]==2)) && ((namotes[1]<9) && (namotes[2]<9)) && ok_to_refresh_display)
	{
		ok_to_refresh_display=false;
		int_when_refresh_stopped = curr_interval;
		System.out.println("Refresh display has stopped for this event");
		if (curr_interval>=(num_intervals-10))
			int_when_refresh_stopped=int_when_refresh_stopped-num_intervals;
	}

	prev_namotes[1]=namotes[1];
	prev_namotes[2]=namotes[2];


	 for (int i=0;i<=n_motes;i++)
          	{
		if ((timeout_upgraded_to_car[i]==false) && ((curr_target_type[1]==2) || (curr_target_type[2]==2)))
		{
			timeout_mote[i]+=timeout_car_plus;
			timeout_upgraded_to_car[i]=true;
		}
	  }
                    
	// health issues

                    for (int i=0;i<=n_motes;i++)
                    {


			if (hldl_mote[i].getx()!=-1)
			{

				int lost_so_far = hldl_mote[i].get_lost();

				try {
                					BufferedWriter out = new BufferedWriter(new FileWriter(fname1, true));
                					String s=""+i+","+lost_so_far+"\n";
                    					out.write(s);
                        				out.close();
                    		     } 
				catch (IOException e) {
                    			}


			}





			boolean reset_eventactive=false;
			if (timeout_mote[i]==0) reset_eventactive=true;

                           
	    
		                        if ((event_active[i][curr_interval]==1) && (moteupdate[i][curr_interval]==0) && (!reset_eventactive))
			    {
				if (curr_interval<num_intervals-1)
				{
				    event_active[i][curr_interval+1]=1;
				    timeout_mote[i]--;
				}
				else
				{
				    event_active[i][0]=1;
				    timeout_mote[i]--;
			                   }
			    }
                
                    } //end health issues
                

            		// display-related

                    for (int k=1;k<=num_targets;k++)

                    {

                  	if ((k!=curr_target[1]) && (k!=curr_target[2]))
              		       			target[k].set_confidence(0);
                    
              	        if (target[k].confidence()==0) 
                		target[k].inc_low_count();
			else
		   		target[k].set_low_count(0);

            		if ((target[k].low_count()>6)&&(!multiple))     // consecutive low confidence and u r out!
             		       target[k].deactivate();

             		if (target[k].active()!=0)
             		      target[k].calculate_expected_type(avg_xdist_motes);

			// Reduce frequency of display to reduce jittery movement

			if (target[k].active()!=0) 
			{

				if ((target[k].get_displaybit()==0) && (ok_to_refresh_display)) ok_to_display=true;
				else ok_to_display=false;

				int dbit = ((target[k].get_displaybit() + 1) % (target[k].gettype()*2));

				target[k].set_displaybit(dbit);

				// At the instant u stop refresh display, just display for one last time
				
				/*if ((int_when_refresh_stopped==curr_interval) && (ok_to_refresh_display==false) && ((namotes[1]>=7) || (namotes[2]>=7)))
				{
					ok_to_display=true;
				}*/


			}

		        if ((target[k].active()!=0) && (target[k].get_iteration()>=1) && ok_to_refresh_display && ok_to_display)
        		{
        		        target[k].display();
     				System.out.println("I am in target display part");
           		        int targetId = k;
               			int type = target[k].gettype();
	                        int targetX = target[k].getx()-xoffset;
              			int targetY = target[k].gety()-yoffset;
            		        int targetSpeed = type*5 ;
               			TargetProperty NewTarget = new TargetProperty(targetId, targetX, targetY, curr_interval, type, targetSpeed);

				// Send participating mote list

				for (int i=1;i<=n_motes;i++)
				{
				if (event_active[i][curr_interval]==1)
				{
					NewTarget.addMoteList(i);
				}
				}

			
               
             		       /* Create notification */  
           		         Notification notification = new Notification( "readTargetMessage", this, -1, System.currentTimeMillis(), "Target Message read" );

               		       /* Allow receiver of notification to access vector of mote object */
                 		  notification.setUserData( NewTarget );

               		       /* Send Notification */
               		          sendNotification( notification );
                    
                 		 System.out.println("I have sent");
                    

	       	 	 }  // end-if
            
                    } // end-display related
                       
                    System.out.println(" ");  //space between intervals
                    end_included=false;
                    if (multiple) last_multiple=curr_interval;

                            
            // I clear the entries in the current interval and keep it ready for filling in the next round
            
            for (int i=0;i<=n_motes;i++)
            {
                    event_active[i][curr_interval]=0; 
                    moteupdate[i][curr_interval]=0;
                
            }

                    curr_interval++;
                    if (curr_interval==num_intervals) curr_interval=0;
	 currproc_time+=jiffies_per_interval;
	
	int time_check = (int)((max_ts/jiffies_per_second))%(num_intervals);
	if (((currproc_time) >( max_ts + late_message_time)) || ((ok_to_refresh_display==false) && ((curr_interval-int_when_refresh_stopped) > 10)) || (inactive > 25))
	{
		event_active_flag=false;

		for (int i=0;i<=n_motes;i++)
		for (int ss=0;ss<num_intervals;ss++)
            		{
              		       event_active[i][ss]=0; 
        		       moteupdate[i][ss]=0;
                
        		}
		

		for (int k=1;k<=num_targets;k++)
		{
			target[k].deactivate();
		}

		System.out.println(" Magnetometer Event Ended... System reset ");
		if ((ok_to_refresh_display==false) && ((int_when_refresh_stopped - curr_interval) > 10)) 
			System.out.println(" Refresh has stopped 10 intervals ago ");
		if (inactive>5)
			System.out.println(" Has been inactive for 6 intervals");
		process_mir_flag=true;
		ok_to_refresh_display=true;
		magactive=false;
		inactive=0;
	}
            
                    multiple=false;
            
            

                end_timer=System.currentTimeMillis();
                if (start_timer!=0) sleeptime=maxsleeptime-(end_timer-start_timer);
                if (sleeptime<minsleeptime) sleeptime=(maxsleeptime+minsleeptime)/2;
          

          

              
            start_timer=System.currentTimeMillis();
            
            } // end-if  !waiting_to_fire

        
        } // end-if eventactiveflag

        else

        {

	

         }
        

    } // end hldl()












  public void messageReceived(int dest_addr, Message msg) {
		if (msg instanceof UpdateMsg) {
			updateReceived(dest_addr, (UpdateMsg)msg);

			System.out.println("Update Message received " );
		} 
		else 
		{
			if(msg instanceof ReportedMsg)	{
				System.out.println("Report Message received " );
				reportedReceived(dest_addr,(ReportedMsg)msg);
			}
			else				
				throw new RuntimeException("messageReceived: Got bad message type: "+msg);
		}
	}
	
  public void reportedReceived(int dest_addr, ReportedMsg rmsg)	{
		
		int id;
		int count;
		long time,time1,time2;
		int type;

		int qsize;
		int qid;

		id = rmsg.get_src();
		count = rmsg.get_count();
		time1 = rmsg.get_time1();
		time2 = rmsg.get_time2();
		if (time1==time2)
			time=time1;
		else
			time=0;
		type = rmsg.get_type();
		
				// Motes from second partition

		if ((type>=10) && (type<=11))
		{
			id = 77-id;
			type=type-10;
		}
else
		if ((type>=12) && (type<=13))
		{
			id=id-100;
			id = 77-id;
			type=type-10;
		}
else
		if ((type>=2) && (type<=3))
		{
			id=id-100;
		}

		System.out.println("Message received from mote no. " + id + "count " + count + "type " + type);

		if (time>all_time_max_ts)
			all_time_max_ts=time;



		
           if (first_time)
                 {

	
	Calendar rightnow = Calendar.getInstance();
	int day = rightnow.get(Calendar.DATE);
	int hour = rightnow.get(Calendar.HOUR);
	int minute = rightnow.get(Calendar.MINUTE);

	fname1 = "lostinfo_" + day + "_" + hour + "_" + minute + ".txt" ;
	fname2 = "data_" + day + "_" + hour + "_" + minute + ".txt" ;
                	
	try {
                	BufferedWriter out2 = new BufferedWriter(new FileWriter(fname1));
                
                        out2.close();
                    } catch (IOException e) {
                    }

	 try {
                	 BufferedWriter out2 = new BufferedWriter(new FileWriter(fname2));
                
                        out2.close();
                    } catch (IOException e) {
                    }

	first_time=false;

                 }  

           try {
                		BufferedWriter out = new BufferedWriter(new FileWriter(fname2, true));
                		String s=""+id+","+count+","+time+","+type+"\n";
                    	out.write(s);
                        	out.close();
                    	} catch (IOException e) {
                    }


           if ((id>=0) && (id<=n_motes))
           {
           if ((id<=n_motes) && (time>hldl_mote[id].get_ts()) && ((type==2) || (type==3)) && process_mir_flag && (time1==time2))
           {
		// MIR Processing

		mircount++;

		mir_up[id]=true;

		mir_start_timer[id]=System.currentTimeMillis();

		mir_x=hldl_mote[id].getx();

		mir_y=hldl_mote[id].gety();

		MIRProperty NewMIR = new MIRProperty(id, mir_x, mir_y, type-2, 5);

		/* Create notification */  
           	Notification notification = new Notification( "readMirMessage", this, -1, System.currentTimeMillis(), "MIR Message read" );

                /* Allow receiver of notification to access vector of mote object */
                notification.setUserData( NewMIR );

        	/* Send Notification */
               	sendNotification( notification );
                    
                 System.out.println("I have sent MIR circle message");


	/*if ((!mir_event_active_flag) && (type==2))
                 	{
		
		
		mir_proc_interval=(int)((time/jiffies_per_interval)%(num_intervals));

		// System.out.println(" at " + proc_interval);
		
		System.out.println(" at " + mir_proc_interval + "  i.e. : actual ts " + time/16384 );

		//System.out.println(" Type inside is : " + type);

		mir_min_ts = time;

		mir_max_ts = time;

		mir_eventstart_timer=System.currentTimeMillis();

		mir_eventstart_timer/=1000;

		System.out.println("First Magnetometer message has been received for this event at " + mir_eventstart_timer);

		
		mir_currproc_time=time-mir_max_delay*32768;

		mir_curr_interval=mir_proc_interval-(mir_max_delay*2);

		if (mir_curr_interval < 0)
			mir_curr_interval = num_intervals + mir_curr_interval;

		mir_event_active_flag=true;

		mir_waiting_to_fire=true;
			
	}

                 if (mir_event_active_flag)
	{

		mir_proc_interval=(int)((time/jiffies_per_interval)%(num_intervals));

		System.out.println(" at " + mir_proc_interval + "  i.e. : actual ts " + time/16384 );

		if (mir_min_ts>time)
		
		{

			mir_min_ts=time;

		}

		if (mir_max_ts<time)

		{
	
			mir_max_ts=time;

		}

				
	}

	if ((type==2) && (time>hldl_mote[id].get_ts())) 	// Start Message .. ignore out of order old messages
                  {
              	    mir_event_active[id][mir_proc_interval]=1;
	    hldl_mote[id].set_ts(time);
	    timeout_mir[id]=30;
		   
                   
            	}


             	if ((type==3) && (time>hldl_mote[id].get_ts()) && mir_event_active_flag)  // End Message
            	{
                		mir_update[id][mir_proc_interval]=1;
		hldl_mote[id].set_ts(time);

	}*/

	
           }
           
           if ((id <= n_motes) && ((type==0) || (type==1)) && (time>hldl_mote[id].get_ts()) && (time1==time2)) 
           {    
                       
	
		// only start messages can set an event to active, not old end messages.

                 if ((!event_active_flag) && (type==0))
                  {
		
		
		proc_interval=(int)((time/jiffies_per_interval)%(num_intervals));

		// System.out.println(" at " + proc_interval);
		
		System.out.println(" at " + proc_interval + "  i.e. : actual ts " + time/16384 );

		//System.out.println(" Type inside is : " + type);

		min_ts = time;

		max_ts = time;

		eventstart_timer=System.currentTimeMillis();

		eventstart_timer/=1000;

		System.out.println("First Magnetometer message has been received for this event at " + eventstart_timer);

		prev_namotes[1]=prev_namotes[2]=0;

		currproc_time=time-max_delay*32768;

		curr_interval=proc_interval-(max_delay*2);

		if (curr_interval < 0)
			curr_interval = num_intervals + curr_interval;

		event_active_flag=true;

		waiting_to_fire=true;
		


	}
                 if (event_active_flag)
	{

		proc_interval=(int)((time/jiffies_per_interval)%(num_intervals));

		System.out.println(" at " + proc_interval + "  i.e. : actual ts " + time/16384 );

		if (min_ts>time)
		
		{

			min_ts=time;

		}

		if (max_ts<time)

		{
	
			max_ts=time;

		}

		// if first message for the event were very old from a previous event, then we reset min_ts to a newer one

		/*if ((time-min_ts > max_jitter + 6*32768) && (waiting_to_fire))
		{

			eventstart_timer=System.currentTimeMillis();
			eventstart_timer/=1000;
			min_ts=time;
			System.out.println("Resetting min_ts");
		}*/
		
	}
                         
              

	if ((type==0) && (time>hldl_mote[id].get_ts())) 	// Start Message .. ignore out of order old messages
                  {
              	    event_active[id][proc_interval]=1;
	    hldl_mote[id].set_ts(time);
	            	    timeout_mote[id]=max_timeout;
		    timeout_upgraded_to_car[id]=false;
	                	    timeout_upgraded_to_tank[id]=false;
                   
            	}


             	if ((type==1) && (time>hldl_mote[id].get_ts()) && (event_active_flag))  // End Message
            	{
                		moteupdate[id][proc_interval]=1;
		hldl_mote[id].set_ts(time);

	}

		int num_lost=0;

		if ((count>((hldl_mote[id].get_count())+1)) && (hldl_mote[id].get_count()!=0))
		{
			//messages lost
			System.out.println("Adding lost for " + id);
			num_lost = count - hldl_mote[id].get_count()-1;
			hldl_mote[id].add_lost(num_lost);
			hldl_mote[id].set_count(count);
		}
		if (count==((hldl_mote[id].get_count())+1))
		{
			hldl_mote[id].set_count(count);
		}
		if (hldl_mote[id].get_count()==0)
		{
			hldl_mote[id].set_count(count);
			
		}

                     
             

              

        } // end if id < n_motes    	

        }

}
		
  public void updateReceived(int dest_addr, UpdateMsg umsg) {

		int start;

		int num_index,offset,state,node,parent,gtype;

		num_index = umsg.numElements_path();
		state = (int)umsg.get_state();
		gtype=umsg.get_type();
		for(offset=0;offset<num_index;offset++)
		{	
			node = state*num_index+offset;
			parent = umsg.getElement_path(offset);
			
			//other partition
			
			if ((gtype==1) && (((node>=0) && (node<=9)) || ((node>=13) && (node<=21)) || ((node>=26) && (node<=33)) || ((node>=39) && (node<=43)) || ((node>=52) && (node<=55)) || ((node>=65) && (node<=67))))

			{

				node=77-node;
				if(parent == 255)
					parent = node;
				else
					parent=77-parent;
			
				int moteId = node;
				int magnetometerReading = 0;
          				int MIRReading = 0;
			        	int batteryReading = 3;
          				int parentMoteID = parent;
				MoteReading NewReading = new MoteReading(moteId, timestamp, magnetometerReading, MIRReading, batteryReading, parentMoteID);
				/* Create notification */  
          				Notification notification = new Notification( "readMoteMessage", this, -1, System.currentTimeMillis(), "Mote Message read" );

          				/* Allow receiver of notification to access vector of mote object */
		          		notification.setUserData( NewReading );

		          		/* Send Notification */
		          		sendNotification( notification );

				System.out.print(node+":"+parent+"  ");
			}

			if ((gtype==0) && (((node>=0) && (node<=9)) || ((node>=13) && (node<=21)) || ((node>=26) && (node<=33)) || ((node>=39) && (node<=43)) || ((node>=52) && (node<=55)) || ((node>=65)&&(node<=67))))

			{

				if (parent==255)
					parent=node;

				int moteId = node;
				int magnetometerReading = 0;
          				int MIRReading = 0;
			        	int batteryReading = 3;
          				int parentMoteID = parent;
				MoteReading NewReading = new MoteReading(moteId, timestamp, magnetometerReading, MIRReading, batteryReading, parentMoteID);
				/* Create notification */  
          				Notification notification = new Notification( "readMoteMessage", this, -1, System.currentTimeMillis(), "Mote Message read" );

          				/* Allow receiver of notification to access vector of mote object */
		          		notification.setUserData( NewReading );

		          		/* Send Notification */
		          		sendNotification( notification );

				System.out.print(node+":"+parent+"  ");
			}

		}


  }

  private void setTime(long t) { timestamp = t; }


 /*
  * -----------------------------------------------------
  * ATTRIBUTE ACCESSIBLE FOR MANAGEMENT BY A JMX AGENT
  * -----------------------------------------------------
  */

  private String message;

 /*
  * --------------------------------------------------------
  * PROPERTY NOT ACCESSIBLE FOR MANAGEMENT BY A JMX AGENT
  * --------------------------------------------------------
  */

  private static final int TARGETMESSAGE = 1;      /* target message type */
  private static final int MOTEMESSAGE = 2;        /* mote message type */
  private boolean stop = true;                     /* thread control variable */ 
  private Socket SocketClient;                     /* Client Socket to read message */
  private InputStream input = null;                /* Input stream for socket */
  private BufferedReader brIn;                     /* file input */
  private static final int PACKET_LEN = 6;         /* Packet length without timestamp */
  private static final int MSG_BYTES = 14;         /* Total message size */
  private long timestamp;                          /* Time stamp of message */

  private static final int GROUP_ID = -1; 	   /* To listen from the SerialForward */
  private MoteIF mote;

	/* Hldl Variables */

	 private boolean hldl_stop=false;

	 int curr_interval=0;
	 int proc_interval=1;
	 int mir_curr_interval=0;
	 int mir_proc_interval=1;
	 int n_motes=112;
	 int num_types=3;
	 int num_intervals=500;
	 int max_targets=100; // max number of parallel targets
	 int mir_msg_interval = 10000;
	
	 int avg_xdist_motes=30;
	 int avg_ydist_motes=25;

	 int nrows=13;
	 int ncols=6;
	 double [] stage1_op_prob = new double[num_types+1]; 
	 double [] stage2_op_prob = new double[num_types+1]; 
	 int stage1_optype;

       	 int num_targets=0;
        
	 int last_multiple=0;

	 boolean first_time=true;
        
       	 int [][] moteupdate = new int[n_motes+1][num_intervals+1];
       	 Moteinfo [] hldl_mote = new Moteinfo[n_motes+1];
   	 int [][] event_active = new int[n_motes+1][num_intervals+1];
       	 Targetinfo [] target = new Targetinfo[max_targets+1];

	 int [][] mir_event_active = new int[n_motes+1][num_intervals+1];
	 int [][] mir_update = new int[n_motes+1][num_intervals+1];

       	 int [][] xbucket = new int[nrows][ncols+1];
       	 int [] xbucketcount = new int[nrows];

      	 int [][] ybucket = new int[nrows][nrows+1];
       	 int [] ybucketcount = new int[ncols];

       	 int min_limit=2;
	 int mir_min_limit = 0;
         int type1_limit=9;
       	 int type2_limit=36;
       	 int max_delay=13;
	 int mir_max_delay=3;
       	 long sleeptime=450; 
	 long mir_sleeptime=450;
       	 int minsleeptime=100;
       	 int maxsleeptime=500;
       	 int jiffies_per_second=32768;
       	 int jiffies_per_interval=16384;
         long max_jitter = 13*32768;
	 long mir_max_jitter = 3*32768;

	int max_timeout=8;
	boolean [] timeout_upgraded_to_car = new boolean[n_motes+1];
	boolean [] timeout_upgraded_to_tank = new boolean[n_motes+1];
	boolean [] counted = new boolean[n_motes+1];
	int timeout_car_plus=12;
   	long newsleeptime=0; 

       	long start_timer=0;
        	long end_timer=0;
	long mir_start_time=0;
        	long mir_end_timer=0;
	
	int mir_ids=300;
       	int [] type_votes = new int[num_types+1];
 	int [] timeout_mote = new int[n_motes+1];
	int [] timeout_mir = new int[n_motes+1];
        
       	boolean end_included = false;

        	private Timer timer;

 	boolean event_active_flag=false;
	boolean mir_event_active_flag=false;
 	boolean waiting_to_fire=true;
	boolean mir_waiting_to_fire=true;
	boolean process_mir_flag = true;
	boolean ok_to_refresh_display=true;
	boolean ok_to_display=true;
	boolean miractive=false;
	boolean magactive=false;

 	long eventstart_timer;
 	long max_ts;
 	long min_ts;
 	long currproc_time;

	long mir_eventstart_timer;
	long mir_max_ts;
 	long mir_min_ts;
 	long mir_currproc_time;
	long all_time_max_ts;
		

 	long late_message_time=0*32768;
 
	int xoffset=0;
	int yoffset=0;

	int inactive=0;
	int int_when_refresh_stopped=0;


	boolean Exists = false;
	String fname1,fname2;

	int [] prev_namotes=new int[3];
	
	Timer timer1,timer2;

	boolean [] mir_up=new boolean[n_motes+1];
	int mir_x ;
	int mir_y ;
	int mir_max=0;
	long [] mir_start_timer = new long[n_motes+1];
	long check_time_for_mir;
	long mir_timeout=10000;
	int mircount=0;

	int mbit=0;
	// Thread t1, t2;

	
 
}
