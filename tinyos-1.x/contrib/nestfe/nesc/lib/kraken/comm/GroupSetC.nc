//$Id: GroupSetC.nc,v 1.1 2005/06/29 05:06:47 cssharp Exp $
includes GroupSet;

module GroupSetC
{
  provides interface StdControl;
  provides interface GroupSet;
  provides interface MsgTestAny as GroupSetTest;
}
implementation
{
#include "BitVecUtils.h"

  groupset_t m_groupset;

  command result_t StdControl.init() {
    memset( &m_groupset, 0, sizeof(m_groupset) );
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command groupset_t GroupSet.getGroup() {
    return m_groupset;
  }

  command void GroupSet.setGroup( groupset_t groupset ) {
    m_groupset = groupset;
  }

  command void GroupSet.andGroup( groupset_t groupset ) {
    int i;
    for( i=0; i<GROUPSET_BYTES; i++ )
      m_groupset.vec[i] &= groupset.vec[i];
  }

  command void GroupSet.orGroup( groupset_t groupset ) {
    int i;
    for( i=0; i<GROUPSET_BYTES; i++ )
      m_groupset.vec[i] |= groupset.vec[i];
  }

  command bool GroupSet.get( uint8_t group ) {
    if( group < GROUPSET_BITS )
      return BITVEC_GET( m_groupset.vec, group ) != 0;
    return FALSE;
  }
  
  command void GroupSet.set( uint8_t group ) {
    if( group < GROUPSET_BITS )
      BITVEC_SET( m_groupset.vec, group );
  }
  
  command void GroupSet.clear( uint8_t group ) {
    if( group < GROUPSET_BITS )
      BITVEC_CLEAR( m_groupset.vec, group );
  }

  command bool_any_t GroupSetTest.passes( TOS_MsgPtr msg ) {
    if( ((msg->addr >> 8) & 0x00ff) == GROUPSET_ADDRESS_PREFIX )
      return call GroupSet.get( msg->addr & 0x00ff );
    return FALSE;
  }
}

