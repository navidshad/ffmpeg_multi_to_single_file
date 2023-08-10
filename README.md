# Merge multiple files
A simple cli tool to convert multiple video files into a single file through ffmpeg

## Dependencies
- FFMPEG cli tool
- Bash terminal

## Best practice
- Copy the script file `merge.sh` into a root directory.
- Run `chmod +x merge.sh` to make the script executable.
- Group your videos into different folders in the root directory.
- Run this command `./merge.sh [folder_name]` to merge each folder.

## Arguments
| Position | Variable Name | Default Value          | Other Values                       |
| -------- | ------------- | ---------------------- | ---------------------------------- |
| 1        | `dir`         | N/A                    | N/A                                |
| 2        | `mode`        | `merge_compress`       | `merge`, `compress`                |
| 3        | `output_dir`  | The base name of `dir` | N/A                                |
| 4        | `source_ext`  | `mp4`                  | Any valid file extension of ffmpeg |
| 5        | `target_ext`  | `mp4`                  | Any valid file extension of ffmpeg |

Note that the first argument (`dir`) does not have a default value or valid values specified, as it is a required argument and can take any valid directory path as input.

## Example with more arguments
`./merge.sh [folder_name] convert scene_01 mp4 avi`
