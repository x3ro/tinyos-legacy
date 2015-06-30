#ifndef __LIST_H__
#define __LIST_H__

/*                                                                      tab:42
 * list.h - Generic embedded linked list functionality.
 *
 * "Copyright (c) 2002 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 *
 * Authors:   Philip Levis, inherited from David Powell?
 * History:   created 1998?, added to TinyOS 5/1/2002
 *
 * Generic circular doubly linked list implementation.
 *
 * list_t is the head of the list.
 * list_link_t should be included in structures which want to be
 *     linked on a list_t.
 *
 * All of the list functions take pointers to list_t and list_link_t
 * types, unless otherwise specified.
 *
 * list_init(list) initializes a list_t to an empty list.
 *
 * list_empty(list) returns 1 iff the list is empty.
 *
 * Insertion functions.
 *   list_insert_head(list, link) inserts at the front of the list.
 *   list_insert_tail(list, link) inserts at the end of the list.
 *   list_insert_before(olink, nlink) inserts nlink before olink in list.
 *
 * Removal functions.
 * Head is list->l_next.  Tail is list->l_prev.
 * The following functions should only be called on non-empty lists.
 *   list_remove(link) removes a specific element from the list.
 *   list_remove_head(list) removes the first element.
 *   list_remove_tail(list) removes the last element.
 *
 * Item accessors.
 *   list_item(link, type, member) given a list_link_t* and the name
 *      of the type of structure which contains the list_link_t and
 *      the name of the member corresponding to the list_link_t,
 *      returns a pointer (of type "type*") to the item.
 *
 * To iterate over a list,
 *
 *    list_link_t *link;
 *    for (link = list->l_next;
 *         link != list; link = link->l_next)
 *       ...
 */

typedef struct list {
	struct list *l_next;
	struct list *l_prev;
} list_t, list_link_t;


#endif /* __LIST_H__ */
