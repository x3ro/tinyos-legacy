echo **Expect nothing
java net.tinyos.matchbox.tools.Dir
java net.tinyos.matchbox.tools.CopyIn test <<!
a test
!
echo **Expect test
java net.tinyos.matchbox.tools.Dir
echo **Expect a test
java net.tinyos.matchbox.tools.CopyOut test

java net.tinyos.matchbox.tools.CopyIn biffer <TestRemote.nc
echo **Expect test, biffer
java net.tinyos.matchbox.tools.Dir

java net.tinyos.matchbox.tools.Rename biffer bigger
echo **Expect test, bigger
java net.tinyos.matchbox.tools.Dir

java net.tinyos.matchbox.tools.CopyOut bigger | grep -v 'Id:'
java net.tinyos.matchbox.tools.CopyOut bigger | diff -s - TestRemote.nc

echo **Expect test, bigger after reset
../reset
sleep 3
java net.tinyos.matchbox.tools.Dir

echo **Expect deltest to appear, first delete to fail, 2nd to succeed
java net.tinyos.matchbox.tools.CopyIn deltest </dev/null
java net.tinyos.matchbox.tools.Dir
java net.tinyos.matchbox.tools.Delete deltest1
java net.tinyos.matchbox.tools.Delete deltest
java net.tinyos.matchbox.tools.Dir -f | grep -v 'bytes free'
