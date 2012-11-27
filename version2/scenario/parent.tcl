#
#
## used to call 2 scene for required number of times based on array length of plamda
#input includes <transmission range> <number of dispatch events> <no of runs>
#
#


set dtr [lindex $argv 0]
set nde	[lindex $argv 1]
set rns [lindex $argv 2]

set plamda {.005 .01 .02 .03 .04 .05 .06 .07 .08 .09 .1 .11}

for {set i 0} {$i<12} { incr i} {
	for {set j 0} {$j<$rns} { incr j} {

		exec ns 2scene.tcl [lindex $plamda $i] 875 $dtr $nde $j &

	}
}
exit 0
