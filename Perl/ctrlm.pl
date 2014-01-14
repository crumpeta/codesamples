#!/usr/bin/perl -w 

my $_file = shift || die "No file provided\n";

open(CTRLMF, "$_file");

my $_clean_f = "";
while ( my $_line = <CTRLMF> ){
    $_line =~ s#\cM#\n#g;
    $_clean_f .= $_line;
}

close CTRLMF;
print "$_clean_f";
