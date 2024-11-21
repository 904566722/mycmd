#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$PROJECT_ROOT/lib/logger.sh"
source "$PROJECT_ROOT/lib/config.sh"

# 验证 flow 模块必需的配置
validate_flow_config() {
    validate_config "flow" "todo-dir"
}

# 显示 flow 模块的帮助信息
show_help() {
    cat << EOF
flow - 管理工作流和学习流

用法：
    mycmd flow <subcommand> [options]

可用子命令：
    todo-flush   初始化或刷新 todo 文件
    list        列出所有已定义的流程
    create      创建新的流程
    edit        编辑现有流程

选项：
    --help      显示此帮助信息

todo-flush 选项：
    --type      todo 类型 (work)
    --project   项目名称列表，用逗号分隔
EOF
}

# 处理 todo-flush 命令
handle_todo_flush() {
    local type=""
    local projects=""
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --type=*)
                type="${1#*=}"
                shift
                ;;
            --project=*)
                projects="${1#*=}"
                shift
                ;;
            *)
                error_log "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 打印解析到的参数
    info_log "解析到的参数:"
    info_log "  type: $type"
    info_log "  projects: $projects"

    # 验证参数
    if [ -z "$type" ]; then
        error_log "必须指定 --type 参数"
        exit 1
    fi
    if [ -z "$projects" ]; then
        error_log "必须指定 --project 参数"
        exit 1
    fi

    # 获取配置的 todo 目录
    local todo_dir="$(get_config "flow" "todo-dir")"
    local template_file="$todo_dir/$type/$type-template.todo"
    local target_file="$todo_dir/$type/$type.todo"

    # 打印文件路径信息
    info_log "文件路径信息:"
    info_log "  todo_dir: $todo_dir"
    info_log "  template_file: $template_file"
    info_log "  target_file: $target_file"

    # 检查模板文件是否存在
    if [ ! -f "$template_file" ]; then
        error_log "模板文件不存在: $template_file"
        exit 1
    fi

    # 检查目标文件是否存在
    if [ -f "$target_file" ]; then
        read -p "文件 $target_file 已存在，是否覆盖？(y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info_log "操作已取消"
            exit 0
        fi
    fi

    # 复制模板文件
    cp "$template_file" "$target_file"
    info_log "已创建 todo 文件: $target_file"

    # 将项目名称转换为数组
    IFS=',' read -ra project_array <<< "$projects"
    
    # 打印项目数组信息
    info_log "项目列表:"
    for project in "${project_array[@]}"; do
        info_log "  - $project"
    done

    # 获取根分类（没有缩进的行，但排除注释行）
    local root_categories=$(grep -E "^[^[:space:]]" "$target_file" | grep -Ev "^(#|//|/\*)")
    
    # 打印根分类信息
    info_log "根分类列表:"
    while IFS= read -r category; do
        info_log "  - $category"
    done <<< "$root_categories"

    # 创建临时文件
    local temp_file=$(mktemp)
    local final_temp_file=$(mktemp)
    
    # 打印临时文件信息
    info_log "临时文件:"
    info_log "  temp_file: $temp_file"
    info_log "  final_temp_file: $final_temp_file"
    
    # 处理文件内容
    local in_category=false
    while IFS= read -r line; do
        # 检查是否是根分类行（非空白开头且非注释）
        if [[ "$line" =~ ^[^[:space:]#/] ]]; then
            in_category=true
            # 确保根分类有冒号结尾
            if [[ ! "$line" =~ :$ ]]; then
                line="$line:"
            fi
            echo "$line" >> "$temp_file"
        # 如果是注释行或空行，直接保留
        elif [[ "$line" =~ ^[[:space:]]*(#|//|/\*|$) ]]; then
            echo "$line" >> "$temp_file"
            in_category=false
        # 跳过分类下的所有缩进内容
        elif [ "$in_category" = true ]; then
            continue
        # 其他情况（比如多行注释的结束）
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$target_file"

    # 现在添加项目到每个根分类下
    cp "$temp_file" "$final_temp_file"
    
    while IFS= read -r category; do
        # 确保根分类后面有冒号
        if [[ ! "$category" =~ :$ ]]; then
            category="$category:"
        fi
        
        # 在临时文件中定位到该分类
        local line_num=$(grep -n "^${category}$" "$final_temp_file" | cut -d: -f1)
        if [ -n "$line_num" ]; then
            # 在分类后插入项目
            for project in "${project_array[@]}"; do
                # 确保项目后面有冒号
                if [[ ! "$project" =~ :$ ]]; then
                    project="$project:"
                fi
                # 使用 awk 插入行
                awk -v line="$line_num" -v project="    ${project}" \
                    'NR==line{print;print project;next}1' "$final_temp_file" > "${final_temp_file}.new" \
                    && mv "${final_temp_file}.new" "$final_temp_file"
                ((line_num++))
            done
        fi
    done <<< "$root_categories"

    # 替换原文件
    mv "$final_temp_file" "$target_file"
    rm -f "$temp_file"
    success_log "已成功更新 todo 文件，添加了项目: $projects"
}

main() {
    # 打印脚本信息
    info_log "脚本信息:"
    info_log "  SCRIPT_DIR: $SCRIPT_DIR"
    info_log "  PROJECT_ROOT: $PROJECT_ROOT"

    # 验证配置
    validate_flow_config

    if [[ $# -eq 0 || "$1" == "--help" ]]; then
        show_help
        exit 0
    fi

    local subcommand="$1"
    shift

    # 打印子命令信息
    info_log "执行子命令: $subcommand"
    info_log "剩余参数: $@"

    case "$subcommand" in
        todo-flush)
            handle_todo_flush "$@"
            ;;
        list|create|edit)
            info_log "执行 $subcommand 命令..."
            # TODO: 实现具体的子命令功能
            ;;
        *)
            error_log "未知的子命令: $subcommand"
            show_help
            exit 1
            ;;
    esac
}

main "$@" 