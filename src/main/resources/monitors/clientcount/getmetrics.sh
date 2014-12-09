#!/bin/bash


#Extract the value between the sum tags
#$1 is the xml to search for the sum
function getSum() 
{
	#First get the sum tag and get the value
	sumtag=$(echo $1 | grep -oP '<sum>.*</sum>')

	if [ -z "$sumtag" ]; then
		echo "0"
	else

		sumtag=${sumtag:5}
		vallength=`expr index $sumtag '<'`
		sumvalue=${sumtag:0:vallength-1}

		echo $sumvalue
	fi
}

#Extract the metric name, drop the 'Calls per Minute' bit and append 'Calls per $2 Minutes' 
#$1 is the XML to search for the path
#$2 is the period the path is to be formatted for
function getMetricPath() 
{
	mnemonic=$1
	met_period=$2

	#First get the sum tag and get the value
	metpath="Information Points|$mnemonic|Calls per $met_period Minutes"

	echo $metpath
}

#
#Echo the metrics in the expected format
function echoMetric() 
{
	mnemonic=$1
	base_url=$2
	met_period=$3
	user_name=$4
	account_name=$5
	password=$6
	
	#For debugging
	#echo "${base_url}${met_period}" >> urls.txt

	met_xml=$(curl -qs -u"$user_name@$account_name:$password" "$base_url$met_period")

	if [ -z "$met_xml" ]; then
		echo "Failed to retrieve the metrics using url: $base_url$met_period"
	else 
		met_path=$(getMetricPath "$mnemonic" $met_period)
		met_val=$(getSum "$met_xml")
		echo "name=Custom Metrics|$met_path,value=$met_val"
	fi
}

#Four expected parameters
if [[ "$#" -ne 4 ]]; then
	echo "Invalid number of arguments."
	echo "use: $0 appdynamics_account client_file_name appdynamics_user appdynamics_password"
	exit
fi

#For debugging
#echo $@ > commandline_args.txt

appd_account=$1
client_file=$2
appd_user_name=$3
appd_password=$4

#minutes interval counts to retrieve
met_period_1=10 
met_period_2=60 
met_period_3=960 #16 hours - all day 

controller_host=192.168.2.155:8090

time_at_5am=$(date -d "today 05:00" +%s)

aftertime_base_url="http://${controller_host}/controller/rest/applications/ComplexDashboardTest/metric-data?metric-path=Information%20Points%7C<client>%7CCalls%20per%20Minute&time-range-type=AFTER_TIME&start-time=<starttime>000&duration-in-mins="

beforenow_base_url="http://${controller_host}/controller/rest/applications/ComplexDashboardTest/metric-data?metric-path=Information%20Points%7C<client>%7CCalls%20per%20Minute&time-range-type=BEFORE_NOW&duration-in-mins="

while read client; do
	beforenow_url=${beforenow_base_url/'<client>'/$client}
	beforenow_url=${beforenow_url/'<starttime>'/$time_at_5am}
	aftertime_url=${aftertime_base_url/'<client>'/$client}
	aftertime_url=${aftertime_url/'<starttime>'/$time_at_5am}	

	echoMetric $client $beforenow_url $met_period_1 $appd_user_name $appd_account $appd_password 
	echoMetric $client $beforenow_url $met_period_2 $appd_user_name $appd_account $appd_password 
	echoMetric $client $aftertime_url $met_period_3 $appd_user_name $appd_account $appd_password 
done <$client_file

