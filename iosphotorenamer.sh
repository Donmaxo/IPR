#!/bin/bash

PREFIX="IPH"
RENAMED_COUNTER=0
FILES_COUNTER=0
PROGRESS_BAR_SIZE=50

rename_file () {
  ((FILES_COUNTER++))
  local FILENAME=$(basename "$1")
  local EXTENSION="${FILENAME##*.}"

  if [[ "$EXTENSION" = "HEIC" ]] || [[ "$EXTENSION" = "HEVC" ]] || [[ "$EXTENSION" = "DNG" ]] || [[ "$EXTENSION" = "JPG" ]] || [[ "$EXTENSION" = "MOV" ]]; then
    local TIME=$(exiftool -s3 -DateTimeOriginal -d "%Y%m%d_%H%M%S" "$1")
    if [ $? -ne 0 ]; then
     	echo
      echo "File $1 has not been renamed because: Failed to extract time using exiftool"
      return
    fi

    local NAME="${PREFIX}_${TIME}.${EXTENSION}"

    if [ -f "$2/$NAME" ]; then
      local SAME_TIME_COUNTER=1
      while [ -f "$2/$NAME" ]
      do
        local NAME="${PREFIX}_${TIME}${SAME_TIME_COUNTER}.${EXTENSION}"
        ((SAME_TIME_COUNTER++))
      done
    fi

    mv "$1" "$2/$NAME"
    if [ $? -ne 0 ]; then
    	echo
      echo "File $1 has not been renamed because: Failed to rename"
      return
    fi

    ((RENAMED_COUNTER++))
  else
    echo "File $1 has not been renamed because: Unsupported file extension"
  fi
}

update_progress_bar() {
  local progress=$(($1 * $PROGRESS_BAR_SIZE / $2))
  printf "\r["
  for ((i=0; i<$PROGRESS_BAR_SIZE; i++)); do
    if [ $i -lt $progress ]; then
      printf "="
    else
      printf " "
    fi
  done
  printf "] $1/$2 files processed"
}

if [ -f "$1" ]; then
  FILE_PATH=$(dirname "$1")
  rename_file "$1" "$FILE_PATH"
  echo "Renamed $RENAMED_COUNTER file."

elif [ -d "$1" ]; then
  TOTAL_FILES=$(find "$1" -maxdepth 1 -type f | wc -l)
  while IFS= read -r -d '' IMAGE; do
    rename_file "$IMAGE" "$1"
    update_progress_bar $FILES_COUNTER $TOTAL_FILES
  done < <(find "$1" -maxdepth 1 -type f -print0)

  echo -e "\nRenamed $RENAMED_COUNTER file(s) out of $FILES_COUNTER encountered."
else
  echo "The supplied path is neither file nor folder or is missing."
fi
