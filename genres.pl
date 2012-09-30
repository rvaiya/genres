#!/usr/bin/env perl
use strict;
use warnings;

if (@ARGV != 1) {
	die "Usage: $0 <Resume Template>\n";
}

my ($filename)=@ARGV;
my ($firstname, $lastname);
my $inlist=0;
my $indiv=0;
my $inbold=0;
my $indate=0;

die "$filename does not exit\n" if ( ! -e $filename );

sub swaptag {
	my $intag=0;
	my $ntags=0;
	my (undef, $match, $tag)=@_;
	return undef if ($tag =~ m/\Q$match\E/); #Prevent infinite loop, incase $tag is a substr of match
	while ($_[0] =~ m/\Q$match\E/) {
		if ($intag) {
			$_[0] =~ s/\Q$match\E/<\/$tag>/;
		} else {
			$_[0] =~ s/\Q$match\E/<$tag>/;
		}
		$intag = $intag ? 0 : 1;
		$ntags++;
	}
	
	return $ntags ? $ntags % 2 : 0;  #If number of tags is even, return 0, else return 1 (error)
}

open MAIN, "<", $filename || die "Unable to open $filename\n";

my $firstline=<MAIN>;
if ($firstline =~ /\\name\s*(.*)\s*\\name/) {
	($firstname, $lastname) = split " ", $1;
} else {
	die "Missing name tage (should be first line) format: \\name <name> \\name";
}

print <<HEAD;
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

<!-- Generated using "genres.pl"
by Raheman Vaiya (see http://github.com/~rvaiya/genres) -->

<head>
	<title>$firstname ${lastname}'s Homepage</title>
	<meta name="keywords" content="$firstname, $lastname, $firstname $lastname,resume"/>
	<meta name="author" content="$firstname $lastname"/>
	<style type="text/css">

	<!--

		html {
			font-size:.9em;
			font-family: sans-serif, Helvetica;
			background-color:white;
		}

		body {
			margin-left:10%;
			margin-right:10%;
		}

		div>h1 {
			font-style: italic; 
			border-bottom:1px solid gray; 
			clear:right;
		}


		i {
			font-style:normal;
			font-size:1em;
			color:darkgray;
			float:right;
		}

		#header ul { 
			list-style-type: none; 
			display:inline-block; 
			margin-bottom:0px;
		}

		h1 { font-size:1.2em; }
		h2 { font-size:1.05em; }
		h3 { font-size:.9em; }

		#rheader { float:right; }
		#lheader { padding-left:0px; }
		#name {text-align: center;}
	-->

	</style>

</head>

<body>

<h1 id="name">
	$firstname $lastname
</h1>

HEAD

my $linenum=0;
while(<MAIN>)
{
	$linenum++;
	if ($_ =~ /\s*\\lheader\s*$/) {
		print "\t</ul>\n" if ($inlist);
		if (!$indiv) {
			print "<div id=\"header\">\n\t<ul id=\"lheader\">\n\n";
		}
		$indiv = $indiv ? 0 : 1;
		$inlist = $inlist ? 0 : 1;
		next;
	}

	if ($_ =~ /\s*\\rheader\s*$/) {
		print "\t</ul>\n" if ($inlist);
		print "</div>\n\n" if ($indiv);
		if (!$indiv) {
			print "\t<ul id=\"rheader\">\n\n";
		}
		$indiv = $indiv ? 0 : 1;
		$inlist = $inlist ? 0 : 1;
		next;
	}


	die "Unmatched \\b tag on line $linenum\n" if (swaptag $_, "\\b", "b");
	die "Unmatched \\d tag on line $linenum\n" if (swaptag $_, "\\d", "i");

	if ($_ =~ m/^\s*(.*?)(\*+)\s*$/) { #Section or subsection 
		 if ($inlist) {
			$inlist=0; 
			print "\t</ul>\n\n";
		 }
		my $headertype=length($2);
		if ($headertype == 1) { 
			print "</div>\n\n" if ($indiv);

			my ($nspc_secname, $secname);
			$nspc_secname=$secname=$1;
			$nspc_secname =~ s/\s//g;

			print "<div id=\"$nspc_secname\">\n";
			print "<h1>$secname</h1>\n\n";
			$indiv=1;
		} else {
			print "\t<h".$headertype.">$1"."</h".$headertype.">\n";
		}
	} 
	
	elsif ($_ =~ m/\s*(\S.*?)\s*$/) { #Non-empty line
		if (!$inlist) {
			print "\t<ul>\n";
			$inlist=1;
		}
		print "\t\t<li>$1</li>\n";
	}
}
print "\t</ul>\n" if ($inlist);
print "</div>\n" if ($indiv);
close MAIN;

print '</body></html>';
