#!/bin/sh

#run the container
docker-compose up &
pid=$!

#clean file contents
> data.txt

#headers
echo "CPU% RAM(MB)" >> data.txt

while kill -0 $pid 2> /dev/null; do
    echo "PROCESS IS RUNNING"
    
    #generate data
    docker stats --no-stream | grep stress | awk 'BEGIN { ORS=" " }; { print $3 } { printf "%s\n", $4 } ' |  sed -e 's/MiB//g' -e 's/GiB//g' -e 's/%//g' >> data.txt;
done

echo "PROCESS TERMINATED"
exit