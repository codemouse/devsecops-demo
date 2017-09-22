#!/usr/bin/env bash

getProjectState()
{
  projectState=$(
    jq -n --arg projectToken "$projectToken" '{"projectToken":$projectToken,"requestType":"getProjectState"}' |
    curl -X POST -H $headers -d @- $api |
    jq -r '.projectState'
  )
}

getUuid()
{
    local N B T

    for (( N=0; N < 16; ++N ))
    do
        B=$(( $RANDOM%255 ))

        if (( N == 6 ))
        then
            printf '4%x' $(( B%15 ))
        elif (( N == 8 ))
        then
            local C='89ab'
            printf '%c%x' ${C:$(( $RANDOM%${#C} )):1} $(( B%15 ))
        else
            printf '%02x' $B
        fi

        for T in 3 5 7 9
        do
            if (( T == N ))
            then
                printf '-'
                break
            fi
        done
    done

    echo
}

api="https://saas.whitesourcesoftware.com/api"
headers="Content-Type:application/json"

#if node project
if [ -f package.json ]; then
  echo -e "project is node.js"

  sed -i '' '/^apiKey/d' ./whitesource-fs-agent.config
  sed -i '' '/^projectName/d' ./whitesource-fs-agent.config
  sed -i '' '/^projectVersion/d' ./whitesource-fs-agent.config

  packageName=$(jq -r '.name' package.json)
  packageVersion=$(jq -r '.version' package.json)
  uuid=$(getUuid)
  projectName="$packageName - $packageVersion-$uuid"

  echo -e "apiKey=$WHITESOURCE_API_KEY" >> whitesource-fs-agent.config
  echo -e "projectName=$packageName" >> whitesource-fs-agent.config
  echo -e "projectVersion=$packageVersion-$uuid" >> whitesource-fs-agent.config
fi

java -jar whitesource-fs-agent-1.8.4.jar -d ./

productToken=$(
  jq -n --arg orgToken "$WHITESOURCE_API_KEY" '{"orgToken":$orgToken,"requestType":"getAllProducts"}' |
  curl -X POST -H $headers -d @- $api |
  jq -r '.products | .[] | .productToken'
);

projectToken=$(
  jq -n --arg productToken "$productToken" '{"productToken":$productToken,"requestType":"getAllProjects"}' |
  curl -X POST -H $headers -d @- $api |
  jq -r --arg projectName "$projectName" '.projects | .[] | select(.projectName==$projectName) | .projectToken'
);

COUNTER=0
while [ $COUNTER -lt 20 ]; do
  getProjectState
  echo "$projectState"

  inProgress=$(
    echo "$projectState" | jq -r '.inProgress'
  )

  if [ !inProgress ]; then
    break
  fi
  let COUNTER+=1
  sleep 5
done

vulns=$(
  jq -n --arg projectToken "$projectToken" '{"projectToken":$projectToken,"requestType":"getProjectAlertsByType","alertType":"SECURITY_VULNERABILITY"}' |
  curl -X POST -H $headers -d @- $api |
  jq -r '.alerts'
);

vulnsCount=$(
  echo $vulns | jq -r 'length'
);

if [ "$vulnsCount" -eq 0 ] ;
then
   echo -e "No Whitesource Vulnerabilities found"
   exit 0
elif [ "$vulnsCount" -gt 0 ] ;
then
   echo -e "$vulnsCount Whitesource Vulnerabilities found:"
   echo $vulns | jq '.[]'
   exit 1
else
   echo -e "Whitesource Error"
   exit 1
fi


