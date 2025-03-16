#!/bin/bash
# Convert bilibili video to mp4
# require: mkvtoolnix, jq
## command: sudo apt install mkvtoolnix jq

### 基础配置变量区 ###
work_dir=""
output_dir=""
tmp_dir=""

#遍历文件夹，取得待转换的目录
#$1: 工作目录
list_folder()
{
    folder_list=$(ls "$1" | grep -v jpg | grep -v ass | grep  -v sh | grep -v output)
}

#处理所有文件夹
#$1: 工作目录
process_per_folder()
{
    #获取文件
    local entry_json_file=$(find $1 -name "entry.json")
    if [ $? -ne 0 ]; then
        return
    fi
    local danmuku_file=$(find $1 -name danmaku.xml)
    local video_file=$(find $1 -name "video.m4s")
    local audio_file=$(find $1 -name "audio.m4s")

    #获取输出文件名称必要的元素
    local owner_name=$(jq -r '.owner_name' "$entry_json_file")
    local title=$(jq -r '.title' "$entry_json_file")
    local quality_pithy_description=$(jq -r '.quality_pithy_description' "$entry_json_file")
    local cover_url=$(jq -r '.cover' "$entry_json_file")
    local cover_filename=$(basename "$cover_url")
    local width=$(jq -r '.page_data.width' "$entry_json_file")
    local height=$(jq -r '.page_data.height' "$entry_json_file")
    
    #准备文件 
    wget -c -O ${tmp_dir}/"$cover_filename" "$cover_url"
    #fn的参数再考虑下
    danmaku2ass -o ${tmp_dir}/${owner_name}-${title}-${quality_pithy_description}.ass -s ${width}x$height -fs 100 -a 0.8 -dm 5 -ds 5 ${danmuku_file}

    #合并音频、视频、封面和字幕
    mkvmerge -o "$output_dir/${owner_name}-${title}-${quality_pithy_description}.mkv" --title "$title" --attachment-mime-type image/jpeg \
            --attach-file ${tmp_dir}/"$cover_filename" \
            --language 0:chi --track-name 0:"$title" "$video_file" \
            --language 0:chi --track-name 0:"$title" "$audio_file" \
            --language 0:chi --track-name 0:"$title"  ${tmp_dir}/${owner_name}-${title}-${quality_pithy_description}.ass
}

#解析参数
parse_param()
{
    while [ "$#" -gt 0 ]; do
        case $1 in
            --output) output_dir="$2"; shift ;;
            --work_dir) work_dir="$2"; shift ;;
            -o) output_dir="$2"; shift ;;
            -w) work_dir="$2"; shift ;;
            *) echo "Unknown parameter passed: $1"; exit 1 ;;
        esac
        shift
    done

    if [ -z "$work_dir" ]; then
        echo "work_dir parameter not set, use current dir."
        work_dir=$(pwd)
        echo "now work_dir is be set in $work_dir"
    fi
    if [ -z "$output_dir" ]; then
        echo "output_dir parameter not set. reset by work_dir"
        output_dir=${work_dir}/output
        echo "now output_dir is be set in $output_dir"
    fi
    tmp_dir="${output_dir}/tmp"
    mkdir -p ${tmp_dir}
}

main()
{
    parse_param "$@"
    list_folder ${work_dir}
    for folder in $folder_list; do
        process_per_folder ${work_dir}/${folder} 
    done;
}

main "$@"