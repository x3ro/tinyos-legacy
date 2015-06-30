/*
 * Copyright (c) 2005 Hewlett-Packard Company
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
 * Authors:		Brian Avery
 * Date last modified:  2/14/05
 *
 *
 */

/**
 * Abstraction for menus.
 *
 * @author Brian Avery
 */
includes Menu;

interface Menu {

  /**
   * initialize the menu structure from a rom list 
   *
   * @return SUCCESS always.
   *
   */

  command int makeRomMenu(void *menuList);

  /**
   * make a new menu
   *
   * @return SUCCESS always.
   *
   */

  command int makeMenu();

  /**
   * delete a menu
   *
   * @return SUCCESS if there is one.
   *
   */

  command result_t deleteMenu(int whichMenu);


  
  /**
   * set the menu selection for  the active menu
   *
   * @return SUCCESS if there is an active menu.
   *
   */

  command result_t setMenuSelection(int i);
  
  /**
   * get the menu selection for  the active menu
   *
   * @return selected item (-1 if none)
   *
   */

  command int getMenuSelection(int whichMenu);
  

  /**
   * set the menu rect for all the menus
   *
   * @return SUCCESS always.
   *
   */

  command result_t setMenuRect(Rect *r);		

  /**
   * set the dynamic bit for the menu
   *
   * @return SUCCESS if that menu exists.
   *
   */

  command result_t setDynamic(int whichMenu);		  

  /**
   * set the font for the menu
   *
   * @return SUCCESS always.
   *
   */

  command result_t setFont(int whichMenu,int font);		  


  /**
   * start the menu going/displaying
   *
   * @return SUCCESS always.
   *
   */

   command result_t displayMenu(int which);		

  /**
   * stop the menu going/displaying
   *
   * @return SUCCESS always.
   *
   */

   command result_t undisplayMenu();		

   /**
   * addItem
   * 
   *
   * @return number of item in menu list
   *
   */

   command int addItem(int whichMenu,void *uid,int8_t state, int8_t type);		

  /**
   * delete Item
   * 
   *
   * @return SUCCESS if it existed.
   *
   */

   command result_t  deleteItem(int whichMenu,int item);		



  /**
   * get the uid for an item
   *
   * @return menuuid or null if ne exist pas.
   *
   */

   command void *getMenuUID(int whichMenu,int whichItem);		


  /**
   * get state for the item
   *
   * @return state -1  if it ne exist pas.
   *
   */

   command int getMenuState(int whichMenu,int whichItem);		

  /**
   * set state for the item
   *
   * @return SUCCESS if it exists.
   *
   */

   command result_t setMenuState(int whichMenu,int whichItem, int menuState);		
   
  /**
   * menuSelect
   * 
   *
   * @return which menuItem was selected
   *
   */
  event result_t menuSelect(int whichMenu,int whichItem);

  /**
   * menuSelectionChanged -- a changed event telling you a
   * menu item selection changed (but was not entered yet)
   * 
   *
   * @return SUCCESS
   *
   */
  event result_t menuSelectionChanged(int whichMenu,int whichItem);


  /**
   * menuEscape
   * 
   *
   * @return which menu did we escape from
   *
   */
  event result_t menuEscape(int whichMenu);

}

