#!/bin/bash
git config --global user.email "opensource@shinesolutions.com"
git config --global user.name "Shine Open Source"
chown -R root:root /github/workspace
make release-major