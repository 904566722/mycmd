#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$PROJECT_ROOT/lib/logger.sh"

# 显示 flow 模块的帮助信息
show_help() {
    cat << EOF
flow - 管理工作流和学习流

用法：
    mycmd flow <subcommand> [options]

可用子命令：
    list        列出所有已定义的流程
    create      创建新的流程
    edit        编辑现有流程

选项：
    --help      显示此帮助信息
EOF
}

main() {
    if [[ $# -eq 0 || "$1" == "--help" ]]; then
        show_help
        exit 0
    fi

    local subcommand="$1"
    shift

    case "$subcommand" in
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