#!/bin/sh

test_file() {
	if [ ! -f "$1" ]; then
		return
	fi
	message="$(qlop -rvCH -f ${1} 2>&1 | head -n 1)"
	error='qlop: insufficient privileges for full /proc access, running merges are based on heuristics'
	if [ "${message}" == "${error}" ]; then
		message="$(qlop -rvCH -f ${1} 2>&1 | head -n 2 | tail -n 1)"
	fi

	if [ "${message}" == "" ]; then
		echo ""
	else
		eme_count=$(echo "${message}" | cut -d '(' -f 2 | cut -d ')' -f 1 | sed -e 's/of/\//g')
		eme_name=$(echo "${message}" | cut -d ' ' -f 3 | sed -e 's/\.\.\.//g')
		if [ "${eme_count}" == "${message}" ]; then
			eme_time=$(echo "${message}" | cut -d '+' -f 2)
			echo "${eme_name} is over by ${eme_time}"
		else
			eme_time=$(echo "${message}" | cut -d ')' -f 2 | cut -d '(' -f 1 | sed -r -e 's/ hours?/h/g' -e 's/ minutes?/m/g' -e 's/, [0-9]* seconds?//g')
			echo "${eme_count}, ${eme_name},${eme_time}"
		fi
	fi
}

m="$(test_file '/mnt/foo/var/log/emerge.log')"
if [[ "$m" == "" ]]; then
	m="$(test_file '/mnt/stable_stage3/var/log/emerge.log')"
	if [[ "$m" == "" ]]; then
		m="$(test_file '/var/log/emerge.log')"
		if [[ "$m" == "" ]]; then
			echo "Not currently emerging"
		else
			echo "$m"
		fi
	else
		echo "stable_stage3: $m"
	fi
else
	echo "foo: $m"
fi
