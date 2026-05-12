#!/bin/bash
apt-get update
apt-get install -y libffi-dev
make ci
