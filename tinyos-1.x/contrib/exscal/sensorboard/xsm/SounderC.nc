/*
 *
 * Authors: Mike Grimmer
 * Date last modified:  2-19-04
 *
 */
includes sensorboard;
configuration SounderC
{
  provides interface Sounder;
}
implementation
{
  components SounderM;

  Sounder = SounderM;
}
