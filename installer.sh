#!/bin/bash
# -*- coding: utf-8 -*-
# python_env_installer.sh - Python环境可视化安装工具

# --- 环境设置与颜色定义 ---
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# --- 全局变量 ---
LANGUAGE="zh" # 默认简体中文
SYSTEM_TYPE=""
INSTALL_METHOD=""
PYTHON_VERSION=""
XGET_HOST="xget.xi-xu.me"
LOG_FILE="/tmp/python_installer.log"

# --- Emojis ---
TICK="✅"
CROSS="❌"
WARN="⚠️"
INFO="ℹ️"
ROCKET="🚀"
PYTHON="🐍"
BOX="📦"
GEAR="⚙️"
WAVE="👋"
PARTY="🎉"
POINT_RIGHT="👉"
COMPUTER="💻"
LOCK="🔒"
CHART="📊"
HOURGLASS="⏳"

# --- 日志与UI函数 ---
log_info() {
    if [ "$LANGUAGE" = "zh" ]; then
        echo -e "${BLUE}${INFO} [信息]${NC} $1"
    else
        echo -e "${BLUE}${INFO} [INFO]${NC} $1"
    fi
}

log_success() {
    if [ "$LANGUAGE" = "zh" ]; then
        echo -e "${GREEN}${TICK} [成功]${NC} $1"
    else
        echo -e "${GREEN}${TICK} [SUCCESS]${NC} $1"
    fi
}

log_warning() {
    if [ "$LANGUAGE" = "zh" ]; then
        echo -e "${YELLOW}${WARN} [警告]${NC} $1"
    else
        echo -e "${YELLOW}${WARN} [WARNING]${NC} $1"
    fi
}

log_error() {
    if [ "$LANGUAGE" = "zh" ]; then
        echo -e "${RED}${CROSS} [错误]${NC} $1"
    else
        echo -e "${RED}${CROSS} [ERROR]${NC} $1"
    fi
}

clear_screen() {
    clear 2>/dev/null || printf "\033[2J\033[H"
}

print_logo() {
    echo -e "${ORANGE}"
    cat << "EOF"

EOF
    echo -e "${NC}"
    echo -e "       Python Environment Installer   "
    echo -e "${CYAN}         Powered by Xget${NC}"
    echo -e "${ORANGE}========================================${NC}"
    echo
}

print_header() {
    clear_screen
    print_logo
    
    if [ "$LANGUAGE" = "zh" ]; then
        echo -e "${CYAN}Python环境安装工具${NC}"
        echo "========================================"
        echo
        echo -e "${GREEN}${ROCKET}${NC} 由 Xget 提供全球加速"
        echo -e "${GREEN}${PYTHON}${NC} 一键安装Python开发环境"
        echo -e "${GREEN}${BOX}${NC} 可视化安装界面"
        echo
    else
        echo -e "${CYAN}Python Environment Installer (v3.6 - Powered by Xget)${NC}"
        echo "========================================"
        echo
        echo -e "${GREEN}${ROCKET}${NC} Globally accelerated by Xget"
        echo -e "${GREEN}${PYTHON}${NC} One-click Python Development Environment Setup"
        echo -e "${GREEN}${BOX}${NC} Visual Installation Interface"
        echo
    fi
}

# --- 系统检测 ---

detect_system() {
    log_info "正在检测系统信息..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$NAME
        elif command -v lsb_release &> /dev/null; then
            DISTRO=$(lsb_release -si)
        else
            DISTRO="Linux"
        fi
        
        if [[ "$ID" == "ubuntu" ]] || [[ "$ID" == "debian" ]]; then
            SYSTEM_TYPE="linux_debian"
            log_success "检测到系统: $DISTRO"
        else
            SYSTEM_TYPE="linux_other"
            log_warning "检测到系统: $DISTRO (可能需要手动处理依赖)"
        fi
    elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "win32" ]]; then
        SYSTEM_TYPE="windows"
        log_success "检测到系统: Windows"
    else
        SYSTEM_TYPE="unknown"
        log_error "不支持的操作系统: $OSTYPE"
        return 1
    fi
    return 0
}

check_admin() {
    log_info "检查管理员权限..."
    
    if [ "$SYSTEM_TYPE" = "windows" ]; then
        return 0
    fi
    
    if [ "$EUID" -ne 0 ]; then
        if ! command -v sudo &> /dev/null; then
            log_error "错误: 需要root权限或sudo命令来安装系统依赖。"
            return 1
        fi
        log_info "检测到sudo，将在需要时使用它。"
    else
        log_success "以root身份运行。"
    fi
    return 0
}

# --- 安装流程菜单 ---

show_install_method_menu() {
    echo -e "${CYAN}请选择安装方法:${NC}"
    echo
    echo -e "  ${GREEN}1)${NC} UV (推荐: ⚡️ 快速、现代)"
    echo -e "  ${GREEN}2)${NC} Pyenv + Poetry (传统、功能丰富)"
    echo -e "  ${GREEN}3)${NC} 退出 ${WAVE}"
    echo
}

select_install_method() {
    while true; do
        clear_screen
        print_header
        show_install_method_menu
        read -p "$(echo -e "${YELLOW}${POINT_RIGHT} 请输入选择 (1-3): ${NC}")" choice
        
        case $choice in
            1) INSTALL_METHOD="uv"; return 0 ;;
            2) INSTALL_METHOD="pyenv_poetry"; return 0 ;;
            3) return 1 ;; # Signal to exit
            *) log_error "无效选择，请重试。"; sleep 1 ;;
        esac
    done
}

show_python_version_menu() {
    echo -e "${CYAN}请选择要安装的Python版本:${NC}"
    echo
    echo -e "  ${GREEN}1)${NC} Python 3.13.5 (最新版)"
    echo -e "  ${GREEN}1)${NC} Python 3.12"
    echo -e "  ${GREEN}2)${NC} Python 3.11"
    echo -e "  ${GREEN}3)${NC} Python 3.10"
    echo -e "  ${GREEN}4)${NC} Python 3.9"
    echo -e "  ${GREEN}6)${NC} 自定义版本 ${GEAR}"
    echo -e "  ${GREEN}7)${NC} 返回上一级"
    echo
}

select_python_version() {
    while true; do
        clear_screen
        print_header
        show_python_version_menu
        read -p "$(echo -e "${YELLOW}${POINT_RIGHT} 请输入选择 (1-7): ${NC}")" choice
        
        case $choice in
            1) PYTHON_VERSION="3.12"; break ;;
            2) PYTHON_VERSION="3.11"; break ;;
            3) PYTHON_VERSION="3.10"; break ;;
            4) PYTHON_VERSION="3.9"; break ;;
            5) PYTHON_VERSION="3.8"; break ;;
            6)
                read -p "$(echo -e "${YELLOW}${POINT_RIGHT} 请输入Python版本 (如 3.11.5): ${NC}")" custom_version
                if [[ $custom_version =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
                    PYTHON_VERSION="$custom_version"
                    break
                else
                    log_error "无效的Python版本格式。"
                    sleep 2
                fi
                ;;
            7) return 1 ;; # Signal to go back
            *) log_error "无效选择，请重试。"; sleep 1 ;;
        esac
    done
    log_success "选择Python版本: $PYTHON_VERSION"
    return 0
}

show_install_summary() {
    clear_screen
    print_header
    echo -e "${CYAN}安装摘要:${NC}"
    echo
    echo -e "  ${COMPUTER}  系统类型: ${GREEN}$SYSTEM_TYPE${NC}"
    echo -e "  ${BOX}  安装方法: ${GREEN}$INSTALL_METHOD${NC}"
    echo -e "  ${PYTHON}  Python版本: ${GREEN}$PYTHON_VERSION${NC}"
    echo -e "  ${ROCKET}  加速服务: ${GREEN}Xget (${XGET_HOST})${NC}"
    echo
    read -p "$(echo -e "${YELLOW}${POINT_RIGHT} 确认开始安装? (y/N): ${NC}")" confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# --- 安装执行 (Xget 驱动) ---

progress_bar() {
    local pid=$1
    local width=40
    local filled_char="▓"
    local empty_char="░"

    tput civis
    trap 'tput cnorm' EXIT

    while ps -p $pid > /dev/null; do
        for i in $(seq 1 $width); do
            if ! ps -p $pid > /dev/null; then break 2; fi
            printf "["
            for j in $(seq 1 $width); do
                if [ $j -le $i ]; then printf "${GREEN}%s${NC}" "$filled_char"; else printf "${CYAN}%s${NC}" "$empty_char"; fi
            done
            printf "] "
            sleep 0.05
            printf "\r"
        done
        for i in $(seq $width -1 1); do
            if ! ps -p $pid > /dev/null; then break 2; fi
            printf "["
            for j in $(seq 1 $width); do
                if [ $j -le $i ]; then printf "${GREEN}%s${NC}" "$filled_char"; else printf "${CYAN}%s${NC}" "$empty_char"; fi
            done
            printf "] "
            sleep 0.05
            printf "\r"
        done
    done
    
    tput cnorm
}

safe_execute() {
    local cmd="$1"
    local description="$2"
    
    log_info "执行: $description"
    
    if eval "$cmd"; then
        log_success "$description 完成"
        return 0
    else
        log_error "$description 失败"
        return 1
    fi
}

safe_execute_with_progress() {
    local cmd="$1"
    local description="$2"
    local start_time=$SECONDS

    echo -ne "${BLUE}${HOURGLASS} [执行中]${NC} $description"

    eval "$cmd" >>"$LOG_FILE" 2>&1 &
    local pid=$!

    progress_bar $pid

    wait $pid
    local exit_code=$?
    local end_time=$SECONDS
    local elapsed_time=$((end_time - start_time))

    printf "\r\033[K"

    if [ $exit_code -eq 0 ]; then
        log_success "$description 完成 (耗时 ${elapsed_time} 秒)"
        return 0
    else
        log_error "$description 失败 (耗时 ${elapsed_time} 秒，详情请查看日志: $LOG_FILE)"
        return 1
    fi
}

configure_apt_mirror_xget() {
    if [ "$SYSTEM_TYPE" != "linux_debian" ]; then return 0; fi

    log_info "使用 Xget 强制配置APT为独占镜像源..."
    
    local sources_list="/etc/apt/sources.list"
    local sources_dir="/etc/apt/sources.list.d"
    local sudo_cmd=""
    if [ "$EUID" -ne 0 ]; then sudo_cmd="sudo"; fi

    $sudo_cmd touch "$sources_list"
    if [ ! -f "${sources_list}.bak_installer" ]; then
        log_info "备份 ${sources_list} 到 ${sources_list}.bak_installer"
        $sudo_cmd cp "$sources_list" "${sources_list}.bak_installer"
    fi

    if [ -d "$sources_dir" ]; then
        if [ ! -d "${sources_dir}.bak_installer" ]; then
            log_info "备份并禁用 ${sources_dir} 目录中的其他源"
            $sudo_cmd mv "$sources_dir" "${sources_dir}.bak_installer"
        fi
    fi
    $sudo_cmd mkdir -p "$sources_dir"

    . /etc/os-release
    local codename="$VERSION_CODENAME"
    
    if [ "$ID" = "debian" ]; then
        $sudo_cmd sh -c "cat > ${sources_list}" << EOF
deb https://${XGET_HOST}/debian/debian ${codename} main contrib non-free non-free-firmware
deb https://${XGET_HOST}/debian/debian ${codename}-updates main contrib non-free non-free-firmware
deb https://${XGET_HOST}/debian/debian ${codename}-backports main contrib non-free non-free-firmware
deb https://${XGET_HOST}/debian/debian-security ${codename}-security main contrib non-free non-free-firmware
EOF
    elif [ "$ID" = "ubuntu" ]; then
        $sudo_cmd sh -c "cat > ${sources_list}" << EOF
deb https://${XGET_HOST}/ubuntu/ubuntu ${codename} main restricted universe multiverse
deb https://${XGET_HOST}/ubuntu/ubuntu ${codename}-updates main restricted universe multiverse
deb https://${XGET_HOST}/ubuntu/ubuntu ${codename}-backports main restricted universe multiverse
deb https://${XGET_HOST}/ubuntu/ubuntu ${codename}-security main restricted universe multiverse
EOF
    fi

    if [ $? -eq 0 ]; then
        log_success "APT镜像源已通过 Xget 配置。"
    else
        log_error "APT镜像源配置失败。"
        return 1
    fi
    return 0
}

install_dependencies_debian() {
    configure_apt_mirror_xget || return 1
    
    local sudo_cmd=""
    if [ "$EUID" -ne 0 ]; then sudo_cmd="sudo"; fi

    safe_execute_with_progress "$sudo_cmd apt-get update" "更新包列表" || return 1
    
    local base_pkgs="curl wget git build-essential"
    safe_execute_with_progress "$sudo_cmd apt-get install -y $base_pkgs" "安装基础编译工具" || return 1

    if [ "$INSTALL_METHOD" = "uv" ]; then
        local python_pkgs="python3 python3-pip python3-venv"
        safe_execute_with_progress "$sudo_cmd apt-get install -y $python_pkgs" "安装系统Python3和pip" || return 1
    elif [ "$INSTALL_METHOD" = "pyenv_poetry" ]; then
        local pyenv_pkgs="libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev"
        safe_execute_with_progress "$sudo_cmd apt-get install -y $pyenv_pkgs" "安装pyenv编译依赖" || return 1
    fi
}

configure_system_pip_mirror_xget() {
    if ! command -v python3 &> /dev/null; then
        log_warning "未找到系统 python3，跳过pip配置。"
        return 0
    fi
    log_info "使用 Xget 配置系统Pip镜像源..."
    
    local mirror_url="https://${XGET_HOST}/pypi/simple"
    safe_execute "python3 -m pip config set global.index-url \"$mirror_url\"" "设置pip索引URL"
    safe_execute "python3 -m pip config set global.trusted-host \"$XGET_HOST\"" "设置pip信任主机"
}

install_uv() {
    log_info "开始安装UV..."
    configure_system_pip_mirror_xget

    safe_execute_with_progress "curl -LsSf https://astral.sh/uv/install.sh | sh" "下载并执行UV安装脚本" || return 1
    
    export PATH="$HOME/.cargo/bin:$PATH"
    
    if ! command -v uv &> /dev/null; then
        log_error "UV安装后未在PATH中找到。"
        return 1
    fi

    export UV_INDEX_URL="https://${XGET_HOST}/pypi/simple"
    safe_execute_with_progress "uv python install $PYTHON_VERSION" "使用UV安装Python $PYTHON_VERSION" || return 1

    configure_uv_environment
    return 0
}

configure_uv_environment() {
    log_info "配置UV环境变量..."
    local shell_configs=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
    local uv_config_block
    read -r -d '' uv_config_block <<EOF

# UV Environment Configuration (Xget Accelerated)
export UV_INDEX_URL="https://${XGET_HOST}/pypi/simple"
export PATH="\$HOME/.cargo/bin:\$PATH"
EOF

    for config_file in "${shell_configs[@]}"; do
        if [ -f "$config_file" ]; then
            sed -i '/# UV Environment Configuration/d' "$config_file"
            sed -i '/export UV_INDEX_URL/d' "$config_file"
            sed -i '/export PATH="\$HOME\/.cargo\/bin:\$PATH"/d' "$config_file"
            echo "$uv_config_block" >> "$config_file"
            log_success "已更新配置到 $config_file"
        fi
    done
}


install_pyenv_poetry() {
    log_info "安装Pyenv + Poetry..."
    
    safe_execute "git config --global url.\"https://${XGET_HOST}/gh/\".insteadOf \"https://github.com/\"" "全局配置 Git 以使用 Xget 加速"

    if [ ! -d "$HOME/.pyenv" ]; then
        safe_execute_with_progress "git clone https://github.com/pyenv/pyenv.git ~/.pyenv" "通过 Xget 克隆 Pyenv" || return 1
    else
        log_info "Pyenv 目录已存在，跳过克隆。"
    fi
    
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"

    local py_mirror="https://registry.npmmirror.com/-/binary/python/"
    log_info "为 Pyenv 配置高速 Python 源码下载镜像: ${py_mirror}"
    log_info "(注: 此源码包不由Xget代理，因此选择已知最快的镜像源)"
    
    safe_execute_with_progress "env PYTHON_BUILD_MIRROR_URL=${py_mirror} pyenv install $PYTHON_VERSION" "使用Pyenv安装Python $PYTHON_VERSION" || return 1
    
    safe_execute "pyenv global $PYTHON_VERSION" "设置全局Python版本为 $PYTHON_VERSION"

    log_info "为 pyenv 管理的 Python 配置 Pip 镜像..."
    local mirror_url="https://${XGET_HOST}/pypi/simple"
    safe_execute "pyenv exec pip config set global.index-url \"$mirror_url\"" "设置pip索引URL"
    safe_execute "pyenv exec pip config set global.trusted-host \"$XGET_HOST\"" "设置pip信任主机"

    if ! pyenv which poetry > /dev/null 2>&1; then
        safe_execute_with_progress "pyenv exec pip install poetry" "通过 pyenv 的 pip 安装 Poetry" || return 1
    else
       log_info "Poetry已安装，跳过。"
    fi
    
    configure_pyenv_environment
    return 0
}

configure_pyenv_environment() {
    log_info "配置Pyenv环境变量..."
    local shell_configs=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
    local pyenv_config_block
    read -r -d '' pyenv_config_block <<'EOF'

# Pyenv Environment Configuration
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "${PYENV_ROOT}/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi
EOF

    for config_file in "${shell_configs[@]}"; do
        if [ -f "$config_file" ]; then
            sed -i '/# Pyenv Environment Configuration/,/fi/d' "$config_file"
            echo "$pyenv_config_block" >> "$config_file"
            log_success "已更新配置到 $config_file"
        fi
    done
}


perform_installation() {
    log_info "开始安装过程..."
    echo "--- Python Installer Log $(date) ---" > "$LOG_FILE"
    
    if [ "$SYSTEM_TYPE" = "linux_debian" ]; then
        install_dependencies_debian || return 1
    fi
    
    if [ "$INSTALL_METHOD" = "uv" ]; then
        install_uv
    elif [ "$INSTALL_METHOD" = "pyenv_poetry" ]; then
        install_pyenv_poetry
    fi
    
    return $?
}

show_completion() {
    clear_screen
    print_header
    log_info "${PARTY} 安装完成! (由 Xget 加速)"
    echo
    echo -e "  ${TICK} Python $PYTHON_VERSION 安装成功"
    echo -e "  ${TICK} 环境变量已配置"
    echo -e "  ${TICK} 所有源已配置为 Xget 全球镜像"
    echo
    echo -e "${YELLOW}💡 下一步建议:${NC}"
    echo -e "   1. ${CYAN}重新打开终端${NC} 或 运行 ${CYAN}'source ~/.bashrc'${NC} (或 ~/.zshrc) 使配置生效。"
    if [ "$INSTALL_METHOD" = "uv" ]; then
        echo -e "   2. 验证Python: ${CYAN}uv python --version${NC}"
        echo -e "   3. 运行Python脚本: ${CYAN}uv python your_script.py${NC}"
        echo -e "   4. 安装包: ${CYAN}uv pip install <package_name>${NC}"
    else
        echo -e "   2. 验证Python: ${CYAN}python --version${NC} 或 ${CYAN}pyenv version${NC}"
        echo -e "   3. 使用Poetry: ${CYAN}poetry new my-project && cd my-project && poetry install${NC}"
    fi
    echo -e "   5. 开始您的Python开发之旅! ${ROCKET}"
    echo
}

# --- 主函数 ---
main() {
    LANGUAGE="zh"
    
    # 初始设置只运行一次
    clear_screen
    print_header
    detect_system || exit 1
    check_admin || exit 1

    # 主菜单流程
    while true; do
        select_install_method
        if [ $? -ne 0 ]; then
            # 用户选择退出
            break
        fi

        select_python_version
        if [ $? -eq 0 ]; then
            # 用户成功选择版本，继续
            if show_install_summary; then
                # 确认安装
                if perform_installation; then
                    show_completion
                else
                    log_error "安装失败，请检查日志: $LOG_FILE"
                fi
                # 无论成功失败，安装流程结束
                exit 0
            else
                # 用户在摘要界面取消，返回主菜单
                log_info "操作已取消，返回主菜单..."
                sleep 2
                continue
            fi
        else
            # 用户在版本选择界面返回，返回主菜单
            log_info "返回到安装方法选择..."
            sleep 1
            continue
        fi
    done
    
    log_info "安装程序已退出。"
    exit 0
}

# --- 运行主程序 ---
main "$@"
