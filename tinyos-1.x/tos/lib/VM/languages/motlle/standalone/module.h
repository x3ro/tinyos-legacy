/*
 * Copyright (c) 1993-1999 David Gay and Gustav H�llberg
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software for any
 * purpose, without fee, and without written agreement is hereby granted,
 * provided that the above copyright notice and the following two paragraphs
 * appear in all copies of this software.
 * 
 * IN NO EVENT SHALL DAVID GAY OR GUSTAV HALLBERG BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF DAVID GAY OR
 * GUSTAV HALLBERG HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * DAVID GAY AND GUSTAV HALLBERG SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS ON AN
 * "AS IS" BASIS, AND DAVID GAY AND GUSTAV HALLBERG HAVE NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

#ifndef MODULE_H
#define MODULE_H

#include "types.h"

enum { module_unloaded, module_error, module_loading, module_loaded, module_protected };

int module_status(struct global_state *gstate, const char *name);
/* Returns: Status of module name:
     module_unloaded: module has never been loaded, or has been unloaded
     module_error: attempt to load module led to error
     module_loaded: module loaded successfully
     module_protected: module loaded & protected
*/

void module_set(struct global_state *gstate, const char *name, int status);
/* Requires: status != module_unloaded
   Effects: Sets module status after load attempt
*/

int module_unload(struct global_state *gstate, const char *name);
/* Effects: Removes all knowledge about module 'name' (eg prior to reloading it)
     module_status(name) will return module_unloaded if this operation is
     successful
     Sets to null all variables that belonged to name, and resets their status
     to var_normal
   Returns: FALSE if name was protected
*/

void module_load(struct compile_context *ccontext, const char *name);
/* Effects: Attempts to load module name by calling mudlle hook
     Error/warning messages are sent to muderr
     Sets erred to TRUE in case of error
     Updates module status
   Modifies: erred
   Requires: module_status(name) == module_unloaded
*/

void module_require(struct compile_context *ccontext, const char *name);
/* Effects: Does module_load(name) if module_status(name) == module_unloaded
     Other effects as in module_load
*/

enum { var_normal, var_module, var_write };
int module_vstatus(struct global_state *gstate, u16 n, struct string **name);
/* Returns: status of global variable n:
     var_normal: normal global variable, no writes
     var_write: global variable which is written
     var_module: defined symbol of a module
       module name is stored in *name
   Modifies: name
   Requires: n be a valid global variable offset
*/

int module_vset(struct global_state *gstate, u16 n, int status, struct string *name);
/* Effects: Sets status of global variable n to status.
     name is the module name for status var_module
   Returns: TRUE if successful, FALSE if the change is impossible
     (ie status was already var_module)
*/

#endif
