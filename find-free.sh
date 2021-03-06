#!/bin/bash

# First parameters contains the config files
CONF_DIR=$1
# Second parameter contains the temporary directory to use
TEMP_DIR=$2
# Third parameter points to the final directory to put the html file.
FINAL_PATH=$3
# Number of days to gather
DAYS=(0 1 2 3)
# DATE PROGRAM to use.  Use gdate on MAC
DATE_PROG='date'
# AUTH TOKEN to use
TOKEN=`cat ${1}/token`;
# BINTANG Resource id
BINTANG=16509
CURRENT_HOUR="$(${DATE_PROG} +%H)";
CURRENT_DATE="$(${DATE_PROG} +%Y-%m-%d)";


TEMP_HTML=${TEMP_DIR}/hours-summary.html

# Remove the previous day's set of files.  Leave them around to debug in case
if ! ls ${TEMP_DIR}/hours*courts-${CURRENT_DATE} 1> /dev/null 2>&1; then
  rm -fr ${TEMP_DIR}/hours*
fi

rm -fr ${TEMP_HTML}

NOW=$(${DATE_PROG});

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

echo "<h1>Please read the following before using the data on this page:</h1>" >> ${TEMP_HTML};
echo "<ul>" >> ${TEMP_HTML};
echo "<li>This is not official Bintang page.  Provided only as a convenience for my baddie friends</li>" >>${TEMP_HTML};
echo "<li>Refreshing this page DOES NOT perform real time updates.  It is a static page generated every hour, so no point in refreshing every 5 minutes.</li>" >> ${TEMP_HTML};
echo "<li>Just because courts are available does not mean the gym is open for drop-in.  Double check the times when the gym is open.</li>" >> ${TEMP_HTML};
echo "<li>Bintang training does not use the reservation system so the numbers you see available here must be subtracted by the number of the courts Bintang training uses.  There's no training usage information online so you have to observe for the times that you often go how many courts are used by training and do that calculation yourself.</li>" >> ${TEMP_HTML};
echo "<li>The time below gives when the page was generated.  The time should give you some idea how recent this data is</li>" >> ${TEMP_HTML};
echo "</ul>" >> ${TEMP_HTML};
echo "<p>As of <b>${NOW}</b>, the court statuses are as follows:</p>" >> ${TEMP_HTML};

for file in ${CONF_DIR}/bintang-*; do
  LOCATION=$(grep location $file | cut -d ':' -f2 | tr -d ' ');
  NAME=$(grep display $file | cut -d ':' -f2);
  MESSAGE=$(grep message $file | cut -d ':' -f2);
  TVAR=$(${DATE_PROG} +%s%3N);
  CONDENSED_NAME=$(grep name ${file} | cut -d ':' -f2 | tr -d ' ()');

  TEMP_COURTS_FILENAME=${TEMP_DIR}/hours-${CONDENSED_NAME}-courts-${CURRENT_DATE};

  echo "<h1>${NAME}</h1>" >> ${TEMP_HTML};
  echo "<p>${MESSAGE}</p>" >> ${TEMP_HTML};
  echo "<div class=\"location\">" >> ${TEMP_HTML};

  # Get the courts
  http --verify=no --check-status --ignore-stdin GET https://app.bukza.com/api/resource-groups/getClientCatalog/${BINTANG}/${LOCATION}?t=${TVAR} Authorization:"${TOKEN}" x-bukza-user-id:"${BINTANG}" Accept:"application/json, text/plain, */*" > ${TEMP_COURTS_FILENAME};
#http --verify=no --check-status --ignore-stdin GET https://a.frontend.bukza.com/api/resource-groups/getCatalog/${BINTANG}/${LOCATION}?t={TVAR} Authorization:"${TOKEN}" > ${TEMP_COURTS_FILENAME};
  retVal=$?;
  if [ ${retVal} -ne 0 ]; then
    echo "<p>Unable to get courts due to ${retVal}</p>" >> ${TEMP_HTML};
    http --verify=no -v --check-status --ignore-stdin GET https://app.bukza.com/api/resource-groups/getClientCatalog/${BINTANG}/${LOCATION}?t=${TVAR} Authorization:"${TOKEN}" x-bukza-user-id:"${BINTANG}" Accept:"application/json, text/plain, */*" > ${TEMP_COURTS_FILENAME}_ERROR 2>&1;
#    http --verify=no -v --check-status --ignore-stdin GET https://a.frontend.bukza.com/api/resource-groups/getCatalog/${BINTANG}/${LOCATION}?t={TVAR} Authorization:"${TOKEN}" > ${TEMP_COURTS_FILENAME}_ERROR 2>&1;
  else
    COURTS=$(cat ${TEMP_COURTS_FILENAME} | jq '.items[] | .resourceId' | tr '\n' ',');
    for i in "${DAYS[@]}"; do
      DATE=$(${DATE_PROG} -d "+$i days" +"%Y-%m-%d");
      DISPLAY_DATE=$(${DATE_PROG} -d "+$i days" +"%Y-%m-%d %a");
      TIME_ZONE=$(${DATE_PROG} +"%Z");
      TEMP_PREFIX=${TEMP_DIR}/hours-${CONDENSED_NAME}-${DATE}
      TEMP_FILENAME=${TEMP_PREFIX}-${CURRENT_HOUR};

      echo "<div class=\"licol\">" >> ${TEMP_HTML};    
      echo "<h2>${DISPLAY_DATE}</h2>" >> ${TEMP_HTML};

      http --verify=no --check-status --ignore-stdin POST https://app.bukza.com/api/clientReservations/getAvailability/${BINTANG}?t=${TVAR} date="${DATE}T07:00:00.000Z" dayCount:=1 includeHours:=true includeRentalPoints:=true includeWorkRuleNames:=false resourceIds:="[${COURTS::-1}]" x-bukza-user-id:"${BINTANG}" Authorization:"${TOKEN}" 'Content-Type: application/json;charset=utf-8' > ${TEMP_FILENAME};
#      http --verify=no --check-status --ignore-stdin post https://a.frontend.bukza.com/api/reservations/getAvailability/${BINTANG}?t=${TVAR} date="${DATE}T07:00:00.000Z" dayCount:=1 includeHours:=true includeRentalPoints:=true includeWorkRuleNames:=false resourceIds:="[${COURTS::-1}]" Authorization:"${TOKEN}" 'Content-Type: application/json;charset=utf-8' > ${TEMP_FILENAME};
      retVal=$?;
      if [ ${retVal} -ne 0 ]; then
        echo "<p>Unable to get data due to ${retVal}</p>" >> ${TEMP_HTML};
      http --verify=no -v --check-status --ignore-stdin POST https://app.bukza.com/api/clientReservations/getAvailability/${BINTANG}?t=${TVAR} date="${DATE}T07:00:00.000Z" dayCount:=1 includeHours:=true includeRentalPoints:=true includeWorkRuleNames:=false resourceIds:="[${COURTS::-1}]" x-bukza-user-id:"${BINTANG}" Authorization:"${TOKEN}" 'Content-Type: application/json;charset=utf-8' > ${TEMP_FILENAME}_ERROR 2>&1;

#        http --verify=no -v --ignore-stdin post https://a.frontend.bukza.com/api/reservations/getAvailability/${BINTANG}?t=${TVAR} date="${DATE}T07:00:00.000Z" dayCount:=1 includeHours:=true includeRentalPoints:=true includeWorkRuleNames:=false resourceIds:="[${COURTS::-1}]" Authorization:"${TOKEN}" 'Content-Type: application/json;charset=utf-8' > ${TEMP_FILENAME}_ERROR 2>&1;
      else 
        echo "<ul>" >> ${TEMP_HTML}
        for HOUR in $(grep hours ${file} | cut -d ':' -f 2 | tr ',' '\n'); do
          if [[ "${DATE}" == "${CURRENT_DATE}" ]]; then
            if [[ "${HOUR}" > "07" && "${HOUR}" < "17" ]]; then
              if ls "${TEMP_PREFIX}-07" 1> /dev/null 2>&1; then
                TEMP_FILENAME="${TEMP_PREFIX}-07";
              fi
            fi
            if [[ "${HOUR}" > "16" && "${HOUR}" < "23" ]]; then
              if ls "${TEMP_PREFIX}-14" 1> /dev/null 2>&1; then
                TEMP_FILENAME="${TEMP_PREFIX}-14";
              fi
            fi
          fi
          HOUR_ZULU=$(${DATE_PROG} -d "${DATE}T${HOUR}:00:00 ${TIME_ZONE}" -u +"%H");
          COURTS_FREE=$(cat ${TEMP_FILENAME} | jq '.resources | .[] | {court: .resourceId, days: .days[]} | {court: .court, start: .days.startPoints[] | .date, end: .days.endPoints[] | .date}' | grep -B 1 "start.*T${HOUR_ZULU}:" | grep court | sort -u | wc -l);
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
