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
 */

#ifndef MENU_H
#define MENU_H

#include <lcd_types.h>
#include <TosTime.h>


enum {MENU_STATE_NONE,MENU_STATE_UNSELECTABLE,MENU_STATE_UNUSED};
enum {MENU_TYPE_NONE,MENU_TYPE_STRING,MENU_TYPE_PARAM,MENU_TYPE_PARAMLIST,MENU_TYPE_MESSAGE};
#define MAX_ITEMS_PER_MENU 50
#define MAX_MENUS 8
#define MAX_MENU_ITEMS 128

// use empty string for init to show done
// tos_time_t is 64 bytes
struct MenuItem
{
  void *menuItemUID;
  int8_t menuItemState;
  int8_t menuItemType;  
};


struct Menu
{
  uint8_t state;
  uint8_t numItems;
  uint8_t numItemsVisible;
  int8_t ascent;
  int8_t descent;  
  uint8_t font;
  uint8_t firstItem;
  struct MenuItem *pMenuItemList[MAX_ITEMS_PER_MENU];
};






#endif //MENU_H
