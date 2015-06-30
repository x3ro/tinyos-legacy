package IO::Capture::Stderr;
use Carp;
use base qw/IO::Capture/;
use IO::Capture::Tie_STDx;

sub _start {
	my $self = shift;
	$self->line_pointer(1);
    tie *STDERR, "IO::Capture::Tie_STDx";
}

sub _retrieve_captured_text {
    my $self = shift;
    my $messages = \@{$self->{'IO::Capture::messages'}};

     @$messages = <STDERR>;
	return 1;
}

sub _check_pre_conditions {
	my $self = shift;

	return unless $self->SUPER::_check_pre_conditions;

	if (tied *STDERR) {
		carp "WARNING: STDERR already tied, unable to capture";
		return;
	}
	return 1;
}

sub _stop {
    untie *STDERR;
    return 1;
}
1;

=head1 NAME

C<IO::Capture::Stderr> - Capture all output sent to C<STDERR>

=head1 SYNOPSYS

    # Generic example (Just to give the overall view)
    use IO::Capture::Stderr;

    $capture = IO::Capture::Stderr->new();

    $capture->start(); 		# STDERR Output captured
    print STDERR "Test Line One\n";
    print STDERR "Test Line Two\n";
    print STDERR "Test Line Three\n";
    $capture->stop();		# STDERR output sent to wherever it was before 'start'

    # In 'scalar context' returns next line
    $line = $capture->read;
    print "$line";         # prints "Test Line One"

    $line = $capture->read;
    print "$line";         # prints "Test Line Two"

    # move line pointer to line 1
    $capture->line_pointer(1);

    $line = $capture->read;
    print "$line";         # prints "Test Line One"

    # Find out current line number
    $current_line_position = $capture->line_pointer;

    # In 'List Context' return an array(list)
    @all_lines = $capture->read;

    # More useful example 1 - "Using in module tests"
    #  Note: If you don't want to make users install 
    #        the IO::Capture module just for your tests,
    #        you can just install in the t/lib directory
    #        of your module and use the lib pragma in  
    #        your tests. 

    use lib "t/lib";
    use IO::Capture:ErrorMessages;

    use Test::More;

    my $capture =  IO::Capture:ErrorMessages->new;
    $capture->start

    # execute with a bad parameter to make sure get
    # an error.

    ok( ! $test("Bad Parameter") );

    $capture->stop();

    # More useful example 2 - "Use with GUI like Tk"
    #   If you are calling a CPAN module that may
    # print some messages that you don't want going
    # to the shell window, or being lost, you can 
    # capture them and then put to a log file or
    # print in a text frame

    

=head1 DESCRIPTION

The module C<IO::Capture::Stderr>, is derived from the abstract class C<IO::Capture>.
See L<IO::Capture>. The purpose of the module (as the name suggests) is to capture 
any output sent to C<STDOUT>.  After the capture is stopped, the STDOUT filehandle 
will be reset to the previous location. E.g., If previously redirected to a file, when 
C<IO::Capture-E<gt>stop> is called, output will start going into that file again.

Note:  This module won't work with the perl function, system(), or any other operation 
       involing a fork().  If you want to capture the output from a system command,
       it is faster to use open() or backticks.  

       my $output = `/usr/sbin/ls -l 2>&1`;

=head1 METHODS

=head2 new

=over 4

=item *

Creates a new capture object.  

=item *

An object can be reused as needed, so will only need to do one of these. 

=over 4

=item *

Be aware, any data previously captured will be discarded if a new 
capture session is started.  

=back

=back

=head2 start

=over 4

=item *

Start capturing data into the C<IO::Capture> Object.

=item *

Can B<not> be called on an object that is already capturing.

=item *

Can B<not> be called while STDERR tied to an object.  

=item *

C<undef> will be returned on an error.

=back

=head2 stop

=over 4

=item *

Stop capturing data and point STDERR back to it's previous output location
I.e., untie STDERR

=back

=head2 read

=over 4

=item *

In I<Scalar Context>

=over 4

=item *

Lines are read from the buffer at the position of the C<line_pointer>, 
and the pointer is incremented by one.

    $next_line = $capture->read;

=back

=item *

In I<List Context>

=over 4

=item *

The array is returned.  The C<line_pointer> is not affected.

    @buffer = $capture->read;

=back

=item *

Data lines are returned exactly as they were captured.  You may want 
to use C<chomp> on them if you don't want the end of line character(s)

    while (my $line = $capture->read) {
	chomp $line;
	$cat_line = join '', $cat_line, $line;
    }

=back

=head2 line_pointer

=over 4

=item *

Reads or sets the C<line_pointer>.

    my $current_line = $capture->line_pointer;
    $capture->line_pointer(1);

=back

=head1 SUB-CLASSING

=head2 Adding Features

If you would like to sub-class this module to add a feature (method) or two,
here is a couple of easy steps. Also see L<IO::Capture::Overview>.

=over 4

=item 1

Give your package a name

    package MyPackage;

=item 2

Use this C<IO::Capture::Stderr> as your base class like this:

    package MyPackage;

    use base qw/IO::Capture::Stderr/;

=item 3

Add your new method like this

    package MyPackage;

    use base qw/IO::Capture::Stderr/;

    sub grep {
	my $self = shift;

	for $line (
    }

=back

=head1 See Also

L<IO::Capture::Overview>

L<IO::Capture>

L<IO::Capture::Stdout>

L<IO::Capture::ErrorMessages>

=head1 AUTHORS

Mark Reynolds
reynolds@sgi.com

Jon Morgan
jmorgan@sgi.com

=head1 COPYRIGHT

Copyright (c) 2003, Mark Reynolds. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
