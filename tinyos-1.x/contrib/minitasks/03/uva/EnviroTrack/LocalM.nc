/* "Copyright (c) 2000-2002 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 * 
 * Authors: Qing Cao,Tian He 
 */
 
module LocalM{  

  provides interface Local;
}
 
 implementation 
 {
  
  uint16_t GridSizeX;
  uint16_t GridSizeY;    
       
  command  uint16_t Local.LocalizationByID_X(uint16_t i)
	  { return (uint16_t) (i%GridSizeX);}

  command  uint16_t Local.LocalizationByID_Y(uint16_t i)
          { return (uint16_t)(i/GridSizeX);}
  
  command  uint16_t Local.setParameters( uint16_t GridX,uint16_t GridY){
  
  		GridSizeX = GridX;
  		GridSizeY = GridY;  	
  		return SUCCESS;  		
  }
 
  command  uint16_t Local.GetIDByLocation(uint16_t x, uint16_t y){
	
	/*check whether the location (x, y) is legal or not. 
	 *If legal, return the ID. It not leagal, return -1
	 */
	if (x >= GridSizeX ||  y >= GridSizeY) 
	  return 0xffff;	
	else 
	  return (x+y*GridSizeX);
	
  }
 	
}
