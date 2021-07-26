#!/bin/bash

# First parameters contains the config files
CONF_DIR=$1
# Second parameter contains the temporary directory to use
TEMP_DIR=$2
# Thid parameter points to the final directory to put the html file.
FINAL_PATH=$3
# Number of days to gather
DAYS=(0 1 2 3)
# DATE PROGRAM to use.  Use gdate on MAC
DATE_PROG=date
# AUTH TOKEN to use
TOKEN=`cat ${1}/token`;
# BINTANG Resource id
BINTANG=16509


TEMP_HTML=${TEMP_DIR}/summary.html

# Remove the previous set of files.  Leave them around to debug in case
rm -fr ${TEMP_DIR}/hours*
rm -fr ${TEMP_HTML}

NOW=`${DATE_PROG}`;

echo "<!DOCTYE html>" > ${TEMP_HTML}
echo "<html>" >> ${TEMP_HTML};
echo "<head>" >> ${TEMP_HTML};
echo "<title>Court Summaries</title>" >> ${TEMP_HTML};
echo "<style>" >> ${TEMP_HTML};
echo ".location {" >> ${TEMP_HTML};
echo "border: 2px solid powderblue;" >> ${TEMP_HTML};
echo "outline: powderblue solid 2px;" >> ${TEMP_HTML};
echo "column-count: 4;" >> ${TEMP_HTML};
echo "column-gap: 40px;" >> ${TEMP_HTML};
echo "column-rule-style: solid;" >> ${TEMP_HTML};
echo "column-rule-color: powderblue;" >> ${TEMP_HTML};
echo "padding-top: 10px;" >> ${TEMP_HTML};
echo "padding-bottom: 10px;" >> ${TEMP_HTML};
echo "}" >> ${TEMP_HTML};
echo ".licol {" >> ${TEMP_HTML};
echo "padding-top: 20px;" >> ${TEMP_HTML};
echo "}" >> ${TEMP_HTML};
echo "</style>" >> ${TEMP_HTML};
echo "</head>" >> ${TEMP_HTML};
echo "<body>" >> ${TEMP_HTML};

echo "<p>Please Note The Following:</p>" >> ${TEMP_HTML};
echo "<ul>" >> ${TEMP_HTML};
echo "<li>This is not official Bintang page.  Provided only as a convenience for my baddie friends</li>" >>${TEMP_HTML};
echo "<li>Refreshing this page DOES NOT perform real time updates.  It is a static page generated every hour.</li>" >> ${TEMP_HTML};
echo "<li>Just because courts are available does not mean the gym is open for drop-in.  Double check the times when the gym is open.</li>" >> ${TEMP_HTML};
echo "<li>The time below gives when the page was generated.</li>" >> ${TEMP_HTML};
echo "<li>The numbers are gathered from 8am-3pm each day because the evening reservations stop at 3pm each day.</li>" >> ${TEMP_HTML};
echo "<li>For current day's daytime courts, check <a href="daytime-summary.html">Daytime Court Summary</a>.</li>" >> ${TEMP_HTML};
echo "</ul>" >> ${TEMP_HTML};
echo "<p>As of ${NOW}, the court statuses are as follows:</p>" >> ${TEMP_HTML};

for file in `ls ${CONF_DIR}/bintang-*`; do
  LOCATION=`grep location $file | cut -d ':' -f2 | tr -d ' '`;
#  COURTS=`grep courts $file | cut -d ':' -f2`;
  NAME=`grep name $file | cut -d ':' -f2`;
  MESSAGE=`grep message $file | cut -d ':' -f2`;
  TVAR=`${DATE_PROG} +%s%3N`;
  CONDENSED_NAME=`echo ${NAME} | tr -d ' ()'`;
  TEMP_COURTS_FILENAME=${TEMP_DIR}/hours-${CONDENSED_NAME}-courts;

  echo "<h1>${NAME}</h1>" >> ${TEMP_HTML};
  echo "<p>${MESSAGE}</p>" >> ${TEMP_HTML};
  echo "<div class=\"location\">" >> ${TEMP_HTML};

  # Get the courts
  http --check-status --ignore-stdin GET https://a.frontend.bukza.com/api/resource-groups/getCatalog/${BINTANG}/${LOCATION}?t={TVAR} Authorization:"${TOKEN}" > ${TEMP_COURTS_FILENAME};
  retVal=$?;
  if [ ${retVal} -ne 0 ]; then
    echo "<p>Unable to get courts due to ${retVal}</p>" >> ${TEMP_HTML};
    http -v --check-status --ignore-stdin GET https://a.frontend.bukza.com/api/resource-groups/getCatalog/${BINTANG}/${LOCATION}?t={TVAR} Authorization:"${TOKEN}" > ${TEMP_COURTS_FILENAME}_ERROR 2>&1;
  else
    COURTS=`cat ${TEMP_COURTS_FILENAME} | jq '.items[] | .resourceId' | tr '\n' ','`;
    for i in "${DAYS[@]}"; do
      DATE=`${DATE_PROG} -d "+$i days" +"%Y-%m-%d"`;
      DISPLAY_DATE=`${DATE_PROG} -d "+$i days" +"%Y-%m-%d %a"`;
      TIME_ZONE=`${DATE_PROG} +"%Z"`;
      TEMP_FILENAME=${TEMP_DIR}/hours-${CONDENSED_NAME}-${DATE};

      echo "<div class=\"licol\">" >> ${TEMP_HTML};    
      echo "<h2>${DISPLAY_DATE}</h2>" >> ${TEMP_HTML};

      http --check-status --ignore-stdin post https://a.frontend.bukza.com/api/reservations/getAvailability/${BINTANG}?t=${TVAR} date="${DATE}T07:00:00.000Z" dayCount:=1 includeHours:=true includeRentalPoints:=true includeWorkRuleNames:=false resourceIds:="[${COURTS::-1}]" Authorization:"${TOKEN}" 'Content-Type: application/json;charset=utf-8' > ${TEMP_FILENAME};
      retVal=$?;
      if [ ${retVal} -ne 0 ]; then
        echo "<p>Unable to get data due to ${retVal}</p>" >> ${TEMP_HTML};
        http -v --ignore-stdin post https://a.frontend.bukza.com/api/reservations/getAvailability/${BINTANG}?t=${TVAR} date="${DATE}T07:00:00.000Z" dayCount:=1 includeHours:=true includeRentalPoints:=true includeWorkRuleNames:=false resourceIds:="[${COURTS::-1}]" Authorization:"${TOKEN}" 'Content-Type: application/json;charset=utf-8' > ${TEMP_FILENAME}_ERROR 2>&1;
      else 
        echo "<ul>" >> ${TEMP_HTML}
        for HOUR in `grep hours ${file} | cut -d ':' -f 2 | tr ',' '\n'`; do 
          HOUR_ZULU=`${DATE_PROG} -d "${DATE}T${HOUR}:00:00 ${TIME_ZONE}" -u +"%H"`;
          COURTS_FREE=`cat ${TEMP_FILENAME} | jq '.resources | .[] | {court: .resourceId, days: .days[]} | {court: .court, start: .days.startPoints[] | .date, end: .days.endPoints[] | .date}' | grep -B 1 "start.*T${HOUR_ZULU}:" | grep court | sort -u | wc -l`;
          echo "<li>${HOUR}:00 ${TIME_ZONE} - ${COURTS_FREE} court(s) available</li>" >> ${TEMP_HTML}
        done
        echo "</ul>" >> ${TEMP_HTML};
      fi
      echo "</div>" >> ${TEMP_HTML};
    done
  fi
  echo "</div>" >> ${TEMP_HTML};
done
echo "</body>" >> ${TEMP_HTML};
echo "</html>" >> ${TEMP_HTML};

cp -f ${TEMP_HTML} ${FINAL_PATH}
