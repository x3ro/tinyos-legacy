// $Id: spatial_model.h,v 1.1.1.1 2007/11/05 19:10:35 jpolastre Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:             Philip Levis
 *
 */

/*
 *   FILE: spatial_model.h
 * AUTHOR: pal
 *   DESC: Model for mote spatial position.
 *
 *   This file declares the interface used by NIDO for spatial simulation.
 *
 *   A data pointer is provided so that large structures can be
 *   dynamically allocated. Otherwise, the simulation has to allocate
 *   the regions of memory for every model, even though only one is in use.
 */

/**
 * @author Philip Levis
 * @author pal
 */


#ifndef SPATIAL_MODEL_H_INCLUDED
#define SPATIAL_MODEL_H_INCLUDED

typedef struct {
  double xCoordinate;
  double yCoordinate;
  double zCoordinate;
} point3D;

typedef struct {
  void(*init)();
  void (*get_position)(int, long long, point3D*);   // int moteID,
                                                     // long long ftime
                                                     // 3d_point* storage
} spatial_model;

// In the simple model, all motes are randomly placed in {0, 1000} and
// do not move
spatial_model* create_simple_spatial_model();

#endif // SPATIAL_MODEL_H_INCLUDED
