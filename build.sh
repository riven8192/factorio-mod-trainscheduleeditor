#!/bin/bash

set -euo pipefail

moddir="./TrainScheduleEditor"

function get_version {
	grep '"version"' "${moddir}/info.json" | \
		awk -F '"' '{print $4}' | \
		head -n 1
}

version="$(get_version)"

rm -f "${moddir}_${version}.zip"
cp -r "${moddir}" "${moddir}_${version}/"
zip "${moddir}_${version}.zip" ${moddir}_${version}/*
rm -r "${moddir}_${version}"