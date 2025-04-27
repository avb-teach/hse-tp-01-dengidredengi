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
    local filename=$(basename -- "$src")
    local path="$output_dir/$filename"
    local counter=1

    while [ -e "$path" ]; do
        name="${filename%.*}"
        exten="${filename##*.}"
        [ "$name" = "$filename" ] && exten="" || exten=".$exten"
        path="$output_dir/${name}_$counter$exten"
        ((counter++))
    done

    cp -- "$src" "$path" || {
        echo "Ошибка: Не удалось скопировать '$src' в '$path'"
        return 1
    }
}

export output_dir

if [ -n "$max_depth" ]; then
    if ! [[ "$max_depth" =~ ^[0-9]+$ ]]; then
        echo "Ошибка: --max_depth должен быть числом"
        exit 1
    fi
    find "$input_dir" -maxdepth "$max_depth" -type f -print0 | while IFS= read -r -d '' file; do
        copy "$file"
    done

else
    find "$input_dir" -type f -print0 | while IFS= read -r -d '' file; do
        copy "$file"
    done
fi 




