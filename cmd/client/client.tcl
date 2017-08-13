lappend ::auto_path .

package require darksky

proc ::main {} {
	global argv
	if {[llength $argv] != 3} {
		::print_usage
		return 0
	}
	set key [lindex $argv 0]
	set latitude [lindex $argv 1]
	set longitude [lindex $argv 2]

	set darksky [::darksky::new $key]
	set res [::darksky::forecast $darksky $latitude $longitude]
	puts "$latitude,$longitude: $res"

	foreach day [dict get $res forecast] {
		puts "time: [clock format [dict get $day time]]"
	}

	return 1
}

proc ::print_usage {} {
	global argv0
	puts "Usage: $argv0 <key> <latitude> <longitude>"
}

if {[::main]} {
	return 0
}
return 1
