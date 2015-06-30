/*
 * Authors: Sidsel Jensen & Anders Egeskov Petersen, 
 *          Dept of Computer Science, University of Copenhagen
 * Date last modified: Nov 2005
 *
 */

configuration HPLADCC
{
  provides interface HPLADC;
}
implementation
{
  components HPLADCM;

  HPLADC = HPLADCM;
}
