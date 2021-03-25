#!/bin/bash

get_now() {
    start=$1
    end=$(date +%s.%N)
    now=$( echo "scale=2; ($end - $start)/1" | bc -l )
    
    now_l=$(echo ${#now})
    limit=3

    if [ $now_l -eq $limit ]
    then
        echo "0$now"
    else
        echo "$now"
    fi
}

#run the container
docker-compose up &
pid=$!

#clean file contents
> data.csv

# headers
echo "t, CPU%, RAM(MB)" >> data.csv

start=`date +%s.%N`

while kill -0 $pid 2> /dev/null; do
    now=$(get_now $start)
    echo "$now PROCESS IS RUNNING"
   
    #generate data
    docker stats --no-stream | grep stress \
        | awk -v var="$now" 'BEGIN { ORS=" " }; { printf "%s, ",var } { printf "%s, ",$3 } { printf "%s\n", $4 }' \
        |  sed -e 's/%//g' >> data.csv;
done

#normalize GiB and MiB values
while read p; do
    if [[ $p == *"GiB"* ]]; then        
        p=$(echo $p | sed -e 's/GiB//g' | sed -E 's/(.*)\./\1/g')
    elif [[ $p == *"MiB"* ]]; then
        p=$(echo $p | sed -e 's/MiB//g')
    fi

    $(echo "$p" >> tmp.csv)
done <data.csv

rm data.csv
mv tmp.csv data.csv

echo "PROCESS TERMINATED"
exit
