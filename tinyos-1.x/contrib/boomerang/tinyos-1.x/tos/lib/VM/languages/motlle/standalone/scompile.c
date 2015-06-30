/*
 * Copyright (c) 1993-1999 David Gay and Gustav Hållberg
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

#include "mudlle.h"
#include "tree.h"
#include "alloc.h"
#include "types.h"
#include "code.h"
#include "ins.h"
#include "env.h"
#include "global.h"
#include "valuelist.h"
#include "calloc.h"
#include "utils.h"
#include "module.h"
#include "mcompile.h"
#include "compile.h"
#include "mparser.h"
#include "call.h"
#include "table.h"
#include "interpret.h"
#include "scompile.h"

#include <string.h>
#include <stdlib.h>

void scompile_recall(location l, const char *name, fncode fn)
{
  u16 offset;
  mtype t;
  variable_class vclass = env_lookup(l, name, &offset, &t, FALSE);

  if (vclass == global_var)
    mrecall(l, offset, name, fn);
  else if (vclass == closure_var)
    ins1(OPmreadc, offset, fn);
  else
    ins1(OPmreadl, offset, fn);
}
