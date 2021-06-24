# TextTwist by siesta



set WORDLIST_FILE "/home/ge/eggdrop/scripts/TextTwist/wordlist.txt"
set WORDRAND_FILE "/home/ge/eggdrop/scripts/TextTwist/wordrand.txt"
set SCORE_FILE "/home/ge/eggdrop/scripts/TextTwist/scores.txt"



set wordlist {}
set wordrand {}
set anagrams {}
set guessed {}
set word ""
set shuffled_word ""
set secret_word ""
set num_guessed 0
set is_init 1
set is_started 0
array unset players *
set allocated_time 180
set utimerid ""


bind pubm -|- * guess_word

bind pub -|- ".start" start_game
bind pub -|- ".twist" twist_word
bind pub -|- ".list" print_list
bind pub -|- ".left" print_left
bind pub -|- ".score" print_score
bind pub -|- ".top" print_top



proc freq {w} {
	set f {}

	for {set i 0} {$i < 26} {incr i} {
		lset f $i 0
	}

	for {set i 0} {$i < [string length $w]} {incr i} {
		set c [string index [string tolower $w] $i]
		scan $c %c a
		set a [expr {$a - 97}]
		if { $a >= 0 && $a <= 25 } {
			lset f $a [expr {[lindex $f $a] + 1}]
		}
	}

	return $f
}



proc is_zero {f} {
	for {set i 0} {$i < 26} {incr i} {
		if {[lindex $f $i] != 0} {
			return 0
		}
	}
	return 1
}



proc is_anagram {w1 w2} {
	set f1 [freq $w1]
	set f2 [freq $w2]
	if {[is_zero $f1] || [is_zero $f2]} {
		return 0
	}
	for {set i 0} {$i < 26} {incr i} {
		if { [lindex $f1 $i] < [lindex $f2 $i] } {
			return 0
		}
	}
	return 1
}



proc load_words {path} {
	set words {}
	set fin [open $path r]
	while {[gets $fin line] >= 0} {
		lappend words $line
	}
	close $fin
	return $words
}



proc get_anagrams {word wordlist} {
	set anagrams {}
	foreach w $wordlist {
		if {[is_anagram $word $w]} {
			lappend anagrams $w
		}
	}
	return $anagrams
}



proc compare_shuffle {a b} {
	return [expr {int(rand()*3)-1}]
}



proc compare_length {a b} {
	set alen [string length $a]
	set blen [string length $b]
	if {$alen < $blen} {
		return -1
	} elseif {$alen > $blen} {
		return 1
	}
	return 0
}



proc lrandom L {
	lindex $L [expr {int(rand()*[llength $L])}]
}



proc get_list {show} {
	global anagrams
	global guessed
	global secret_word
	set retval ""
	for {set i 0} {$i < [llength $anagrams]} {incr i} {
		if {$i != 0} {
			append retval ", "
		}
		if {$show} {
			if {[string equal $secret_word [lindex $anagrams $i]]} {
				append retval ?
			}
			if {[lindex $guessed $i]} {
				append retval [lindex $anagrams $i]
			} else {
				append retval "\[[lindex $anagrams $i]\]"
			}
		} elseif {[lindex $guessed $i]} {
			if {[string equal $secret_word [lindex $anagrams $i]]} {
				append retval ?
			}
			append retval [lindex $anagrams $i]
		} else {
			set clue ""
			for {set j 0} {$j < [string length [lindex $anagrams $i]]} {incr j} {
				append clue "*"
			}
			append retval $clue
		}
	}
	return $retval
}



proc shuffle_word {w} {
	set a [split $w ""]
	for {set i [expr {[llength $a] - 1}]} {$i > 0} {incr i -1} {
		set j [expr {int(rand()*($i+1))}]
		set t [lindex $a $i]
		lset a $i [lindex $a $j]
		lset a $j $t
	}
	return [join $a ""]
}



proc print_list {nick uhost handle chan text} {
	global is_started
	if {$is_started} {
		putserv "PRIVMSG $chan :\[TEXTTWIST\] [get_list 0]"
	} else {
		putserv "PRIVMSG $chan :\[TEXTTWIST\] $nick, game is not started."
	}
}



proc print_left {nick uhost handle chan text} {
	global is_started
	global anagrams
	global num_guessed
	if {$is_started} {
		set left [ expr {[llength $anagrams] - $num_guessed }]
		putserv "PRIVMSG $chan :\[TEXTTWIST\] $nick, number of words left are $left."
	} else {
		putserv "PRIVMSG $chan :\[TEXTTWIST\] $nick, game is not started."
	}
}



proc twist_word {nick uhost handle chan text} {
	global is_started
	global shuffled_word
	if {$is_started} {
		set shuffled_word [shuffle_word $shuffled_word]
		putserv "PRIVMSG $chan :\[TEXTTWIST\] $shuffled_word"
	} else {
		putserv "PRIVMSG $chan :\[TEXTTWIST\] $nick, game is not started."
	}
}



proc load_scores {} {
	global SCORE_FILE
	global players
	array unset players *
	if {[file exists $SCORE_FILE]} {
		set fin [open $SCORE_FILE r]
		while {[gets $fin line] >= 0} {
			set a [split $line]
			set players([lindex $a 0]) [lindex $a 1]
		}
		close $fin
	}
}



proc save_scores {} {
	global SCORE_FILE
	global players
	set fout [open $SCORE_FILE w]
	foreach key [array names players] {
		puts $fout "$key $players($key)"
	}
	close $fout
}



proc print_score {nick uhost handle chan text} {
	global players
	load_scores
	if {[string equal $text ""] || [string equal $text $nick]} {
		if {[info exists players($nick)]} {
			putserv "PRIVMSG $chan :\[TEXTTWIST\] $nick, your score is $players($nick)."
		} else {
			putserv "PRIVMSG $chan :\[TEXTTWIST\] $nick, your score is 0."
		}
	} elseif {[info exists players($text)]} {
		putserv "PRIVMSG $chan :\[TEXTTWIST\] $nick, $text's score is $players($text)."	
	} else {
		putserv "PRIVMSG $chan :\[TEXTTWIST\] $nick, $text's score is 0."	
	} 
}



proc print_top {nick uhost handle chan text} {
	global players
	
	load_scores
	
	set top [lsort -decreasing -integer -stride 2 -index 1 [array get players]]

	set n [expr {int([llength $top] / 2)}]
	if {$n > 10} {
		set n 10
	}

	if {$n > 0} {
		set output ""
		for {set i 0} {$i < $n} {incr i} {
			if {$i != 0} {
				append output ", "
			}
			append output "[expr {$i+1}]. [lindex $top [expr {$i*2}]] [lindex $top [expr {$i*2+1}]]"
		}

		putserv "PRIVMSG $chan :\[TEXTTWIST\] $output"	
	} else {
		putserv "PRIVMSG $chan :\[TEXTTWIST\] No top scorer"			
	}
}


proc guess_word {nick uhost handle chan text} {
	global is_started
	global anagrams
	global guessed
	global num_guessed
	global word
	global secret_word
	global players
	global utimerid

	if {$is_started} {
		set w ""
		set f 0
		for {set i 0} {$i < [llength $anagrams]} {incr i} {
			set w [lindex $anagrams $i]
			if {[string compare -nocase $text $w]==0} {
				if {[lindex $guessed $i]} {
					putserv "PRIVMSG $chan :\[TEXTTWIST\] $nick, the word '$w' is already guessed." 
				} else {
					lset guessed $i 1
					incr num_guessed 

					set points 0
					set bonus ""

					if {[string compare -nocase $text $secret_word]==0} {
						incr points 100
						append bonus " Secret Word Bonus! "
					} 
				
					if {[string length $text] == [string length $word]} {
						incr points 100
						append bonus " Long Word Bonus! "
					} 
				
					if {$num_guessed == [llength $anagrams]} {
						incr points 100
						append bonus " Last Word Bonus! "
					} 

					incr points [string length $w]

					if {[info exists players($nick)]} {
						incr players($nick) $points 
					} else {
						set players($nick) $points
					}

					save_scores

					putserv "PRIVMSG $chan :\[TEXTTWIST\] $nick, guessed '$w' plus $points points. $bonus" 
					
					break
				}
			}
		}

		if {$num_guessed == [llength $anagrams]} {
			set is_started 0
			killutimer $utimerid
			putserv "PRIVMSG $chan :\[TEXTTWIST\] $nick finished the game!"
			putserv "PRIVMSG $chan :\[TEXTTWIST\] [get_list 1]"
			putserv "PRIVMSG $chan :\[TEXTTWIST\] Game Over"		
		}

	}
}



proc time_up {nick uhost handle chan text} {
	global is_started
	if {$is_started} {
		putserv "PRIVMSG $chan :\[TEXTTWIST\] Time is up!"
		putserv "PRIVMSG $chan :\[TEXTTWIST\] [get_list 1]"
		putserv "PRIVMSG $chan :\[TEXTTWIST\] Game Over"
		set is_started 0
	}
}



proc start_game {nick uhost handle chan text} {
	global WORDLIST_FILE WORDRAND_FILE SCORE_FILE
	global wordlist wordrand	
	global word
	global shuffled_word
	global anagrams
	global guessed
	global num_guessed
	global secret_word
	global is_init
	global is_started
	global allocated_time
	global utimerid

	if {$is_init} {
		set wordlist [load_words $WORDLIST_FILE]
		set wordrand [load_words $WORDRAND_FILE]
		set is_init 0
	}

	if {!$is_started} {

		if {[set thetimer [timerexists time_up]]!=""} {
			killtimer $thetimer
		}

		load_scores

		set word [lrandom $wordrand]

		set anagrams [get_anagrams $word $wordlist]

		set anagrams [lsort -command compare_shuffle $anagrams]
		set anagrams [lsort -command compare_length $anagrams]

		for {set i 0} {$i < [llength $anagrams]} {incr i} {
			lset guessed $i 0
		}

		set num_guessed 0

		set secret_word [lindex $anagrams [expr {int(rand()*[llength $anagrams])}]]

		set shuffled_word [shuffle_word $word]

		putserv "PRIVMSG $chan :\[TEXTTWIST\] $shuffled_word"

		set is_started 1

		set utimerid [utimer $allocated_time [list time_up $nick $uhost $handle $chan $text]]

	} else {
		putserv "PRIVMSG $chan :\[TEXTTWIST\] $nick, game is running."
	}
}




