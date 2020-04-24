#!/bin/bash

set -o pipefail

org='PokeAPI'
data_repo='api-data'
branch_name='testbranch'

prepare() {
  mkdir -p ./testpr
  cd testpr || exit
}

clone() {
  git clone "https://github.com/$org/$data_repo.git" "$data_repo"
  cd "$data_repo" || exit
}

configure_git() {
  git config --global user.name "pokeapi-machine-user"
  git config --global user.email pokeapi.co@gmail.com
}

push() {
  git checkout -b "$branch_name"
  touch .gitkeeptestpr
  git add .
  git commit -m "play: add test file"
  git push -uf origin "$branch_name"
}

pr_content() {
  cat <<EOF
{
  "title": "API data update",
  "body": "Incoming data generated by https://github.com/PokeAPI/pokeapi CircleCI worker",
  "head": "$branch_name",
  "base": "master",
  "assignees": [
    "Naramsim"
  ],
  "labels": [
    "api-data-update"
  ]
}
EOF
}

assignees_and_labels() {
  cat <<EOF
{
  "assignees": [
    "Naramsim"
  ],
  "labels": [
    "api-data-update"
  ]
}
EOF
}

reviewers() { # TODO: Add core team
  cat <<EOF
{
  "reviewers": [
    "Naramsim"
  ]
}
EOF
}

create_pr() {
  pr_number=$(curl -H "Authorization: token $MACHINE_USER_GITHUB_API_TOKEN" -X POST --data "$(pr_content)" "https://api.github.com/repos/$org/$data_repo/pulls" | jq '.number')
  if [[ "$pr_number" = "null" ]]; then
    echo "Couldn't create the Pull Request"
    exit 1
  fi
  echo "$pr_number"
}

customize_pr() {
  pr_number=$1
  curl -H "Authorization: token $MACHINE_USER_GITHUB_API_TOKEN" -X PATCH --data "$(assignees_and_labels)" "https://api.github.com/repos/$org/$data_repo/issues/$pr_number"
  if [ $? -ne 0 ]; then
		echo "Couldn't add Assignees and Labes to the Pull Request"
	fi
}

assign_pr() {
  pr_number=$1
  curl -H "Authorization: token $MACHINE_USER_GITHUB_API_TOKEN" -X POST --data "$(reviewers)" "https://api.github.com/repos/$org/$data_repo/pulls/$pr_number/requested_reviewers"
  if [ $? -ne 0 ]; then
    echo "Couldn't add Reviewers to the Pull Request"
  fi
}

prepare
clone
configure_git
push
sleep 10
pr_number=$(create_pr)
sleep 10
customize_pr "$pr_number"
sleep 10
assign_pr "$pr_number"
