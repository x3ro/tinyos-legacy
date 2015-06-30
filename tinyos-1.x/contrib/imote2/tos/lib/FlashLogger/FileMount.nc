// $Id: FileMount.nc,v 1.1 2006/10/11 00:11:09 lnachman Exp $

/*									tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 *
 * Ported to imote2 by Junaith Ahemed
 */

includes Storage;

interface FileMount 
{
  /**
   * FileMount.fopen
   *
   * Open a file for read / write by passing file name as the parameter.
   * The function calls mount and commit for a particular file and returns
   * SUCCESS | FAIL. Inorder to access the file it is required to wire
   * the BlockRead and BlockWrite interface with the same blockId as the
   * mount interface.
   *
   * @param filename Name of the file to be opened.
   * @return SUCCESS | FAIL
   */
  command result_t fopen (const uint8_t* filename);

  /**
   * FileMount.fclose
   *
   * 
   */
  command result_t fclose (const uint8_t* filename);

  /**
   * Mount.mount
   *
   * Mount a file for reading / writing. The function takes volumeId of
   * a file as paramter which could be obtained through FormatStorage interface. 
   * It is required to  wire the BlockRead and BlockWrite interface with the 
   * same blockId as the mount interface.
   * 
   * @param id Volume id of a file.
   * @return SUCCESS | FAIL
   */  
  command result_t mount(volume_id_t id);

  /**
   * Mount.mountDone
   *
   * Event generated for a mount or an fopen call from the SectorStorage
   * module. The first parameter will be the success code and the second is
   * the volume id of the file.
   * 
   * @param result STORAGE_OK | STORAGE_FAIL
   */  
  event void mountDone(storage_result_t result, volume_id_t id);
}
