cd  /opt/tinyos-1.x/contrib/ucbRobo/apps/sensornet/MagMHopRpt
make clean
make mica2dot
testbed-program.pl --testbed=$TOS_TESTBED_CONFIG --download

cd /opt/tinyos-1.x/apps/TOSBase
make clean
make mica2dot
program.sh --download --platform=mica2dot --moteid=0 --networkhost=192.168.0.100

