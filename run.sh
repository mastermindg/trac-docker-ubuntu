#!/usr/bin/env bash

/setup_trac.sh
exec supervisord -n
