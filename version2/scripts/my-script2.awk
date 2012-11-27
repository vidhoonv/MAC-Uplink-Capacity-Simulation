BEGIN {
	pflag=0;
	
	tpkt_cnt=0;
	
	pkt_len=1; #KB
	
	a=0;
	highest_returned = 0;

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
		
		
		if($1=="r" && $3=="_0_" && $7=="cbr" && $4== "MAC")
		{
			
			#for per vehicle throughput calculation 
			vid="0x" $11;
			vid=strtonum(vid);
			if(start_time[vid]==0)
			{
				start_time[vid]=$2;
	                        last_time[vid]=$2 ;

				pkt_cnt[vid]=0;
			}
			else {	
				last_time[vid]=$2 ;
			
			}
			pkt_cnt[vid]++;	
			
			
		}
		else if($1=="VEHICLE" && $3=="DISPATCHED")
		{
			node_id=$2;

                                nid=$2;

                               if(start_time[nid]!=0) {

                                data_upload[a]=pkt_cnt[nid];
                        returned_not_counted[nid] = 0;

                                a++;
                                #start_time[nid]=0;
                                #last_time[nid]=0;
                                #pkt_cnt[nid]=0;
                                }

			start_time[node_id]=0;
			end_time[node_id]=0;
			last_time[node_id]=0;
			pkt_cnt[node_id]=0;
		}
		else if($1=="VEHICLE" && $3=="RETURNED")
		{

                        nid=$2;

			if (highest_returned < nid) {
				highest_returned = nid;
			}
			
			returned_not_counted[nid] = 1;

		#		if(start_time[nid]!=0) {
		#		
		#		
		#		data_upload[a]=pkt_cnt[nid];
		#		
		#		
		#		a++;
		#		start_time[nid]=0;
		#		last_time[nid]=0;
		#		pkt_cnt[nid]=0;
		#		}
		}
			
		}
}

END {
	sum1=0;
	sum2=0;
	
		
	#per vehicle throughput and dataupload averaging

	#printf("average throughput %f", 

		for(i=0;i<a;i++)
		{
			#sum2+=data_upload[i];
			printf("%f ",data_upload[i]) >> DTR
		}
		
		for (i=0; i<= highest_returned; i++) {

			if (returned_not_counted[i]) {
				printf("%f ", pkt_cnt[i]) >> DTR
				returned_not_counted[i]=0;
			}
		}
		
	
	
}
