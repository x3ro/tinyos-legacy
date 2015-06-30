/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: RouteState.nc,v 1.7 2003/02/16 14:06:44 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * interface to query info from table
 * Author: Terence Tong
 */
/*////////////////////////////////////////////////////////*/
includes Routing;
interface RouteState {
  command uint8_t getParent();
  command cost_t getCost();
  command uint8_t getHop();
  command uint8_t getNeighborsEstimate(uint8_t *id, uint8_t *quality, uint8_t size);
}

