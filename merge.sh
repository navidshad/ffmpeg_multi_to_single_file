#! /bin/bash

dir=$1
# valid modes: convert, fix
mode=${2-"convert"}

# convert dir to name if not specified
output_dir=${3:-$(basename $dir)}
source_ext=${4:-"mp4"}
target_ext=${5:-"mp4"}

function convert_with_file_list() {
	text_fle="files.txt"

	# clean up
	rm -f $text_fle

	for f in $dir/*.$source_ext; do
		echo "file $f" >>$text_fle
	done

	# convert all file into a single file with ffmpeg, copy first file codec and aoide re-encoding
	ffmpeg -f concat -safe 0 -i $text_fle -c copy ${output_dir}_merged.$target_ext

	# clean up
	rm -f $text_fle
}

function fix_all_files() {
	fixed_dir_in_same_level=$dir.fixed
	mkdir -p $fixed_dir_in_same_level
	for f in $dir/*.$source_ext; do
		fixed_file=$fixed_dir_in_same_level/$(basename $f)
		ffmpeg -i $f -c copy $fixed_file
	done
}

if [ "$mode" == "convert" ]; then
	convert_with_file_list
elif [ "$mode" == "fix" ]; then
	fix_all_files
else
	echo "invalid mode: $mode"
	exit 1
fi
