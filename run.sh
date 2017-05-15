#!/usr/bin/env bash

[ ! -f /trac/VERSION ] && /bin/bash /setup_trac.sh
exec supervisord -n
