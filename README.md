# Limitly

Limitly is a macOS menu bar app for viewing the signed-in user's Codex five-hour and weekly usage limits.

## Download

Download the latest Apple Silicon (`arm64`) DMG from [GitHub Releases](https://github.com/yunhachoi/Limitly/releases). The installer is for macOS 13 or later. Intel `x86_64` and Windows builds are not currently planned.

Limitly reads the local Codex app-server session on each Mac. It does not ask for an OpenAI API key and does not copy or store Codex passwords, cookies, or account tokens. Each person sees the limits for their own signed-in Codex account.

## Install

1. Download `Limitly-<version>.dmg` from Releases.
2. Open it and drag `Limitly.app` to `Applications`.
3. Launch `/Applications/Limitly.app`.

The first launch may show a macOS security prompt because the current distribution is ad hoc signed.

## Distribution

This repository is used to distribute the macOS DMG. The development source and build files remain maintained in the project workspace and are not included in the public release repository at this time.
