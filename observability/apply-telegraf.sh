#!/bin/bash
kapp deploy -a telegraf -n tanzu-kapp --into-ns telegraf -f <(ytt -f telegraf -f harbor)