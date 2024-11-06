#!/bin/bash
USERNAME="enter-github-username"
curl -s "https://api.github.com/users/$USERNAME/repos?per_page=100" | jq -r '.[].ssh_url' | while read repo; do
  git clone "$repo"
done

# replace with gitlab via its api and token
#
# GITLAB_TOKEN="private-access-token"
# curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/users/$USERNAME/projects?per_page=100" | jq -r '.[].ssh_url_to_repo' | while read repo; do
#  git clone "$repo"
#  done
