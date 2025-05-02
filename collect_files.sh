#!/bin/bash

max_depth=""
while [ $# -gt  0 ]; do
    case "$1" in
        --max_depth)
            max_depth="$2"
            shift 2
            ;;
        *)
            if [ -z "$input_dir" ]; then
                input_dir="$1"
            else
                output_dir="$1"
            fi
            shift
            ;;
    esac
done

if [ -z "$input_dir" ] || [ -z "$output_dir" ]; then
    exit 1
fi

if [ ! -d "$input_dir" ]; then
    exit 1
fi

mkdir -p "$output_dir" || exit 1

export output_dir input_dir max_depth
get_depth(){
    echo "${1//[^\/]/}" | wc -c
}

copy() {
    local src="$1"
    local relative_path="${src#$input_dir/}"
    local clean_relative_path=$(echo "$relative_path" | sed 's/ \././g' | tr -s '/')
    local filename="$(basename "$clean_relative_path")"
    local path_cut=""
    local src_depth=$(get_depth "$relative_path")

    if [ -n "$max_depth" ] && [ "$src_depth" -gt "$max_depth" ]; then
        local path_base=$(echo "$clean_relative_path" | cut -d'/' -f1-"$max_depth")
        local remain_path=$(echo "$clean_relative_path" | cut -d'/' -f"$((max_depth+1))"-)
        local dir_last=$(dirname "$remain_path")
        if [ "$dir_last" != "." ]; then
            path_cut="$path_base/$dir_last"
        else
            path_cut="$path_base"
        fi

        mkdir -p "$output_dir/$path_cut"
        dest="$output_dir/$path_cut/$filename"
    else
        dest="$output_dir/$clean_relative_path"
        mkdir -p "$(dirname "$dest")"
    fi

    local name="${filename%.*}"
    local ext_file="${filename##*.}"
    [ "$name" = "$filename" ] && ext_file="" || ext_file=".$ext_file"

    local count=1
    local path_dest="$dest"
    while [ -e "$path_dest" ]; do
        path_dest="$(dirname "$dest")/${name}_${count}${ext_file}"
        ((count++))
    done
    
    cp -- "$src" "$path_dest"
}

find "$input_dir" -type d -print0 | \
    while IFS= read -r -d '' dir; do
        retemp="${dir#$input_dir/}"
        clean_retemp=$(echo "$retemp" | tr -s '/')
        depth_dir=$(get_depth "$clean_retemp")
        if [ -z "$max_depth" ] || [ "$depth_dir" -le "$max_depth" ]; then
            [ -n "clean_retemp" ] && mkdir -p "$output_dir/$clean_retemp"
        fi
    done

find "$input_dir" -type f -print0 | \
while IFS= read -r -d '' file; do
    copy "$file"
done
