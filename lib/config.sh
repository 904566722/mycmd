#!/bin/bash

# 配置文件路径
CONFIG_FILE="/etc/.mycmd.conf"

# 读取配置文件中指定模块的配置
# 参数:
#   $1: 模块名称 (如 "flow")
#   $2: 配置项名称 (如 "todo-dir")
get_config() {
    local module="$1"
    local key="$2"

    if [ ! -f "$CONFIG_FILE" ]; then
        error_log "错误: 配置文件不存在: $CONFIG_FILE"
        exit 1
    fi

    # 使用 awk 解析 YAML 格式的配置文件
    local value=$(awk -v module="$module:" -v key="$key:" '
        $0 ~ "^"module {
            in_module=1
            next
        }
        in_module && $0 ~ "^[a-zA-Z]" {
            in_module=0
        }
        in_module && $1 == key {
            gsub(/^[[:space:]]*'\''"?|'\''"?[[:space:]]*$/, "", $2)
            print $2
            exit
        }
    ' "$CONFIG_FILE")

    if [ -z "$value" ]; then
        error_log "错误: 未找到配置项 $module.$key"
        exit 1
    fi

    # 展开波浪号为用户主目录
    echo "${value/#\~/$HOME}"
}

# 验证配置文件中必需的配置项
# 参数:
#   $1: 模块名称
#   $@: 必需的配置项列表
validate_config() {
    local module="$1"
    shift
    local required_keys=("$@")

    if [ ! -f "$CONFIG_FILE" ]; then
        error_log "错误: 配置文件不存在: $CONFIG_FILE"
        exit 1
    fi

    for key in "${required_keys[@]}"; do
        if ! get_config "$module" "$key" >/dev/null 2>&1; then
            error_log "错误: 缺少必需的配置项 $module.$key"
            exit 1
        fi
    done
} 