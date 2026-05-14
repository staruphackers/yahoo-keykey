# Yahoo! KeyKey Modernization Notes

This repository started as a modern installer around the final Yahoo! KeyKey
binary release, not as the original application source tree.

## Current M-series Compatibility Path

The archived app contains an x86_64 main input method binary and x86_64
OpenVanilla/LFExtensions frameworks, so it can run on Apple Silicon through
Rosetta. It does not contain arm64 slices.

The modern packaging flow in `script/build_and_run.sh` prepares a clean staging
bundle before packaging:

- removes 32-bit-only helper apps that cannot run on modern macOS
- thins the main input method and frameworks to x86_64
- updates the minimum system metadata
- ad-hoc signs the staged input method by default
- installs Rosetta during preinstall on Apple Silicon when needed
- refreshes LaunchServices registration during postinstall

For public distribution, set `APP_SIGN_IDENTITY` and `INSTALLER_SIGN_IDENTITY`
to Developer ID identities before building.

## Native arm64 Blockers

The YahooArchive/KeyKey source tree can be partially driven by modern Xcode with
`ARCHS=arm64 SDKROOT=macosx`, but a complete native rebuild is blocked by missing
commercial SQLite CEROD/SEE source used by the original `KeyKey.db`.

Observed blockers during the arm64 probe:

- old XIB files mark targets earlier than macOS 10.6 and need metadata updates
- `OVFileHelper.h` needs modern POSIX declarations such as `unistd.h`
- the public source tree lacks `ExternalLibraries/sqlite-cerod-see/sqlite3-cerod-see-aes128-ccm-combined.c`
- replacing CEROD/SEE with public SQLite compiles further but cannot read the
  shipped encrypted `KeyKey.db`

Native arm64 work therefore needs one of these follow-up tracks:

- rebuild an unencrypted compatible dictionary database from redistributable
  data sources
- replace the database engine and migrate the smart Mandarin model
- port Yahoo KeyKey behavior onto a currently maintained OpenVanilla or
  McBopomofo foundation
