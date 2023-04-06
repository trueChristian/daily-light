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
command -v curl >/dev/null 2>&1 || {
  echo >&2 "We require curl for this script to run, but it's not installed.  Aborting."
  exit 1
}

# global config options
DRY_RUN=0

# check if we have options
while :; do
  case $1 in
  --dry)
    DRY_RUN=1
    ;;
  *) # Default case: No more options, so break out of the loop.
    break ;;
  esac
  shift
done

#██████████████████████████████████████████████████████████████ DATE TODAY ███
# must set the time to Namibian :)
TODAY=$(TZ="Africa/Windhoek" date '+%A %d-%B, %Y')

BOT_TOKEN="${BOT_TOKEN}"
CHANNEL_ID="${CHANNEL_ID}"

CHAT_INFO=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getChat?chat_id=${CHANNEL_ID}")

MESSAGE_ID=$(echo $CHAT_INFO | jq ".result.pinned_message.forward_from_message_id")
TEXT=$(echo $CHAT_INFO | jq ".result.pinned_message.text" | tr -d "\"")
KEYWORD=$(echo -e "$TEXT" | awk 'NR==1 {print $1}' | tr '[:upper:]' '[:lower:]')

FILE_PATH="${KEYWORD}.tg.id"

# check test behaviour
if (("$DRY_RUN" == 1)); then
  echo "===================================================="
  echo "Message ID: ${MESSAGE_ID}"
  echo "Keyword: ${KEYWORD}"
  echo "===================================================="
elif [ ! -f "${FILE_PATH}" ] || [ "$(cat "${FILE_PATH}")" != "${MESSAGE_ID}" ]; then
  # set ID
  echo "${MESSAGE_ID}" >"${FILE_PATH}"

  # make sure to add new files and folders
  git add .
  git commit -am"${TODAY}"
  git push
fi

exit 0
