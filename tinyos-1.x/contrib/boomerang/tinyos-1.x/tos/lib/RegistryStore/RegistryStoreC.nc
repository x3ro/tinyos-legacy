// $Id: RegistryStoreC.nc,v 1.1.1.1 2007/11/05 19:09:16 jpolastre Exp $

/*									tab:2
 *
 *
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
 *
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author Kamin Whitehouse
 * 
 * This file does not need to be copied into your platform directory,
 * as the RegistryStore.h file does.  However, for convenience this
 * file can be copied as well, and all attributes that are defined to
 * be saved in the the RegistryStore.h file can be declared in this
 * file as well (be using its Attribute interface with the correct
 * type).  That solves the problem that may occur when some
 * applications that use the RegistryStore do not declare all
 * attributes that it stores (which would result in a compiler
 * error).  
 */

configuration RegistryStoreC {
  provides {
    interface RegistryStore @rpc();
  }
}

implementation {
  
  components RegistryStoreM;
  components InternalFlashC;
  components RegistryC;

  RegistryStore = RegistryStoreM;
					    
  RegistryStoreM.InternalFlash -> InternalFlashC;

  RegistryStoreM.AttrBackend -> RegistryC.AttrBackend;
}
