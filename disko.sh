#!/bin/sh 

#.------------------------------------------------------------------.#
#. disko                                                             #
#.                                                                   #
#. Copyright (C) 2017 LAFKON/Benjamin Stephan                        #
#.                                                                   #
#. disko is free software: you can redistribute it and/or modify     #
#. it under the terms of the GNU General Public License as published #
#. by the Free Software Foundation, either version 3 of the License, #
#. or (at your option) any later version.                            #
#.                                                                   #
#. disko is distributed in the hope that it will be useful,          #
#. but WITHOUT ANY WARRANTY; without even the implied warranty of    #
#. MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.              #
#. See the GNU General Public License for more details.              #
#.                                                                   #
#.------------------------------------------------------------------.#

EXCLUDEDIRCONTENTS="\.rtfd|\.app|\.lpdf|\.workflow|^\."
EXCLUDEDIRS="\.Trashes|\.Spotlight*|\.fseventsd|\.TemporaryItems|TheVolumeSettingsFolder"
EXCLUDEDFILES="\.DS_Store|.localized|\._\.*|Desktop DB|Desktop DF|Icon|\.DocumentRevisions.*"
GROUPEXT=".*\.png|.*\.jpg|.*\.JPG|.*\.jpeg|.*\.tga|.*\.tif|.*\.tiff|.*\.gif|.*\.eps|.*\.ai|.*\.AI|.*\.psd|.*\.svg|.*\.pdf"
GROUPMIN=10

#=====================================================================

SCRIPTPATH=$PWD;
IFS=$'\n'

COUNTFILES=0
COUNTDIRS=0
COUNTALL=0

DISKNAME=""
DIR="."

if [ $# -ne 2 ]; then
    echo "USAGE: ./disko.sh inputpath diskname"
    exit 1;
fi

PA=`realpath $1`
DISKNAME="$2"

HTML="$SCRIPTPATH/$DISKNAME.html"
HEAD="$SCRIPTPATH/diskolib/diskohead.html"
FOOT="$SCRIPTPATH/diskolib/diskofoot.html"

STARTTIME=$(date +%s)

#=====================================================================

function disko() {

  if !(test -d "$1") 
    then 
      echo "Please specify a directory, not a file!"
      return;
  fi

  cd -- "$1"

  #*******************************************************************
  echo '<li id="d'$COUNTDIRS'" class="d">'`basename "$PWD"`'<ul>' >>  $HTML   # print dir
  #*******************************************************************

  # check EXCLUDEDIRCONTENTS
  #----------------------------------------------------------
  TMP=`echo "$PWD" | egrep -v "$EXCLUDEDIRCONTENTS"`
  if [  "$TMP" == "" ]
    then
      return;
  fi
  #----------------------------------------------------------

  NEWDIR=1

  #-------------------------------------------------------------------
  for i in `gls -A --group-directories-first`
    do
      if [ -d "$i" ]                                     #if directory
        then 
        # check EXCLUDEDIRS
        #----------------------------------------------------
        TMP=`echo "$i" | egrep -v "$EXCLUDEDIRS"`
        if [ ! "$TMP" == "" ] && !(test -h "$i")
          then
          ((COUNTDIRS++));
          #***********************************************************
          disko "$i"                             # recurse into subdir
          #***********************************************************
          cd ..
          echo "</ul></li>"                     >>  $HTML
          NEWDIR=1
        fi
      else                                                  #else file
        # check EXCLUDEDFILES
        #----------------------------------------------------
        TMP=`echo "$i" | egrep -v "$EXCLUDEDFILES"`
        if [ ! "$i" == "*" ] && [ ! "$TMP" == "" ]
          then
          # check IMAGE SEQUENCES
          #----------------------------------------------------
          if [[ $NEWDIR -eq 1 ]]            #if: first time in this dir
            then
              #count img files in dir
              CNTSEQ=`gfind ./ -maxdepth 1 -type f \
                               -regextype posix-extended \
                               -regex ".*/$GROUPEXT" \
                               -printf '.' | wc -c`
              if [[ $CNTSEQ -gt $GROUPMIN ]]      #if: more than x img
                then
                #count all files in dir
                CNTALL=`gfind ./ -maxdepth 1 -type f \
                                 -regextype posix-extended \
                                 -not -regex ".*($EXCLUDEDFILES)" \
                                -printf '.' | wc -c`
                if [[ $CNTALL -eq $CNTSEQ ]]     #if: only imgs in dir
                  then
                  #***************************************************
                  echo "<li id=\"f"$COUNTFILES"\" class=\"f\"> \
                      $i</li>"                                    >>  $HTML # print imgseq
                  echo "<li id=\"s"$COUNTFILES"\" class=\"s\"> \
                      + $((CNTSEQ-1)) other img-files</li>"       >>  $HTML   
                  #***************************************************
                  COUNTFILES=$((COUNTFILES+CNTSEQ))
                  break
                fi
              fi
            NEWDIR=0
          fi
          #----------------------------------------------------
          #***********************************************************
          echo "<li id=\"f"$COUNTFILES"\" class=\"f\">$i</li>"    >>  $HTML # print file
          #***********************************************************
          ((COUNTFILES++));
        fi
      fi

      COUNTALL=$((COUNTFILES+COUNTDIRS));
      printf "  DISKO: Indexing $COUNTALL items \r"
    done 
  #-------------------------------------------------------------------
}

#=====================================================================

cat $HEAD                                       >  $HTML

#-------------------------------------------------------------------

echo '<h1>'                                    >>  $HTML
echo $DISKNAME                                 >>  $HTML    # diskname
echo '</h1>'                                   >>  $HTML

echo "<h3>"                                    >>  $HTML
echo $PA                                       >>  $HTML   # startpath
echo "</h3>"                                   >>  $HTML
echo '<div id="jstree" class="plain">'         >>  $HTML

#-------------------------------------------------------------------
  
echo "<ul>"                                    >>  $HTML
disko "$1"                                                    # DISKO!
echo "</ul>"                                   >>  $HTML

#-------------------------------------------------------------------

echo "</div>"                                  >>  $HTML
echo "<h2>"                                    >>  $HTML
echo "$COUNTDIRS Folders "                     >>  $HTML
echo "$COUNTFILES Files ~"                     >>  $HTML    # howmany
du -sh $PA | cut -f 1                          >>  $HTML
echo "total"                                   >>  $HTML
echo "</h2>"                                   >>  $HTML

#-------------------------------------------------------------------

DISKINFO=`diskutil info "$PA"`                        # print diksinfo
if [ `echo "$DISKINFO" | wc -l` -gt 1 ] 
  then
  echo "<div class=\"infobox\"><b>diskutil info $PA</b>\
        <pre class=\"pad\">"                                  >> $HTML
  echo "$DISKINFO" \
          | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\<br\/\>/g' >> $HTML
  echo "</pre></div>"                                         >> $HTML
else
  echo "<div class=\"infobox\"><b>df -h $PA</b><pre>"         >> $HTML
  df -h "$PA" \
          | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\<br\/\>/g' >> $HTML
  echo '</pre></div>'                                         >> $HTML
fi

#-------------------------------------------------------------------

                                                  # print excludefiles
echo "<div class=\"infobox\"><b>EXCLUDED FROM LISTING:</b>\
                <pre style=\"padding-left: 0px;\">"          >>  $HTML
echo "<b>FILES:</b><br/>"$EXCLUDEDFILES"<br/>" \
                | sed 's/\\//g' | sed 's/|/  /g'             >>  $HTML
echo "<b>DIRS:</b><br/>"$EXCLUDEDIRS"<br/>" \
                | sed 's/\\//g' | sed 's/|/  /g'             >>  $HTML
echo "<b>DIR CONTENTS:</b><br/>"$EXCLUDEDIRCONTENTS"<br/>"\
                | sed 's/\\//g' | sed 's/|/    /g'           >>  $HTML
echo '</pre></div>'                                          >>  $HTML

#-------------------------------------------------------------------

cat $FOOT                                                    >>  $HTML

#-------------------------------------------------------------------

ENDTIME=$(date +%s)
DIFFTIME=$(( $ENDTIME - $STARTTIME ))

printf " "
echo "  DISKO: Indexed $COUNTALL items in $DIFFTIME Seconds"
exit 0;

