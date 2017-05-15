#!/usr/bin/env bash

source /etc/apache2/envvars
exec apache2 -D FOREGROUND
