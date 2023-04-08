#!/bin/bash

# Do some prep work
command -v jq >/dev/null 2>&1 || {
  echo >&2 "We require jq for this script to run, but it's not installed.  Aborting."
  exit 1
}
command -v git >/dev/null 2>&1 || {
  echo >&2 "We require git for this script to run, but it's not installed.  Aborting."
  exit 1
}

#█████████████████████████████████████████████████████████████████ GLOBALS ███
# global config options
DRY_RUN=0
DO_GIT=1
# the date
TODAY=$(TZ="Africa/Windhoek" date '+%B-%d')
TODAY_DATE=$(TZ="Africa/Windhoek" date '+%A %d-%B, %Y')

#█████████████████████████████████████████████████████████████ SET OPTIONS ███
# check if we have options
while :; do
  case $1 in
  --dry)
    DRY_RUN=1
    ;;
  --git-off)
    DO_GIT=0
    ;;
  -t | --today) # Takes an option argument; ensure it has been specified.
    if [ "$2" ]; then
      TODAY=$2
      shift
    else
      echo >&2 '"--today" requires a non-empty option argument.'
      exit 17
    fi
    ;;
  -t=?* | --today=?*)
    TODAY=${1#*=} # Delete everything up to "=" and assign the remainder.
    ;;
  -t= | --today=) # Handle the case of an empty --today=
    echo >&2 '"--today=" requires a non-empty option argument.'
    exit 17
    ;;
  *) # Default case: No more options, so break out of the loop.
    break ;;
  esac
  shift
done

#█████████████████████████████████████████████████████████████ SCRIPT PATH ███
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#█████████████████████████████████████████████████████████████ DAILY LIGHT ███
DAILY="$DIR/Daily_Light"

#████████████████████████████████████████████████████████████ MORNING KEYS ███
M_TIME_M=2
M_TIME_V=3
M_TIME_N="Morning"

#████████████████████████████████████████████████████████████ EVENING KEYS ███
E_TIME_M=4
E_TIME_V=5
E_TIME_N="Evening"

#███████████████████████████████████████████████████████ GET TODAY'S LIGHT ███
LIGHT=$(grep "${TODAY,,}" "${DAILY}");

#█████████████████████████████████████████████████████████████ FORMAT TEXT ███
IFS='|' read -ra DAILYLIGHT <<< "${LIGHT}"
# Get Morning Message
IFS='+' read -ra DAILYLIGHTARRAY_M <<< "${DAILYLIGHT[$M_TIME_M]}"
DAILYLIGHT_M_M=$( IFS=$'\n'; echo "${DAILYLIGHTARRAY_M[*]}" )
# Get Evening Message
IFS='+' read -ra DAILYLIGHTARRAY_E <<< "${DAILYLIGHT[$E_TIME_M]}"
DAILYLIGHT_M_E=$( IFS=$'\n'; echo "${DAILYLIGHTARRAY_E[*]}" )
# get name
DATE_NAME="${DAILYLIGHT[0]}"
DATE_KEY="${DAILYLIGHT[1]}"

#████████████████████████████████████████████ SET TODAY'S MESSAGES IN HTML ███

MORNING="<i><u>${M_TIME_N}</u></i>
${DAILYLIGHT_M_M}

<strong>${DAILYLIGHT[$M_TIME_V]}</strong>"

EVENING="<i><u>${E_TIME_N}</u></i>
${DAILYLIGHT_M_E}

<strong>${DAILYLIGHT[$E_TIME_V]}</strong>"

TELEGRAM_LINK="

<a id=\"daily-light-link\" href=\"https://t.me/daily_light\">${TODAY_DATE}</a>"

#████████████████████████████████████████ SET TODAY'S MESSAGES IN MARKDOWN ███

DAILYLIGHT_M_M="${DAILYLIGHT_M_M/<strong>/**}"
DAILYLIGHT_M_M="${DAILYLIGHT_M_M/<\/strong>/**}"
MORNING_MD="**${M_TIME_N}**

${DAILYLIGHT_M_M}

**${DAILYLIGHT[$M_TIME_V]}**"

DAILYLIGHT_M_E="${DAILYLIGHT_M_E/<strong>/**}"
DAILYLIGHT_M_E="${DAILYLIGHT_M_E/<\/strong>/**}"
EVENING_MD="**${E_TIME_N}**

${DAILYLIGHT_M_E}

**${DAILYLIGHT[$E_TIME_V]}**"

TELEGRAM_LINK_MD="

[${TODAY_DATE}](https://t.me/daily_light)"

README="# ${M_TIME_N}

${DAILYLIGHT_M_M}

**${DAILYLIGHT[$M_TIME_V]}**

# ${E_TIME_N}

${DAILYLIGHT_M_E}

**${DAILYLIGHT[$E_TIME_V]}**

---

[${TODAY_DATE}](https://t.me/s/daily_light)

> Jonathan Bagster, the son of Samuel Bagster, created the Daily Light for his own family's daily devotion in 1875
"

#████████████████████████████████████████ SET TODAY'S MESSAGES IN JSON ███

# Process a Section
processSection() {
  local NAME="$1"
  local SECTION="$2"
  local SCRIPTURE_REFERENCES="$3"
  local SCRIPTURE_REFERENCES_ARRAY
  local HEADER

  # Extract and remove the header
  HEADER=$(echo "$SECTION" | grep -o -P '(?<=<strong>).*(?=</strong>)')
  SECTION=$(echo "$SECTION" | sed 's/<strong>.*<\/strong>//')

  # Use mapfile to store the output in an array and remove empty lines
  mapfile -t SCRIPTURE_REFERENCES_ARRAY < <(echo "${SCRIPTURE_REFERENCES}" | tr ';' '\n')

  # Build the JSON object for the section
  local SECTION_JSON='{}'
  SECTION_JSON="$(
    jq -n --arg name "$NAME" \
      --arg header "$HEADER" \
      --argjson body "$(printf '%s' "${SECTION}" | jq -R -s -c 'split("+ +") | map(select(. | length > 0)) | map(gsub("^\\s+|\\s+$"; ""))')" \
      --argjson references "$(printf '%s\n' "${SCRIPTURE_REFERENCES_ARRAY[@]}" | jq -R -c '[inputs | select(length > 0) | gsub("^\\s+|\\s+$"; "")]')" '
      {
        name: $name,
        header: $header,
        body: $body,
        references: $references
      }
    '
  )"

  echo "$SECTION_JSON"
}

# Process the morning and evening sections
MORNING_JSON=$(processSection "${M_TIME_N}" "${DAILYLIGHT[$M_TIME_M]}" "${DAILYLIGHT[$M_TIME_V]}")
EVENING_JSON=$(processSection "${E_TIME_N}" "${DAILYLIGHT[$E_TIME_M]}" "${DAILYLIGHT[$E_TIME_V]}")

# Build the final JSON object
JSON='{}'
JSON="$(
    jq -n --arg date_name "$TODAY_DATE" \
        --arg date_key "$DATE_KEY" \
        --argjson morning "$MORNING_JSON" \
        --argjson evening "$EVENING_JSON" \
        --arg telegram "daily_light" \
        --arg source "https://github.com/trueChristian/daily-light" \
        --arg joomla "https://git.vdm.dev/christian/mod_dailylight" '
        {
            date_name: $date_name,
            date_key: $date_key,
            morning: $morning,
            evening: $evening,
            telegram: $telegram,
            source: $source,
            joomla: $joomla
        }
    '
)"

#████████████████████████████████████████████████ SET TODAY'S MESSAGES ███

# check test behaviour
if (("$DRY_RUN" == 1)); then
  echo "===================================================="
  echo "HTML"
  echo "===================================================="
  echo "MORNING: "
  echo -e "${MORNING}"
  echo "----------------------------------------------------"
  echo "EVENING: "
  echo -e "${EVENING}"
  echo "===================================================="
  echo "MARDOWN"
  echo "===================================================="
  echo "MORNING: "
  echo -e "${MORNING_MD}"
  echo "----------------------------------------------------"
  echo "EVENING: "
  echo -e "${EVENING_MD}"
  echo "===================================================="
  echo "JSON"
  echo "===================================================="
  jq <<<"$JSON" -S .
  echo "===================================================="
  echo "README"
  echo "===================================================="
  echo -e "${README}"
else
  #███████████████████████████████████████████████████████████████ SET FILES ███

  echo "${MORNING}${TELEGRAM_LINK}" > morning.html
  echo "${EVENING}${TELEGRAM_LINK}" > evening.html

  echo "${MORNING_MD}${TELEGRAM_LINK_MD}" > morning.md
  echo "${EVENING_MD}${TELEGRAM_LINK_MD}" > evening.md

  #██████████████████████████████████████████████████████████████ SET README ███

  echo "${README}" > README.md

  #████████████████████████████████████████████████████████████████ SET JSON ███

  jq <<<"$JSON" -S . >README.json

  #██████████████████████████████████████████████████████████████ UPDATE GIT ███
  if (("$DO_GIT" == 1)); then
    git add .
    git commit -am"${TODAY_DATE}"
    git push
  fi
fi

exit 0
