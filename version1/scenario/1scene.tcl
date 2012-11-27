# ======================================================================
# Define options
# ======================================================================
set val(exp_avg)   [lindex $argv 0]    		;# channel type
set val(cbr_rate) [lindex $argv 1]		; #cbr packet trans rate
set val(nloop)	35				; #no of loops
set val(nr)	[lindex $argv 2]	;#no of runs
set val(plamda) [expr 1*1.0/[lindex $argv 0]] ; #poison lamda
	
# ======================================================================
# Define options
# ======================================================================
set val(chan)         Channel/WirelessChannel  ;# channel type
set val(prop)         Propagation/TwoRayGround ;# radio-propagation model
set val(ant)          Antenna/OmniAntenna      ;# Antenna type
set val(ll)           LL                       ;# Link layer type
set val(ifq)          Queue/DropTail/PriQueue  ;# Interface queue type
set val(ifqlen)       5                       ;# max packet in ifq
set val(netif)        Phy/WirelessPhy          ;# network interface type
set val(mac)          Mac/802_11               ;# MAC type
set val(rp)           DumbAgent                     ;# ad-hoc routing protocol 

set val(x)	     10000			;#no of rows for topo grid
set val(y) 	     1000			;#no of columns for topo grid
set val(bsn)	 1				;#no of base station nodes

set val(APx)   	[expr $val(x)/2]			; #x,y positions where Ap is placed
set val(APy)   	[expr $val(y)/2+39]
set val(vdist)	400	;#vertical distance moved during looping 
set val(dtr)	246.939				; #default trans range
set val(hdist)	[expr 2*$val(dtr)]	;#horizontal distance moved during looping 
set val(hloop_len) [expr $val(vdist)+$val(dtr)*2]	;#$val(dtr)*2 is the horizontal distance -> in total this is half loop length
set val(dspeed)	[expr 24.59*(1-$val(plamda)/.12)]		; # default speed
set val(gen_close) [expr $val(APx)-$val(dtr)-$val(hloop_len)*2]			; #interval_close [expr $val(APx)-$val(dtr)]	
set val(tr_loop) 28				; #loop from which trace should begin
set val(vtime)	[expr $val(vdist)/$val(dspeed)] ;# time to travel vertical distance of loop
set val(htime)	[expr $val(hdist)/$val(dspeed)] ;#time to travel horizontal distance of loop
set val(in_loop_duration) [expr $val(htime)-5] ;#if duration between two received packets is greater than this then node has been in a loop

puts "speed set as:$val(dspeed) $val(plamda)"
#NEW SETTINGS
########################################
Phy/WirelessPhy set CPThresh_  1.69e3
Phy/WirelessPhy set CSThresh_  4.5e-12 
Antenna/OmniAntenna set Z_ 1.0 
Phy/WirelessPhy  set RXThresh_ 7.21506e-11 ; # included after calc from threshold.cc for antenna height=1

#Mac/802_11 set ShortRetryLimit_       5              ;# retransmittions
#####################################
Mac/802_11 set RTSThreshold_                 2346

#generate exponential random numbers and store them
#creating new random number generating seed
# seed the default RNG
global defaultRNG
$defaultRNG seed 9999

	set my_rand_gen1 [new RNG]
	for {set r 0} {$r<$val(nr)} {incr r} {
		$my_rand_gen1 next-substream    ;# seed 0
	}
	##create random variable and associate it with the seed
	set vpos [new RandomVariable/Exponential]
	$vpos set avg_ $val(exp_avg)
	$vpos use-rng  $my_rand_gen1



#creating simulator object
set ns [new Simulator]

#define flow colors
$ns color 1 Blue
$ns color 2 Red


	

	#generating position of vehicles in X-axis 
	set interval_close $val(gen_close)


	set ivd [$vpos value];
	set dummy  [expr $val(APx)-$val(dtr)];
 
	for {set i 0} {$dummy>$interval_close} {} {
		set x_vpos($i)  $dummy  ; #storing in sepearate array
		set ivd [$vpos value] ;
		set dummy [expr  $dummy-$ivd] ;#finding X-pos
		incr i
	}

	puts "No of cars: $i";
	
	# Define options
	# ======================================================================
	set val(mn)         $i                ;# number of mobilenodes

	#calculting cbr start time for induvidual vehicles
	for {set j 0} {$j< $val(mn)} {incr j} {
		set k [expr $val(APx)-$val(dtr)]
		set k [expr ($k-$x_vpos($j))/$val(dspeed)]
		set cbr_start($j) $k
	}

	#calculting cbr stop time for induvidual vehicles
	for {set j 0} {$j< $val(mn)} {incr j} {
		set k [expr $val(APx)+$val(dtr)]
		set k [expr ($k-$x_vpos($j))/$val(dspeed)]
		set cbr_stop($j)  $k
	}


	#puts "transmission details"

	
	#for {set j 0} {$j< $val(mn)} {incr j} {
	#	puts "[expr $j+1]\t$x_vpos($j)\t$cbr_start($j)\t$cbr_stop($j)"
	#}

	#trace details
	set nstr [open traces11/nstrf_$val(exp_avg)_$val(cbr_rate)_$val(nloop)_run-$val(nr).tr w]
	$ns trace-all $nstr

	#creating topo
	set topo	[new Topography]
	$topo load_flatgrid $val(x) $val(y)

	#creating god obj
	create-god [expr $val(mn)+$val(bsn)]

	set chan_1 [new $val(chan)]

	#general node configurations for bsn and mn
	
	# Configure node for bsn (AP)
        $ns node-config -adhocRouting $val(rp)\
                         -llType $val(ll) \
                         -macType $val(mac) \
                         -ifqType $val(ifq) \
                         -ifqLen $val(ifqlen) \
                         -antType $val(ant) \
                         -propType $val(prop) \
                         -phyType $val(netif) \
                         -topoInstance $topo \
			 -wiredRouting OFF \
                         -channel $chan_1 \
                         -agentTrace OFF \
                         -routerTrace OFF \
                         -macTrace ON \
                         -movementTrace OFF

	#creating AP-wired node
	set AP [$ns node ]
	$AP random-motion 0
	$AP set X_ $val(APx)
	$AP set Y_ $val(APy)
	$AP set Z_ 0.00


	#creating vehicles (mn)
	for {set j 0} {$j<$val(mn)} {incr j} {	
		set v_($j) [$ns node]
		#$v_($j) base-station [AddrParams addr2id [$AP node-addr]]   ;# provide each mobilenode with  hier address of its base-station
	
		$v_($j) random-motion 0
		$v_($j) set X_ [expr $x_vpos($j)]
		$v_($j) set Y_ [expr $val(y)/2]
		$v_($j) set Z_ 0.00
		set my_ifq($j) [$v_($j) set ifq_(0)] ;#handle to interface queue
		set my_mac($j) [$v_($j) set mac_(0)] ;# handle to mac 
	
	}

	#traffic generation
	# setup UDP connections
	for {set j 0} {$j<$val(mn) } {incr j} {
		set null_($j) [new Agent/Null]
		$ns attach-agent $AP $null_($j)
	}

	for {set j 0} {$j<$val(mn) } {incr j} {
		set udp_($j) [new Agent/UDP]
		$ns attach-agent $v_($j) $udp_($j)
		$ns connect $udp_($j) $null_($j)
		set cbr_($j) [new Application/Traffic/CBR]
		$cbr_($j) set rate_ $val(cbr_rate)
		$cbr_($j) set packet_size_ 1000 ; #set packet size - application level
		$cbr_($j) attach-agent $udp_($j)
	
	}

	set lpcnt 0
#loop generation - for the vehicles to loop around the AP
	for {set i 0} {$i<$val(nloop)} {incr i} {

		incr lpcnt
		#puts "loop $i --> "
		#fix trace start time
		if {$i== [expr $val(tr_loop)-1] } {
			# ======================================================================
			# Define options
			# ======================================================================
			set val(tr_start) $cbr_start(0)	; #awk start of tracing at this loop
		}
		if {$i== [expr $val(nloop)-1] } {
			# ======================================================================
			# Define options
			# ======================================================================
			set val(stop) [expr $cbr_stop([expr $val(mn)-1])+100]	; #defining end time of simulation
		}
#included for the sake of testing
		if {$i== [expr $val(tr_loop)+6] } {
			# ======================================================================
			# Define options
			# ======================================================================
			set val(tr_stop) [expr $cbr_stop([expr $val(mn)-1])+10]	; #awk start of tracing at this loop
		}


			for {set j 0} {$j<$val(mn)} {	incr j} {
				#new motion chart
				puts "vehicle $j --> $cbr_start($j) to $cbr_stop($j)"
				$ns at $cbr_start($j) "$cbr_($j) start"
				$ns at [expr $cbr_stop($j)-1] "$cbr_($j) stop"
				$ns at [expr $cbr_stop($j)-1] "$my_ifq($j) reset"
				$ns at [expr $cbr_stop($j)-1+0.001] "$my_mac($j) reset"
				if {$i==0} {
				$ns at 0.00 "$v_($j) setdest [expr $val(APx)+$val(dtr)] [expr $val(y)/2] $val(dspeed)" ;#left to right end - horizontal movement 
				} else	{
				$ns at $cbr_start($j) "$v_($j) setdest [expr $val(APx)+$val(dtr)] [expr $val(y)/2] $val(dspeed)" ;#left to right end - horizontal movement 
				}
				$ns at $cbr_stop($j) "$v_($j) setdest [expr $val(APx)+$val(dtr)] [expr $val(y)/2-$val(vdist)] $val(dspeed)" ;# right top to right bottom - verticfal movement
				$ns at [expr $cbr_stop($j)+$val(vtime)] "$v_($j) setdest [expr $val(APx)-$val(dtr)] [expr $val(y)/2-$val(vdist)] $val(dspeed)" ;#right bottom to left bottom - horizontal movement
				$ns at [expr $cbr_stop($j)+$val(vtime)+$val(htime)] "$v_($j) setdest [expr $val(APx)-$val(dtr)] [expr $val(y)/2] $val(dspeed)" ;#left bottom to left top - vertical movement
				set cbr_start($j) [expr $cbr_stop($j)+$val(vtime)*2+$val(htime)] ;# this produces time required to do the looping
				set cbr_stop($j) [expr $cbr_start($j)+$val(htime)]
	
			}
		
		
	}
	puts "No of loops: $lpcnt"
	
	
#	puts "start time:$val(tr_start) stop time:$val(tr_stop) ILD:$val(in_loop_duration)"
	puts "sim end time: $val(stop)"

	$ns at $val(stop) "finish"
	$ns at $val(stop) "puts \"NS2 EXITING...\" ; $ns halt"


#exec gawk -f 51trp2.awk -v MN=$val(mn) -v ILD=$val(in_loop_duration) -v st_time=$val(tr_start) -v end_time=$val(tr_stop) traces875/nstrf_$val(exp_avg)_$val(cbr_rate)_$val(nloop)_run-$val(nr).tr > outputs1/output_$val(exp_avg)_$val(cbr_rate)_$val(nloop)_run-$val(nr).txt ;#to get detailed output of each run
	
exec gawk -f 54trp2.awk -v MN=$val(mn) -v ILD=$val(in_loop_duration) -v st_time=$val(tr_start)  -v end_time=$val(tr_stop)  traces875/nstrf_$val(exp_avg)_$val(cbr_rate)_$val(nloop)_run-$val(nr).tr >> outputs1/final_output_$val(exp_avg)_$val(cbr_rate)_$val(nloop).txt ;#to get consolidated output of all runs
	
	proc finish {} {
	#	global nstr nmtr val
	global nstr  val
	#	close $nmtr
		close $nstr
	#exec nam nmtrf.nam &
	#exec gawk -f 51trp2.awk -v MN=$val(mn) -v ILD=$val(in_loop_duration) -v st_time=$val(tr_start) traces875/nstrf_$val(exp_avg)_$val(cbr_rate)_$val(nloop)_run-$val(nr).tr > outputs1/output_$val(exp_avg)_$val(cbr_rate)_$val(nloop)_run-$val(nr).txt ;#to get detailed output of each run
	
	#exec gawk -f 54trp2.awk -v MN=$val(mn) -v ILD=$val(in_loop_duration) -v st_time=$val(tr_start) traces875/nstrf_$val(exp_avg)_$val(cbr_rate)_$val(nloop)_run-$val(nr).tr >> outputs1/final_output_$val(exp_avg)_$val(cbr_rate)_$val(nloop).txt ;#to get consolidated output of all runs
	
	
	}
	#$ns run
	unset ns
	



