#
# Usage: listen.exe | perl compass.pl
#

$| = 1;

while (<>)
{
    if (/^7E/)
    {
        @tokens = split();

        $counter = (hex($tokens[6]) << 8) + hex $tokens[5];
        $magx = (hex($tokens[8]) << 8) + hex $tokens[7];
        $magy = (hex($tokens[10]) << 8) + hex $tokens[9];
        $biasx = hex $tokens[11];
        $biasy = hex $tokens[12];

        
        printf("%5d:    %5d  -  %5d    [biasX: %3d, biasY: %3d]\n", $counter, $magx, $magy, $biasx, $biasy);

    }
}

