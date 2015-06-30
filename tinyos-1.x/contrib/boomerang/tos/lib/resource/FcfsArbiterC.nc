// $Id: FcfsArbiterC.nc,v 1.1.1.1 2007/11/05 19:11:27 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Please refer to TEP 108 for more information about this component
 * and its intended use. This arbiter has some resemblence to the
 * FcfsArbiterC from TinyOS 2.x by Kevin Klues.  
 * <p> 
 *
 * This component provides the Arbiter, Resource, ResourceCmd,
 * ResourceCmdAsync, and ResourceValidate interfaces.  Controller
 * interfaces and uses the ResourceConfigure interface as described in
 * TEP 108.  It provides arbitration to a shared resource in an FCFS
 * fashion.  An array is used to keep track of which users have put in
 * requests for the resource.  Upon the release of the resource by one
 * of these users, the array is checked and the next user (in FCFS
 * order) that has a pending request will ge granted control of the
 * resource.  If there are no pending requests, then the resource
 * becomes idle and any user can put in a request and immediately
 * receive access to the Resource.
 *
 * @param numResources The maximum number of resources this arbiter is managing
 * 
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
generic configuration FcfsArbiterC( uint8_t numResources )
{
  // reserve slot 0 for "no resource" by allocating with unqiueCount(str)+1 and unique(str)+1

  provides interface Init;
  provides interface Arbiter;
  provides interface ResourceValidate;
  provides interface Resource[ uint8_t id ];
  provides interface ResourceCmd[ uint8_t id ];
  provides interface ResourceCmdAsync[ uint8_t id ];
  uses interface ResourceConfigure[ uint8_t id ];
}
implementation
{
  components new FcfsArbiterP( numResources ) as ArbiterP;
  components new TaskBasicC() as GrantTaskC;

  Init = ArbiterP;
  Arbiter = ArbiterP;
  ResourceValidate = ArbiterP;
  Resource = ArbiterP;
  ResourceCmd = ArbiterP;
  ResourceCmdAsync = ArbiterP;
  ResourceConfigure = ArbiterP;

  ArbiterP.GrantTask -> GrantTaskC;
}

