#
# used to generate merged output from individual runs for processing by final_trp.awk
#
#
#
#
#!/bin/awk -f

BEGIN { 
mn=MN 
in_loop_duration=ILD

	for(i=1;i<=mn;i++)
	{
		
		not[i]=0;	#no of transmissions
		noc[i]=0;	#no of collisions due to cbr
		nor[i]=0;	# no of cbr packets received
		
		stime[i]=0;
		etime[i]=0;
		cnt[i]=0;
		tdata[i]=0;
		lprt[i]=0;	#last packet recv time
		throughput[i]=0;
			loop_count[i]=0; # no_of_loops_completed in trace
		sumdata[i]=0
		sumduration[i]=0;
		totaldata[i]=0;
		
	}
 #total size of packets transmitted
}
{
if($2>st_time  && $2<end_time)
{
ed_time=$2;
	if($1=="s" && $7=="cbr" && $4=="MAC")
	{
		
		for(i=1;i<=mn;i++)
		{
			format="_" i "_";
			
			if($3==format)
			{
				
				not[i]++;
				
			}
		}
		
	}
	else if($1=="r" && $3=="_0_" && $7=="cbr" && $4== "MAC")
	{
		
		for(i=1;i<=mn;i++)
		{
			sender="0x" $11;
			sender=strtonum(sender);
			if(sender==i)
			{
				
				nor[i]++;
				if(lprt[i]==0)
				{
					lprt[i]=$2;
				}
				else if($2-lprt[i]>in_loop_duration)
				{		
					sumdata[i]+=tdata[i];
					sumduration[i]+=(etime[i]-stime[i]);
					tdata[i]=0;stime[i]=0;
					cnt[i]=0;
					loop_count[i]++;
					
				}
				if(cnt[i]==0)
				{
					stime[i]=$2;
				}	
				
				cnt[i]++;
				etime[i]=$2;
				tdata[i]+=$8;
				lprt[i]=$2;
			}
		}
		
	}
	else if($1=="D" && $5=="COL" && $7=="cbr") #else if($1=="D" && $5=="COL") NO ARP CONSIDERATION ONLY CBR
	{
		for(i=1;i<=mn;i++)
		{
			sender="0x" $11;
			sender=strtonum(sender);
			if(sender==i)
			{
				
				noc[i]++;
				
			}
		}
	}	
}
}
END {



dummy=0;	
dummy2=0;
dummy3=0;
dummy4=0;
dummy5=0;
for(i=1;i<=mn;i++)
	{

		if(not[i]!=0) {
		
		dummy=noc[i]/not[i];
		}
		else
		{ dummy=0 ;}
		
		totaldata[i]=sumdata[i];
		throughput[i]=sumdata[i]/sumduration[i];
		dummy3+=dummy;
		#dummy5+=sumdata[i];
		dummy5+=throughput[i];		
		dummy2+=throughput[i];
		dummy4+=totaldata[i]/loop_count[i];
	
	}

#calculation of avg_collision_prob


	acp=dummy3/mn;
	atrn=dummy2/(1000*mn);
		#asdata=dummy5/(1000*(end_time-st_time)); #network throughput
		asdata=dummy5/(1000);
	atdata=dummy4/(1000*mn);
printf("%f\t%f\t%f\t%f\n",acp,atrn,atdata,asdata);

}
