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
TODAY=$(TZ="Africa/Windhoek" date '+%B-%d')
TODAY_DATE=$(TZ="Africa/Windhoek" date '+%A %d-%B, %Y')

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

#███████████████████████████████████████████████████████████████ SET FILES ███

echo "${MORNING}${TELEGRAM_LINK}" > morning.html
echo "${EVENING}${TELEGRAM_LINK}" > evening.html

echo "${MORNING_MD}${TELEGRAM_LINK_MD}" > morning.md
echo "${EVENING_MD}${TELEGRAM_LINK_MD}" > evening.md

#██████████████████████████████████████████████████████████████ SET README ███

echo "# ${M_TIME_N}

${DAILYLIGHT_M_M}

**${DAILYLIGHT[$M_TIME_V]}**

# ${E_TIME_N}

${DAILYLIGHT_M_E}

**${DAILYLIGHT[$E_TIME_V]}**

---

[${TODAY_DATE}](https://t.me/s/daily_light)

> Jonathan Bagster, the son of Samuel Bagster, created the Daily Light for his own family's daily devotion in 1875
" > README.md

git commit -am"${TODAY_DATE}"
git push

exit 0
