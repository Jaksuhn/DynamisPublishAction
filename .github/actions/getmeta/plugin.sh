#!/usr/bin/env bash
set -euo pipefail

version_gte() {
    printf '%s\n%s\n' "$2" "$1" | sort --check=quiet --version-sort
}

say() {
    echo "$@" | tee -a $GITHUB_OUTPUT
}

die() {
    echo >&2 "$@"
    exit 1
}

if [ -z "$PLUGIN_ID" ]; then
    die "Plugin ID is required."
fi

if [ -z "$INTERNAL_NAME" ]; then
    INTERNAL_NAME="$(curl -f https://puni.sh/api/plugins/$PLUGIN_ID/internal-name)"
fi

if [ -z "$INTERNAL_NAME" ]; then
    die "Internal error: unable to fetch internal name from Dynamis for plugin $PLUGIN_ID"
fi

say "internal_name=$INTERNAL_NAME"

if [ -z "$PROJECT_FILE" ]; then
    PROJECT_FILE="$(find . -type f -name "$INTERNAL_NAME".csproj)"
fi

if [ -z "$PROJECT_FILE" ]; then
    die "Unable to find project file '$INTERNAL_NAME.csproj'."
fi

say "project_file=$PROJECT_FILE"

remote_versions=$(curl -f "https://puni.sh/api/plugins/$PLUGIN_ID/versions")

remote_release="$(jq .latest <<< $remote_versions)"
remote_testing="$(jq .testing <<< $remote_versions)"

if version_gte "$remote_testing" "$remote_release"; then
    remote_actual="$remote_testing"
else
    remote_actual="$remote_release"
fi

say "remote_version=$remote_actual"

if [ -z "$VERSION" ]; then
    case "$VERSION_POLICY" in
        assembly)
            VERSION="$(dotnet msbuild -getProperty:Version "$PROJECT_FILE")"
            ;;
        tag)
            if [[ "$REF_NAME" == t* ]]; then
                TESTING="true"
            fi
            tag=$(sed 's/^[tv]//' <<< $REF_NAME)
            if grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' <<< "$tag"; then
                VERSION="$tag"
            else
                die "$tag doesn't look like a valid version number"
            fi
            ;;
        increment)
            VERSION=$(awk -F. -v OFS=. '{$NF += 1; print}' <<< $remote_actual)
            ;;
        *)
            die "Unknown version policy '$VERSION_POLICY': valid values are assembly, tag, increment; or specify version manually"
            ;;
    esac
fi

if [ -z "$VERSION" ]; then
    die "Unable to determine version (policy: $VERSION_POLICY)"
fi

say "local_version=$VERSION"
if [ "$TESTING" = "true" ]; then
    say "release_type=testing"
else
    say "release_type=latest"
fi

if version_gte "$remote_actual" "$VERSION"; then
    say "should_build=false"
else
    say "should_build=true"
fi
