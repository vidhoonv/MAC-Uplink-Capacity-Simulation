#
# used to process and produce consilated result
#
#


set plamda {.005 .01 .02 .03 .04 .05 .06 .07 .08 .09 .1 .11}

set val(txrange) [lindex $argv 0]

for {set i 0} {$i<12} { incr i} {
	
	for  {set j 0} {$j<20} { incr j} {
	exec gawk -f scripts/script1.awk -v lamda=[lindex $plamda $i] traces_$val(txrange)/trace_[lindex $plamda $i]_875kb_$j.tr >> outputs$val(txrange)/output_[lindex $plamda $i]_875kb.txt &
	}
}
exit 0
