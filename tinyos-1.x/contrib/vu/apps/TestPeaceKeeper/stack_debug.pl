#
# Usage: java listen COM1 | perl track.pl
#

$| = 1;

while (<>)
{
    #if (/^data:7e/)
    {
        @tokens = split(",");

        $stack_size = ((hex $tokens[6]) << 8) + (hex $tokens[5]);
        
        print "Maximum stack size : " . $stack_size . "\n";
    }
}
