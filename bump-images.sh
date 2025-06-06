#!/bin/bash
set -euo pipefail

# Validate args
#
if [ "$#" -lt 3 ] || [ $(( ($# - 1) % 2 )) -ne 0 ]; then
  echo "Usage: $0 <image> <source1> <dest1> [<source2> <dest2> ...]"
  exit 1
fi

if ! git diff --cached --quiet; then
  echo "There are staged changes. Aborting"
  exit 1
fi

image="$1"


# Create a copy for easier review
commit_message="Copy over $image images for version bumps"$'\n'
for (( i=2; i<=$#; i++ )); do
  src="${!i}"
  i=$((i+1))
  dst="${!i}"

  if [ ! -d "images/$image/$src" ]; then
    echo "Error: images/$image/$src must exist."
    exit 1
  fi
  if [ -e "images/$image/$dst" ]; then
    echo "Error: images/image/$dst must not exist."
    exit 1
  fi

  cp -r "images/$image/$src" "images/$image/$dst"

  commit_message+=$'\n'"$src -> $dst"
  git add "images/$image/$dst"
done

git commit -s -m "$commit_message"


# Attempt to bump image versions
commit_message="[WIP]Bump $image versions"$'\n'
for (( i=2; i<=$#; i++ )); do
  src=${!i}
  i=$((i+1))
  dst=${!i}


  src_ver=${src#v}
  dst_ver=${dst#v}

  dst_path="images/$image/${!i}"

  # sed is actually expected to fail some times, for instance with binary files
  find "$dst_path" -type f -exec sed -i "s/$src_ver/$dst_ver/g" {} \;

  commit_message+=$'\n'"$src -> $dst"
  git add "$dst_path"
done

# $dst_path is defined in the previous for loop. Be careful with scope when making changes
git commit -s -m "$commit_message"
