A composite action for [Dalamud](https://github.com/goatcorp/Dalamud) plugins that upload to [Dynamis](https://github.com/PunishXIV/Dynamis).

A consuming workflow looks like the following. 

```yaml
on:
  push:
    tags:
      - "v*.*.*.*"

permissions:
  contents: read

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - name: Build and publish
        uses: Jaksuhn/DynamisPublishAction@master
        with:
          plugin_id: 00
          publisher_key: ${{ secrets.PUBLISHER_KEY }}
```

The only required inputs are the dynamis plugin id, and the publisher key, which should be set up as a secret in your repo.  
The remaining inputs are optional overrides in case auto detection fails.
