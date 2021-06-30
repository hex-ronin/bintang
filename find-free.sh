#!/bin/bash

# First parameters contains the config files
CONF_DIR=$1
# Second parameter contains the temporary directory to use
TEMP_DIR=$2
# Thid parameter points to the final directory to put the html file.
FINAL_DIR=$3
# Number of days to gather
DAYS=(0 1 2 3)
# DATE PROGRAM to use.  Use gdate on MAC
DATE_PROG=date
# AUTH TOKEN to use
TOKEN="Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1laWQiOiIxNDA3OTU3Iiwicm9sZSI6ImNsaWVudCIsIm5iZiI6MTYyMzY4NjkxMywiZXhwIjoxNzEwMDg2OTEzLCJpYXQiOjE2MjM2ODY5MTMsImlzcyI6IkJ1a3phIiwiYXVkIjoiVXNlcnMifQ.X3d0oOUllpyrx9m5UwmC_uBGU-nGimQgA2QvwuE8vjBqiK016zvdQ5WeG6pX9n-3N72clmD9m5JzNCQ5J0ixa0jOCdZ8gduwcFcsNUuDpeS8Xsh7xWyE3o6wYOIzjDp4psQCsyHQUvTmEvclnMqCwgfhCiUcrBKk2qciglMxSGNevuGoIn6oldNfHguUrOHZLRDy-jChoGqLBzmBq3-NLfPYdhHXy2V1vXvLrvBkKuDFZG_v4gUSMXW5ymlL75NbDWJ3VvEJ8TeCQP6473QQa4kefYslRljny4SI55b4qzYuhzb05jpC1Vv6t5fWnbRzB_RDrLLeI9OvDhdXYMJ3dA"

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

echo "<p>Refreshing this page DOES NOT give real time updates.  It is a static page generated every hour.  Note the time below which gives when the page was generated.</p><p>As of ${NOW}, the court statuses are as follows:</p>" >> ${TEMP_HTML};

for file in `ls ${CONF_DIR}/bintang-*`; do
  LOCATION=`grep location $file | cut -d ':' -f2 | tr -d ' '`;
  COURTS=`grep courts $file | cut -d ':' -f2`;
  NAME=`grep name $file | cut -d ':' -f2`;
  TVAR=`${DATE_PROG} +%s%3N`;
  MESSAGE=`grep message $file | cut -d ':' -f2`;

  echo "<h1>${NAME}</h1>" >> ${TEMP_HTML};
  echo "<p>${MESSAGE}</p>" >> ${TEMP_HTML};
  echo "<div class=\"location\">" >> ${TEMP_HTML};
  for i in "${DAYS[@]}"; do
    DATE=`${DATE_PROG} -d "+$i days" +"%Y-%m-%d"`;
    TIME_ZONE=`${DATE_PROG} +"%Z"`;
    CONDENSED_NAME=`echo ${NAME} | tr -d ' ()'`; 
    TEMP_FILENAME=${TEMP_DIR}/hours-${CONDENSED_NAME}-${DATE};
    echo "<div class=\"licol\">" >> ${TEMP_HTML};    
    echo "<h2>${DATE}</h2>" >> ${TEMP_HTML};

    http --check-status --ignore-stdin post https://a.frontend.bukza.com/api/reservations/getAvailability/${LOCATION}?t=${TVAR} date="${DATE}T07:00:00.000Z" dayCount:=1 includeHours:=true includeRentalPoints:=true includeWorkRuleNames:=false resourceIds:="[${COURTS}]" Authorization:"${TOKEN}" 'Content-Type: application/json;charset=utf-8' > ${TEMP_FILENAME};
    retVal=$?;
    if [ ${retVal} -ne 0 ]; then
      echo "<p>Unable to get data due to ${retVal}</p>" >> ${TEMP_HTML};
      http -v --ignore-stdin post https://a.frontend.bukza.com/api/reservations/getAvailability/${LOCATION}?t=${TVAR} date="${DATE}T07:00:00.000Z" dayCount:=1 includeHours:=true includeRentalPoints:=true includeWorkRuleNames:=false resourceIds:="[${COURTS}]" 'Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1laWQiOiIxNDA3OTU3Iiwicm9sZSI6ImNsaWVudCIsIm5iZiI6MTYyMzY4NjkxMywiZXhwIjoxNzEwMDg2OTEzLCJpYXQiOjE2MjM2ODY5MTMsImlzcyI6IkJ1a3phIiwiYXVkIjoiVXNlcnMifQ.X3d0oOUllpyrx9m5UwmC_uBGU-nGimQgA2QvwuE8vjBqiK016zvdQ5WeG6pX9n-3N72clmD9m5JzNCQ5J0ixa0jOCdZ8gduwcFcsNUuDpeS8Xsh7xWyE3o6wYOIzjDp4psQCsyHQUvTmEvclnMqCwgfhCiUcrBKk2qciglMxSGNevuGoIn6oldNfHguUrOHZLRDy-jChoGqLBzmBq3-NLfPYdhHXy2V1vXvLrvBkKuDFZG_v4gUSMXW5ymlL75NbDWJ3VvEJ8TeCQP6473QQa4kefYslRljny4SI55b4qzYuhzb05jpC1Vv6t5fWnbRzB_RDrLLeI9OvDhdXYMJ3dA' 'Content-Type: application/json;charset=utf-8' > ${TEMP_FILENAME}_ERROR 2>&1;
    else 
      echo "<ul>" >> ${TEMP_HTML}
      for HOUR in `grep hours ${file} | cut -d ':' -f 2 | tr ',' '\n'`; do 
        HOUR_ZULU=`${DATE_PROG} -d "${DATE}T${HOUR}:00:00 ${TIME_ZONE}" -u +"%H"`;
        COURTS_FREE=`cat ${TEMP_FILENAME} | jq '.resources | .[] | {court: .resourceId, days: .days[]} | {court: .court, start: .days.startPoints[] | .date, end: .days.endPoints[] | .date}' | grep -B 1 "start.*T${HOUR_ZULU}:" | grep court | sort -u | wc -l`;
        echo "<li>${HOUR}:00 ${TIME_ZONE} - ${COURTS_FREE} courts are free</li>" >> ${TEMP_HTML}
      done
      echo "</ul>" >> ${TEMP_HTML};
      echo "</div>" >> ${TEMP_HTML};
    fi
  done
  echo "</div>" >> ${TEMP_HTML};
done
echo "</body>" >> ${TEMP_HTML};

cp -f ${TEMP_HTML} ${FINAL_DIR}/summary.html
