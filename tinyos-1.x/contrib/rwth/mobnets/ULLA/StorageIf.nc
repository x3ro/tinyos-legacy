/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */
 
/**
 * Interface for ULLA Storage
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/
 
includes ulla;
includes msg_type;
includes UllaStorage;

interface StorageIf {
	
	/*
	 * Read an attribute of ullaLink class from the storage.
	 */
	command result_t readAttributeFromUllaLink(AttrDescr_t *attrDescr, ullaLinkHorizontalTuple *horizontal_tuple, uint8_t *attr_length, uint8_t *tuple_length); 
	
	/*
	 * Read an attribute of ullaLink class from the storage.
	 */
	command result_t readAttributeFromElse(AttrDescr_t *attrDescr, elseHorizontalTuple *horizontal_tuple, uint8_t *attr_length, uint8_t *tuple_length); 
	
	/*
	 * Read an attribute from the storage.
	 */
  command result_t readAttribute(uint16_t linkid, uint8_t attribute, void *data, uint8_t *length);
	
	/*
	 * Update an attribute from the storage.
	 */
  //command result_t updateAttribute(uint16_t linkid, uint8_t attribute, void *data, uint8_t *length);
	command result_t updateAttribute(AttrDescr_t *attrDescr);
	
	/*
	 * Update an attribute from the storage.
	 */
  command result_t updateMessage(TOS_Msg *update);
	
	/*
	 * Read available links which are present in the storage.
	 * @return numLinks: number of available links in the storage.
	 * @return linkHead: head pointer to links.
	 */
  command result_t readAvailableLinks(uint8_t *numLinks, uint8_t *linkHead);
	
	/*
	 * Add a new link to the storage.
	 */
  command result_t addLink(uint8_t linkid);
	
	/*
	 * Remove a link from the storage.
	 */
  command result_t removeLink(uint8_t linkid);
	
	/*
	 * Check whether there is still an available link in the storage.
	 * FIXME: should check whether there is a next link (instead of returning 0)
	 */
	command result_t hasNextLink();
	
	/*
	 * Fetch the next link in the storage if present.
	 */
	command uint8_t getLink();
}
