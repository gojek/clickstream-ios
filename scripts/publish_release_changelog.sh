#!/usr/bin/env bash

# Define constants
RED='\033[0;31m'
NC='\033[0m'
GITLAB_PROJECT_URL="$DANGER_GITLAB_HOST/mobile/$CI_PROJECT_NAME"
GITLAB_API_BASE_URL=$DANGER_GITLAB_API_BASE_URL
GITLAB_PROJECT_ID="$CI_PROJECT_ID"
GITLAB_TOKEN="$PRIVATE_API_TOKEN"

# Method to print errors. Prepends the date and time and prints in RED color.
err() {
  echo -e "${RED}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@${NC}" >&2
}

# Get latest tag
latest_tag=$(git describe --abbrev=0 --tags)

# Get the tag before the latest tag i.e. the second latest tag
second_latest_tag=$(git describe --abbrev=0 --tags `git rev-list --tags --skip=1 --max-count=1`)

# Generate changelog from second latest tag to the latest tag
changelog="$(git log --no-merges ${second_latest_tag}..${latest_tag} --grep 'DEVX-' --pretty=format:"%s" | sort -u )"

# Format the changelog: Read the changelog line by line and wrap each line between <li> tags and
# then wrap the entire thing in <ul> tags to render bullet list in gitlab release notes
changelog="<ul>$(while IFS= read -r line ; do echo -n "<li>$line</li>"; done <<< "$changelog")</ul>"

# Method to return changelog as a string which has JSON object. This is used for inserting the
# json object as data inside the curl command
generate_changelog()
{
  cat <<EOF
{
  "description": "$(echo "$changelog")"
}
EOF
}

# Method to generate the gitlab tags api url using the BASE_URL, PROJECT_ID and latest_tag variables
generate_gitlab_tags_api_url() {
    echo "${GITLAB_API_BASE_URL}/projects/${GITLAB_PROJECT_ID}/repository/tags/"$(echo "$latest_tag")"/release"
}

# Make a POST request to Gitlab to create the Release Notes for the latest tag
postApiResponse="$(curl -X POST \
     -H "Content-Type: application/json" \
     -H "PRIVATE-TOKEN: $(echo "$GITLAB_TOKEN")" \
     -d "$(echo "$(generate_changelog)")" \
     --write-out "%{http_code}\n" --silent --output /dev/null \
     --url $(generate_gitlab_tags_api_url))"

# If the POST request gives 200 as HTTP response code i.e. it succeeds the script will exit with code 0
if [[ ${postApiResponse} == *"200"* ]];
then
    echo "Release notes creation successful !"
    exit 0
fi

echo "$(generate_changelog)"

# Make a PUT request to Gitlab to edit the Release Notes for the latest tag
# This will only be executed if the above POST request fails i.e. the release notes already exist
# and thus cannot be created and have to be modified hence a PUT request.
putApiResponse="$(curl -X PUT \
     -H "Content-Type: application/json" \
     -H "PRIVATE-TOKEN: $(echo "$GITLAB_TOKEN")" \
     -d "$(echo "$(generate_changelog)")" \
     --write-out "%{http_code}\n" --silent --output /dev/null \
     --url $(generate_gitlab_tags_api_url))"

# If the PUT request gives 200 as HTTP response code i.e. it succeeds the script will exit with code 0
if [[ ${putApiResponse} == *"200"* ]];
then
    echo "Release notes editing successful !"
    exit 0
fi

# If both the POST and PUT request fail, the script will print the http response codes for both and
# exit with code 1 which will fail the job
err "Release Unsuccessful"
err "Post API Response Code= ${postApiResponse}"
err "Put API Response Code= ${putApiResponse}"
exit 1
