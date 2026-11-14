#!/usr/bin/env bash
set -eu
cp -R "$(dirname "$0")/files/." .
mv flutter-speed-tips/skill-main.md flutter-speed-tips/SKILL.md
