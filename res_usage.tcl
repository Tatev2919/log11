#!/usr/bin/tclsh

set title [ list "test name" "runtime elab golden" "memory elab golden" "runtime elab revised" "memory elab revised" "runtime compile golden" "runtime compile revised" "runtime set_mode ec" "memory set_mode ec" "runtime map" "memory map" "runtime compare" "memory compare" "overall run time" "mapped inputs" "unmapped inputs golden" "unmapped inputs revised" "mapped outputs" "unmapped outputs golden" "unmapped outputs revised" "mapped states" "unmapped states golden" "unmapped states revised" "mapped internal" "compare result" "compare result type" "compute initial" ]

set res_US [ list  "resource usage after elaborate -golden" \
		"resource usage after elaborate -revised" \
		"resource usage after compile -golden" \
		"resource usage after compile -revised" \
		"resource usage after set_mode ec" \
		"resource usage after map" \
		"resource usage after compare" \
		"resource_usage_after_golden_elaboration" \
		"resource_usage_after_revised_elaboration" \
		"resource_usage_after_golden_compilation" \
		"resource_usage_after_revised_compilation" \
		"resource_usage_after_ec_mode_setup" \
		"resource_usage_after_map" \
		"resource_usage_after_compute_initial_state" \
		"resource_usage_after_compare" ] 
set time_var 0
set data [list] 

proc read_in_file { in_file } {
	global title
	set log_file [open $in_file r]
	puts "the file $in_file will be parsed"
	set content [ read $log_file ]
	set linee [ split $content "\n" ]
	close $log_file
	set t_id 0 
	set flagSt 0
	set flagM 0
	set flagC 0
	for {set i 0} { $i <= [ expr { [llength $linee ] - 1 } ] } {incr i} {
		if { [ string match "*resource_usage*" [ lindex $linee $i] ] == 1 } {
			set t_id [ resUsage [ lindex $linee $i ] ]
			if { $t_id >= 0 } {
				set m_id [ expr { $t_id +1 } ]
				set system_line [ lindex $linee [expr { $i + 1 }] ]
				parse_system_line $system_line $t_id $m_id
				if { $t_id == 7 } {
					set flagM 1
				}
				if { $t_id == 9 } {
					set flagSt 1
					set flagM 0
				}
				if { $t_id == 11} {
					set flagSt 0
					set flagC 1
					puts "-----------------"
				}
			}
		}
		if { $flagSt == 1 } {
			res_type [ lindex $linee $i ]
		}
		if { $flagM == 1 } {
			parse_map_line [lindex $linee $i]
		}
		if { $flagC == 1 } {
			parse_compare_line [lindex $linee $i]		
		}
	}
}

proc res_type { t_line } {
	puts $t_line
	set some_data 0
	if { [ string match "*<<<<<< Check*finished*" $t_line ] == 1 } {
		set sp [split $t_line " ()"]
		puts " Compare result type is [ lindex $sp 4] "
	} 
}

proc status_info { t_line } {
	if { $some_data == 0 } {
		puts "Synthesis issue"
        #	lset data $st_id "Synthesis issue"
	} elseif {[ lsearch -regexp $t_line "The designs are equivalent" ] > 0 } {
		puts "Equiv"
        #	lset data $st_id "Equiv"
	} elseif { [ lsearch -regexp $t_line "The designs are not"] > 0 } {
		puts "Not Equiv"
        #	lset data $st_id "Not Equiv"
	} elseif { [ lsearch -regexp $t_line "Design equivalence inconclusive"] > 0 } {
		puts "inconclusive"
        #	lset data $st_id "Inconclusive"
	} else {
		puts "Open"
        	#lset data $st_id "Open"
	}
}

proc parse_map_line { line } {
	set l [ split $line " ."]	
	puts $line 
	puts "<<<<<<<<<<<<<<<<<<<<<<<<"
	foreach d $l {
		if { [ string  is integer -strict $d ] == 1 } {
			set t [lindex [split [lindex $d end] "."] 0]
			puts " this  is $t"
		}
	}
}

proc parse_compare_line { line } {
	puts "Compare information is "
	puts $line	
}

proc parse_system_line { sublist t_id m_id } {
	global time_var 
	global data 
	global title
	set c_t 0
	set l_index [ lsearch -regexp $sublist "System" ]
	if { $l_index > 0 } {
		set l [split $sublist " "]
		set mid_index [ lsearch -regexp $l min ]
		puts "-----------"
		if {$mid_index > 0 } {
			set sec1 [lindex $l [expr { $mid_index + 1}]]
			set min1 [lindex $l [expr { $mid_index - 1}]]
    			set sec [scan $sec1 %d%s n rest]
		 	set min [scan $min1 %d%s n rest]
			puts "--------------"
			puts $min
			set t [ expr $min * 60 + $sec ]
			set mem_index [lsearch -regexp $l "virtMem:" ]
			set m [lindex $l [expr { $mem_index + 1}]]
		} else {
			foreach sl $l {
				if { [string is integer -strict $sl] == 1 } {
					 set m $sl
					 puts $m
				} elseif {[string is double -strict $sl] == 1 } {
					 set t $sl
					 puts $t
				}
			}
		}
		if {$m_id < [llength $title]} {
			puts " [lindex $title $m_id] is $m"
		#	lset data $m_id $m
		}
		if {$t_id < [llength $title]} {
			if {[lindex $title $t_id] == "overall run time"} {
			#	lset data $t_id $t
                		puts " [lindex $title $t_id] is $t"
			} else { 
				set c_t [expr {$t - $time_var}]
			#	puts $c_t
			#	lset data $t_id $c_t
				puts " [lindex $title $t_id] is $c_t"
			}
		}
		set time_var $t
	}
} 

proc resUsage { res_us } {
	set resource [ split $res_us " _" ]
	set line [ lrange $resource 3 end ]
	puts $res_us
	if { [ string match "*elab*" $line ] == 1 }  { 
		if { [ string match "*revised*" $line ] == 1 } {
			return [ searchI "elab revised" ]
		} else { 
			return [ searchI "elab golden" ]
		}
	}
	if { [ string match "*compil*" $line ] == 1 } {
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

