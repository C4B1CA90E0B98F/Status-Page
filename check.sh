#!/bin/bash
# In the original repository we'll just print the result of status checks,
# without committing. This avoids generating several commits that would make
# later upstream merges messy for anyone who forked us.
commit=true
origin=$(git remote get-url origin)

if [[ $origin == *CZ4B/Status-Page* ]]; then
  commit=false
fi

KEYSARRAY=()
URLSARRAY=()

urlsConfig="./urls.cfg"
echo "Reading $urlsConfig"

if [[ -f "$urlsConfig" ]]; then
  while IFS='=' read -r key url || [[ -n $key ]]; do
    key=$(echo "$key" | xargs)
    url=$(echo "$url" | xargs)

    if [[ -n "$key" && -n "$url" ]]; then
      KEYSARRAY+=("$key")
      URLSARRAY+=("$url")
    fi
  done < "$urlsConfig"
else
  echo "Error: $urlsConfig file not found."
  exit 1
fi

mkdir -p logs

echo "Number of URLs: ${#URLSARRAY[@]}"

for (( index=0; index < ${#KEYSARRAY[@]}; index++ )); do
  key="${KEYSARRAY[index]}"
  url="${URLSARRAY[index]}"

  for i in {1..4}; do
    echo "Checking $url (Attempt $i)"
    response=$(curl --write-out '%{http_code}' --silent --output /dev/null "$url")

    if [[ "$response" -eq 200 || "$response" -eq 202 || "$response" -eq 301 || "$response" -eq 307 ]]; then
      result="success"
      break
    else
      result="failed"
    fi

    sleep 5
  done

  dateTime=$(date +'%Y-%m-%d %H:%M')

  if [[ $commit == true ]]; then
    echo "$dateTime, $result" >> "logs/${key}_report.log"
  else
    echo "    $dateTime, $result"
  fi
done

if [[ $commit == true ]]; then
  git config --global user.name "$1"
  git config --global user.email "$2"
  git add -A --force logs/
  git commit -am '[Automated] Update Status'
  git push
fi
