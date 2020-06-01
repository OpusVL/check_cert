#!/bin/bash
#
# Written by Paul Bargewell, OpusVL (26 May 2020)
#
# Parts borrowed from: check_ssl_cert
#
# Copyright (c) 2007-2012 ETH Zurich.
# Copyright (c) 2007-2016 Matteo Corti <matteo@corti.li>
#
# This module is free software; you can redistribute it and/or modify it
# under the terms of GNU general public license (gpl) version 3.
# See the LICENSE file for details.
#
# Use curl to fetch the certificate details from a site and report
# the number of days remaining. It checks no other aspects of the
# certificate.
#
# Return Nagios compatible exit codes based on days remaining, eg.
# 30=WARN, 14=CRIT

# Default Values
VERSION=1.0
HOSTNAME=
WARN=30
CRIT=14
CERT_END_DATE=
SUBJECT=
ISSUER=
DAYS_VALID=0
STATE="UNKOWN"

DATEBIN=`which date`

usage() {
  echo
  echo "Usage: check_cert.sh -H host [OPTIONS]"
  echo
  echo "Options:"
  echo "   -H,--host                  host"
  echo "   -c,--critical days         minimum number of days a certificate has to be valid"
  echo "                              to issue a critical status"
  echo "   -h,--help                  this help message"
  echo "   -V,--version               version"
  echo "   -w,--warning days          minimum number of days a certificate has to be valid"
  echo "                              to issue a warning status"  
}

# Command line options
while true; do
  case "$1" in
    -H|--host)
      if [ $# -gt 1 ]; then
        HOSTNAME="$2"
        # Strip the https protocol if necessary
        if [[ ${HOSTNAME} =~ 'https://' ]]; then
          HOSTNAME=${HOSTNAME:8}
        fi
        shift 2      
      fi
      ;;
    -w|--warning)
      if [ $# -gt 1 ]; then
        WARN="$2"
        shift 2
      fi
      ;;
    -c|--critical)
      if [ $# -gt 1 ]; then
        CRIT="$2"
        shift 2
      fi
      ;;
    -V|--version)
      shift
      echo "Version ${VERSION}"
      exit 3
      ;;   
   -h|--help)
      shift
      usage
      exit 0
      ;;    
    *)
      if [ ! -z "$1" ]; then
        echo "Invalid option $1"
        usage
        exit 3
      fi
      shift
      break
      ;;
  esac

done

while read line
do

  if [[ $line =~ 'expire date:' ]]; then
    CERT_END_DATE="${line:16}"
  elif [[ $line =~ 'subject:' ]]; then
    SUBJECT="${line:12}"
  elif [[ $line =~ 'issuer:' ]]; then
    ISSUER="${line:11}"
  fi

done < <(curl --insecure -v https://${HOSTNAME} 2>&1 | awk 'BEGIN { cert=0 } /^\* SSL connection/ { cert=1 } /^\*/ { if (cert) print }')

DAYS_VALID=$(( ( $(${DATEBIN} -d "${CERT_END_DATE}" +%s) - $(${DATEBIN} +%s) ) / 86400 ))

STATE="UNKNOWN"
if [ ${DAYS_VALID} -lt ${CRIT} ]; then
  STATE="CRIT"
elif [ ${DAYS_VALID} -lt ${WARN} ]; then
  STATE="WARN"
else
  STATE="OK"
fi

printf "SSL_CERT %s X.509 certificate for 'subject=%s' from 'issuer=%s' valid until %s (expires in %d days)|days=%d;%d;%d;0;90\n" "${STATE}" "${SUBJECT}" "${ISSUER}" "${CERT_END_DATE}" "${DAYS_VALID}" "${DAYS_VALID}"  "${WARN}" "${CRIT}"

# Nagios exit codes
case ${STATE} in
  OK)
    exit 0;
    ;;
  WARN)
    exit 1
    ;;
  CRIT)
    exit 2
    ;;
  *)
    # UNKNOWN
    exit 3
    ;;
esac
