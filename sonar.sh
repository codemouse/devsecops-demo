#!/usr/bin/env bash

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

script_path="$0"

if [ -h "$script_path" ] ; then
  # resolve recursively symlinks
  script_path=$(real_path "$script_path")
fi

sonar_scanner_home=$(dirname "$script_path")/..

# make it fully qualified
sonar_scanner_home=$(cd "$sonar_scanner_home" && pwd -P)

jar_file=sonar-scanner-cli-3.0.3.778.jar

# check that sonar_scanner_home has been correctly set
if [ ! -f "$jar_file" ] ; then
  echo "File does not exist: $jar_file"
  echo "'$sonar_scanner_home' does not point to a valid installation directory: $sonar_scanner_home"
  exit 1
fi

if [ -n "$JAVA_HOME" ]
then
  java_cmd="$JAVA_HOME/bin/java"
else
  java_cmd="$(which java)"
fi

project_home=$(pwd)

#echo "Info: Using sonar-scanner at $sonar_scanner_home"
#echo "Info: Using java at $java_cmd"
#echo "Info: Using classpath $jar_file"
#echo "Info: Using project $project_home"

exec "$java_cmd" \
  -Djava.awt.headless=true \
  -Dsonar.projectKey="$projectKey" \
  -Dsonar.sources=src \
  -Dsonar.host.url=https://sonarcloud.io \
  -Dsonar.organization="$organization" \
  -Dsonar.login="$SONARCLOUD_TOKEN" \
  -classpath  "$jar_file" \
  -Dscanner.home="$sonar_scanner_home" \
  -Dproject.home="$project_home" \
  org.sonarsource.scanner.cli.Main "$@"
