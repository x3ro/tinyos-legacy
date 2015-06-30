// $Id: FcfsArbiterP.nc,v 1.1.1.1 2007/11/05 19:11:27 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

// @author Cory Sharp <cory@moteiv.com>
// Used TOS2 FcfsArbiterP.nc by Kevin Klues as a point of contrast.

#include "reservedQueue.h"

generic module FcfsArbiterP( uint8_t numResources )
{
  provides interface Init;
  provides interface Arbiter;
  provides interface ResourceValidate;
  provides interface Resource[ uint8_t id ];
  provides interface ResourceCmd[ uint8_t id ];
  provides interface ResourceCmdAsync[ uint8_t id ];
  uses interface ResourceConfigure[ uint8_t id ];
  uses interface TaskBasic as GrantTask;
}
implementation
{
  enum {
    COUNT = numResources,
  };

  struct {
    uint8_t head;
    uint8_t tail;
    uint8_t next[COUNT];
  } m_queue;

  uint8_t m_urgentCount;
  uint8_t m_granted;


  ReservedQueue_t* queue() {
    return (ReservedQueue_t*)&m_queue;
  }


  command result_t Init.init() {
    atomic {
      rqueue_init( queue(), COUNT );
      m_urgentCount = 0;
      m_granted = RESOURCE_NONE;
      return SUCCESS;
    }
  }

  event void GrantTask.runTask() {
    uint8_t id;
    atomic id = m_granted;
    if( id != RESOURCE_NONE ) {
      atomic call ResourceConfigure.configure[id]();
      signal ResourceCmdAsync.granted[id]( id );
      signal ResourceCmd.granted[id]( id );
      signal Resource.granted[id]();
    }
  }

  async command bool Arbiter.inUse() {
    atomic return (m_granted != RESOURCE_NONE);
  }

  async command uint8_t Arbiter.user() {
    atomic return m_granted;
  }

  async command bool ResourceValidate.validateUser( uint8_t rh ) {
    atomic return (rh != RESOURCE_NONE) && (rh == m_granted);
  }

  async command void Resource.request[ uint8_t id ]() {
    atomic {
      if( m_granted == RESOURCE_NONE ) {
        m_granted = id;
      }
      else {
        rqueue_push( queue(), id );
        return; //not granted yet
      }
    }
    call GrantTask.postTask();
  }

  async command uint8_t Resource.immediateRequest[ uint8_t id ]() {
    atomic {
      if( m_granted == RESOURCE_NONE ) {
        m_granted = id;
        call ResourceConfigure.configure[id]();
        return id;
      }
    }
    signal Arbiter.requested();
    return RESOURCE_NONE;
  }

  async command void Resource.release[ uint8_t id ]() {
    uint8_t grantMode = 0; // 0=post, 1=post urgent, 2=idle, 3=nothing

    atomic {
      if( id == m_granted ) {
        uint8_t granted = rqueue_pop(queue());

        if( granted == RQUEUE_NONE ) {
          m_granted = RESOURCE_NONE;
          grantMode = 2; //idle, nothing to grant
        }
        else {
          m_granted = granted;
          if( m_urgentCount > 0 ) {
            m_urgentCount--;
            grantMode = 1; //post urgent
          }
        }
      }
      else {
        return; //nothing to release, not idle, nothing to grant
      }
    }

    if( grantMode == 0 ) call GrantTask.postTask();
    else if( grantMode == 1 ) call GrantTask.postUrgentTask();
    else signal Arbiter.idle();
  }


  command void ResourceCmd.request[ uint8_t id ]( uint8_t rh ) {
    bool grant = TRUE;
    atomic {
      if( m_granted == RESOURCE_NONE ) {
        m_granted = rh = id;
        call ResourceConfigure.configure[id]();
      }
      else if( rh != m_granted ) {
        rqueue_push( queue(), id );
        grant = FALSE;
      }
    }
    if( grant ) {
      signal ResourceCmd.granted[id]( rh );
    }
    else {
      signal Arbiter.requested();
    }
  }

  async command void ResourceCmd.deferRequest[ uint8_t id ]() {
    call Resource.request[id]();
  }

  async command void ResourceCmd.release[ uint8_t id ]() {
    call Resource.release[id]();
  }

  async command void ResourceCmdAsync.request[ uint8_t id ]( uint8_t rh ) {
    bool grant = TRUE;
    atomic {
      if( m_granted == RESOURCE_NONE ) {
        m_granted = rh = id;
        call ResourceConfigure.configure[id]();
      }
      else if( rh != m_granted ) {
        rqueue_push( queue(), id );
        grant = FALSE;
      }
    }
    if( grant ) {
      signal ResourceCmdAsync.granted[id]( rh );
    }
    else {
      signal Arbiter.requested();
    }
  }

  async command void ResourceCmdAsync.urgentRequest[ uint8_t id ]( uint8_t rh ) {
    bool grant = TRUE;
    atomic {
      if( m_granted == RESOURCE_NONE ) {
        m_granted = rh = id;
        call ResourceConfigure.configure[id]();
      }
      else if( rh != m_granted ) {
        if( rqueue_pushFront( queue(), id ) )
          m_urgentCount++;
        grant = FALSE;
      }
    }
    if( grant ) {
      signal ResourceCmdAsync.granted[id]( rh );
    }
    else {
      signal Arbiter.requested();
    }
  }

  async command uint8_t ResourceCmdAsync.immediateRequest[ uint8_t id ]( uint8_t rh ) {
    atomic {
      if( m_granted == RESOURCE_NONE ) {
        m_granted = rh = id;
        call ResourceConfigure.configure[id]();
      }
      else if( rh != m_granted ) {
        rh = RESOURCE_NONE;
      }
    }
    if( rh == RESOURCE_NONE )
      signal Arbiter.requested();
    return rh;
  }

  async command void ResourceCmdAsync.release[ uint8_t id ]() {
    call Resource.release[id]();
  }


  default async event void Arbiter.idle() {
  }

  default async event void Arbiter.requested() {
  }

  default event void Resource.granted[ uint8_t id ]() {
  }

  default event void ResourceCmd.granted[ uint8_t id ]( uint8_t rh ) {
  }

  default async event void ResourceCmdAsync.granted[ uint8_t id ]( uint8_t rh ) {
  }

  default async command void ResourceConfigure.configure[ uint8_t id ]() {
  }
}

