BEGIN {
	pflag=0;
	ns=0;
	nak=0;
	tpkt_cnt=0;
	tstart=0;
	tend=0;
	sumdata=0;
	sumduration=0;
	pkt_len=1; #KB
	nthend=0
	a=0;
	PKTLIMIT=50000; #no of packets to be considered for nth calc
}
{
	if($1=="START") { 
		pflag=1; #indicates start processing the file
	}
	else if($1=="STOP") { 
		pflag=0; #indicates start processing the file
	}
	if(pflag==1) {
		
		if($1=="s" && $7=="cbr" && $4=="MAC")
		{
			ns++;	
		}
		else if($1=="s" && $7=="ACK" && $3=="_0_")
		{
			nak++;
		}
		else if($1=="r" && $3=="_0_" && $7=="cbr" && $4== "MAC")
		{


			#for network throughput calculation
			if(nthend==0) {
			if(tstart==0) { 
				tstart=$2; 
				tend=$2;
			}
			else {
				tend=$2;
			}
			tpkt_cnt++;	
			if(tpkt_cnt==PKTLIMIT){
				nthend=1; }	
			}	
			#network throughput calculation ends

			#for per vehicle throughput calculation 
			vid="0x" $11;
			vid=strtonum(vid);
			if(start_time[vid]==0)
			{
				start_time[vid]=$2;
				pkt_cnt[vid]=0;
				last_time[vid]=$2 ;
			}
			else {	
			last_time[vid]=$2 ;
			
			}
			pkt_cnt[vid]++;	
			
			
		}
		else if($1=="VEHICLE" && $3=="DISPATCHED")
		{
			node_id=$2;
			start_time[node_id]=0;
			end_time[node_id]=0;
			last_time[node_id]=0;
			pkt_cnt[node_id]=0;
		}
		else if($1=="VEHICLE" && $3=="RETURNED")
		{
				nid=$2;
				if(start_time[nid]!=0) {
				end_time[nid]=last_time[nid];
				duration=end_time[nid]-start_time[nid];
				data_upload[a]=pkt_cnt[nid];
				sumdata+=data_upload[a]-1;
				sumduration+=duration;
				a++;
				start_time[nid]=0;
				last_time[nid]=0;
				pkt_cnt[nid]=0;
				}
		}
			
		}
}

END {
	sum1=0;
	sum2=0;
	#network throughput
		nth=tpkt_cnt/(tend-tstart);
		

	#collision probability
		pc=1-(nak/ns);
		
	#per vehicle throughput and dataupload averaging
		for(i=0;i<a;i++)
		{
			sum2+=data_upload[i];
		
		}
		
		pvt=sumdata/sumduration;
		dup=sum2/a;
		
	printf("%f\t%f\t%f\t%f\t%f\n",lamda,pc,nth,pvt,dup);
	
}
