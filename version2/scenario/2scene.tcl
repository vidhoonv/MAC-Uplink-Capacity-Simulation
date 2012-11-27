# ======================================================================
# Define options
# ======================================================================

if {$argc != 5} {
	puts	"Usage: $argv0 vehicle_lambda cbr_rate tx_range no_dispatches no_runs"
	exit
}

set val(plamda)   [lindex $argv 0]    		; #vehicle lambda
set val(cbr_rate) [lindex $argv 1]		; #cbr packet trans rate
set val(txrange)  [lindex $argv 2]		; #transmission range
set val(nde)	[lindex $argv 3]	;#no of dispatch events to determine stop time
set val(nr)	[lindex $argv 4]	;#run number

set val(exp_avg) [expr 1*1.0/[lindex $argv 0]] ; #poison lamda
	
#creating simulator object
set ns [new Simulator]

#define flow colors
#$ns color 1 Blue
#$ns color 2 Red


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

set val(APshift)	39
set val(APx)   	[expr $val(x)/2]			; #x,y positions where Ap is placed
set val(APy)   	[expr $val(y)/2+$val(APshift)]

set val(dtr)	[expr sqrt([expr  $val(txrange)*$val(txrange)-$val(APshift)*$val(APshift)] )] 		; #default trans range
set val(hdist)	[expr 2*$val(dtr)]	;#horizontal distance moved during looping 

set val(l_jam) 0.12 	;#lamda jam
set val(dspeed)	[expr 24.59*(1-$val(plamda)/$val(l_jam))]		; # default speed

set val(gen_close) [expr $val(dtr)*2*$val(l_jam)*1.5] ;#[expr $val(APx)-$val(dtr)+$val(dtr)*2]			; #interval_close [expr $val(APx)-$val(dtr)] this is a blind decision -> I still dint find any equations 	

set val(htime)	[expr $val(hdist)/$val(dspeed)] ;#time to travel horizontal distance of loop

set val(vqh) 0; # vehicle queue head
set val(vqt) 0; #vehicle queue tail	 
set val(rspeed) 30000 ; #high speed while returning back to entry point

set val(jammed) 0; #to detect jamming

set val(cbr_packet_length) 1000; #packet length

set val(arp_speed) [expr 2*$val(dtr)/(($val(cbr_packet_length)*8*1.0/($val(cbr_rate)*1000))*10)]
#set val(dtr_usr) [lindex $argv 2]
set kb "kb"
set val(cbr_rate) $val(cbr_rate)$kb 

set val(first_exit_done) 0
set val(no_dispatched) 0

#trace details
	set nstr [open traces$val(txrange)/trace_$val(plamda)_$val(cbr_rate)_$val(nr).tr w]
	$ns trace-all $nstr
	

#NEW SETTINGS
########################################
Phy/WirelessPhy set CPThresh_  1.69e3
Phy/WirelessPhy set CSThresh_  4.5e-12 
Antenna/OmniAntenna set Z_ 1.0 
Phy/WirelessPhy  set RXThresh_ 7.21506e-11 ; # included after calc from threshold.cc for antenna height=1

#Mac/802_11 set ShortRetryLimit_       5              ;# retransmittions
#####################################
Mac/802_11 set RTSThreshold_                 2346
#Mac/802_11 set dataRate_ 11.0e6 
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

#generating position of vehicles in X-axis 
set interval_close $val(gen_close)

#set ivd 0;
#	set dummy  [expr $val(APx)-$val(dtr)];

#	for {set i 0} {$i<$interval_close } {} { #2R'L-Jam condition
#		set x_vpos($i)  $ivd ; #storing in seperate array
#		set ivd [$vpos value] ;
#		set dummy [expr  $dummy+$ivd] ;#finding X-pos
#		incr i
#	}
# Define options
# ======================================================================
set val(mn)         [expr round($interval_close)]                ;# number of mobilenodes
set val(vqh)	   0	;#vehicle queue initialization
set val(vqt)	   [expr $val(mn)-1] ;#vehicle queue initialization   	

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
	
puts "no of cars: $val(mn)"

#creating vehicles (mn)
for {set j 0} {$j<$val(mn)} {incr j} {	
	set v_($j) [$ns node]
	#$v_($j) base-station [AddrParams addr2id [$AP node-addr]]   ;# provide each mobilenode with  hier address of its base-station

	$v_($j) random-motion 0
	$v_($j) set X_ [expr $val(APx)-$val(dtr)]
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
	$cbr_($j) set packet_size_ $val(cbr_packet_length) ; #set packet size - application level
	$cbr_($j) attach-agent $udp_($j)
}

set arp_cbr_start_(0) 0.00
set arp_cbr_stop_(0) [expr $arp_cbr_start_(0)+2*$val(dtr)/$val(arp_speed)]
for  {set i 1} {$i<$val(mn) } {incr i} {
	set arp_cbr_start_($i) $arp_cbr_stop_([expr $i-1])
	set arp_cbr_stop_($i) 	[expr $arp_cbr_start_($i)+2*$val(dtr)/$val(arp_speed)]
}

for  {set i 0} {$i<$val(mn) } {incr i} {
	$ns at $arp_cbr_start_($i) "arp_motion_start $i" 
			
	$ns at $arp_cbr_stop_($i) "arp_motion_stop $i" 
}

$ns at [expr round($arp_cbr_stop_([expr $val(mn)-1])+1)] "entry_action"

proc arp_motion_start {vid} {
	global val cbr_ v_
	$v_($vid) setdest [expr $val(APx)+$val(dtr)] [expr $val(y)/2] $val(arp_speed) ;#left to right end - horizontal movement 
	$cbr_($vid) start
}

proc arp_motion_stop {vid} {
	global val cbr_ v_ my_mac my_ifq
	$cbr_($vid) stop
	$v_($vid) setdest [expr $val(APx)-$val(dtr)] [expr $val(y)/2] $val(rspeed) 
	$my_ifq($vid) reset
	$my_mac($vid) reset
}

proc dispatch_vehicle {vid} {
	global val  v_ ns
	$v_($vid) setdest [expr $val(APx)+$val(dtr)] [expr $val(y)/2] $val(dspeed)  ;#left to right end - horizontal movement 	
}

proc exit_action {vid} {
	global val  cbr_ v_ my_ifq my_mac ns nstr

	if {$val(first_exit_done) == 0} {
		puts $nstr "START"
		set val(first_exit_done) 1
	}

	set tail_vehicle $val(vqt)
	if {$vid==[expr ($tail_vehicle+1)%$val(mn)]} {
		$cbr_($vid) stop
		$my_ifq($vid) reset
		$my_mac($vid) reset
		$v_($vid) setdest [expr $val(APx)-$val(dtr)] [expr $val(y)/2] $val(rspeed) 
		
		

		$ns at [expr [$ns now]+0.05] "puts $nstr \"VEHICLE [expr $vid +1] RETURNED\""

		set val(jammed) 0

		set val(vqt) $vid
				
	} else {
		puts "error"
	}
		
}


proc entry_action {} {
	global val v_ cbr_ exit_action ivd vpos ns nstr

	if {$val(no_dispatched) == $val(nde)} {
		puts $nstr "STOP"
		$ns at [expr [$ns now] +0.01] finish
	}

	set nxt_vehicle $val(vqh)
	if {$val(jammed)==0} {
		dispatch_vehicle $nxt_vehicle
		$cbr_($nxt_vehicle) start
			
		puts $nstr "VEHICLE [expr $nxt_vehicle +1] DISPATCHED"

		$ns at [expr [$ns now]+2.0*$val(dtr)/$val(dspeed)] "exit_action $nxt_vehicle"
		
		if {$val(first_exit_done)} {
			incr	val(no_dispatched)
		}
		if {$val(vqh)==$val(vqt)} {
			;#queue empty for next dispatch
			puts "empty queue"
			set val(jammed) 1;
		} 
		set val(vqh) [expr ($val(vqh)+1)%$val(mn)];
	 
	}
				
	set ivd [$vpos value]
	$ns at [expr [$ns now]+$ivd*1.0/$val(dspeed)] "entry_action"
			
			
}

#set val(stop) [expr $arp_cbr_stop_([expr $val(mn)-1])+1.0*$val(nde)*$val(exp_avg)/$val(dspeed)]

#puts "simulation end time: $val(stop)"

#$ns at $val(stop) "finish"
#$ns at $val(stop) "puts \"NS2 EXITING...\" ; $ns halt"

proc finish {} {

	global nstr nmtr val
	global nstr  ns
		
	close $nstr

	puts "NS2 EXITING..."

	$ns halt

	exec gawk -f scripts/script1.awk -v lamda=$val(plamda) traces$val(txrange)/trace_$val(plamda)_$val(cbr_rate)_$val(nr).tr >> outputs$val(txrange)/output_$val(plamda)_$val(cbr_rate).txt ;#to get detailed output of each run	
}

$ns run
