#!/bin/bash
# Ensure Homebrew binaries are found inside tmux
export PATH="/opt/homebrew/bin:$PATH"

ALERT_IF_IN_NEXT_MINUTES=10
ALERT_POPUP_BEFORE_SECONDS=10
NERD_FONT_FREE="󱁕 "
NERD_FONT_MEETING="󰤙"

get_attendees() {
  attendees=$(
    icalBuddy \
      --includeEventProps "attendees" \
      --propertyOrder "datetime,title" \
      --noCalendarNames \
      --dateFormat "%A" \
      --includeOnlyEventsFromNowOn \
      --limitItems 1 \
      --excludeAllDayEvents \
      --separateByDate \
      --excludeEndDates \
      --bullet "" \
      --excludeCals "training,omerxx@gmail.com" \
      eventsToday 2>/dev/null
  )
}

parse_attendees() {
  attendees_array=()
  for line in $attendees; do
    attendees_array+=("$line")
  done
  number_of_attendees=$((${#attendees_array[@]}-3))
  if [[ $number_of_attendees -lt 0 ]]; then number_of_attendees=0; fi
}

get_next_meeting() {
  next_meeting=$(
    icalBuddy \
      --includeEventProps "title,datetime" \
      --propertyOrder "datetime,title" \
      --noCalendarNames \
      --dateFormat "%A" \
      --includeOnlyEventsFromNowOn \
      --limitItems 1 \
      --excludeAllDayEvents \
      --separateByDate \
      --bullet "" \
      --excludeCals "training,omerxx@gmail.com" \
      eventsToday 2>/dev/null
  )
}

get_next_next_meeting() {
  end_timestamp=$(date +"%Y-%m-%d ${end_time}:01 %z")
  tonight=$(date +"%Y-%m-%d 23:59:00 %z")
  next_next_meeting=$(
    icalBuddy \
      --includeEventProps "title,datetime" \
      --propertyOrder "datetime,title" \
      --noCalendarNames \
      --dateFormat "%A" \
      --limitItems 1 \
      --excludeAllDayEvents \
      --separateByDate \
      --bullet "" \
      --excludeCals "training,omerxx@gmail.com" \
      eventsFrom:"${end_timestamp}" to:"${tonight}" 2>/dev/null
  )
}

parse_result() {
  # Expect format like: "Friday 15:30 - 16:15 Title of meeting ..."
  # Convert to array tokens
  array=()
  for token in $1; do array+=("$token"); done

  # Guard: if not enough tokens -> no meeting
  if [[ ${#array[@]} -lt 5 ]]; then
    time=""
    end_time=""
    title=""
    return
  fi

  time="${array[2]}"
  end_time="${array[4]}"

  # Title may contain spaces; join the rest
  title="${array[*]:5}"
}

calculate_times(){
  if [[ -z "$time" ]]; then
    epoc_diff=999999
    minutes_till_meeting=9999
    return
  fi
  epoc_meeting=$(date -j -f "%T" "$time:00" +%s 2>/dev/null)
  epoc_now=$(date +%s)
  epoc_diff=$((epoc_meeting - epoc_now))
  minutes_till_meeting=$((epoc_diff/60))
}

display_popup() {
  tmux display-popup \
    -S "fg=#eba0ac" \
    -w50% \
    -h50% \
    -d '#{pane_current_path}' \
    -T meeting \
    icalBuddy \
      --propertyOrder "datetime,title" \
      --noCalendarNames \
      --formatOutput \
      --includeEventProps "title,datetime,notes,url,attendees" \
      --includeOnlyEventsFromNowOn \
      --limitItems 1 \
      --excludeAllDayEvents \
      --excludeCals "training" \
      eventsToday
}

print_tmux_status() {
  if [[ $minutes_till_meeting -lt $ALERT_IF_IN_NEXT_MINUTES && $minutes_till_meeting -gt -60 ]]; then
    echo "$NERD_FONT_MEETING $time $title ($minutes_till_meeting minutes)"
  else
    echo "$NERD_FONT_FREE"
  fi

  if [[ $epoc_diff -gt $ALERT_POPUP_BEFORE_SECONDS && $epoc_diff -lt $((ALERT_POPUP_BEFORE_SECONDS+10)) ]]; then
    display_popup
  fi
}

main() {
  get_attendees
  parse_attendees

  get_next_meeting
  parse_result "$next_meeting"
  calculate_times

  # If first meeting invalid or solo (<=1 attendee), try the next one
  if [[ -z "$time" || -z "$title" || $number_of_attendees -lt 2 ]]; then
    get_next_next_meeting
    parse_result "$next_next_meeting"
    calculate_times
  fi

  print_tmux_status
}

main
