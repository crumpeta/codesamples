#!/usr/local/bin/php
<?php

/* Return the first word in text file with most letter repetitions. */


/* Place the following text into a file and run the script with the filename as its argument. The word printed should be 'necessitatibus'.

At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat."

On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the charms of pleasure of the moment, so blinded by desire, that they cannot foresee the pain and trouble that are bound to ensue; and equal blame belongs to those who fail in their duty through weakness of will, which is the same as saying through shrinking from toil and pain. These cases are perfectly simple and easy to distinguish. In a free hour, when our power of choice is untrammelled and when nothing prevents our being able to do what we like best, every pleasure is to be welcomed and every pain avoided. But in certain circumstances and owing to the claims of duty or the obligations of business it will frequently occur that pleasures have to be repudiated and annoyances accepted. The wise man therefore always holds in these matters to this principle of selection: he rejects pleasures to secure other greater pleasures, or else he endures pains to avoid worse pains.

*/


# Check if we are running this script from the command line.
if (php_sapi_name() == "cli") {

	if (!isset($argv[1])) {
		print "Usage: $argv[0] <filename>\n";
		exit(-1);
	}
	
	$text_filename = $argv[1];	
	
	print find_most_repetitive_word($text_filename) . "\n";
}



	function find_most_repetitive_word($textfile) {

		$myS = file_get_contents($textfile);	
		
		# Remove non-alpha characters.
		$myS = preg_replace("/[^a-z\s]/i", "", $myS);
		
		# Remove spaces and normalize capitalization.
		$myStrings = preg_split("/\s+/", $myS);
		$myStrings = array_map("trim", $myStrings);
		$myStrings = array_map("strtolower", $myStrings);
		
		
		function stringLengthCompare($s1, $s2) {
			
			$s1_length = strlen($s1);
			$s2_length = strlen($s2);
			
			if ($s1_length == $s2_length) {
				return 0;
			}
			
			return ($s1_length < $s2_length) ? 1 : -1;
		}
		
		# Sort by length of word descending.
		usort($myStrings, "stringLengthCompare");

		$most_repetitive_word = '';
		$longest_letter_repetition = 0;

	    # Collect letter repetition counts
		foreach ($myStrings as $s) {	

			$j = 0;
			$letters = array();
			
			for ($i=0; $i<strlen($s); $i++)  {
							
				if (isset($letters[$s[$i]])) {
					$letters[$s[$i]]++;
				} else {
					$letters[$s[$i]] = 1;
				}
				
			}
			
			arsort($letters, SORT_NUMERIC);
			
			foreach ($letters as $letter => $length) {
				
				if ($length > $longest_letter_repetition) {
					$longest_letter_repetition = $length;
					$most_repetitive_word = $s;
				}
				
			}
			
		}
		
		return $most_repetitive_word;
	}
	

	
?>