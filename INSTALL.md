# Installation

## Requirements

- X-Plane 12
- FeelMySparks 748i aircraft package

## Installing

1. Download or obtain the FeelMySparks 748i aircraft package.
2. Extract the downloaded archive, if applicable.
3. Copy the aircraft folder into your X-Plane 12 `Aircraft` directory. For example:

   `X-Plane 12/Aircraft/FeelMySparks 748i/`

4. Start X-Plane 12.
5. Open the aircraft selection menu and select **FeelMySparks 748i**, if it is available.

## Notes

- This project is currently in early development. Installation instructions may change.
- Additional aircraft dependencies may be required and will be listed here if applicable.
- Do not install over another aircraft's folder.
- This aircraft is intended for flight simulation in X-Plane 12 only.

## Troubleshooting

If the aircraft does not appear in X-Plane 12, check that the aircraft folder is extracted correctly and that the aircraft files are not nested inside an extra folder.

---

*FeelMySparks 748i — an independent X-Plane 12 community project.*

## Weight and Balance Plugin

When installing the aircraft package into `X-Plane 12/Aircraft/FeelMySparks 748i/`, ensure that this companion plugin is present at:

```
FeelMySparks 748i/747-8i/plugins/FeelMySparks748i_WB/64/mac.xpl
```

On macOS, remove quarantine from the copied aircraft package so X-Plane does not require manual approval on every launch:

```
xattr -dr com.apple.quarantine '/path/to/FeelMySparks 748i'
```

Current platform support:

- macOS universal binary: included.
- Windows and Linux binaries: not yet built.
