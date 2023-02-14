#!/usr/bin/env bash

MATRIX_OUTPUT="["
COMMA=""
for path in ./images/*; do \
  IMAGE_NAME=${path#./images/}
  for version in "$path"/*; do \
    IMAGE_TAG="$IMAGE_NAME:${version#./images/$IMAGE_NAME/}"
    MATRIX_OUTPUT+="$COMMA\"$IMAGE_TAG\""
    COMMA=","
  done
done
MATRIX_OUTPUT+="]"

echo "$MATRIX_OUTPUT"
