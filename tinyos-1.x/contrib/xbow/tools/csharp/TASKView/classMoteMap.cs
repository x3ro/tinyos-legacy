using System;
using System.Drawing;
using System.Windows.Forms;

namespace TASKView.lib
{
	/**
	 *  The MoteMap class implements an interactive network topology map. 
	 * 
	 * @author      Martin Turon
	 * @version     2004/4/14    mturon      Initial version
	 * 
	 * $Id: classMoteMap.cs,v 1.5 2004/04/28 18:19:11 mturon Exp $
	 */
	public class MoteMap : System.Windows.Forms.PictureBox
	{
		#region // ===================== CLASS DATA ==========================
		const int		m_node_radius	= 25;	//!< node radius
		const int		m_glow_radius	= 33;	//!< glow radius
		static Brush	m_link_color	= Brushes.SpringGreen;
		static Brush	m_glow_color	= Brushes.Magenta;
		static Brush	m_node_color	= Brushes.Cyan;
		static Brush	m_text_color	= Brushes.Black;
		static Font		m_node_font		= new Font("Arial", 8, FontStyle.Bold);

	#endregion

		#region // ==================== INSTANCE DATA ========================
		int			m_mouseX;			//!< x coord of MouseDown event
		int			m_mouseY;			//!< y coord of MouseDown event
		ushort		m_activeNode;		//!< nodeid of last rollover or drag
		
		float		m_scaleX;
		float		m_scaleY;

		string		m_bitmap;
		Bitmap		m_image;

		Rectangle	m_dragObj;
		#endregion

		// ======================= METHODS ===========================

		#region // ==> MoteMap: Initialization Code
		/** Constructor. */
		public MoteMap() 
		{
			m_activeNode = MoteInfo.MF_NO_PARENT;
			m_dragObj = new Rectangle(0, 0, 25, 25);
			this.DragEnter += new DragEventHandler(OnDragEnter);
			this.DragDrop  += new DragEventHandler(OnDragDrop);
			this.AllowDrop = true;
		}

		public void Initialize()
		{
			m_bitmap = "..\\..\\xbow.bmp";
			try 
			{
				m_image  = new Bitmap(m_bitmap);
				Rescale();
				this.Image = m_image;	// Strap in current image.
			} 
			catch (Exception ex) 
			{
				theOdbcManager.Instance.ErrorLog(ex.ToString());
			}
		}
		#endregion

		#region // ==> MoteMap: Sizing Code
		/** 
		 * Recalculates the largest scale factor possible within the current
		 * size of the MoteMap while preserving the aspect ratio of the bitmap.
		 * 
		 * @author      Martin Turon
		 * @version     2004/4/15    mturon      Initial version
		 */
		public void Rescale()
		{
			if (null != m_image) 
			{
				// Insure original aspect ratio.
				m_scaleX = (float)Width / (float)m_image.Width;
				m_scaleY = (float)Height / (float)m_image.Height;
				if (m_scaleX > m_scaleY) 
				{
					m_scaleX = m_scaleY;
				} 
				else 
				{
					m_scaleY = m_scaleX;
				}
			
				Width = (int)((float)m_image.Width * m_scaleX);
				Height = (int)((float)m_image.Height * m_scaleY);
			}
		}


		/**
		 * Calculates new scale of picture.  This scale factor is 
		 * field in the class and is used by the OnPaint method to 
		 * correctly render the topology map.  The scale factor is 
		 * at a fixed 1:1 ratio, so the image is never stretched in 
		 * either direction.
		 * 
		 * @author		Martin Turon
		 * @version     2004/2/17    mturon      Initial version
		*/
		protected override void OnResize(EventArgs e)
		{
			if (null != m_image) 
			{
				Rescale();
				Width = (int)((float)m_image.Width * m_scaleX);
				Height = (int)((float)m_image.Height * m_scaleY);
			}
			base.OnResize (e);
		}
		#endregion

		#region // ==> MoteMap: Drawing Code
		/** 
		 * Handles custom portion of paint event chain and all
		 * low-level drawing for the the network topology map.
		 * 
		 * @author		Martin Turon
		 * @version		2004/2/13	mturon		Initial version
		 * @n           2004/3/4	mturon		Converted to use MoteTable
		 * @n			2004/4/15   mturon		Ported to C# from VB6
		 */
		protected override void OnPaint(PaintEventArgs e)
		{
			base.OnPaint(e);		// Base handler will draw the image.

			Graphics g = e.Graphics;

			MoteTable moteTable = theMoteTable.Instance;		
	
			foreach (MoteInfo moteInfo in moteTable.Values)
			{
				ushort parent = moteInfo.m_parent;
				Pen pen = new Pen(m_link_color, 3);
				if (parent != MoteInfo.MF_NO_PARENT) 
				{
					MoteInfo parentInfo = (MoteInfo)moteTable[parent];
					g.DrawLine( pen, 
						(float)moteInfo.m_x * m_scaleX, 
						(float)moteInfo.m_y * m_scaleY, 
						(float)parentInfo.m_x * m_scaleX,
						(float)parentInfo.m_y * m_scaleY);
				} 
				else 
				{
					// Special drawing of mote with no parent information.
					//Picture1.FillColor = MOTE_FAIL_COLOR
					//Picture1.FillStyle = 6
					//Picture1.Circle (moteInfo.m_x * m_scaleX, _
					//                 moteInfo.m_y * m_scaleY), _
					//                 MOTE_GLOW_RADIUS * m_scaleX * 1.5, _
					//                 MOTE_FAIL_COLOR
					//Picture1.FillStyle = 0
				}
			}
		
			float node_r = m_node_radius * m_scaleX;		// node radius
			float glow_r = m_glow_radius * m_scaleX;		// glow radius
			float node_r2 = node_r / 2;
			float glow_r2 = glow_r / 2;
			foreach (MoteInfo moteInfo in moteTable.Values)
			{
				float c_x = moteInfo.m_x * m_scaleX;
				float c_y = moteInfo.m_y * m_scaleY;

				// Draw the node as circles.
				g.FillEllipse(m_glow_color, 
					c_x - glow_r2, c_y - glow_r2, glow_r, glow_r); 
				g.FillEllipse(m_node_color, 
					c_x - node_r2, c_y - node_r2, node_r, node_r); 

				// Draw the node id as text.
				Font	drawFont = m_node_font;
				ushort  nodeid   = moteInfo.m_nodeid;
				string	nodeName = nodeid.ToString();
				if (nodeid == 0) nodeName = "GW";
				g.DrawString(nodeName, drawFont, m_text_color, 
					c_x - node_r2, c_y - (drawFont.Height / 2));
			}
		}

		/*
		'====================================================================
		' Picture1_DrawMoteInfo
		'====================================================================
		' DESCRIPTION:  Handles dynamic information popups on mouse rollovers.
		'
		' HISTORY:      mturon      2004/2/24    Initial version
		'
		Private Sub Picture1_DrawMoteInfo(nodeid As Integer)
			' Initialize mote info pop-up display for nodeid = i
			MotePopupLabel.Visible = False
    
			' Get this mote Object from the Dictionary
			Set moteInfo = g_MoteInfo.Item(nodeid)
    
			MotePopupLabel.Caption = _
				"Node = " & moteInfo.m_nodeid & vbLf & _
				"Name = " & moteInfo.m_name & vbLf & _
				"Parent = " & moteInfo.m_parent & vbLf & _
				"Epoch = " & moteInfo.m_epoch & vbLf & _
				"Time = " & moteInfo.m_time
    
			If (nodeid = 0) Then
				' Special treatment for Gateway
				MotePopupLabel.Caption = _
					"Name = Gateway" & vbLf & _
					"Status = Started" & vbLf & _
					"Jobs = " & objSQL.DBTable
			End If
    
			' Default position is lower right of mote
			MotePopupLabel.Left = m_scaleX * _
				(moteInfo.m_x + MOTE_GLOW_RADIUS)
			MotePopupLabel.Top = m_scaleY * _
				(moteInfo.m_y + MOTE_GLOW_RADIUS)
    
			' Insure mote info display is within bounds
			If (MotePopupLabel.Left + MotePopupLabel.Width) > Picture1.Width Then
				MotePopupLabel.Left = MotePopupLabel.Left - MotePopupLabel.Width _
									- (2 * MOTE_GLOW_RADIUS * m_scaleX)
			End If
			If (MotePopupLabel.Top + MotePopupLabel.Height) > Picture1.Height Then
				MotePopupLabel.Top = MotePopupLabel.Top - MotePopupLabel.Height _
								   - (2 * MOTE_GLOW_RADIUS * m_scaleY)
			End If
    
			MotePopupLabel.Visible = True
		End Sub
		 */

		#endregion	// Drawing code

		#region // ==> MoteMap: Mouse/Drag Code
		/**
		 * Initiates a Drag event when the user clicks on the MoteMap.
		 * 
		 * @author		Martin Turon
		 * @version		2004/2/17    mturon      Initial version
		 * @n			2004/4/15    mturon      Ported to C#
		 */
		protected override void OnMouseDown(MouseEventArgs e)
		{
			base.OnMouseDown (e);

		    // Disable info rollovers on all mouse clicks (drag or popup)
			m_activeNode = MoteInfo.MF_NO_PARENT;
			m_mouseX = e.X;
			m_mouseY = e.Y;

			bool mote_clicked = false;
			foreach (MoteInfo moteInfo in theMoteTable.Instance.Values) 
			{
				int x = moteInfo.m_x,
					y = moteInfo.m_y;
				
				if (((e.X > (x - m_glow_radius) * m_scaleX)  &&
					(e.X < (x + m_glow_radius) * m_scaleX)) &&
					((e.Y > (y - m_glow_radius) * m_scaleY)  &&
					(e.Y < (y + m_glow_radius) * m_scaleY))) 
				{
					mote_clicked = true;
					if (e.Button == MouseButtons.Right) 
					{
						theOdbcManager.Instance.ErrorLog("\nmote popup!");
						// Right-click pop-up menu
			            // MDIForm1.MnMotePopup.Tag = moteInfo.m_nodeid  'Store mote_id in popup
						// PopupMenu MDIForm1.MnMotePopup
					} 
					else 
					{
						m_dragObj.X = e.X;
						m_dragObj.Y = e.Y;
						m_activeNode = moteInfo.m_nodeid;
						//this.DoDragDrop(m_dragObj, DragDropEffects.Move);
						this.DoDragDrop(m_image, DragDropEffects.Move);
						break;
					}
				}
			}

			if ((!mote_clicked) && (e.Button == MouseButtons.Right))
			{
				theOdbcManager.Instance.ErrorLog("\nnew mote popup!");
				// PopupMenu MDIForm1.MnNewMotePopup
			}
		}

		protected virtual void OnDragEnter (object sender, DragEventArgs drgevent)
		{
			if (drgevent.Data.GetDataPresent(DataFormats.Bitmap)) 
			{
				drgevent.Effect = DragDropEffects.Move;		// Allow drop.
			}
			else {
				drgevent.Effect = DragDropEffects.None;		// Do not allow drop.
			}
		}


		/**
		 * Handles the end of a DragDrop sequence by storing the new 
		 * mote position as an unscaled pixel offset relative to the 
		 * MoteMap size.
		 * 
		 * @author		Martin Turon
		 * @version		2004/2/17    mturon      Initial version
		 * @n			2004/4/15    mturon      Ported to C#
		 */
		protected virtual void OnDragDrop(object sender, DragEventArgs e)
		{
			ushort nodeid    = m_activeNode;		
			Point  dropPoint = this.PointToClient(new Point(e.X, e.Y));
			theOdbcManager.Instance.ErrorLog("\nMoved node " + nodeid
				+ " to: " + dropPoint.X + "," + dropPoint.Y);

			// Write new position into MoteTable
			MoteTable moteTable = theMoteTable.Instance;
			MoteInfo  moteInfo  = (MoteInfo)moteTable[nodeid];	// always index with ushort
			moteInfo.m_x = (int)((float)dropPoint.X / m_scaleX);
			moteInfo.m_y = (int)((float)dropPoint.Y / m_scaleY);
			moteInfo.m_flags |= MoteFlags.MF_DIRTY;
			Refresh();			// Refresh MoteMap
		}

		/**
		 * Handles dynamic information popups on mouse rollovers.
		 *
		 * @author		Martin Turon
		 * @version		2004/2/24    mturon      Initial version
		 * @n			2004/4/15    mturon      Ported to C#
		 */
		protected override void OnMouseMove(MouseEventArgs e)
		{
			base.OnMouseMove (e);
			/*
			Private Sub Picture1_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
				Dim found As Boolean
				Dim i, myX, myY As Integer
				found = False
				For Each v In g_MoteInfo.Items
					Set moteInfo = v
					myX = moteInfo.m_x
					myY = moteInfo.m_y
					If ((X > (myX - MOTE_GLOW_RADIUS) * m_scaleX) And _
						(X < (myX + MOTE_GLOW_RADIUS) * m_scaleX)) And _
					   ((Y > (myY - MOTE_GLOW_RADIUS) * m_scaleY) And _
						(Y < (myY + MOTE_GLOW_RADIUS) * m_scaleY)) Then
						 found = True
						m_rollover = moteInfo.m_nodeid
						Timer1.Enabled = True
					End If
				Next
				If Not found Then
					m_rollover = -1
					MotePopupLabel.Visible = False
				End If
			End Sub
			*/
		}
		#endregion

	} // class MoteMap

} // namespace TASKView.lib
