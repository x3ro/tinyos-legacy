# simple script to read packets (ie dumped by serial listener)
# and convert the 6 channel readings into a gnuplot readable format
#  ~/work/tinyos-1.1.10/tools/src/sf/sl /dev/ttyS0 57600 | awk -f ./parse.awk --

function getValFromPair(histr, lowstr)
{
  hi = strtonum("0x"histr);
  low = strtonum("0x"lowstr);
  return low + lshift(hi, 8);
}

{
  addr =  getValFromPair($8, $7);
  chan0 =  getValFromPair($10, $9);
  chan1 =  getValFromPair($12, $11);
  chan2 =  getValFromPair($14, $13);
  chan3 =  getValFromPair($16, $15);
  chan4 =  getValFromPair($18, $17);
  chan5 =  getValFromPair($20, $19);
  parsedfile = sprintf("node-%d.dat", addr);
  dumpfile = sprintf("node-%d.pktdump", addr);
  printf ("%d %s\n", systime(), $0) >> dumpfile;
  printf ("%d %4d %4d %4d %4d %4d %4d\n", systime(), chan0, chan1, chan2, chan3, chan4, chan5) >> parsedfile;
  system(""); # flush output
}
