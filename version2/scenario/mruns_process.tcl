#
# used to process trace files for multiple runs 
#

set plamda {.005 .01 .02 .03 .04 .05 .06 .07 .08 .09 .1 .11}

set val(txrange) [lindex $argv 0]



for {set i 0} {$i<12} { incr i} {
	

	exec gawk -f scripts/process_mruns.awk  outputs$val(txrange)/output_[lindex $plamda $i]_875kb.txt  >> outputs$val(txrange)/final_output_mruns_875kb.txt &
	

}
