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
    echo "Аргументов использовано: $0 [--max_depth N]"
    echo "Ожидалось: <входная_директория> <выходная_директория>"
    exit 1
fi

if [ ! -d "$input_dir" ]; then
    echo "Ошибка: Входная директория '$input_dir' не существует"
    exit 1
fi

mkdir -p "$output_dir" || {
    echo "Ошибка: Не получилось создать выходную директорию '$output_dir'"
    exit 1
}

copy() {
    local src="$1"
    local relative_path="${src#$input_dir/}"
    local clean_relative_path=$(echo "$relative_path" | sed 's/ \././g')
    local path="$output_dir/$clean_relative_path"
    local app_dir=$(dirname "$path")

    mkdir -p "$app_dir" || {
        echo "Ошибка: Не удалось создать директорию '$app_dir'"
        return 1
    }

    cp -- "$src" "$path" || {
        echo "Ошибка: Не получилось скопировать '$src' в '$path'"
        return 1
    }
}

export -f copy
export output_dir input_dir

if [ -n "$max_depth" ]; then
    if ! [[ "$max_depth" =~ ^[0-9]+$ ]]; then
        echo "Ошибка: --max_depth должен быть числом"
        exit 1
    fi
    find "$input_dir" -mindepth 1 -maxdepth "$max_depth" -type f -print0 | while IFS= read -r -d '' file; do
        copy "$file"
    done

    find "$input_dir" -mindepth 1 -maxdepth "$max_depth" -type d -print0 | while IFS= read -r -d '' dir; do
        relative_path="${dir#$input_dir/}"
        clean_relative_path=$(echo "$relative_path" | sed 's/ \././g')
        mkdir -p "$output_dir/$clean_relative_path"
    done
else
    find "$input_dir" -type f -print0 | while IFS= read -r -d '' file; do
        copy "$file"
    done
fi