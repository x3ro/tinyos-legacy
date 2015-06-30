#!/usr/bin/perl -w

# Send questions/bugs to 
# kwright@eecs.berkeley.edu

use CGI;
use strict;

my $faqfile = "/usr/local/apache/htdocs/tos/dist2/faq.html";

my $q = new CGI;

print
    $q->header,
    $q->start_html('Add a question/answer to the TinyOS FAQ'),
    $q->h1('Add a Question & Answer to the TinyOS FAQ'),
    $q->em("Enter your question and answer below. You can include HTML tags."),
    $q->start_form,
    "Question: ",
    $q->br,
    $q->textarea(-name=>'question', -rows=>10, -columns=>50),
    $q->p,
    "Answer: ",
    $q->br,
    $q->textarea(-name=>'answer', -rows=>10, -columns=>50),
    $q->p,
    $q->submit,
    $q->end_form,
    $q->hr;

my $question;
my $answer;

if ($q->param()) {

    if (($q->param('answer') && $q->param('question'))) {
	my $entry;

	$question = $q->param('question');
	$answer = $q->param('answer');

	print "<H3>$question</H3>";
	print "$answer";

	open (FAQFILE, "$faqfile") or die "Can't open FAQFILE for reading: $faqfile<BR>\n";
	my @faqfile = <FAQFILE>;
	close(FAQFILE);

	# Open it again so that we can add the current Q&A to the file	
	open (FAQFILE, ">$faqfile") || die "Can't open FAQFILE for writing: $faqfile<BR>\n";

	my $line;
	foreach $line (@faqfile) {
	    # Get the last entry number used
	    if ($line =~ /^<!-- Last number used: (\d+) -->/i) {
		$entry = $1 + 1;
		print FAQFILE "<!-- Last number used: $entry -->\n";

            # see if we're at the last miscellaneous TOC entry
	    } elsif ($line =~ /^<!-- Last miscellaneous toc entry  -->/) {
		# we are, so add our latest question
		print FAQFILE "	    <LI><A NAME=\"TOC-$entry\" HREF=\"faq.html\#SEC-$entry\">$question</A></LI>\n";
		print FAQFILE "<!-- Last miscellaneous toc entry  -->\n"; 
		
            # see if we're at the last miscellaneous SEC entry
	    } elsif ($line =~ /^<!-- Last miscellaneous sec entry  -->/) {
		# we are, so add our latest answer
	 	print FAQFILE "<H3><A NAME=\"SEC-$entry\" HREF=\"faq.html#TOC-$entry\">$question</A></H3>\n";
		print FAQFILE "$answer\n\n";
		print FAQFILE "<!-- Last miscellaneous sec entry  -->";

	    } else {
		# just print the existing line to the updated file
		print FAQFILE "$line";
	    }
	}
	close (FAQFILE);

    } else {
	print 
	    "Please enter a Question",
	    $q->em("and"),
	    "an Answer";
    }
    
} else {
    print "No params.";
}

print $q->end_html;

