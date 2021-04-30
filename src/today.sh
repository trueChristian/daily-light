#!/bin/bash

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

#█████████████████████████████████████████████████████████████████████ DAY ███
TODAY=`date '+%B-%d'`
TODAY_DATE=`date '+%A %d-%B, %Y'`

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

#████████████████████████████████████████████ SET TODAY'S MESSAGES IN HTML ███

DAILYLIGHT="${DAILYLIGHT_M_M//$'\n'/<br>}"
MORNING="<p><i><u>${M_TIME_N}</u></i></p>
<p>${DAILYLIGHT}</p>
<p><strong>${DAILYLIGHT[$M_TIME_V]}</strong></p>"
DAILYLIGHT="${DAILYLIGHT_M_E//$'\n'/<br>}"
EVENING="<p><i><u>${E_TIME_N}</u></i></p>
<p>${DAILYLIGHT}</p>
<p><strong>${DAILYLIGHT[$E_TIME_V]}</strong></p>"

TELEGRAM_LINK="<p><a id=\"daily-light-link\" href=\"https://t.me/daily_light\">${TODAY_DATE}</a></p>"

#████████████████████████████████████████ SET TODAY'S MESSAGES IN MARKDOWN ███

DAILYLIGHT="${DAILYLIGHT_M_M/<strong>/**}"
DAILYLIGHT="${DAILYLIGHT/<\/strong>/**}"
MORNING_MD="## ${M_TIME_N}

${DAILYLIGHT}

**${DAILYLIGHT[$M_TIME_V]}**"

DAILYLIGHT="${DAILYLIGHT_M_E/<strong>/**}"
DAILYLIGHT="${DAILYLIGHT/<\/strong>/**}"
EVENING_MD="## ${E_TIME_N}

${DAILYLIGHT}

**${DAILYLIGHT[$E_TIME_V]}**"

TELEGRAM_LINK_MD="

[${TODAY_DATE}](https://t.me/daily_light)"

#███████████████████████████████████████████████████████████████ SET FILES ███

echo "${MORNING}${TELEGRAM_LINK}" > morning.html
echo "${EVENING}${TELEGRAM_LINK}" > evening.html

echo "${MORNING_MD}${TELEGRAM_LINK_MD}" > morning.md
echo "${EVENING_MD}${TELEGRAM_LINK_MD}" > evening.md

#██████████████████████████████████████████████████████████████ SET README ███

echo "${MORNING_MD}

${EVENING_MD}

---

[${TODAY_DATE}](https://t.me/s/daily_light)

> Jonathan Bagster, the son of Samuel Bagster, created the Daily Light for his own family's daily devotion in 1875
" > README.md

git commit -am"${TODAY_DATE}"
git push

exit 0
