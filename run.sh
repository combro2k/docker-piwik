#!/bin/bash

docker run -ti --rm --name piwik -P combro2k/piwik:latest ${@}
