#!/bin/bash

search_and_replace() {
  rg --files -uuu "$1" -g '!\.cache' -g '!\.git' > "$2"
  echo "  Done searching"
  sed -e "s#^$1/##g" "$2" -i
  echo "  Done replacing in $2"
  sort -o "$2" "$2"
  echo "  Done sorting"
}

if [ "$2" == "" ]; then
  first_folder="${HOME}"
else
  first_folder="$2"
fi
second_folder="$1"

out_1="/tmp/current"
out_2="/tmp/snapshot"

filter() {
  rg -v 'CachedData|Cache_Data|__pycache__|\.wine|\.local/share/Trash|\.mozilla|\.thunderbird|\.config/Signal/attachments|\.config/VSCodium|/logs|/User|\.vscode-oss/extensions|/target/build|\.julia|\.local/share/okular|\.local/share/RecentDocuments|Documents/Git/sources|\.mypy_cache|\.cargo/registry|\.zsh|\.nuget|\.npm|node_modules|\.mapscii|\.m2/repository|\.local/state|mangas/.*/[0-9]*|\.config/libreoffice'
}

echo "Doing ${first_folder}"
search_and_replace "${first_folder}" "${out_1}"
echo "Doing ${second_folder}"
search_and_replace "${second_folder}" "${out_2}"

echo "Now diffing"
diff "${out_2}" "${out_1}" > /tmp/diff

echo "In ${second_folder} but not in ${first_folder}:"
rg "^< " /tmp/diff --no-line-number | filter
echo "In ${first_folder} but not in ${second_folder}:"
rg "^> " /tmp/diff --no-line-number | filter
