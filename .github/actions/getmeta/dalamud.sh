#!/usr/bin/env bash
set -euo pipefail

say() {
    echo "$@" | tee -a $GITHUB_OUTPUT
}

schema="$(curl -f https://kamori.goats.dev/Dalamud/Release/meta)"
case "$DALAMUD_TRACK" in
    prefer-release)
        track=$(jq -er '
            to_entries
            | map(select(.value.hidden | not))
            | max_by([.value.supportedGameVer, (.key == "release"), (.key == "stg")])
            | .key
        ' <<< "$schema")
        ;;
    *)
        track="$DALAMUD_TRACK"
        ;;
esac

track_schema=$(jq -e --arg t "$track" '.[$t]' <<< "$schema")

if [ -z "$DALAMUD_VERSION" ]; then
    DALAMUD_VERSION=$(jq -er .assemblyVersion <<< $track_schema | cut -d. -f1)
fi

if [ -z "$DOTNET_VERSION" ]; then
    DOTNET_VERSION=$(jq -er .runtimeVersion <<< $track_schema | cut -d. -f1-2)
fi

if [ "$track" = "release" ]; then
    say "dalamud_url=https://goatcorp.github.io/dalamud-distrib/latest.zip"
else
    say "dalamud_url=https://goatcorp.github.io/dalamud-distrib/$track/latest.zip"
fi

say "dalamud_version=$DALAMUD_VERSION"
say "dotnet_version=$DOTNET_VERSION"
