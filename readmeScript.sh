#!/bin/bash

# sending love to https://github.com/mshick :) <3
readonly GITHUB_TOKEN=${GITHUB_TOKEN}
readonly FEED_URL=${FEED_URL:-https://github.blog/feed/}
readonly TIMEZONE=${TIMEZONE:-Europe/London}

readonly pushes_graphql="
{
  viewer {
    repositories(first: 10, privacy: PUBLIC, orderBy: {field: PUSHED_AT, direction: DESC}, ownerAffiliations: [OWNER]) {
      pageInfo {
        hasNextPage
        endCursor
      }
      nodes {
        name
        description
        url
        pushedAt
      }
    }
  }
}
"

function gnudate {
  if hash gdate 2>/dev/null; then
    TZ=${TIMEZONE} gdate "$@"
  else
    TZ=${TIMEZONE} date "$@"
  fi
}

function pushes::request {
  local token="$1"
  local formatted_query="${2//[$'\t\r\n']}"

  curl -sS \
    --request 'POST' \
    --url 'https://api.github.com/graphql' \
    --header "authorization: Bearer ${token}" \
    --header "content-type: application/json" \
    --data "{\"query\":\"${formatted_query}\"}"
}

function pushes::format {
  local IFS=','
  
  declare -a data=( )

  while read -ra data; do
    local name=${data[0]}
    name="${name%\"}"
    name="${name#\"}"

    local url=${data[1]}
    url="${url%\"}"
    url="${url#\"}"

    local pushed_at=${data[2]}
    pushed_at="${pushed_at%\"}"
    pushed_at="${pushed_at#\"}"    
    pushed_at=$(gnudate --date "${pushed_at}" --iso-8601=minutes)    

    echo "- <samp>[${name}](${url}) <kbd>${pushed_at}</kbd></samp>"
  done  
}

function posts::request {
  curl -sS \
    --request 'GET' \
    --url "${FEED_URL}"
}

function posts::format_atom_feed {
  local IFS='>'
  local tag=''
  local value=''

  while read -d '<' tag value; do
    case ${tag/%\ */} in
      'entry')
        title=''
        link=''
        pubDate=''
        description=''
        datetime=''
        ;;
      'title')
        title="$value"
        ;;
      'link')
        link=$(echo $tag | sed -e 's/.*href="\([^"]*\).*/\1/')
        ;;
      'updated')
        datetime=$(gnudate --date "$value" --iso-8601=minutes)
        pubDate=$(gnudate --date "$value" '+%D %H:%M%P')
        ;;
      '/entry')
        echo "- <samp>[${title}](${link}) <kbd>${datetime}</kbd></samp>"
        ;;
    esac
  done
}

function posts::format_rss_feed {
  local IFS='>'
  local tag=''
  local value=''

  while read -d '<' tag value; do
    case ${tag/%\ */} in
      'item')
        title=''
        link=''
        pubDate=''
        description=''
        datetime=''
        ;;
      'title')
        title="$value"
        ;;
      'link')
        link="$value"
        ;;
      'pubDate')
        datetime=$(gnudate --date "$value" --iso-8601=minutes)
        pubDate=$(gnudate --date "$value" '+%D %H:%M%P')
        ;;
      '/item')
        echo "- <samp>[${title}](${link}) <kbd>${datetime}</kbd></samp>"
        ;;
    esac
  done
}

function format::insert {
  awk -i inplace \
    -v begin="$1" \
    -v end="$2" \
    -v data="$3" '$0~end{f=0} !f{print} $0~begin{print data;f=1}' \
    "$4"
}

function main {
  local pushes=$(
    pushes::request "$GITHUB_TOKEN" "$pushes_graphql" \
    | jq -r '.data.viewer.repositories.nodes[] | [.name, .url, .pushedAt] | @csv' \
    | pushes::format \
    | sed -e 's/  *$//'
  )

  format::insert \
    "<!-- PUSHES:START -->" \
    "<!-- PUSHES:END -->" \
    "\n$pushes\n" \
    README.md

  local posts=$(
    posts::request \
    | posts::format_rss_feed \
    | sed -e 's/  *$//'
  )

  format::insert \
    "<!-- POSTS:START -->" \
    "<!-- POSTS:END -->" \
    "\n$posts\n" \
    README.md
}

main "$@"
