BEGIN{
sum1=0;
avg1=0;
sum2=0;
avg2=0;
sum3=0;
avg3=0;
sum4=0;
avg4=0;
lamda=0;
cnt=0;	
}
{
	lamda=$1;
	sum1+=$2;
	sum2+=$3;
	sum3+=$4;
	sum4+=$5;
	cnt++;
}
END {
	avg1=sum1/cnt;
	avg2=sum2/cnt;
	avg3=sum3/cnt;
	avg4=sum4/cnt;
	printf("%f \t %f \t %f \t%f \t%f\n",lamda,avg1,avg2,avg3,avg4); 
}
