#
#to generate upload data values for cdf analysis from multiple runs
#
#
set plamda {.01 .02 .05 .1 .11}
set dtr [lindex $argv 0]
set path "data-cdf/data-cdf-output-mruns-"

set ext ".txt"
for {set i 0} {$i<[llength $plamda]} { incr i} {
	set dest $path$dtr
	set dest $dest[lindex $plamda $i]
	set dest $dest$ext
	for {set j 0} {$j<20} { incr j} {
		exec gawk -f scripts/my-script2.awk -v DTR=$dest traces$dtr/trace_[lindex $plamda $i]_875kb_$j.tr  &
	}	
}
exit 0
