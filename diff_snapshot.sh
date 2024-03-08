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
  rg -v 'CachedData|Cache_Data|\.config/VSCodium|\.vscode-oss/extensions' | \
  rg -v '__pycache__|\.mypy_cache' | \
  rg -v 'node_modules|\.npm' | \
  rg -v '\.wine|\.cargo/registry|\.julia|\.nuget|\.mapscii|\.m2/repository' | \
  rg -v '\.local/share/Trash|\.local/share/okular' | \
  rg -v '\.mozilla|\.thunderbird|\.local/share/RecentDocuments' | \
  rg -v '\.config/Signal/attachments' | \
  rg -v '\.config|libreoffice' | \
  rg -v '/target/build|/target/release|/target/debug|Documents/Git/sources' | \
  rg -v '\.local/state' | \
  rg -v 'mangas/.*/[0-9]*' | \
  rg -v 'Documents/Gentoo/gentoo|Documents/Gentoo/GURU'
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
