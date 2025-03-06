#!/bin/bash
USERNAME="MANGSA_HANG_KAU_NK_TARGET"
curl -s "https://api.github.com/users/$USERNAME/gists?per_page=100" | jq -r '.[].id' | while read gist_id; do
  git clone "https://gist.github.com/$USERNAME/$gist_id.git"
done
