#!/usr/bin/tclsh

set title [ list "test name" "runtime elab golden" "memory elab golden" "runtime elab revised" "memory elab revised" "runtime compile golden" "runtime compile revised" "runtime set_mode ec" "memory set_mode ec" "runtime map" "memory map" "runtime compare" "memory compare" "overall run time" "mapped inputs" "unmapped inputs golden" "unmapped inputs revised" "mapped outputs" "unmapped outputs golden" "unmapped outputs revised" "mapped states" "unmapped states golden" "unmapped states revised" "mapped internal" "compare result" "compare result type" "compute initial" ]

set ::init [ list "--" "--" "--" "--" "--" "--" "--" "--" "--" "--" "--" "--" "--" "--" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "--" "--" "--" ]

set ::time_var 0
set data [list] 
set some_data 1

proc read_in_file { in_file } {
	global title
	global data	
	set log_file [open $in_file r]
	puts "the file $in_file will be parsed"
	set content [read $log_file]
	close $log_file
    	set lines [split $content \n]	
	set line_ind [ lsearch -all -regexp $lines "-File-" ]
	set data $::init
	if { [ llength  $line_ind ] > 0 && [lindex line_ind 0 ] > 0 } {	
		for { set i 0 } { $i < [ llength $line_ind ] } { incr i } {
			set ind1 [ lindex $line_ind $i]
			if {  [lindex $line_ind $i] == [ lindex $line_ind end ] } {
				parse_file [ lrange $lines $ind1 end ]
			} else {
				set ind2 [lindex $line_ind [ expr {$i + 1 }]]
				parse_file [ lrange $lines $ind1 $ind2 ]  
			}
		}
	} else {
       		parse_file $lines
	}
	
}

proc parse_file { dline } {
	global title
	global data 
	set t_id 0 
	set ind 0
	set ind1 0 
	set flagSt 0
	set flagM 0
	set flagC 0
	set f_exist [file exists "Result1.csv"]
        set mf [ open "Result1.csv" a+ ]
        if { $f_exist == 0 } {
                puts $mf [join $title ", "]
        }
		
	lset data 0 [ lindex [ lindex $dline 0 1] ]
	#puts [lindex $data 0 ]
	for {set i 0} { $i <= [ expr { [llength $dline ] - 1 } ] } {incr i} {
		if { [ string match "*resource?usage*" [ lindex $dline $i] ] == 1 } {
			#puts [lindex $dline $i] 
			set t_id [ resUsage [ lindex $dline $i ] ]
			#puts "t_id is $t_id"
			if { $t_id >= 0 } {
				set m_id [ expr { $t_id +1 } ]
				set system_line [ lindex $dline [expr { $i + 1 }] ]
                set $::time_var 0
                puts "this is a time variableeee $::time_var"
				parse_system_line $system_line $t_id $m_id 0
				switch $t_id {
					7  { set flagM 1 }
					9  { set flagM 0
					     set flagC 1 
				    	     set ind $i  }
					11 { set flagC 0 
				       	     set ind1 $i }
					5  { parse_line [ lindex $dline $i ] $t_id }
					6  { parse_line [ lindex $dline $i ] $t_id }
				}
			}
		}
		if { $flagM == 1 } {
			if { [string match "*inputs:*" [ lindex $dline $i]] == 1 } {
				parse_map_line [lindex $dline $i] 14
			}	
			if { [string match "*outputs:*" [ lindex $dline $i] ] == 1 } {
				parse_map_line [lindex $dline $i] 17 
			}
			if { [ string match "*states:*" [ lindex $dline $i]] ==1  } {
				parse_map_line [lindex $dline $i] 20 
			}
			if { [ string match "*internal:*" [ lindex $dline $i]] ==1  } {
				parse_map_line [lindex $dline $i] 23 
			}
		}
		if { $flagC == 1 } {
			if { [string match "*The designs are*" [ lindex $dline $i ] ] == 1} {
				parse_status_info [lindex $dline $i ] 24
			}
		}
	}
	parse_compare_info [ lrange $dline $ind $ind1 ] 11 12 25
	#puts [ resUsage "resource usage after map"]
	puts $mf [ join $data ", " ]
	close $mf
}

proc parse_line { line t_id } {
	global time_var 
	global data 
	global title
	set c_t 0
	set l [split $line " "]
	set form [lsearch -regexp $l "minutes."]
	#puts " format for line ***** $l ********* is set to  $form "
	if {[ regexp {[0-9]+.?[0-9]+} $l t]} {
		# the calculation below is not work
		#set time_var [expr {$time_var + $t}]
		if {$form > 0 } {
			set ms [split $t ":"]
			set m [ lindex $ms 0]
			set s [ lindex $ms 1]
			set t [ expr {$m * 60 + $s} ]
		}
    		lset data $t_id $t
		#puts " [lindex $title $t_id] is $t"
	 } else {
		 puts "Doesn't find number in $l"
	 }
}

proc parse_status_info { t_line st_id} {
	global data
	global some_data
	if { $some_data == 0 } {
		puts "Synthesis issue"
        	lset data $st_id "Synthesis issue"
	} elseif {[ string match "*The designs are equivalent*" $t_line ] == 1 } {
		puts "Equiv"
        	lset data $st_id "Equiv"
	} elseif { [ string match "*The designs are not*" $t_line ] == 1 } {
		puts "Not Equiv"
        	lset data $st_id "Not Equiv"
	} elseif { [ string match "*Design equivalence inconclusive*" $t_line ] == 1 } {
		puts "inconclusive"
		lset data $st_id "Inconclusive"
	} else {
		puts "Open"
        	lset data $st_id "Open"
	}
}

proc parse_map_line { line m_id } {
	#puts "mapping line $line"
	global time_var 
	global data 
	global title
	set c_t 0
	#puts "parse_line: $line "
	set l [split $line " "]
	set l_index [ lsearch -regexp $l "unmapped" ]
	if { $l_index > 0 &&  $m_id < 23 } {
		set m_id_1 [expr {$m_id + 1}]
		set m_id_2 [expr {$m_id + 2}]
		foreach sl $l {
			if { [string is integer -strict $sl] == 1 } {
				set t $sl
				#puts " [lindex $title $m_id] is $t"
				lset data $m_id $t
			}
		}
		set split_num [split [lindex $l [incr l_index ]] ")/"]
		#puts " [lindex $title $m_id_1] is [lindex $split_num 0]"
    		lset data $m_id_1 [lindex $split_num 0]
		#puts " [lindex $title $m_id_2] is [lindex $split_num 1]"
    		lset data $m_id_2 [lindex $split_num 1]
	} else {
		set t [lindex [split [lindex $l end] "."] 0]
		#puts " [lindex $title $m_id] is $t"
		lset data $m_id $t
	}
}



proc parse_compare_info { sublist t_id m_id c_id } {
	global time_var 
	global data 
	global title
	#puts "sublist is $sublist"
	set time_mem_line [ lsearch -all -inline -regexp $sublist "CPU time" ]
	#puts "time mem line is $time_mem_line" 
	set l [split $time_mem_line " "]
	#puts "l value is $l " 
	set type_line [ lindex $sublist 19 ]
	#puts "type line is $type_line"
	set c_t [lindex [split $type_line "()" ] 1]
	#puts "type line is $type_line"
	# this part shoulld be modified to support full time formal
	foreach sl $l {
		if { [string is integer -strict $sl] == 1 } {
			set m $sl
			#puts " [lindex $title $m_id] is $m"
			lset data $m_id $m
		 } elseif {[string is double -strict $sl] == 1 } {
			set t $sl
			#puts " [lindex $title $t_id] is $t"
			lset data $t_id $t
		}
	}
	if {$t_id < [llength $title] } {
		#puts " [lindex $title $c_id] is $c_t"
		#puts $c_t
		lset data $c_id $c_t
	}
        #puts $data	
}

proc parse_system_line { sublist t_id m_id time_var} {

	#global time_var 
    #set $time_var 0
	global data 
	global title
	set c_t 0
	set l_index [ lsearch -regexp $sublist "System" ]
	puts $l_index
	if { $l_index > 0 } {
		set l [split $sublist " "]
		#puts "----------------------------------"
		#puts $l
		set mid_index [ lsearch -regexp $l min ]
		#puts $mid_index
		if {$mid_index > 0 } {
			set sec1 [lindex $l [expr { $mid_index + 1}]]
			set min1 [lindex $l [expr { $mid_index - 1}]]
    			#set sec [scan $sec1 %d%s n rest]
		 	set min [scan $min1 %d%s n rest]
			set t [ expr $min * 60 + $sec1 ]
			#puts "time is $t"
			set tmp 0
			set mem_index1 [ lsearch -regexp $l "virtMem:" ]
			set mem_index [lsearch -regexp $l "MByte" ]
			if { $mem_index1 > 0 } {
				set tmp $mem_index1
			} 
			if { $mem_index > 0 } {
				set tmp  $mem_index
			}
			set m [lindex $l [expr { $tmp - 1}]]
			#puts $tmp
		} else {
			foreach sl $l {
				if { [string is integer -strict $sl] == 1 } {
					 set m $sl
				} elseif {[string is double -strict $sl] == 1 } {
					 set t $sl
				}
			}
		}
		if {$m_id < [llength $title]} {
			#puts " [lindex $title $m_id] is $m"
			lset data $m_id $m
		}
		if {$t_id < [llength $title]} {
			if {[lindex $title $t_id] == "overall run time"} {
                puts "hiiiiiiiiiiiiiiiiiiiiii"
				lset data $t_id $t
             #   		puts " [lindex $title $t_id] is $t"
			} else {
                puts "hellooooooooooooooooooo" 
				set c_t [expr {$t - $time_var}]
                puts "t is $t"
				puts "c_t is $c_t"
				lset data $t_id $c_t
			#	puts " [lindex $title $t_id] is $c_t"
			}
		}
		set time_var $t
        puts " $time_var is time var " 
	}
} 

proc resUsage { res_us } {
	puts $res_us
	set resource [ split $res_us " _" ]
	set line [ lrange $resource 3 end ]
	if { [ string match "*elab*" $line ] == 1 }  { 
		if { [ string match "*revised*" $line ] == 1 } {
			return [ searchI "elab revised" ]
		} else { 
			return [ searchI "elab golden" ]
		}
	}
	if { [ string match "*compil*" $res_us ] == 1 } {
		if { [ string match "*revised*" $line ] == 1 } {
			return [ searchI "compile revised"]
		} else { 
			return [ searchI "compile golden" ]
		}
	}
	if { [ string match "*ec*" $line] == 1 } {
                return [ searchI "set_mode ec" ]
        }
	if { [ string match "*compare*" $line] == 1 } {
		return [ searchI "compare" ]
	} 
	if { [ string match "*map*" $line] == 1 } {
		return [ searchI "map" ]
	} 
	if { [ string match "*compute*" $line] == 1 } {
		return [ searchI "compute initial" ]
	} else {
		return 
	}
} 

proc searchI { word } {
	global title
	return  [ lsearch -regexp $title $word ]
}
 
if { $argc > 0   } {
    set fp [lindex $argv 0]
        if { [file exists $fp] == 1} {
                read_in_file  $fp 
        } else {
                puts "The file $fp can't be found."
        }
} else {
        puts "There is no any arguments to parse"
}

