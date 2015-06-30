//$Id: GroupSet.nc,v 1.1 2005/06/29 05:06:47 cssharp Exp $

includes GroupSet;

interface GroupSet
{
  command groupset_t getGroup();
  command void setGroup( groupset_t groupset );
  command void andGroup( groupset_t groupset );
  command void orGroup( groupset_t groupset );
  command bool get( uint8_t group );
  command void set( uint8_t group );
  command void clear( uint8_t group );
}

