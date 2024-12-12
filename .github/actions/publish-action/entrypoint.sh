#!/bin/bash
make clean deps lint package
chown -R root:root /github/workspace
make publish "forge_token=${PUPPETFORGE_TOKEN}"
