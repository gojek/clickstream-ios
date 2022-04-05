#!/usr/bin/env bash

# Define constants
RED='\033[0;31m'
NC='\033[0m'
GITLAB_PROJECT_URL="$DANGER_GITLAB_HOST/mobile/$CI_PROJECT_NAME"
SLACK_WEBHOOK_URL="$SLACK_SECRET_PATH"

# Method to print errors. Prepends the date and time and prints in RED color.
err() {
  echo -e "${RED}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@${NC}" >&2
}

# Get latest tag
latest_tag=$(git describe --abbrev=0 --tags)

# Get the tag before the latest tag i.e. the second latest tag
second_latest_tag=$(git describe --abbrev=0 --tags `git rev-list --tags --skip=1 --max-count=1`)

# Generate changelog from second latest tag to the latest tag. Match pattern 'DEVX-' to discard any extraneous commits.
changelog="$(git log --no-merges ${second_latest_tag}..${latest_tag} --grep 'DEVX-' --pretty=format:"%s" | sort -u)"

# Format the changelog:
# Read the changelog line by line and insert '-' at the start and '\n' at end of each line
changelog="$(while IFS= read -r line ; do echo -n "- $line \n"; done <<< "$changelog")"

# Compose the release message
release_message="\`$CI_PROJECT_NAME $latest_tag\` has been released. \n \
\`\`\`Changelog:\n\
$changelog\`\`\` \
You can also find the changelog at: $GITLAB_PROJECT_URL/-/tags/$latest_tag"

echo $release_message

# Method to return changelog as a string which has JSON object. This is used for inserting the
# json object as data inside the curl command
generate_changelog()
{
  cat <<EOF
{
  "text": "$(echo "<!channel> $release_message")"
}
EOF
}

# Make a POST request to Slack to send the Release Notes  message for the latest release
slackPostApiResponse="$(curl -X POST \
     -H 'Content-type: application/json' \
     --data "$(echo "$(generate_changelog)")" \
     --write-out "%{http_code}\n" --silent --output /dev/null \
     --url ${SLACK_WEBHOOK_URL})"

# If the POST request gives 200 as HTTP response code i.e. it succeeds the script will exit with code 0
if [[ ${slackPostApiResponse} == *"200"* ]];
then
    echo "Announcing $CI_PROJECT_NAME release to Slack successful"
    exit 0
fi

If the POST request fails, the script will print the http response code for the request and
exit with code 1 which will pass the job with a warning. This is done so that the job isn't blocking.
err "Announcing $CI_PROJECT_NAME release to Slack Unsuccessful"
err "Post API Response Code= ${slackPostApiResponse}"
exit 1
