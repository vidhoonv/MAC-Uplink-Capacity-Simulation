#
# used to call 1scene.tcl for the required number of runs 
#input parameters to be given include <exponential_lamda> <cbr rate> <no of runs>
#
#
#
#

set rns [lindex $argv 2]
set el  [lindex $argv 0]
set dr [lindex $argv 1]
puts "E<lamda> $el and  cbr-rate $dr"
for {set i 0} {$i<$rns} {incr i} {
puts "start -$i"
exec ns 1scene.tcl $el $dr $i & 
puts "complete -$i"
}

puts "success"

exit 0

