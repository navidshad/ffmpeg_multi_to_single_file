#! /bin/bash
set -e

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
output_dir="${3:-$(dirname "$dir")}"
source_ext=${4:-"mp4"}
target_ext=${5:-"mp4"}

# eacho input
echo "  "
echo "Merge Inputs --------------------"
echo "dir: $dir"
echo "mode: $mode"
echo "output_dir: $(pwd)/$output_dir"
echo "source_ext: $source_ext"
echo "target_ext: $target_ext"
echo "---------------------------------"

function convert_with_file_list() {
	compress=${1-"false"}
	text_fle="files.txt"

	# clean up
	rm -f "$text_fle"

	# Use a for loop with a glob that correctly handles spaces
	# and escape single quotes for ffmpeg's concat format
	for f in "$dir"/*."$source_ext"; do
		# Check if files exist to handle empty glob case
		if [ -e "$f" ]; then
			# Skip already compressed files
			if [[ "$f" == *"_compressed."* ]]; then
				continue
			fi
			# Escape single quotes: ' becomes '\''
			f_escaped=$(echo "$f" | sed "s/'/'\\\\''/g")
			echo "file '$f_escaped'" >>"$text_fle"
		fi
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
	# Determine target output directory
	local target_out=""
	if [ "$output_dir" == "$dir" ] || [ "$output_dir" == "." ]; then
		target_out="compressed"
	else
		target_out="$output_dir"
	fi

	mkdir -p "$target_out"

	local files=()
	if [ -f "$dir" ]; then
		# If $dir is a single file
		files=("$dir")
	else
		# If $dir is a directory, use a glob that handles spaces
		for f in "$dir"/*."$source_ext"; do
			if [ -e "$f" ]; then
				# Skip files that were already compressed to avoid processing them as input
				if [[ "$f" == *"_compressed."* ]]; then
					echo "Skipping already compressed file: $f"
					continue
				fi
				files+=("$f")
			fi
		done
	fi

	local total=${#files[@]}
	local current=1
	echo "Total files to process: $total"

	# process each file
	for f in "${files[@]}"; do
		echo "--------------------------------------------------"
		echo "Processing $current of $total:"
		echo "Input:  $f"
		
		# Check if file exists right before processing
		if [ ! -f "$f" ]; then
			echo "ERROR: File not found: $f"
			current=$((current + 1))
			continue
		fi

		# extract filename
		local base_name=$(basename -- "$f")
		local out_file="$target_out/${base_name%.*}_compressed.$target_ext"
		echo "Output: $out_file"

		# convert file with ffmpeg
		ffmpeg -i "$f" -y "$out_file"

		current=$((current + 1))
	done
}

# create_output_dir
function create_output_dir() {
	local path="$1"
	if [ ! -d "$path" ]; then
		mkdir -p "$path"
	fi
}

function split_with_file_list() {
	local input_file="$1"
	local duration="$2"
	local out_dir="${3:-$(basename "$input_file" ."$source_ext")}"
	local s_ext=${4:-"mp4"}
	local t_ext=${5:-"mp4"}

	# create output dir if not exist
	create_output_dir "$out_dir"

	# extract filename without extension
	local base=$(basename -- "$input_file")
	local name_no_ext="${base%.*}"

	# split the file into fragments
	ffmpeg -i "$input_file" -c:v libx264 -preset fast -c:a aac -b:a 128k -segment_time "$duration" -g $(($duration * 2)) -sc_threshold 0 -force_key_frames "expr:gte(t,n_forced*$duration)" -f segment -reset_timestamps 1 "$out_dir/${name_no_ext}_part%03d.$t_ext"
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
