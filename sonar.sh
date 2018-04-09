#!/usr/bin/env bash

jarFile="sonar-scanner-cli-3.1.0.1141.jar"
hostUrl="https://sonarcloud.io"

#if node project
if [ -f package.json ]; then
  echo -e "project is node.js"

  sed -i '' '/^sonar\.projectKey/d' ./sonar-project.properties
  sed -i '' '/^sonar\.projectName/d' ./sonar-project.properties
  sed -i '' '/^sonar\.projectVersion/d' ./sonar-project.properties

  packageName=$(jq -r '.name' package.json)
  packageVersion=$(jq -r '.version' package.json)
  organization=$(jq -r '.organization' package.json)
  projectKey="com.$organization.$packageName"

  echo -e "sonar.projectKey=$projectKey" >> sonar-project.properties
  echo -e "sonar.projectName=$packageName" >> sonar-project.properties
  echo -e "sonar.projectVersion=$packageVersion" >> sonar-project.properties
fi

real_path () {
  target=$1

  (
  while true; do
    cd "$(dirname "$target")"
    target=$(basename "$target")
    link=$(readlink "$target")
    test "$link" || break
    target=$link
  done

  echo "$(pwd -P)/$target"
  )
}

scriptPath="$0"

if [ -h "$scriptPath" ] ; then
  # resolve recursively symlinks
  scriptPath=$(real_path "$scriptPath")
fi

sonarScannerHome=$(dirname "$scriptPath")/..

# make it fully qualified
sonarScannerHome=$(cd "$sonarScannerHome" && pwd -P)

# check that sonarScannerHome has been correctly set
if [ ! -f "$jarFile" ] ; then
  echo "File does not exist: $jarFile"
  echo "'$sonarScannerHome' does not point to a valid installation directory: $sonarScannerHome"
  exit 1
fi

if [ -n "$JAVA_HOME" ]
then
  javaCmd="$JAVA_HOME/bin/java"
else
  javaCmd="$(which java)"
fi

projectHome=$(pwd)

#echo "Info: Using sonar-scanner at $sonarScannerHome"
#echo "Info: Using java at $javaCmd"
#echo "Info: Using classpath $jarFile"
#echo "Info: Using project $projectHome"

exec "$javaCmd" \
  -Djava.awt.headless=true \
  -Dsonar.projectKey="$projectKey" \
  -Dsonar.sources=src \
  -Dsonar.host.url="$hostUrl" \
  -Dsonar.organization="$organization" \
  -Dsonar.login="$SONAR_TOKEN" \
  -classpath  "$jarFile" \
  -Dscanner.home="$sonarScannerHome" \
  -Dproject.home="$projectHome" \
  org.sonarsource.scanner.cli.Main "$@"
