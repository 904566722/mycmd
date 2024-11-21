# mycmd

## 简介

mycmd 是一个命令行工具，用于创建、编辑和管理自己的命令。

```bash
mycmd xxx ...
```

> 每个子命令对应调用不同模块目录的脚本
> e.g. mycmd flow 对应调用 ./modules/flow/xxx.sh

> sudo ln -s "$(pwd)/bin/mycmd" /usr/local/bin/mycmd

- --help 查看帮助，根命令或者每个子命令的详细帮助

## 子命令 1. - flow

用于管理自己的各种流（工作流、学习流等）

调用
```bash
mycmd flow xxx ...
```

## 通用方法

### 日志打印

```bash
fg_red="\033[31m"
fg_green="\033[32m"
fg_yellow="\033[33m"
fg_blue="\033[34m"

set_clear="\033[0m"
set_bold="\033[1m"

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
```