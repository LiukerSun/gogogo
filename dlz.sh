#!/bin/bash

# dlz - Docker安装脚本
# 支持Ubuntu和Debian系统的Docker安装

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 系统信息变量
OS=""
VERSION=""
CPU_MODEL=""
CPU_CORES=""
TOTAL_MEM=""
DISK_SPACE=""

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "此脚本需要root权限执行"
        log_info "请使用 sudo 运行此脚本"
        exit 1
    fi
}

# 检查系统类型
check_system() {
    log_step "检查系统类型"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
        log_info "检测到系统: $OS $VERSION"
        
        if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
            log_error "不支持的系统类型: $OS"
            log_info "此脚本仅支持Ubuntu和Debian系统"
            exit 1
        fi
    else
        log_error "无法确定操作系统类型"
        exit 1
    fi
}

# 获取系统配置信息
get_system_info() {
    log_step "获取系统配置信息"
    
    # 获取CPU型号
    CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -n 1 | cut -d ":" -f 2 | xargs)
    
    # 获取CPU核心数
    CPU_CORES=$(grep -c "processor" /proc/cpuinfo)
    
    # 获取内存大小
    TOTAL_MEM=$(free -h | grep "Mem:" | awk '{print $2}')
    
    # 获取磁盘空间
    DISK_SPACE=$(df -h / | awk 'NR==2 {print $2 " 总共, " $4 " 可用"}')
    
    log_info "CPU型号: $CPU_MODEL"
    log_info "CPU核心数: $CPU_CORES"
    log_info "内存大小: $TOTAL_MEM"
    log_info "磁盘空间: $DISK_SPACE"
}

# 显示菜单
show_menu() {
    echo ""
    echo -e "${BLUE}========== DLZ Docker管理工具 ==========${NC}"
    echo -e "${BLUE}系统信息: ${NC}$OS $VERSION"
    echo -e "${BLUE}CPU: ${NC}$CPU_MODEL ($CPU_CORES 核)"
    echo -e "${BLUE}内存: ${NC}$TOTAL_MEM"
    echo -e "${BLUE}磁盘: ${NC}$DISK_SPACE"
    echo ""
    echo -e "${GREEN}1.${NC} 安装Docker"
    echo -e "${GREEN}2.${NC} 卸载Docker"
    echo -e "${GREEN}3.${NC} 查看Docker状态"
    echo -e "${GREEN}4.${NC} 清理Docker系统"
    echo -e "${GREEN}0.${NC} 退出"
    echo ""
    echo -n "请输入选项 [0-4]: "
    
    # 使用read -n 1获取单个字符并立即处理
    read -n 1 choice
    echo ""  # 添加换行，使输出更美观
    
    case $choice in
        1) install_docker_full ;;
        2) uninstall_docker ;;
        3) show_docker_status ;;
        4) clean_docker ;;
        0) exit 0 ;;
        *) log_error "无效选项，请重新选择" && show_menu ;;
    esac
}

# 卸载Docker功能
uninstall_docker() {
    log_step "卸载Docker"
    apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    apt-get autoremove -y
    rm -rf /var/lib/docker
    rm -rf /var/lib/containerd
    rm -f /etc/apt/sources.list.d/docker.list
    log_info "Docker已卸载"
    show_menu
}

# 显示Docker状态
show_docker_status() {
    log_step "Docker状态"
    
    # 更严格地检查Docker是否已安装
    if ! which docker &> /dev/null; then
        log_error "Docker未安装"
        show_menu
        return
    fi
    
    # 只有当Docker安装时才执行以下命令
    echo -e "${GREEN}Docker版本:${NC}"
    docker --version
    
    echo -e "\n${GREEN}Docker服务状态:${NC}"
    if systemctl is-active --quiet docker; then
        systemctl status docker --no-pager | head -n 20
    else
        echo "Docker服务未运行"
    fi
    
    echo -e "\n${GREEN}Docker镜像列表:${NC}"
    docker images
    
    echo -e "\n${GREEN}运行中的容器:${NC}"
    docker ps
    
    show_menu
}

# 清理Docker系统
clean_docker() {
    log_step "清理Docker系统"
    if ! which docker &> /dev/null; then
        log_error "Docker未安装"
        show_menu
        return
    fi
    
    echo "1. 删除所有停止的容器"
    echo "2. 删除所有未使用的镜像"
    echo "3. 删除所有未使用的数据卷"
    echo "4. 删除所有未使用的网络"
    echo "5. 一键清理所有"
    echo "0. 返回主菜单"
    echo -n "请选择操作 [0-5]: "
    
    # 使用read -n 1获取单个字符并立即处理
    read -n 1 clean_choice
    echo ""  # 添加换行，使输出更美观
    
    case $clean_choice in
        1)
            echo "删除所有停止的容器..."
            docker container prune -f
        ;;
        2)
            echo "删除所有未使用的镜像..."
            docker image prune -a -f
        ;;
        3)
            echo "删除所有未使用的数据卷..."
            docker volume prune -f
        ;;
        4)
            echo "删除所有未使用的网络..."
            docker network prune -f
        ;;
        5)
            echo "执行全面清理..."
            docker system prune -a -f --volumes
        ;;
        0)
            show_menu
            return
        ;;
        *)
            log_error "无效选项"
        ;;
    esac
    
    show_menu
}

# 安装必要的依赖包
install_dependencies() {
    log_step "安装必要的依赖包"
    apt-get update
    apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
    
    if [ $? -ne 0 ]; then
        log_error "安装依赖包失败"
        exit 1
    fi
    log_info "依赖包安装完成"
}

# 安装Docker的GPG密钥
install_docker_gpg() {
    log_step "安装Docker的GPG密钥"
    mkdir -p /etc/apt/keyrings
    
    # 如果GPG密钥文件已存在，先删除它
    if [ -f /etc/apt/keyrings/docker.gpg ]; then
        log_info "发现已存在的Docker GPG密钥文件，将覆盖它"
        rm -f /etc/apt/keyrings/docker.gpg
    fi
    
    curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    if [ $? -ne 0 ]; then
        log_error "获取Docker GPG密钥失败"
        exit 1
    fi
    
    chmod a+r /etc/apt/keyrings/docker.gpg
    log_info "Docker GPG密钥安装完成"
}

# 设置Docker APT仓库
setup_docker_repo() {
    log_step "设置Docker APT仓库"
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    if [ $? -ne 0 ]; then
        log_error "设置Docker仓库失败"
        exit 1
    fi
    log_info "Docker APT仓库设置完成"
}

# 安装Docker Engine
install_docker() {
    log_step "安装Docker Engine"
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    if [ $? -ne 0 ]; then
        log_error "安装Docker失败"
        exit 1
    fi
    log_info "Docker安装完成"
}

# 设置Docker自启动
setup_docker_service() {
    log_step "设置Docker服务自启动"
    systemctl enable docker
    systemctl start docker
    
    if [ $? -ne 0 ]; then
        log_error "设置Docker服务自启动失败"
        exit 1
    fi
    log_info "Docker服务设置完成"
}

# 添加当前用户到docker组
add_user_to_docker_group() {
    if [ -n "$SUDO_USER" ]; then
        log_step "将用户 $SUDO_USER 添加到docker组"
        usermod -aG docker $SUDO_USER
        if [ $? -ne 0 ]; then
            log_warn "将用户添加到docker组失败，您可能需要手动执行: sudo usermod -aG docker $USER"
        else
            log_info "用户已添加到docker组，请注销并重新登录以使更改生效"
        fi
    else
        log_warn "无法确定真实用户，请手动执行: sudo usermod -aG docker $USER"
    fi
}

# 验证Docker安装
verify_docker() {
    log_step "验证Docker安装"
    if docker --version > /dev/null 2>&1; then
        DOCKER_VERSION=$(docker --version)
        log_info "Docker安装成功: $DOCKER_VERSION"
    else
        log_error "Docker安装验证失败，请检查安装过程中的错误"
        exit 1
    fi
}

# 显示安装后的信息
show_post_install_info() {
    echo ""
    log_info "========== Docker安装完成 =========="
    log_info "您可以使用以下命令测试Docker:"
    echo "  docker run hello-world"
    log_info "如果您刚刚被添加到docker组，请注销并重新登录以应用更改"
    echo ""
    show_menu
}

# 更新系统软件包
update_system() {
    log_step "更新系统软件包"
    apt-get update
    apt-get upgrade -y
    
    if [ $? -ne 0 ]; then
        log_warn "系统更新可能未完全成功，继续安装可能会有风险"
        echo -n "是否继续安装? [y/N]: "
        read -r continue_choice
        if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
            log_info "安装已取消"
            return 1
        fi
    else
        log_info "系统软件包已更新"
    fi
    return 0
}

# 完整的Docker安装流程
install_docker_full() {
    check_root
    
    # 先更新系统软件包
    update_system
    if [ $? -ne 0 ]; then
        show_menu
        return
    fi
    
    install_dependencies
    install_docker_gpg
    setup_docker_repo
    install_docker
    setup_docker_service
    add_user_to_docker_group
    verify_docker
    show_post_install_info
}

# 主函数
main() {
    echo "========== DLZ Docker管理工具 =========="
    
    # 先检查root权限
    check_root
    
    # 检查系统类型和获取系统配置
    check_system
    get_system_info
    
    # 显示主菜单
    show_menu
}

# 执行主函数
main