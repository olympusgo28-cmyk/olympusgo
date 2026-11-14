#!/usr/bin/env bash
set -eu
cp -R "$(dirname "$0")/files/." .
mv cool-skill/skill-main.md cool-skill/SKILL.md
