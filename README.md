# Shodini Open-Source LLM App

A cross-platform Flutter application concept and implementation workspace for making open-source LLM
interaction more accessible across desktop and mobile devices.

## Overview

Flutter application repository with a detailed PRD. The main Flutter project is under `llm_app/`,
and the product direction is documented in `prd.md`.

## What This Repository Contains

- Product requirements for an open-source LLM app in `prd.md`.
- Flutter application code under `llm_app/`.
- Platform folders for Android, iOS, Linux, macOS, web, and Windows.
- Assets, tests, lockfile, and Flutter work plan.

## Who This Is For

- Flutter developers
- Open-source LLM app builders
- Cross-platform product developers
- AI UX designers

## Repository Structure

| Path | Purpose |
|------|---------|
| `prd.md` | Product requirements document. |
| `llm_app/` | Main Flutter project. |
| `llm_app/lib/` | Dart application code. |
| `llm_app/assets/` | Images, icons, and animation assets. |
| `llm_app/test/` | Flutter tests. |
| `llm_app/pubspec.yaml` | Flutter dependency and asset configuration. |

## Getting Started

- Install Flutter with a Dart SDK compatible with `llm_app/pubspec.yaml`.
- Change into `llm_app/`.
- Run `flutter pub get`.
- Run `flutter run` for the target platform.

## Common Workflows

- Use `flutter test` before publishing application changes.
- Keep PRD decisions and implemented behavior aligned as features mature.

## Quality, Security, And Maintenance Notes

- Do not commit model API keys, private chat logs, or personal documents.
- Document privacy controls clearly before adding account, sync, marketplace, or document-processing features.

## Current Documentation State

This README was rewritten to make the repository purpose, structure, setup path, and safety
expectations clear to a new reader. If implementation details change, update this file in the same
change so the GitHub landing page stays accurate.

Last documentation refresh: 2026-05-31.
