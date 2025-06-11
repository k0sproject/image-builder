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

if [ "$1" = "calico" ]; then
  images=(calico-node calico-kube-controllers calico-cni)
else
  images=("$1")
fi


# Create a copy for easier review
commit_message="Copy over $1 images for version bumps"$'\n'
for (( i=2; i<=$#; i++ )); do
  src="${!i}"
  i=$((i+1))
  dst="${!i}"

  commit_message+=$'\n'"$src -> $dst"
  for image in "${images[@]}"; do
    if [ ! -d "images/$image/$src" ]; then
      echo "Error: images/$image/$src must exist."
      exit 1
    fi
    if [ -e "images/$image/$dst" ]; then
      echo "Error: images/image/$dst must not exist."
      exit 1
    fi

    cp -r "images/$image/$src" "images/$image/$dst"
    git add "images/$image/$dst"
  done

done

git commit -s -m "$commit_message"


# Attempt to bump image versions
commit_message="[WIP]Bump $1 versions"$'\n'
for (( i=2; i<=$#; i++ )); do
  src=${!i}
  i=$((i+1))
  dst=${!i}

  commit_message+=$'\n'"$src -> $dst"

  src_ver=${src#v}
  src_ver=${src_ver%-*}
  dst_ver=${dst#v}
  dst_ver=${dst_ver%-*}

  for image in "${images[@]}"; do
    dst_path="images/$image/${!i}"

    # sed is actually expected to fail some times, for instance with binary files
    find "$dst_path" -type f -exec sed -i "s/$src_ver/$dst_ver/g" {} \;
    git add "$dst_path"
  done
done

# $dst_path is defined in the previous for loop. Be careful with scope when making changes
git commit -s -m "$commit_message"
