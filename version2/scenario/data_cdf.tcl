#
# to generate upload data values for cdf analysis-cdf 
#

set plamda {.01 .05 .1 .11}
set dtr [lindex $argv 0]
set path "data-cdf/data-cdf-output"

set ext ".txt"
for {set i 0} {$i<4} { incr i} {
	set dest $path$dtr
	set dest $dest[lindex $plamda $i]
	set dest $dest$ext
	exec gawk -f scripts/script2.awk -v DTR=$dest traces$dtr/trace_[lindex $plamda $i]_875kb.tr &
	
}
exit 0
