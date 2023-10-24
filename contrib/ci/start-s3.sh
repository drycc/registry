#!/usr/bin/env bash
eval "cat <<EOF >/etc/seaweedfs/s3.json
$( cat /tmp/weed/s3.json )
EOF
" 2> /dev/null

weed server -dir=/data -s3 -s3.config=/etc/seaweedfs/s3.json
