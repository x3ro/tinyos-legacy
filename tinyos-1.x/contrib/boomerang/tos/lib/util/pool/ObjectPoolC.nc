/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * A generic implementation of an pool data structure.
 * <p>
 * The pool is made up of 'object_type' objects and has a maximum
 * capacity of 'size'.  Create a new object pool for each type of data
 * you'd like to manage.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
generic module ObjectPoolC(
			    typedef object_type,
			    uint8_t size
			    )
{
  provides interface ObjectPool<object_type> as Pool;
  provides interface ObjectPoolEvents<object_type> as PoolEvents;
}
implementation {

  // object pointers
  norace object_type* m_pool[size];

  command result_t Pool.insert(object_type* obj) {
    object_type** p;
    object_type** pend = &m_pool[size];
    for( p=m_pool+0; p!=pend; p++ ) {
      if (*p == obj) {
	signal PoolEvents.inserted(obj);
	return SUCCESS;
      }
    }
    for( p=m_pool+0; p!=pend; p++ ) {
      if (*p == NULL) {
	*p = obj;
	signal PoolEvents.inserted(obj);
	return SUCCESS;
      }
    }
    return FAIL;
  }

  command result_t Pool.remove(object_type* obj) {
    object_type** p;
    object_type** pend = m_pool+size;
    for( p=m_pool+0; p!=pend; p++ ) {
      if (*p == obj) {
	*p = NULL;
	signal PoolEvents.removed(obj);
	return SUCCESS;
      }
    }
    return FAIL;
  }

  async command uint8_t Pool.max() {
    return size;
  }

#if 0
  command void Pool.compress() {
    int i,j;
    for (i = 0; i < size - 1; i++) {
      for (j = i+1; j < size ; j++) {
	if ((m_pool[i] == NULL) && (m_pool[j] != NULL)) {
	  m_pool[i] = m_pool[j];
	  m_pool[j] = NULL;
	}
      }
    }
  }
#endif

  async command uint8_t Pool.populated() {
    object_type** p;
    object_type** pend = m_pool+size;
    uint8_t num = 0;
    for( p=m_pool+0; p!=pend; p++ ) {
      if( *p != NULL )
        num++;
    }
    return num;
  }

  async command object_type* Pool.get( uint8_t n ) {
    return m_pool[n];
  }

  async command uint8_t Pool.first() {
    return (m_pool[0] != NULL) ? 0 : call Pool.next(0);
  }

  async command bool Pool.valid( uint8_t n ) {
    return n < size;
  }

  async command uint8_t Pool.next( uint8_t n ) {
    if( n < size ) {
      for( n++; n<size; n++ ) {
        if( m_pool[n] != NULL )
          break;
      }
    }
    return n;
  }
}

