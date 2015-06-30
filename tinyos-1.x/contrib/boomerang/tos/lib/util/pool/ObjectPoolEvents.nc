/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Notification of changes that occur in a generic object pool structure.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface ObjectPoolEvents<object_type> {

  /**
   * An object was inserted into the pool.
   */
  event void inserted(object_type* object);
  /**
   * An object was removed from the pool.
   * The pointer is only valid within the event handler and must be
   * copied if the content is required outside of this function's context.
   */
  event void removed(object_type* object);

}
