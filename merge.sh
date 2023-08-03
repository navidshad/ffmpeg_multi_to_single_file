#! /bin/bash

dir=$1
# valid modes: merge, merge-compress
mode=${2-"merge-compress"}

# convert dir to name if not specified
output_dir=${3:-$(basename $dir)}
source_ext=${4:-"mp4"}
target_ext=${5:-"mp4"}

function convert_with_file_list() {
	compress=${1-"false"}
	text_fle="files.txt"

	# clean up
	rm -f $text_fle

	for f in $dir/*.$source_ext; do
		echo "file $f" >>$text_fle
	done

	# convert all file into a single file with ffmpeg, copy first file codec and aoide re-encoding
	if [ "$compress" == "true" ]; then
		ffmpeg -f concat -safe 0 -i $text_fle ${output_dir}_merged_compressed.$target_ext
	else
		ffmpeg -f concat -safe 0 -i $text_fle -c copy ${output_dir}_merged.$target_ext
	fi

	# clean up
	rm -f $text_fle
}

if [ "$mode" == "merge" ]; then
	convert_with_file_list
elif [ "$mode" == "merge-compress" ]; then
	convert_with_file_list true
else
	echo "invalid mode: $mode"
fi
