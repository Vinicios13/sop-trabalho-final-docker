#!/bin/bash

#obtém otempo de execução do script
get_runtime() {
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

#executa o contêiner
docker-compose up &
pid=$!

#deleta os conteudos do arquivo
> data.csv

# cabeçaho
echo "t, CPU%, RAM(MB)" >> data.csv

start=`date +%s.%N`

#enquanto o processo do contêiner estiver ativo continua gerando os dados
while kill -0 $pid 2> /dev/null; do
    now=$(get_runtime $start)
    echo "$now PROCESS IS RUNNING"
   
    #gera os dados
    docker stats --no-stream | grep stress \
        | awk -v var="$now" 'BEGIN { ORS=" " }; { printf "%s, ",var } { printf "%s, ",$3 } { printf "%s\n", $4 }' \
        |  sed -e 's/%//g' >> data.csv;
done

#normaliza os valores de GiB e MiB
while read p; do
    if [[ $p == *"GiB"* ]]; then        
        p=$(echo $p | sed -e 's/GiB//g' | sed -E 's/(.*)\./\1/g')
    elif [[ $p == *"MiB"* ]]; then
        p=$(echo $p | sed -e 's/MiB//g')
    fi

    #arquivo temporário com os valores corretos
    $(echo "$p" >> tmp.csv)
done <data.csv

#apaga o arquivo original
rm data.csv

#move o arquivo temporário para ser o novo data.csv 
mv tmp.csv data.csv

echo "PROCESS TERMINATED"
exit
