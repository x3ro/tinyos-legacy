/*                                                                      tab:4
 *
 *
 * "Copyright (c) 2001 and The Regents of the University 
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
 * Authors:             Philip Levis
 *
 */

/*
 *   FILE: spatial_model.c
 * AUTHOR: pal
 *   DESC: Implementation of simple spatial model.
 *
 *   This file declares the interface used by TOSSIM for spatial simulation.
 *
 *   A data pointer is provided so that large structures can be
 *   dynamically allocated. Otherwise, the simulation has to allocate
 *   the regions of memory for every model, even though only one is in use.
 */

#include "spatial_model.h"
#include "tossim.h"
#include "tos.h"

#include <stdlib.h>

point3D* points;

void simple_spatial_init() {
  int i;
  points = (point3D*)malloc(sizeof(point3D) * TOSNODES);

  for (i = 0; i < TOSNODES; i++) {
    points[i].xCoordinate = (double)(rand() % 1000);
    points[i].yCoordinate = (double)(rand() % 1000);
    points[i].zCoordinate = (double)(rand() % 1000);
  }

}

void simple_spatial_get_position(int moteID, long long time, point3D* point) {
  point->xCoordinate = points[moteID].xCoordinate;
  point->yCoordinate = points[moteID].yCoordinate;
  point->zCoordinate = points[moteID].zCoordinate;
}


spatial_model* create_simple_spatial_model() {
  spatial_model* model = (spatial_model*)(malloc(sizeof(spatial_model)));
  model->init = simple_spatial_init;
  model->get_position = simple_spatial_get_position;
  model->data = NULL;

  return model;
}

