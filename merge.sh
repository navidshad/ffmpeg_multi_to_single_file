#! /bin/bash

dir=$1
# valid modes: merge, merge-compress, compress
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

# compress all files in a directory without merging
function compress_with_file_list() {
	output_dir=$(pwd)/$output_dir

	# create output dir if not exist
	if [ ! -d "$output_dir" ]; then
		mkdir $output_dir
	fi

	all_files=$(ls $dir/*.$source_ext)

	# print current and total files
	total_files=$(echo $all_files | wc -w)
	current_file=1
	echo "total files: $total_files"

	for f in $all_files; do
		echo "Converting file $current_file/$total_files: $f"

		# extract filename and extension
		filename=$(basename -- "$f")

		# convert file
		ffmpeg -i $f $output_dir/$filename'_compressed'.$target_ext

		current_file=$((current_file + 1))
	done
}

if [ "$mode" == "merge" ]; then
	convert_with_file_list
elif [ "$mode" == "merge-compress" ]; then
	convert_with_file_list true
elif [ "$mode" == "compress" ]; then
	compress_with_file_list
else
	echo "invalid mode: $mode"
fi
