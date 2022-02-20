#!/bin/bash

# cf ../data/list_ms

# Script folder
EXE_DIR=$(dirname $(readlink -f $0));

# Data / Logs folder
node_name=`uname -n`;
if [[ ${node_name} == "vegeta" ]]; then
    DATA_ROOT="/data/obernard_logsunit";
    # DATA_ROOT="/data/thnguyen_logsunit";
else
    DATA_ROOT=$(dirname ${EXE_DIR});
fi;
DATA_DIR="${DATA_ROOT}/data"; 
LOGS_DIR="${DATA_ROOT}/logs";


# Just check that parent folders are indeed where they should be
[[ ! -d ${DATA_DIR} ]] && {
    echo -e "\x1b[31m[Err]\x1b[0m Data directory ${DATA_DIR} does not exist.";
    exit 1;
};

[[ ! -d ${LOGS_DIR} ]] && {
    echo -e "\x1b[31m[Err]\x1b[0m Logs directory ${LOGS_DIR} does not exist.";
    exit 1;
};


# Compute approached log-S-Unit lattices
for m in "$@"; do
    nf="z$m";
    # NB: Currently the CDW codes only works for 1 orbit
    echo "Simulate IdSVP Solve using CDW for Q(z$m) [orb=#1]";
    sage ${EXE_DIR}/cdw_protocol.sage ${DATA_DIR} $nf 1>${LOGS_DIR}/${nf}_d1.aflog_cdw 2>&1 &
done;

exit 0;
