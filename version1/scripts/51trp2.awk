#
#
#used to print individual run details in a seperate file specific to that run
##
#
#!/bin/awk -f

BEGIN { 
mn=MN 
in_loop_duration=ILD
printf("ANALYSIS started at %f %f\n",st_time,end_time); 
	for(i=1;i<=mn;i++)
	{
		
		not[$i]=0;	#no of transmissions
		noc[$i]=0;	#no of collisions due to cbr
		nor[i]=0;	# no of cbr packets received
		
		cnt[i]=0;
		stime[i]=0;
		etime[i]=0;
		tdata[i]=0; #total size of packets transmitted
		lprt[i]=0;	#last packet recv time
		throughput[i]=0;
		loop_count[i]=0; # no_of_loops_completed in trace
		sumdata[i]=0
		sumduration[i]=0;
		totaldata[i]=0;
	}

}
{
if($2>st_time && $2<end_time)
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

printf("NODE  \t TOTAL TRANSMISSIONS \t TOTAL_RECV \t TOTAL COLLISIONS \t COLLISION PROBABILITY\tTDATA\t\tTDURATION\tDATA/LOOP\t\n");

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
		#dummy5+=sumdata[i];
		dummy5+=throughput[i];
		dummy3+=dummy;
		dummy2+=throughput[i];
		dummy4+=totaldata[i]/loop_count[i];
printf("%d \t %d\t \t \t%d \t\t\t %d \t\t\t %f\t %f\t %f\t%f\n",i,not[i],nor[i],noc[i],dummy,sumdata[i]/1000,sumduration[i],totaldata[i]/loop_count[i]);
	
	}

#calculation of avg_collision_prob


	acp=dummy3/mn; #avg collision prob
	
	atrn=dummy2/(1000*mn); #avg node throughout
	atdata=dummy4/(1000*mn); #avg data per loop
	#asdata=dummy5/(1000*(end_time-st_time)); #network throughput
	asdata=dummy5/(1000);
printf("%f %f\n",end_time-st_time,ed_time);
printf("Avg Collision probability : %f \n Avg Throughput: %f \n Avg TDATA: %f \n NTH: %f\n",acp,atrn,atdata,asdata);

}
