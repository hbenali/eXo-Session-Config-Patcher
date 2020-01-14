#!/bin/bash
function patch_war() {
  warfile=$(realpath $1)
  local wkdir="/tmp/exopatch/"
  mkdir -p $wkdir 2>&1 &>/dev/null || return
  local webxmlfile="$wkdir/WEB-INF/web.xml"
  rm -rf $wkdir &> /dev/null
  unzip -u $warfile "WEB-INF/web.xml" -d /tmp/exopatch/ 2>&1 &>/dev/null || return 1
  [ -f $webxmlfile ] || return 1
  cp -f $webxmlfile $wkdir/WEB-INF/web.xml.old
  sed -i ':a;N;$!ba; s|<session-config>.*<\/session-config>||g' $webxmlfile # Remove any old config
  sed -i ':a;N;$!ba; s|<\/web-app>|<session-config><session-timeout>1<\/session-timeout><\/session-config><\/web-app>|g' $webxmlfile || return 1
  hash xmllint && xmllint --format $webxmlfile > $wkdir/b.xml && cp -f $wkdir/b.xml $webxmlfile &> /dev/null
  cd $wkdir
  zip -u $warfile "WEB-INF/web.xml.old" 2>&1 &> /dev/null || return 1
  zip -u $warfile "WEB-INF/web.xml" 2>&1 &> /dev/null || return 1
  cd - &> /dev/null
  rm -rf $wkdir &> /dev/null
  echo "$1 ---> OK"
}


if [ ! -f "./bin/launcher.jar" ]; then
   echo "Error! Please make sure your are working on JBoss Instance!"
   exit 1
fi
webappsdir="standalone/deployments/platform.ear"
warfiles=($(find $webappsdir -name *.war))
for i in ${warfiles[@]}; do
  patch_war $i || echo "$i ---> SKIPPED"
done
