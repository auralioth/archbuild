#!/bin/bash

nvfile=$INPUT_NVFILE
changed_files=$INPUT_CHANGED_FILES
keyfile=$INPUT_KEYFILE

oldver_file=$(cat $nvfile | grep -n "^oldver" | awk -F '\"' '{print $2}')

levels=(warning warn error exception critical)
keys=(name old_version version event level)

if [ -z "$keyfile" ]; then
	data=$(nvchecker -t 3 --logger json -c $nvfile)
else
	data=$(nvchecker -t 3 --logger json -c $nvfile --keyfile $keyfile)
fi

packages_need_update=()
versions=()
old_pkgvers=()

while read -r group; do
	for key in "${keys[@]}"; do
		declare "$key=$(echo "$group" | jq -r ".${key}")"
	done

	if [[ "${levels[@]}" =~ "${level}" ]]; then
		echo "::group::Nvchecker"
		echo "::error file=entrypoint.sh,line=27, endline=38, title=${name}::nvchecker error"
		echo "::endgroup::"
		exit 1
	fi

	if [ "$event" = "up-to-date" ]; then
		continue
	fi

	if comm -12 <(find "$name" -type f | sort) <(echo "$changed_files" | tr ' ' '\n' | sort) | grep -q .; then
		file_changed="true"
	else
		file_changed="false"
	fi

	if [ "$event" = "updated" ] || [ "$file_changed" = "true" ]; then

		# 可以用于后续 delete-asset
		old_pkgver=$(cat $name/PKGBUILD | grep -n "^pkgver=" | awk -F= '{print $2}')

		packages_need_update+=($name)
		versions+=($version)
		old_pkgvers+=($old_pkgver)

		nvtake --ignore-nonexistent -c $nvfile $name

	fi
done < <(echo "$data" | jq -c '.')

if [ ${#packages_need_update[@]} -eq 0 ]; then
	echo "status=false" >>$GITHUB_OUTPUT
else
	echo "status=true" >>$GITHUB_OUTPUT

	# matrix="{\"pkg\": ["
	# for package in "${packages_need_update[@]}"; do
	# matrix="${matrix}\"$package\", "
	# done
	# matrix="${matrix%, }]}"
	# echo "matrix=${matrix}" >> $GITHUB_OUTPUT

	matrix="{\"include\": ["
	for ((i = 0; i < ${#packages_need_update[@]}; i++)); do
		matrix="${matrix}{\"pkg\": \"${packages_need_update[i]}\", \"version\": \"${versions[i]}\", \"old_pkgver\": \"${old_pkgvers[i]}\"}"
		if [ $i -lt $((${#packages_need_update[@]} - 1)) ]; then
			matrix="${matrix}, "
		fi
	done
	matrix="${matrix}]}"
	echo "matrix=${matrix}" >>$GITHUB_OUTPUT

	echo "oldver_file=$oldver_file" >>$GITHUB_OUTPUT
fi
