#!/bin/bash
get-client() {
    target_version="$1"
    # All remote branches
    branches=$(git branch -a | sed 's|remotes/origin/||')
    echo "Finding matching client version from cogstate-client repository..."
    echo "Using branch: $target_version"

    version=$(echo $target_version | grep -o '[0-9]*\.[0-9]*\.[0-9]*')
    echo "Version found: $version"

    matching_version=$(echo "$branches" | grep -E "*release/$version")
    echo "Matching version found: $matching_version"

    if [ -z "$matching_version" ]; then
      echo "No matching version found."
      # TODO: Handle the case where no matching version is found find nearest version
      closest_version="release/4.13.0"
      echo "client_version=$closest_version" >> $GITHUB_OUTPUT
      exit 1
    fi
    echo "client_version=$matching_version" >> $GITHUB_OUTPUT
}