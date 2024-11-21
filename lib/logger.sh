#!/bin/bash

# 颜色定义
fg_red="\033[31m"
fg_green="\033[32m"
fg_yellow="\033[33m"
fg_blue="\033[34m"

set_clear="\033[0m"
set_bold="\033[1m"

# 日志函数
success_log() {
    echo -e "${fg_green}${set_bold}$1${set_clear}"
}

error_log() {
    echo -e "${fg_red}${set_bold}$1${set_clear}"
}

warning_log() {
    echo -e "${fg_yellow}${set_bold}$1${set_clear}"
}

info_log() {
    echo -e "${fg_blue}${set_bold}$1${set_clear}"
} 