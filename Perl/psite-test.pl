#!/usr/bin/perl -w
use strict;
#require "parseHTMLFile.pl";
my $initial_dir = shift;

&main($initial_dir);

#=========================================================================

sub main{
    my $initial_dir = shift || "";
    if (!$initial_dir) {
	&printUsage();
	exit;
    }elsif (!&isValidDir($initial_dir)) {
	print "$initial_dir is not a valid directory\n";
	exit;
    }

    my @dirs_to_traverse;
    $initial_dir = &addEndSlash($initial_dir);
    push(@dirs_to_traverse, $initial_dir);

    while (my $current_dir = shift(@dirs_to_traverse)) {
	chdir($current_dir) || die "Could not change dir to $current_dir: $!";
	print "Opening $current_dir\n";
	opendir(DIRHANDLE, $current_dir) || die "Could not open $current_dir: $!";

	my @log_files;
	while (my $filename = readdir(DIRHANDLE)) {
	    if ( (!&isDotDir($filename)) && (-d $filename) ) {
		$filename = "$current_dir$filename";
		$filename = &addEndSlash($filename);
		print "\tFound dir $filename\n";
		push(@dirs_to_traverse, $filename);
	    }elsif (&isLogFile($filename)) {
		push(@log_files, "$current_dir$filename");
		print "\tFound log file $filename\n";
	    }else {
		#ignore file;
	    }
	}
	close(DIRHANDLE);

###################  BEGIN LOG CODE

my $log_line = "";
my $requests = 0;
my $total_cookie_reqs    = 0;
my $non_cookied_requests = 0;
my %date_counts;
my %counts_by_day;
my %counts_by_cookie;
my %store;
my $corrupt_lines = 0;
my $_is_zipped_file = 0;

my %months = ('Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04', 'May' => '05', 'Jun' => '06',
              'Jul' => '07', 'Aug' => '08', 'Sep' => '09', 'Oct' => '10', 'Nov' => 11, 'Dec' => 12 );

	@log_files = reverse sort @log_files;

	while (my $current_logfile = shift(@log_files) ) {
	    print "Reading $current_logfile\n";
            
            my $length;
            my $all_requests = 0;
            if ( $current_logfile =~ /(.*)\.gz$/ ) {
                my $gunzipped_filename = $1;
                #if ( -f $gunzipped_filename ){
                #    print "STATUS: gunzipped filename $gunzipped_filename already exists, renaming $current_logfile";
                #    my $_current_time = time;
                #    $gunzipped_filename = "${gunzipped_filename}_$_current_time";
                #    rename($current_logfile, "$gunzipped_filename.gz") || die "Could not rename $current_logfile";
                #    print " OK\n";
                #    $current_logfile = "$gunzipped_filename.gz";
                #}
                print "STATUS: $current_logfile is a gz file....";
		$_is_zipped_file = 1; 
                #my $output = `gunzip -c $current_logfile`;
		#print $output;
		#exit;
                #print " OK\n";
                #$current_logfile = $gunzipped_filename;
            }else{
		$_is_zipped_file = 0;
	    }

	    if (! $_is_zipped_file) {
                open(LOG, $current_logfile) || die "Could not open $current_logfile: $!";
	    }else{
		open(LOG, "gunzip -c $current_logfile|") || die "Could not open $current_logfile: $!";
	    }
 
	    my $earliest_year  = 9999;
            my $earliest_month = 9999;
            my $earliest_day   = 9999;
            my $latest_year    = 0;
            my $latest_month   = 0;
            my $latest_day     = 0;

#sub next_log_line{

#my $_logfile_handle  = shift;
#my $_current_logfile = shift;
#my $_is_zipped_file  = shift;

 #   if ( $_is_zipped_file )



######### BEGIN LOG LINE ANALYSIS CODE

#$log_line = <LOG>

while ( $log_line = <LOG> ) {
        $requests++;
        if ( ($requests % 20_000) == 0) {
                print "Processed $requests requests...\n";
        }

        if ($log_line =~ /^[a-zA-Z]{3}\s/){
                #matched 1st line of logfile
                print "CORRUPT LINE: $log_line";
                $corrupt_lines++;
                next;
        }

        #do a quick check to see if there is a cookie on this line,
	# if no cookie, skip this line.
        if ($log_line) {
           # DEBUG: print "LINE NOT EMPTY: $log_line_copy\n";
            if ( $log_line =~ m/"([^"]+)"$/ ) {
                #it matched possible cookie pattern, continue
		#$current_cookie = $1;
                #print "COOKIE DEBUG : $log_line_copy";
            } else {
                #print "CORRUPT LINE: skipping $log_line";
                #no cookie here, skip.
                $corrupt_lines++;
                next;
            }
        }


        my $current_date = "";  
        my $day = "";
        my $month = "";
        my $year = "";        
        {$log_line =~ m#(\d{2})/(\w{3})/(\d{4})#;
        $day   = $1;
        $month = $months{$2};
        $year  = $3;
        }
        $current_date = "$day-$month-$year";

        if ($current_date) {
            $current_date =~ s[/][-]g;
            $date_counts{$current_date}++;
        }

	my $reset = 0;
        if ($year < $earliest_year) {
            $reset = 1;
        } elsif ( ($month < $earliest_month) && ($year == $earliest_year) ) {
            $reset = 1;
        } elsif ( ($day < $earliest_day) && ($month == $earliest_month) && ($year == $earliest_year) ) {
            $reset = 1;
        }
 
        if ($reset) {
            $earliest_year  = $year;
            $earliest_month = $month;
            $earliest_day   = $day;
            my $month_text = getMonthText($earliest_month);
            #print "STATUS: reset earliest date [ $month_text $earliest_day, $earliest_year ]\n";
        }

        $reset = 0;
        if ($year > $latest_year) {
                $reset = 1;
        } elsif ($month > $latest_month) {
                $reset = 1;
        } elsif ($day > $latest_day) {
                $reset = 1;
        }

        if ($reset) {
                $latest_year  = $year;
                $latest_month = $month;
                $latest_day   = $day;
                my $month_text = getMonthText($latest_month);
                #print "STATUS: reset latest date [ $month_text $latest_day, $latest_year ] [\t$requests\t]\n";
                #$requests = 0;
        }



 	my $current_cookie = "";
        my $log_line_copy  = $log_line;
         
        {#get rid of the newline
        $log_line =~ s/\n//;
         if (! $log_line){
                print "BLANK LINE: line \#$requests\n";
                next;
         }
        }

        {#get rid of ips - works
        $log_line =~ s/^([\w\.-]+)\s+//;

        if ($1 eq '-') {
#                print "CORRUPT LINE: $log_line_copy";
                $corrupt_lines++;
                next;
        }
        }
  
	{#get rid of %l - works 
        $log_line =~ s/^([\w-]+\s+)//; 
        }

        {#get rid of %u - works
        $log_line =~ s/^([\w-]+\s+)//;
        }

        {#get rid of datetime - works
        $log_line =~ s/^(\[[^\]]+\])\s+//;
        }

        #get rid of page/image request - works
        my $req = "";
        {
        if ( $log_line =~ s/^"(GET|POST|HEAD|-)([^"]*")\s+// ) {
           $req = $1 || "";
        } else {
           $req = "";
        }
        }
 
	if ( ($req eq '-') || ($req eq "") ){
 #               print "CORRUPT LINE: $log_line_copy";
                $corrupt_lines++;
                next;
        }

                
        #get rid of http status code - works
        my $corrupt = 0;
        {
                if ( !( $log_line =~ s/^(\d{3}\s+)// ) ) {
  #                      print "CORRUPT LINE: $log_line_copy";
                        $corrupt = 1;
                }
        } 
        if ($corrupt) {
                $corrupt_lines++;
                next;
        }
 
	{#get rid of transfer size - works
         if (! ( $log_line =~ s/^(\d+|-)\s*// ) ) {
   #          print "CORRUPT LINE: $log_line_copy";   
             $corrupt = 1;
         }
        }
        if ($corrupt) {
                $corrupt_lines++;
                next;
        }
         
                
        {#get rid of referrer
         if ( !($log_line =~ s/^("[^"]+")\s+//) && ($log_line ne "") ) {
    #        print "CORRUPT LINE: $log_line_copy";
             $corrupt = 1;
         }
        }
        if ($corrupt) {
                $corrupt_lines++;
                next;
        }
 
	{
        #get rid of browser info
        $log_line =~ s/^("[^"]*"\s*)//;
          #  if ($1) { 
          #      $store{$1}++;   
          #  }else { 
          #      $store{'NO REFERRER'}++;
          #  }
        }       
 
	#get cookie
        if ($log_line) {
           # DEBUG: print "LINE NOT EMPTY: $log_line_copy\n";
            if ( $log_line =~ m/"([^"]+)"/ ) {
                $current_cookie = $1;
                #print "COOKIE DEBUG : $log_line_copy";
            } else {
                 #print "CORRUPT LINE: $log_line_copy";
                $corrupt_lines++;
                next;
            }
        }else {
            $current_cookie = "";
#           print "empty logline\n";   
        }
          
        #print "\n"; 
        if ($current_cookie eq '-') { $current_cookie = ""; }
        if ($current_cookie) {
            $counts_by_day{$current_date}{$current_cookie} += 1;
#            $counts_by_day{$current_date}{$current_cookie}++;
            $counts_by_cookie{$current_cookie} += 1;

	    $total_cookie_reqs++;
        if ( ($total_cookie_reqs % 5000) == 0) {
                print "STATUS : Processed $total_cookie_reqs cookies...\n";
        }


        } else {
            $non_cookied_requests++;
        }
}
########## END LOG LINE ANALYSIS CODE 
 	    close LOG;
	
 my %server_names = ('orange' => 1, 'brown' => 1, 'khaki' => 1, 'slate' => 1, 'linen' => 1, 'purple' => 1,
                                        'indigo' => 1, 'yellow' => 1, 'violet' => 1, 'black' => 1, 'ebony' => 1,
                                        'wheat' => 1, 'beige' => 1, 'olive' => 1, 'white' => 1, 'ivory' => 1);

                #get rid of everything but the filename
                $current_logfile =~ s#(.*/)##;
                my $path = $1;

                #search for a machine name in the log file name
                my $current_machine = "";
                foreach my $mach_name (keys %server_names) {
                        if ( $current_logfile =~ /$mach_name/ ) {
                                $current_machine = $mach_name;
                                last;
                        }
                }

                #was a machine name found ?
                if ($current_machine eq "" ){
                        print "STATUS: Did not recognize machine name for this file : $current_logfile";
                        $current_machine = "UNKNOWN-MACHINE";
                }

		my $_zip_ext = "";
		if ($_is_zipped_file){
		   $_zip_ext = ".gz";
		}

		my $ungz_rec_name    = "$latest_year-$latest_month-${latest_day}_$current_machine";
                my $recommended_name = "$latest_year-$latest_month-${latest_day}_$current_machine$_zip_ext";
                my $message          = "\nSTATUS: Should rename $current_logfile to $recommended_name\n";
                
                if ($recommended_name eq $current_logfile) {
                        $message = "OK\n";
                }else {

                        if (-e "$path$recommended_name") {
                                $message .=  "STATUS: Cant rename $current_logfile, $recommended_name already exists\n";
                                my $_renaming = 1;
                                while ( $_renaming ) {
                                    my $_new_rec_name = "$path${ungz_rec_name}_$_renaming$_zip_ext";
                                    if ( -e $_new_rec_name ) {
                                        $_renaming++;
                                    }else{
                                        $message .=  "STATUS: Renaming $current_logfile to $_new_rec_name...\n";
                                        my $success = rename "$path$current_logfile", $_new_rec_name;
                                        if ($success) {
                                            $message .="STATUS: Renaming successful\n";
                                            $current_logfile = $_new_rec_name;
                                        }else{
                                            $message .= "STATUS: Renaming failed\n";
                                        }
                                        $_renaming = "";
                                    }
                                }

                        } else {
                                $message .=  "STATUS: Renaming $current_logfile to $recommended_name...\n";
                                my $success = rename "$path$current_logfile", "$path$recommended_name";
                                if ($success) {
                                         $message .="STATUS: Renaming successful\n";
                                         $current_logfile = $recommended_name;
                                }else{
                                        $message .= "STATUS: Renaming failed\n";
                                }
                        }
                }
                print "\nSTATUS: $current_logfile spanned the following dates: ";
                $earliest_month = getMonthText($earliest_month);
                my $latest_month_text   = getMonthText($latest_month);
                print "$earliest_month $earliest_day, $earliest_year TO $latest_month_text $latest_day, $latest_year $message";

                close LOG;
                #print "STATUS: gzipping $current_logfile...";
                #`gzip $current_logfile`;
                #print " OK\n";



}

	print "\nRequests per day:\n";
	my $total_requests = 0;
	foreach my $date (sort (keys %date_counts)) {
        	print "$date : $date_counts{$date} requests\n";
        	$total_requests += $date_counts{$date};
	}
            
print "\n";
#foreach my $cookie (keys %counts_by_cookie) {
#       print "Cookie: $cookie : $counts_by_cookie{$cookie} requests\n";
#}

print "\nCookied user:\n";
foreach my $day (sort (keys %counts_by_day)) {
        my %daily_uniques = %{$counts_by_day{$day}};
        my $daily_unique_count = keys %daily_uniques;
        print "$day : $daily_unique_count unique visitors\n";
}
         
my $cookie_total = (keys %counts_by_cookie);
#my @cookie_array = (keys %counts_by_cookie);
#print "\nCookie array @cookie_array\n";
print "\nSummary:\n";
print "$cookie_total unique users\n";
print "$non_cookied_requests requests did not use cookies\n";
print "$corrupt_lines corrupt lines\n";
print "Total Requests: $total_requests\n";
print "Total Lines: $requests\n";


#print "\n\n DEBUG\n";
#foreach my $key (keys %store) {
#       print "$key : $store{$key}\n";
#}


############ END LOG CODE 

    }
}

#-------------------------------------------------------------------
sub getMonthText{
        my $month_number = shift;
my %months = ('Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04', 'May' => '05', 'Jun' => '06',
              'Jul' => '07', 'Aug' => '08', 'Sep' => '09', 'Oct' => 10, 'Nov' => 11, 'Dec' => 12 );

        my $month_text = "";
        foreach my $month (keys %months) {
                if ($months{$month} == $month_number){
                        $month_text = $month;
                        last;
                }
        }
        return $month_text;
}




#----------------------------------------------------------------------

sub isDotDir{
    my $file = shift || "";
    if ( (-d $file) && ( ($file eq '.') || ($file eq '..')) ) {
	return 1;
    }else{
	return 0;
    }
}

#---------------------------------------------------------------------

sub isValidDir{
    my $dir = shift || "";
    return 1;
}

#--------------------------------------------------------------------

sub printUsage{
    print "Usage: psite <initial dir (full pathname)>\n";
}

#-------------------------------------------------------------------

sub addEndSlash{
    my $dir = shift;
    if ( !($dir =~ /\/$/) ) {
	$dir = "$dir/";
    }
    return $dir;
}

#-------------------------------------------------------------------

#sub parseHTMLFile{
#    my $html_file = shift || "";
#    my @file_sections;
#    if ($html_file) {
#	@file_sections = &parseHTMLFile($html_file);
#    }
#    return @file_sections;
#}

#-------------------------------------------------------------------

sub saveFileSections{
    my @file_sections = @_;
    #save this array as tab delimited fields in specified file
    open(FILEH, '>>/home/alan/out.txt');
    for (my $i = 0; $i <= $#file_sections; $i++){
      print FILEH "\t$file_sections[$i]";
    }
    print FILEH "\n";
    close FILEH;
}

#------------------------------------------------------------------

sub isLogFile{
    my $log_file = shift || die "No file provided";
    if ( -f $log_file ){
	return 1;
    }else{
	return 0;
    }
}




