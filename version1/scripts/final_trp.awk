#
# used to generate final consolidated output from all the runs
#
#

BEGIN {
avg1=0;
sum1=0;
avg2=0;
sum2=0;
sum3=0
avg3=0;
sum4=0;
avg4=0;
count=0;
}
{
if($0!~/^$/ )
{
sum1+=$1;
sum2+=$2;
sum3+=$3;
sum4+=$4;
count++;
}
}
END{

avg1=sum1/count;
avg2=sum2/count;
avg3=sum3/count;
avg4=sum4/count;
printf("p(c) %f \n Thr %f \nDPL %f\n \nNr %f \n",avg1,avg2,avg3,count);

}
