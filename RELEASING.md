# Release process

Every public download must be generated with `Package-Release.ps1`.
The script creates `release/CoAAnalytics.zip` and requires both addon folders:

- `CoAAnalytics`
- `CoAAnalytics_DataProbe`

Upload `CoAAnalytics.zip` to the matching GitHub Release. Keep the asset name
unchanged so the permanent latest-download link continues to work.
