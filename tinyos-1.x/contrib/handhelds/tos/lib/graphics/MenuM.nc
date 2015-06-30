/*
 * Copyright (c) 2004,2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * 
 * Authors:  Brian Avery <b.avery@hp.com>
 */




module MenuM {
    provides interface StdControl;
    provides interface Menu;


    uses {
      interface Leds;
      interface LCD;
      interface Buttons;
      interface ParamList;
      interface IMAPLite;
      interface Time;      
    }    
}


implementation {
#include "Menu.h"

#define MENU_LINE_PADDING 1
#define DEFAULT_MENU_FONT 0  

#define SCROLL_X_OFFSET 4
#define SCROLL_WIDTH 3

  
#define BUTTON_ESCAPE  0x01
#define BUTTON_RECEDE  0x02
#define BUTTON_SELECT  0x04
#define BUTTON_ADVANCE 0x08



#define MIN(a,b) ((a) < (b) ? (a) : (b))
#define MAX(a,b) ((a) > (b) ? (a) : (b))  

  enum 
    {
      MENU_STATE_MADE=0x01,
      MENU_STATE_DYNAMIC=0x02
    };
  
  
      
  
  
  inline void clearSelection();
  task void clearSelectionTask();
  void drawMenu(struct Menu *m);
  void drawScrollBars(struct Menu *m);
  result_t freeMenuItem(struct MenuItem *mi);
  
  

  
  // menu pool structures
  struct Menu gMainMenus[MAX_MENUS];  // all the main menus
  struct MenuItem gMenuItemPool[MAX_MENU_ITEMS]; // shared by all menus ram & rom


  
  //global shared data
  static Rect gMenuRect = { 1,30,158,89};
  static Rect gScrollRect = { 2,30,2,89};
  int gActiveMenu = -1;
  int gMenuStrPoolIndex;  
  int gSelectedItem = -1;
  Rect gSelectedRect = {0,0,0,0};
  
  
  void *gdebugP = 0x0;
  
  
  
  command result_t StdControl.init() {
    int i;
    int ascent = 0;
    int descent=0;
    
    
    
    for (i=0; i < MAX_MENU_ITEMS; i++)
      freeMenuItem(&gMenuItemPool[i]);
    
     
    
    for (i=0; i < MAX_MENUS; i++){
      gMainMenus[i].state = 0;
      gMainMenus[i].numItems = 0;
      gMainMenus[i].firstItem = 0;
      gMainMenus[i].font = DEFAULT_MENU_FONT;
      call LCD.gf_get_font_info(gMainMenus[i].font,&ascent,&descent);      
      gMainMenus[i].numItemsVisible = MIN( gMainMenus[i].numItems,gMenuRect.h/(ascent+descent+MENU_LINE_PADDING));
      gMainMenus[i].ascent = ascent;
      gMainMenus[i].descent = descent;	
      
    }

    call Buttons.enable();
    
    return SUCCESS;
  }
  
  
  command result_t StdControl.start() {


    return SUCCESS;
  }
  command result_t StdControl.stop() {


      return SUCCESS;
  }

  struct MenuItem  *getMenuItem()
    {
      int i;
      struct MenuItem *mi;
      
      for (i=0; i<MAX_MENU_ITEMS; i++){
	if (gMenuItemPool[i].menuItemState == MENU_STATE_UNUSED){
	  mi = &gMenuItemPool[i];
	  mi->menuItemState = MENU_STATE_NONE;
	  return mi;
	}
      }
      return NULL;      
    }

  int countFreeMenuItems()
    {
      int i;
      int count=0;
      
      
      for (i=0; i<MAX_MENU_ITEMS; i++){
	if (gMenuItemPool[i].menuItemState == MENU_STATE_UNUSED){
	  count++;
	}
      }
      return count;      
    }

  
  result_t freeMenuItem(struct MenuItem *mi)
    {
      mi->menuItemState = MENU_STATE_UNUSED;
      mi->menuItemUID = NULL;
      mi->menuItemType = MENU_TYPE_NONE;
      return SUCCESS;
    }

  int getMenu()
    {
      int i;

      for (i=0; i<MAX_MENUS; i++){
	struct Menu *m = &gMainMenus[i];
	if (!(m->state & MENU_STATE_MADE))
	  return i;
      }
      return -1;
    }
  
      
	     
  command int Menu.makeMenu()
    {
      int whichMenu;

      if ((whichMenu = getMenu())<0)
	return -1;
      
      gMainMenus[whichMenu].state |= MENU_STATE_MADE;
      return whichMenu;
    }

  command result_t Menu.deleteMenu(int whichMenu)
    {
      struct Menu *m;
      int i;
      
      if (whichMenu >= MAX_MENUS) 
	return FAIL;
      m = &gMainMenus[whichMenu];
      
      if (!(m->state & MENU_STATE_MADE))
	return FAIL;

      for (i=0; i < m->numItems; i++)
	freeMenuItem(m->pMenuItemList[i]);


      m->state = 0;
      m->numItems = 0;
      m->firstItem = 0;

      
      return SUCCESS;
    }

  command result_t Menu.deleteItem(int whichMenu,int whichItem)
    {
      struct Menu *m;
      struct MenuItem *pMI ;
      int i;
      
      if (whichMenu >= MAX_MENUS) 
	return FAIL;
      m = &gMainMenus[whichMenu];

      if (!(m->state & MENU_STATE_MADE))
	return FAIL;

      if (!(whichItem < m->numItems))
	return FAIL;

      // compace the list down by reusing the menupoolitems and free the last one
      for (i=whichItem; i < m->numItems-1; i++)
	*(m->pMenuItemList[i]) = *(m->pMenuItemList[i+1]);

      freeMenuItem(m->pMenuItemList[m->numItems-1]);
      m->numItems--;      
      
      return SUCCESS;
      
    }
  


  command int Menu.addItem(int whichMenu,void *uid,int8_t state,int8_t type)
    {
      struct Menu *m;
      struct MenuItem *pMI ;

      if (whichMenu >= MAX_MENUS) 
	return -1;
      m = &gMainMenus[whichMenu];

      if (!(m->state & MENU_STATE_MADE))
	return -1;
      
      if (!(pMI = getMenuItem()))
	{
	  return -1;
	}
      pMI->menuItemUID = uid;
      pMI->menuItemState = state;
      pMI->menuItemType = type;
      m->pMenuItemList[m->numItems] = pMI;      
      m->numItems++;

#if 0

      {
	char buf[128];
	Point p = {2,100};
	volatile int hold;
	
	if (m->pMenuItemList[m->numItems-1]->menuItemType == MENU_TYPE_MESSAGE) {	  
	  call LCD.clear();
	  sprintf(buf,"added id:%u",
		  m->pMenuItemList[m->numItems-1]->menuItemUID);	  
	  for (hold = 1; hold < 30; hold++)
	    call LCD.gf_draw_string(buf,FONT_HELVETICA_R_12,&p,GF_OR);
	}
	
      }
#endif



      
#if 0

      {
	char buf[128];
	Point p = {2,100};
	volatile int hold;
	
	  
	call LCD.clear();
	sprintf(buf,"add free:%d",countFreeMenuItems());	
	for (hold = 1; hold < 30; hold++)
	  call LCD.gf_draw_string(buf,FONT_HELVETICA_R_12,&p,GF_OR);
	
      }
#endif
      
#if 0
      {
	char buf[128];
	Point p = {2,100};
	volatile int hold;
	
	  
	call LCD.clear();
	sprintf(buf,"add:0x%x to m:%d i:0x%x",(void *) uid,whichMenu,pMI);	
	for (hold = 1; hold < 100; hold++)
	  call LCD.gf_draw_string(buf,FONT_HELVETICA_R_12,&p,GF_OR);

#if 0
	if (m->pMenuItemList[m->numItems-1]->menuItemType == MENU_TYPE_PARAM) {

	  char l_buf[64];
	  call LCD.clear();
	  //call ParamList.displayParamValue(l_buf,64,(const struct Param *)m->pMenuItemList[m->numItems-1]->menuItemUID);
	  call ParamList.displayParamValue(l_buf,64,(const struct Param *)uid);   
	  
	  sprintf(buf,"now holds:%s in %d",l_buf,m->numItems-1);	
	  for (hold = 1; hold < 100; hold++)
	    call LCD.gf_draw_string(buf,FONT_HELVETICA_R_12,&p,GF_OR);
	} 
	else if (m->pMenuItemList[m->numItems-1]->menuItemType == MENU_TYPE_STRING) {
	  call LCD.clear();
	  sprintf(buf,"now holds:%s in %d",(char *)m->pMenuItemList[m->numItems-1]->menuItemUID ,m->numItems-1);	
	  for (hold = 1; hold < 100; hold++)
	    call LCD.gf_draw_string(buf,FONT_HELVETICA_R_12,&p,GF_OR);
	} 
	  
	  
#endif
	
      }
#endif
      return (m->numItems-1);      
    } 
  
  command int Menu.makeRomMenu(void *menuList)
    {
      int whichMenu;      
      struct MenuItem *pRomMI = (struct MenuItem *) menuList;
      
      if ((whichMenu = call Menu.makeMenu()) < 0)
	return -1;

      
      while (pRomMI->menuItemUID){	
	if (call Menu.addItem(whichMenu,
			      pRomMI->menuItemUID,
			      pRomMI->menuItemState,
			      pRomMI->menuItemType) < 0) {
	  
	  call Menu.deleteMenu(whichMenu);
	  return -1;
	}
	pRomMI++;
      }
      
      return whichMenu;
    }	

    command int Menu.getMenuSelection(int whichMenu)
    {
      
      if (gActiveMenu < 0)
	return -1;
      if (gActiveMenu != whichMenu)
	return -1;
      return gSelectedItem;
    }

  command result_t Menu.setMenuSelection(int i)
    {
      struct Menu *m;


      
      if (gActiveMenu < 0)
	return FAIL;
      m = &gMainMenus[gActiveMenu];
      if (i > m->numItems)
	return FAIL;
      if (m->pMenuItemList[i]->menuItemState == MENU_STATE_UNSELECTABLE)
	return FAIL;

      clearSelection();      
      gSelectedItem = i;
      if (gSelectedItem >= 0)
	drawMenu(&gMainMenus[gActiveMenu]);
      return SUCCESS;
    }
  
  // Make sure you undisplay the menu before changing this
  command result_t Menu.setMenuRect(Rect *r)
    {
      int i,ascent,descent;
      
      if (gActiveMenu != -1)
	return FAIL;
      gMenuRect = *r;

      // fix the # of lines to display
      for (i=0; i < MAX_MENUS; i++){
	if (call LCD.gf_get_font_info(gMainMenus[i].font,&ascent,&descent) == SUCCESS){
	  gMainMenus[i].numItemsVisible = MIN( gMainMenus[i].numItems,gMenuRect.h/(ascent+descent+MENU_LINE_PADDING));
	  if (!gMainMenus[i].numItemsVisible)	  
	    gMainMenus[i].numItemsVisible=1;		
	}
	else
	  gMainMenus[i].numItemsVisible = 1;
      }

      gScrollRect.x = gMenuRect.x-SCROLL_X_OFFSET;
      gScrollRect.w = SCROLL_WIDTH;
      gScrollRect.y = gMenuRect.y;
      gScrollRect.h = gMenuRect.h;
      
      
      return SUCCESS;
    }	


  command result_t Menu.setDynamic(int whichMenu)
    {
      struct Menu *m ;

      if (whichMenu >= MAX_MENUS) 
	return FAIL;
      m = &gMainMenus[whichMenu];

      if (!(m->state & MENU_STATE_MADE))
	return FAIL;
      m->state |= MENU_STATE_DYNAMIC;      
      return SUCCESS;      
    }
  

  // Make sure you undisplay the menu before changing this
  command result_t Menu.setFont(int whichMenu,int font)
    {
      int i,ascent,descent;
      if (gActiveMenu == whichMenu)
	return FAIL;
      if (whichMenu >= MAX_MENUS) 
	return FAIL;
      gMainMenus[whichMenu].font = font;

      // fix the # of lines to display
      for (i=0; i < MAX_MENUS; i++){
	if (call LCD.gf_get_font_info(gMainMenus[i].font,&ascent,&descent) == SUCCESS){
	  gMainMenus[i].numItemsVisible = MIN( gMainMenus[i].numItems,gMenuRect.h/(ascent+descent+MENU_LINE_PADDING));
	  gMainMenus[i].ascent = ascent;
	  gMainMenus[i].descent = descent;
	  if (!gMainMenus[i].numItemsVisible)	  
	    gMainMenus[i].numItemsVisible=1;		
	}
	else
	  gMainMenus[i].numItemsVisible = 1;
      }

      return SUCCESS;
    }	

  // mark item so we can see why we cant select it
  void markItemUnselectable(char *s,struct Menu *m,Point *p)
    {
      Rect r;

      call LCD.gf_get_string_rect(s,m->font,p,&r);
      call LCD.gf_draw_line(r.x+1,r.y+r.h/2,r.x+r.w-2,r.y+r.h/2);
      
    }
  
  
  // clear a selection box
  task void clearSelectionTask()
    {
      clearSelection();      
    }
  inline void clearSelection()
    {
      call LCD.gf_clear_frame_rect(&gSelectedRect);
    }

  // draw a selection box
  void drawSelection(struct Menu *m,Point *p)
    {
      char l_buf[64];
      char l_buf2[128];
      char *s=NULL;

      gSelectedRect.x = p->x - 1;
      // frame rect does TopLeft corner and down. so we reset the p.y - leading (m->a+m->d+pad) + desc so we clear a p and + 1
      gSelectedRect.y = p->y  + 1 - (m->ascent + MENU_LINE_PADDING);
      gSelectedRect.h = m->ascent+m->descent+2;
      // add 1 here so we don't run into the end of the word
      switch (m->pMenuItemList[gSelectedItem]->menuItemType)
	{
	case MENU_TYPE_STRING:
	  s = (char *) m->pMenuItemList[gSelectedItem]->menuItemUID;	
	  gSelectedRect.w = call LCD.gf_get_string_width(s,m->font)+1;
	  break;
	case MENU_TYPE_PARAM:
	  {
	    const struct Param *pLA;
	    pLA = (const struct Param *)m->pMenuItemList[gSelectedItem]->menuItemUID;	    
	    call ParamList.displayParamValue(l_buf,64,pLA);
	    //sprintf(l_buf2,"%s\t%s",pLA->name,l_buf);
	    sprintf(l_buf2,"%s:%s",pLA->name,l_buf);
	    s = l_buf2;
	    gSelectedRect.w = call LCD.gf_get_string_width(s,m->font)+1;
	  }
	  break;
	case MENU_TYPE_PARAMLIST:
	  s = ((const struct ParamList *)m->pMenuItemList[gSelectedItem]->menuItemUID)->name;	  
	  gSelectedRect.w = call LCD.gf_get_string_width(s,m->font)+1;
	  break;
	case MENU_TYPE_MESSAGE:
	  {
	    gSelectedRect.w = gMenuRect.w-5;	    
	  }
	  
	  break;
	default:
	  break;
	}
      

      call LCD.gf_frame_rect(&gSelectedRect);
    }

  void drawScrollBars(struct Menu *m)
    {
      int i;
      uint16_t top;
      uint16_t bottom;

      call LCD.gf_clear_rect(&gScrollRect);
      
      // no scroll bars if we dont need them
      if (m->numItems <= m->numItemsVisible)
	return;
      
      
      top = (gScrollRect.h * m->firstItem)/m->numItems + gScrollRect.y;
      bottom = (gScrollRect.h * (m->firstItem+m->numItemsVisible))/m->numItems + gScrollRect.y;
      

	
      for (i = gScrollRect.x; i < (gScrollRect.x+gScrollRect.w); i++)
      {
	call LCD.gf_draw_line(i,top,i,bottom);
	call LCD.gf_draw_dashed_line(i,gScrollRect.y,i,gScrollRect.y+gScrollRect.h,1);	
      }

    }
  
  // draw the visible items in the menu
  void drawMenu(struct Menu *m)
    {
      int i;
      Point p;      
      int leading = m->ascent+m->descent+MENU_LINE_PADDING;
      char l_buf[64];
      char l_buf2[128];
      char *s = NULL;
      const struct TextMessage *tmsg;
      int maxMessageSize;      

      if (m->numItems == 0)
	return;
      
      p.y = gMenuRect.y + m->ascent+ MENU_LINE_PADDING;
      p.x = gMenuRect.x;
      for (i=m->firstItem; i < m->numItemsVisible+m->firstItem; i++)
	{	
	  if (gSelectedItem == i){
	    drawSelection(m,&p);
	  }
	  
	  switch (m->pMenuItemList[i]->menuItemType)
	    {
	    case MENU_TYPE_STRING:
	      s = (char *) m->pMenuItemList[i]->menuItemUID;

	      
	      break;
	    case MENU_TYPE_PARAM:
	      {
		const struct Param *pLA;
		pLA = (const struct Param *)m->pMenuItemList[i]->menuItemUID;	    
		call ParamList.displayParamValue(l_buf,64,pLA);
		//sprintf(l_buf2,"%s\t%s",pLA->name,l_buf);
		sprintf(l_buf2,"%s:%s",pLA->name,l_buf);
		s = l_buf2;
	      }
	      break;
	    case MENU_TYPE_PARAMLIST:
	      s = ((const struct ParamList *)m->pMenuItemList[i]->menuItemUID)->name;	      
	      break;
	    case MENU_TYPE_MESSAGE:
	      {
		struct tm l_tm;
		char buf_time[8];
		Point ptTime;
		

		tmsg = call IMAPLite.get_msg_by_id((uint16_t)m->pMenuItemList[i]->menuItemUID);
		
		// magic numbers try better later
		maxMessageSize = (gMenuRect.w - 20)/8; // allow space for time
		
		if (tmsg){
		  bzero(l_buf2,128);		  
		  strncpy(l_buf2,tmsg->text,maxMessageSize);
		  s = l_buf2;
		  // draw the time here, not ideal but we'll look at it
		  // do the time
		  call Time.localtime(&tmsg->timestamp, &l_tm);	
		  sprintf(buf_time,"%.2d:%.2d",l_tm.tm_hour,l_tm.tm_min);
		  // why 3??  1 wasnt enough
		  ptTime.x = gMenuRect.x+gMenuRect.w-6;
		  ptTime.y = p.y;
#if 1
		  call LCD.gf_draw_string_aligned(buf_time,m->font,&ptTime,GF_OR,LCD_ALIGN_RIGHT);
#endif
		}
	      }
	      break;
	    default:
	      break;
	    }

	  if (s)
	    call LCD.gf_draw_string(s,m->font,&p,GF_OR);
	  else
	    call LCD.gf_draw_string("MsgDeleted",m->font,&p,GF_OR);
	  
	  
	  
	  if (m->pMenuItemList[i]->menuItemState == MENU_STATE_UNSELECTABLE)
	    markItemUnselectable(s,m,&p);
	    
	  p.y += leading;
	  
	}
      drawScrollBars(m);
      
    }

  
	
  
  command result_t Menu.displayMenu(int whichMenu)
    {
      if (whichMenu >= MAX_MENUS) 
	return FAIL;

      call LCD.gf_clear_rect(&gMenuRect);
      
      // reset the old menu
      if ((gActiveMenu >= 0) && (gActiveMenu != whichMenu)){
	gMainMenus[gActiveMenu].firstItem = 0;
	gSelectedItem = -1;
      }
      gActiveMenu = whichMenu;
      drawMenu(&gMainMenus[gActiveMenu]);


      return SUCCESS;
    }

  command result_t Menu.undisplayMenu()
    {
      clearSelection();      
      call LCD.gf_clear_rect(&gMenuRect);
      gActiveMenu = -1;
      gSelectedItem = -1;
      return SUCCESS;
    }


  command void * Menu.getMenuUID(int whichMenu,int whichItem)
    {

      if (whichMenu >= MAX_MENUS) 
	return NULL;
      if (whichItem >= (gMainMenus[whichMenu].numItems))
	return NULL;      
      return gMainMenus[whichMenu].pMenuItemList[whichItem]->menuItemUID;	
    }

  command int Menu.getMenuState(int whichMenu,int whichItem)
    {

      if (whichMenu >= MAX_MENUS) 
	return -1;
      if (whichItem >= (gMainMenus[whichMenu].numItems))
	return -1;      
      return gMainMenus[whichMenu].pMenuItemList[whichItem]->menuItemState;	
    }

  command result_t Menu.setMenuState(int whichMenu,int whichItem, int menuState)
    {

      if (whichMenu >= MAX_MENUS) 
	return FAIL;
      if (whichItem >= (gMainMenus[whichMenu].numItems))
	return FAIL;      
      return gMainMenus[whichMenu].pMenuItemList[whichItem]->menuItemState = menuState;
      return SUCCESS;
      
    }

  // advance the selection ptr to the next valid entry
  void AdvanceSelection()
    {
      struct Menu *m = &gMainMenus[gActiveMenu];      
      int i = gSelectedItem+1;
      
      while (i < m->numItems){
	if (m->pMenuItemList[i]->menuItemState != MENU_STATE_UNSELECTABLE){
	  gSelectedItem = i;
	  signal Menu.menuSelectionChanged(gActiveMenu,gSelectedItem);
	  return;	  
	}
	i++;
      }
    }
  
  // recede the selection ptr to the next valid entry
  void RecedeSelection()
    {
      struct Menu *m = &gMainMenus[gActiveMenu];      
      int i = gSelectedItem;

      if (i < 0)
	i =m->numItems-1;
      else
	i--;
      
      
      while (i >= 0){
	if (m->pMenuItemList[i]->menuItemState != MENU_STATE_UNSELECTABLE){
	  gSelectedItem = i;
	  signal Menu.menuSelectionChanged(gActiveMenu,gSelectedItem);
	  return;	  
	}
	i--;
      }
    }
  
      
  
  task void AdvanceMenu()
    {
      struct Menu *m;


      //call Leds.yellowToggle();
      
      if (gActiveMenu == -1)
	return;
      m = &gMainMenus[gActiveMenu];      

      AdvanceSelection();      
      
      if (gSelectedItem >=0)
	clearSelection();

      // the selected item is off the screen
      if (gSelectedItem >= (m->firstItem + m->numItemsVisible))
	{
	  m->firstItem = gSelectedItem - m->numItemsVisible + 1;
	  call Menu.displayMenu(gActiveMenu);
	}
      else if (gSelectedItem <  m->firstItem)
      {
	m->firstItem = gSelectedItem ;
	call Menu.displayMenu(gActiveMenu);
      }		
      else // just redraw it, no erase unless the items are dynamic
	{
	  if (m->state & MENU_STATE_DYNAMIC)
	    call Menu.displayMenu(gActiveMenu);
	  else
	    drawMenu(&gMainMenus[gActiveMenu]);
	}
    }
  
  task void RecedeMenu()
    {

      struct Menu *m;


      //call Leds.yellowToggle();
      
      if (gActiveMenu == -1)
	return;
      m = &gMainMenus[gActiveMenu];      

      RecedeSelection();      
      
      if (gSelectedItem >= 0)
	clearSelection();

      // the selected item is off the screen
      if (gSelectedItem < m->firstItem)
	{
	  m->firstItem = gSelectedItem ;
	  call Menu.displayMenu(gActiveMenu);
	}
      else if (gSelectedItem >= (m->firstItem + m->numItemsVisible))
	{
	  m->firstItem = gSelectedItem - m->numItemsVisible + 1;
	  call Menu.displayMenu(gActiveMenu);
	}
      else // justr redraw it, no erase
	{
	  if (m->state & MENU_STATE_DYNAMIC)
	    call Menu.displayMenu(gActiveMenu);
	  else
	    drawMenu(&gMainMenus[gActiveMenu]);
	}
    }

  task void signalSelect()
    {
      if ((gActiveMenu < 0) || (gSelectedItem < 0))
	return;
      
      signal Menu.menuSelect(gActiveMenu,gSelectedItem);
      
    }
  
  task void signalEscape()
    {

      signal Menu.menuEscape(gActiveMenu);	
      
    }
  
  async event result_t Buttons.down(uint8_t state,bool isRepeat)
    {
      if (state & BUTTON_ADVANCE)
	post AdvanceMenu();
      else if (state & BUTTON_RECEDE)
	post RecedeMenu();
      else if (state & BUTTON_SELECT)
	post signalSelect();      
      else if (state & BUTTON_ESCAPE)
	post signalEscape();
      return SUCCESS;      
    }
  
  async event result_t Buttons.up(uint8_t state)
    {

      return SUCCESS;      
    }



  /*****************************************
   *  IMAP Interface
   *****************************************/

  event void IMAPLite.updateDone()
  {
  }

  event void IMAPLite.changed( int reason )
  {
  }

  /*****************************************
   *  Time interface
   *****************************************/

  event void Time.tick(  )
    {
    }
  
}
