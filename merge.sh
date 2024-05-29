set -e

#! /bin/bash
echo "Running merge.sh from $(pwd)"

# help message
if [ "$1" == "-h" ]; then
	echo "Usage: ./merge.sh <dir> <mode> <output_dir> <source_ext> <target_ext>"
	echo "Example: ./merge.sh ./videos merge-compress merged mp4 mp4"
	echo "Example: ./merge.sh ./videos compress compressed mp4 mp4"
	echo "Example: ./merge.sh ./videos merge merged mp4 mp4"
	echo "Single file split: ./merge.sh <file> <mode> <duration> <output_dir> <source_ext> <target_ext>"
	echo "Example: ./merge.sh ./videos/single.mp4 split-single 10 out_dir mp4 mp4"
	exit 0
fi

dir="$1"
# valid modes: merge, merge-compress, compress
mode=${2-"merge-compress"}

# convert dir to name if not specified
output_dir="${3:-$(basename "$dir")}"
source_ext=${4:-"mp4"}
target_ext=${5:-"mp4"}

function convert_with_file_list() {
	compress=${1-"false"}
	text_fle="files.txt"

	# clean up
	rm -f "$text_fle"

	for f in "$dir"/*."$source_ext"; do
		echo "file '$f'" >>"$text_fle"
	done

	# convert all file into a single file with ffmpeg, copy first file codec and aoide re-encoding
	if [ "$compress" == "true" ]; then
		ffmpeg -f concat -safe 0 -i "$text_fle" "${output_dir}_merged_compressed.$target_ext"
	else
		ffmpeg -f concat -safe 0 -i "$text_fle" -c copy "${output_dir}_merged.$target_ext"
	fi

	# clean up
	rm -f "$text_fle"
}

# compress all files in a directory without merging
function compress_with_file_list() {
	output_dir=$(pwd)/"$output_dir"

	# create output dir if not exist
	if [ ! -d "$output_dir" ]; then
		mkdir "$output_dir"
	fi

	all_files=$(ls "$dir"/*."$source_ext")

	# print current and total files
	total_files=$(echo "$all_files" | wc -w)
	current_file=1
	echo "total files: $total_files"

	for f in $all_files; do
		echo "Converting file $current_file/$total_files: $f"

		# extract filename and extension
		filename=$(basename -- "$f")

		# convert file
		ffmpeg -i "$f" "$output_dir/$filename'_compressed'.$target_ext"

		current_file=$((current_file + 1))
	done
}

# create_output_dir
function create_output_dir() {
	output_dir="$1"
	if [ ! -d "$output_dir" ]; then
		mkdir "$output_dir"
	fi
}

function split_with_file_list() {
	file="$1"
	duration="$2"
	output_dir="${3:-$(basename "$file" ."$source_ext")}"
	source_ext=${4:-"mp4"}
	target_ext=${5:-"mp4"}

	# create output dir if not exist
	create_output_dir "$output_dir"

	# extract filename without extension
	filename=$(basename -- "$file")
	filename="${filename%.*}"

	# split the file into fragments
	ffmpeg -i "$file" -c:v libx264 -preset fast -c:a aac -b:a 128k -segment_time "$duration" -g $(($duration * 2)) -sc_threshold 0 -force_key_frames "expr:gte(t,n_forced*$duration)" -f segment -reset_timestamps 1 "${output_dir}/${filename}_part%03d.$target_ext"
}

if [ "$mode" == "merge" ]; then
	convert_with_file_list
elif [ "$mode" == "merge-compress" ]; then
	convert_with_file_list true
elif [ "$mode" == "compress" ]; then
	compress_with_file_list
elif [ "$mode" == "split-single" ]; then
	split_with_file_list "$dir" "$3" "$4" "$5" "$6"
else
	echo "invalid mode: $mode"
fi
