#!/usr/bin/env bash

whitesourceVersion="18.3.1"
sonarVersion="3.1.0.1141"

curl -LO https://s3.amazonaws.com/file-system-agent/whitesource-fs-agent-"$whitesourceVersion".jar

curl -LO https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-"$sonarVersion".zip &&
  unzip -j sonar-scanner-cli-"$sonarVersion".zip sonar-scanner-"$sonarVersion"/lib/sonar-scanner-cli-"$sonarVersion".jar  &&
  rm sonar-scanner-cli-"$sonarVersion".zip
