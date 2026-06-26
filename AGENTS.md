# ReNamery Agent Rules

## Release Trigger

When the user says `リリースしてください` or otherwise explicitly requests a release, handle the release workflow. Do not create release commits, tags, or pushes without an explicit release request.

## Release Versioning

- Follow Semantic Versioning.
- Use PATCH for bug fixes, UI tweaks, and wording changes.
- Use MINOR for new features, UX improvements, and new settings.
- Use MAJOR only when the user explicitly requests a major version or the change is intentionally incompatible.
- Keep `pubspec.yaml` version and the latest `CHANGELOG.md` entry in sync.
- The release tag must be `v<version>` and must match the version in `pubspec.yaml` and `CHANGELOG.md`.

## Release Steps

1. Confirm the intended version bump level when it is ambiguous.
2. Update `pubspec.yaml` version.
3. Update `CHANGELOG.md` with the release entry.
4. Update the homepage version in the external `apps.html` file as described below.
5. Run relevant validation such as `dart scripts/release_validator.dart --validate-version`, `flutter analyze`, and targeted tests/builds when feasible.
6. Inspect `git status`, `git diff`, and `git log --oneline -10` before committing.
7. Commit only intended files.
8. Create tag `v<version>`.
9. Push the branch and the tag. GitHub Actions release runs only when a `v*` tag is pushed.

## GitHub Actions Release Behavior

- A normal branch push does not publish a release.
- `.github/workflows/release.yml` starts on `push` tags matching `v*`.
- The workflow builds Windows, Android, and Linux artifacts and uploads them to GitHub Releases.

## Release Notes After Failed Releases

- If a previous `v*` tag was pushed but GitHub Actions failed before publishing usable artifacts, do not assume users saw that version.
- The next successful release entry in `CHANGELOG.md` must include the user-facing changes accumulated since the last successful release, not only the technical fix that made CI pass.
- Keep the wording approachable: describe what users can do better or what became more stable, then mention technical details only when they help explain the fix.
- Avoid release notes that only say things like dependency updates, CI fixes, or build corrections when those changes are required to deliver earlier user-facing improvements.
- When creating GitHub Release notes, use the same principle: summarize the visible improvements from the last successful release through the current successful release.

## Windows Release Artifact Naming

Windows release artifact names must use `win`, not `windows`.

- `ReNamery-vX.X.X-win-x64.msi`
- `ReNamery-vX.X.X-win-x64.msix`
- `ReNamery-vX.X.X-win-x64.zip`

## Homepage Version Update

When handling `リリースしてください`, also update the external homepage file.

- File path: `C:\Users\s.kodatai\OneDrive - 株式会社セラフ\source\toyo-craft\apps.html`
- Target element: the `<span>` with `id="renamery-version"`
- Update value: the latest version from `pubspec.yaml` formatted as `vX.X.X`
- Preserve UTF-8 encoding to avoid mojibake.

## Existing Gemini Compatibility

These rules intentionally mirror the release-related instructions from `gemini.md`, but are tracked and loaded for OpenCode through `opencode.json`.
