/*
  Interface for accessing flash with the page abstraction.

  Copyright (C) 2004 Klaus S. Madsen <klaussm@diku.dk>
  Copyright (C) 2006 Marcus Chang <marcus@diku.dk>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/



interface FlashAccess {

  command uint16_t firstUsablePage();
  command uint16_t lastUsablePage();

  /**
   * Read a page from the flash. 
   *
   * @param page_no The page to read from.
   * @param page    A buffer to hold the page bring read.
   * @return SUCCESS, the page could be read
   */
	command result_t read(uint16_t page_no, void *page);
	event void readReady(uint16_t page_no, void *page, uint16_t length);

  /**
   * Erase the sector holding the page in the flash.
   *
   * @param page_no The page inside the sector.
   * @return SUCCESS, the sector was erased.
   */
  command result_t erase(uint16_t page_no);
  event void eraseDone(uint16_t page_no);

  /**
   * Erase the entire flash.
   *
   * @return SUCCESS, the flash was erased.
   */
  command result_t eraseAll();
  event void eraseAllDone();

  /**
   * Write a page to the flash
   *
   * <p>Note this function does not clear the page before the
   * write. This must be done by calling erase</p>
   *
   * @param page_no The page to write
   * @param page    A buffer containing the contents to write
   * @result SUCCESS, the self-programming has successfully finished.
   */
  command result_t write(uint16_t page_no, void *page); 
  event void writeDone(uint16_t page_no, void *page);

}
