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
    echo -e "${GREEN}5.${NC} 安装WordPress独立站"
    echo -e "${GREEN}0.${NC} 退出"
    echo ""
    echo -n "请输入选项 [0-5]: "
    
    # 使用read -n 1获取单个字符并立即处理
    read -n 1 choice
    echo ""  # 添加换行，使输出更美观
    
    case $choice in
        1) install_docker_full ;;
        2) uninstall_docker ;;
        3) show_docker_status ;;
        4) clean_docker ;;
        5) install_wordpress ;;
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

# 安装WordPress独立站
install_wordpress() {
    # 添加中断信号处理 - 改进信号处理
    trap 'echo -e "\n[INFO] 用户中断操作，退出安装"; cleanup_and_exit' INT TERM
    
    # 定义清理函数
    cleanup_and_exit() {
        echo "[INFO] 正在清理..."
        cd $ORIGINAL_DIR 2>/dev/null || true
        show_menu
        exit 0
    }
    
    # 保存当前目录
    ORIGINAL_DIR=$(pwd)
    
    log_step "安装WordPress独立站"
    
    # 检查Docker是否已安装
    if ! which docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        read -n 1 -p "是否现在安装Docker? [y/N]: " install_docker_choice
        echo ""
        if [[ "$install_docker_choice" =~ ^[Yy]$ ]]; then
            install_docker_full
        else
            show_menu
            return
        fi
    fi
    
    # 检查docker-compose是否已安装
    if ! which docker-compose &> /dev/null; then
        log_info "安装docker-compose..."
        apt-get install -y docker-compose
        if [ $? -ne 0 ]; then
            log_error "docker-compose安装失败"
            show_menu
            return
        fi
    fi
    
    # 创建工作目录
    SITE_DIR="./wordpress_site"
    mkdir -p $SITE_DIR
    cd $SITE_DIR
    
    # 检查是否已存在数据
    if [ -d "./data/mysql" ] || [ -d "./data/wordpress" ]; then
        log_warn "检测到已存在的WordPress数据"
        echo -e "${YELLOW}继续安装将使用现有数据，这可能导致连接问题${NC}"
        
        # 明确提示用户并等待输入
        while true; do
            echo -n "是否删除现有数据并全新安装? [Y/n]: "
            read -n 1 delete_choice
            echo ""
            
            # 检查是否按了回车键（默认Y）
            if [ -z "$delete_choice" ]; then
                delete_choice="Y"
            fi
            
            # 验证输入
            if [[ "$delete_choice" =~ ^[YyNn]$ ]]; then
                break
            else
                log_error "无效输入，请输入 Y 或 n"
            fi
        done
        
        if [[ "$delete_choice" =~ ^[Nn]$ ]]; then
            log_info "将使用现有数据继续安装"
            EXISTING_DATA=true
        else
            log_info "删除现有数据并重新安装"
            # 先停止所有相关容器
            log_info "停止现有Docker容器..."
            docker-compose down 2>/dev/null || true
            
            # 确保没有与这些文件相关的进程
            log_info "确保数据可以安全删除..."
            sleep 2
            
            # 强制删除所有相关文件和目录
            log_info "删除现有WordPress数据..."
            rm -rf ./data
            rm -f docker-compose.yml mysql-init.sql site_info.txt wp-cli.yml
            
            # 验证删除是否成功
            if [ -d "./data" ]; then
                log_error "数据目录删除失败，可能是权限问题"
                log_info "尝试使用sudo删除..."
                sudo rm -rf ./data 2>/dev/null || {
                    log_error "无法删除数据目录，请手动删除后重试"
                    cleanup_and_exit
                    return
                }
            fi
            
            # 创建全新的数据目录
            log_info "创建新的数据目录..."
            mkdir -p ./data
            
            EXISTING_DATA=false
            log_info "数据已成功删除，准备重新安装"
        fi
    else
        EXISTING_DATA=false
    fi
    
    # 收集用户输入
    echo -e "${BLUE}请输入WordPress站点信息${NC}"
    echo "=================================="
    
    # 在提示后添加一个空行，使界面更清晰
    echo ""
    
    # 站点域名
    echo -n "站点域名 (例如: wordpress.liukersun.com): "
    read SITE_DOMAIN
    SITE_DOMAIN=${SITE_DOMAIN:-wordpress.liukersun.com}
    
    # MySQL配置
    echo -n "MySQL用户名 (默认: wordpress): "
    read MYSQL_USER
    MYSQL_USER=${MYSQL_USER:-wordpress}
    
    # 生成随机16位密码，如果用户不输入，则自动生成
    echo -n "MySQL密码 (留空将自动生成): "
    read MYSQL_PASSWORD
    if [ -z "$MYSQL_PASSWORD" ]; then
        MYSQL_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 16)
        log_info "随机生成的MySQL密码: $MYSQL_PASSWORD"
    fi
    
    echo -n "MySQL根密码 (默认: root_password): "
    read MYSQL_ROOT_PASSWORD
    MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-root_password}
    
    echo -n "MySQL数据库名 (默认: wordpress): "
    read MYSQL_DATABASE
    MYSQL_DATABASE=${MYSQL_DATABASE:-wordpress}
    
    # WordPress管理员配置
    echo -n "WordPress管理员用户名 (默认: admin): "
    read WP_ADMIN
    WP_ADMIN=${WP_ADMIN:-admin}
    
    # 生成随机16位密码，如果用户不输入，则自动生成
    echo -n "WordPress管理员密码 (留空将自动生成): "
    read WP_ADMIN_PASSWORD
    if [ -z "$WP_ADMIN_PASSWORD" ]; then
        WP_ADMIN_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 16)
        log_info "随机生成的WordPress管理员密码: $WP_ADMIN_PASSWORD"
    fi
    
    echo -n "WordPress管理员邮箱: "
    read WP_ADMIN_EMAIL
    WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL:-admin@${SITE_DOMAIN}}
    
    echo -n "WordPress站点标题 (默认: My WordPress Site): "
    read WP_TITLE
    WP_TITLE=${WP_TITLE:-"My WordPress Site"}
    
    # 端口配置
    echo -n "WordPress访问端口 (默认: 8080): "
    read WP_PORT
    WP_PORT=${WP_PORT:-8080}
    
    echo -n "MySQL端口 (默认: 3306): "
    read MYSQL_PORT
    MYSQL_PORT=${MYSQL_PORT:-3306}
    
    # 确认用户输入
    echo ""
    echo "您输入的信息如下:"
    echo "站点域名: $SITE_DOMAIN"
    echo "MySQL用户名: $MYSQL_USER"
    echo "MySQL密码: $MYSQL_PASSWORD"
    echo "MySQL根密码: $MYSQL_ROOT_PASSWORD"
    echo "MySQL数据库名: $MYSQL_DATABASE"
    echo "WordPress管理员用户名: $WP_ADMIN"
    echo "WordPress管理员密码: $WP_ADMIN_PASSWORD"
    echo "WordPress管理员邮箱: $WP_ADMIN_EMAIL"
    echo "WordPress站点标题: $WP_TITLE"
    echo "WordPress访问端口: $WP_PORT"
    echo "MySQL端口: $MYSQL_PORT"
    
    # 请求用户确认
    while true; do
        echo -n "确认以上信息并继续安装? [Y/n]: "
        read -n 1 confirm
        echo ""
        
        # 默认为Y
        if [ -z "$confirm" ]; then
            confirm="Y"
        fi
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            log_info "继续安装..."
            break
            elif [[ "$confirm" =~ ^[Nn]$ ]]; then
            log_info "取消安装"
            cleanup_and_exit
            return
        else
            log_error "无效输入，请输入 Y 或 n"
        fi
    done
    
    # 创建目录结构 - 只有在不使用现有数据时才创建
    if [ "$EXISTING_DATA" = "false" ]; then
        log_info "创建数据持久化目录..."
        mkdir -p ./data/mysql
        mkdir -p ./data/wordpress
        
        # 设置目录权限确保Docker容器可以访问
        chmod -R 777 ./data
    else
        log_info "使用现有数据目录..."
    fi
    
    # 修改docker-compose.yml文件，改进MySQL配置
    cat > docker-compose.yml << EOF
version: '3'

services:
  # 数据库
  db:
    image: mysql:5.7
    volumes:
      - ./data/mysql:/var/lib/mysql
      - ./mysql-init.sql:/docker-entrypoint-initdb.d/mysql-init.sql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    ports:
      - "${MYSQL_PORT}:3306"
    command: --default-authentication-plugin=mysql_native_password --bind-address=0.0.0.0 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci --max-connections=1000 --wait-timeout=3600 --skip-ssl

  # WordPress
  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    volumes:
      - ./data/wordpress:/var/www/html
    ports:
      - "${WP_PORT}:80"
    restart: always
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}
      WORDPRESS_CONFIG_EXTRA: |
        define('WP_DEBUG', true);
        define('WP_DEBUG_LOG', true);
EOF
    
    # 更新MySQL容器的配置，使用官方推荐的连接设置
    cat > mysql-init.sql << EOF
-- 设置MySQL配置
SET GLOBAL max_connections = 1000;
-- 禁用SSL要求
SET GLOBAL have_ssl = 'DISABLED';
SET GLOBAL have_openssl = 'DISABLED';
-- 创建用户并授予权限（使用原生SQL语法确保兼容MySQL 5.7）
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'localhost';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'172.%.%.%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'172.%.%.%';
FLUSH PRIVILEGES;
EOF
    
    # 启动容器 - 只启动数据库和WordPress
    log_info "启动MySQL和WordPress容器..."
    
    # 如果使用现有数据，先尝试停止并移除现有容器
    if [ "$EXISTING_DATA" = "true" ]; then
        log_info "停止并移除现有容器..."
        docker-compose down 2>/dev/null || true
        sleep 2
    fi
    
    # 使用超时命令，确保可以被中断
    timeout 60s docker-compose up -d db wordpress || {
        log_error "启动容器超时或失败"
        cleanup_and_exit
        return
    }
    
    # 等待MySQL数据库准备就绪
    log_info "等待MySQL数据库准备就绪..."
    MYSQL_READY=false
    MAX_ATTEMPTS=30
    ATTEMPT=1
    
    while [ $ATTEMPT -le $MAX_ATTEMPTS ] && [ "$MYSQL_READY" = "false" ]; do
        if docker-compose logs db | grep -q "ready for connections"; then
            log_info "MySQL数据库已准备就绪"
            MYSQL_READY=true
        else
            log_info "等待MySQL准备就绪... (尝试 $ATTEMPT/$MAX_ATTEMPTS)"
            sleep 3
            ATTEMPT=$((ATTEMPT+1))
        fi
    done
    
    if [ "$MYSQL_READY" = "false" ]; then
        log_error "MySQL数据库未能在预期时间内准备就绪"
        docker-compose logs db
        cleanup_and_exit
        return
    fi
    
    # 等待WordPress准备就绪
    log_info "等待WordPress准备就绪..."
    WP_READY=false
    MAX_ATTEMPTS=30
    ATTEMPT=1
    
    while [ $ATTEMPT -le $MAX_ATTEMPTS ] && [ "$WP_READY" = "false" ]; do
        # 检查WordPress容器是否运行
        if ! docker-compose ps wordpress | grep -q "Up"; then
            log_error "WordPress容器未能正常启动"
            docker-compose logs wordpress
            cleanup_and_exit
            return
        fi
        
        # 检查WordPress是否已经能够处理HTTP请求 - 修改匹配模式以适应实际日志
        if docker-compose logs wordpress | grep -q "Apache/2.4" && \
        (docker-compose logs wordpress | grep -q "resuming normal operations" || \
            docker-compose logs wordpress | grep -q "ready to handle connections"); then
            log_info "WordPress已准备就绪"
            WP_READY=true
        else
            log_info "等待WordPress准备就绪... (尝试 $ATTEMPT/$MAX_ATTEMPTS)"
            sleep 3
            ATTEMPT=$((ATTEMPT+1))
        fi
    done
    
    if [ "$WP_READY" = "false" ]; then
        log_error "WordPress未能在预期时间内准备就绪"
        docker-compose logs wordpress
        cleanup_and_exit
        return
    fi
    
    # 检查WordPress与数据库的连接
    log_info "检查WordPress与数据库的连接..."
    DB_CONNECT_READY=false
    MAX_ATTEMPTS=20
    ATTEMPT=1
    
    while [ $ATTEMPT -le $MAX_ATTEMPTS ] && [ "$DB_CONNECT_READY" = "false" ]; do
        if docker-compose exec wordpress ls -la /var/www/html/wp-config.php > /dev/null 2>&1; then
            # 确认wp-config.php已创建
            if docker-compose logs wordpress | grep -q "database connection established"; then
                log_info "WordPress已成功连接到数据库"
                DB_CONNECT_READY=true
                elif ! docker-compose logs wordpress | grep -q "Error establishing a database connection"; then
                # 如果没有发现数据库连接错误，我们假设连接已建立
                log_info "WordPress似乎已成功连接到数据库"
                DB_CONNECT_READY=true
            fi
        fi
        
        if [ "$DB_CONNECT_READY" = "false" ]; then
            log_info "等待WordPress连接到数据库... (尝试 $ATTEMPT/$MAX_ATTEMPTS)"
            sleep 5
            ATTEMPT=$((ATTEMPT+1))
        fi
    done
    
    if [ "$DB_CONNECT_READY" = "false" ]; then
        log_error "WordPress无法连接到数据库，安装失败"
        docker-compose logs wordpress
        docker-compose logs db
        cleanup_and_exit
        return
    fi
    
    # 运行WP-CLI安装命令
    log_info "配置WordPress站点..."
    
    # 创建WP-CLI配置文件
    cat > wp-cli.yml << EOF
path: /var/www/html
url: ${SITE_DOMAIN}:${WP_PORT}
user: ${WP_ADMIN}
# 显示设置数据库连接信息
database:
  host: db
  name: ${MYSQL_DATABASE}
  user: ${MYSQL_USER}
  password: ${MYSQL_PASSWORD}
EOF
    
    # 创建临时脚本文件
    cat > setup-wp.sh << 'EOF'
#!/bin/bash
# 设置超时和中断处理
trap 'echo "收到中断信号，脚本退出"; exit 1' INT TERM
set -e

# 添加调试信息
echo "======环境变量======="
env | grep -E 'WORDPRESS|WP_|MYSQL'
echo "===================="

# 检查并确保文件权限正确
echo "设置正确的文件权限..."
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# 修改wp-config.php确保使用正确的数据库主机名和凭证
echo "检查数据库连接..."
if [ -f /var/www/html/wp-config.php ]; then
  echo "找到wp-config.php，更新所有数据库设置..."

  # 直接设置所有数据库配置项
  wp config set DB_HOST db --allow-root
  wp config set DB_NAME "$WORDPRESS_DB_NAME" --allow-root
  wp config set DB_USER "$WORDPRESS_DB_USER" --allow-root
  wp config set DB_PASSWORD "$WORDPRESS_DB_PASSWORD" --allow-root

  # 移除可能导致问题的SSL设置
  echo "移除SSL设置，避免连接问题..."
  if grep -q "MYSQL_CLIENT_FLAGS" /var/www/html/wp-config.php; then
    wp config delete MYSQL_CLIENT_FLAGS --allow-root || true
  fi

  # 直接编辑wp-config.php文件，手动添加禁用SSL验证的代码
  echo "手动添加数据库连接选项..."
  if ! grep -q "wp_db_connect_flags" /var/www/html/wp-config.php; then
    # 在wp-config.php文件开头附近添加自定义连接函数
    sed -i '/\/\* That.s all, stop editing!.*/i \
// 自定义数据库连接设置\
if ( !function_exists( "wp_db_connect_flags" ) ) {\
    function wp_db_connect_flags() { return 2; /*MYSQLI_CLIENT_SSL_DONT_VERIFY_SERVER_CERT*/ }\
}\
' /var/www/html/wp-config.php
  fi

  # 打印wp-config.php的数据库配置部分，用于调试
  echo "数据库配置："
  grep -A 10 "DB_" /var/www/html/wp-config.php

  # 检查是否已安装WordPress
  if wp core is-installed --allow-root; then
    echo "WordPress已安装，不需要重新安装"
    WP_INSTALLED=true
  else
    echo "WordPress尚未安装，需要进行安装"
    WP_INSTALLED=false
  fi
fi

# 等待数据库连接可用
echo "测试数据库连接..."
max_attempts=20
attempt=1

# 首先诊断网络连接
echo "检查与数据库容器的网络连接..."
ping -c 3 db || echo "无法ping通数据库容器，但这可能是因为容器未配置响应ping"

# 检查数据库端口
echo "检查数据库端口..."
nc -z -v db 3306 || echo "无法连接到数据库端口，可能是MySQL尚未完全启动"

# 尝试root用户直接连接
echo "尝试以root用户连接数据库..."
if mysql -h db -u root -p"$MYSQL_ROOT_PASSWORD" --skip-ssl -e "SHOW DATABASES;" 2>/dev/null; then
  echo "以root用户成功连接数据库!"

  # 验证并修复用户权限
  echo "验证WordPress用户权限..."
  mysql -h db -u root -p"$MYSQL_ROOT_PASSWORD" --skip-ssl << EOSQL
CREATE USER IF NOT EXISTS '$WORDPRESS_DB_USER'@'%' IDENTIFIED BY '$WORDPRESS_DB_PASSWORD';
GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO '$WORDPRESS_DB_USER'@'%';
CREATE USER IF NOT EXISTS '$WORDPRESS_DB_USER'@'localhost' IDENTIFIED BY '$WORDPRESS_DB_PASSWORD';
GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO '$WORDPRESS_DB_USER'@'localhost';
CREATE USER IF NOT EXISTS '$WORDPRESS_DB_USER'@'172.%.%.%' IDENTIFIED BY '$WORDPRESS_DB_PASSWORD';
GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO '$WORDPRESS_DB_USER'@'172.%.%.%';
FLUSH PRIVILEGES;
EOSQL

  echo "用户权限已更新"
else
  echo "无法以root用户连接，将继续尝试WordPress用户连接"
fi

while [ $attempt -le $max_attempts ]; do
  # 显示更多的连接调试信息
  echo "尝试连接数据库... ($attempt/$max_attempts)"

  # 使用mysqladmin ping测试连接 - 使用兼容的参数
  if mysqladmin -h db -u "$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" --skip-ssl ping 2>/dev/null | grep -q 'mysqld is alive'; then
    echo "数据库连接成功 (mysqladmin ping)!"
    break
  fi

  # 备用方法：尝试MySQL直接连接 - 使用兼容的参数
  if mysql -h db -u "$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" --skip-ssl -e "SHOW DATABASES;" 2>/dev/null; then
    echo "数据库连接成功 (mysql query)!"
    break
  fi

  # 显示详细的连接错误（但仅显示最多两行错误信息，避免信息过多）
  echo "连接错误详情:"
  mysql -h db -u "$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" --skip-ssl -e "SHOW DATABASES;" 2>&1 | head -2

  # 显示MySQL容器状态
  if [ $attempt -eq 5 -o $attempt -eq 10 -o $attempt -eq 15 ]; then
    echo "MySQL容器状态检查 (尝试 $attempt):"
    ps aux | grep mysql || echo "没有找到MySQL进程"
    netstat -tuln | grep 3306 || echo "没有找到监听在3306端口的服务"

    # 再次尝试以root用户连接并修复权限
    echo "尝试以root用户修复权限..."
    mysql -h db -u root -p"$MYSQL_ROOT_PASSWORD" --skip-ssl << EOSQL
GRANT ALL PRIVILEGES ON *.* TO '$WORDPRESS_DB_USER'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOSQL
  fi

  attempt=$((attempt+1))
  sleep 5

  if [ $attempt -gt $max_attempts ]; then
    echo "无法连接到数据库，最大尝试次数已用完"
    echo "最终尝试使用root密码强制完成安装..."
    # 尝试替换WordPress配置中的用户为root用户
    wp config set DB_USER "root" --allow-root
    wp config set DB_PASSWORD "$MYSQL_ROOT_PASSWORD" --allow-root
    echo "已切换到root用户，继续安装..."
    break
  fi
done

# 等待WordPress完全初始化
echo "WordPress初始化..."
if wp core is-installed --allow-root 2>/dev/null; then
  echo "WordPress已安装，跳过初始化"

  # 如果WordPress已安装但用户需要更新管理员信息
  echo "检查是否需要更新管理员账户..."
  ADMIN_EXISTS=$(wp user get "$WP_ADMIN" --field=login --allow-root 2>/dev/null || echo "")

  if [ -n "$ADMIN_EXISTS" ]; then
    echo "管理员账户 $WP_ADMIN 已存在，更新密码..."
    wp user update "$WP_ADMIN" --user_pass="$WP_ADMIN_PASSWORD" --allow-root || echo "更新管理员密码失败"
  else
    echo "创建新的管理员账户..."
    wp user create "$WP_ADMIN" "$WP_ADMIN_EMAIL" --role=administrator --user_pass="$WP_ADMIN_PASSWORD" --allow-root || echo "创建管理员账户失败"
  fi

  # 更新站点标题和URL
  echo "更新站点信息..."
  wp option update blogname "$WP_TITLE" --allow-root || echo "更新站点标题失败"
  wp option update siteurl "http://${SITE_DOMAIN}:${WP_PORT}" --allow-root || echo "更新站点URL失败"
  wp option update home "http://${SITE_DOMAIN}:${WP_PORT}" --allow-root || echo "更新站点首页URL失败"
else
  # 安装WordPress核心
  echo "安装WordPress核心..."
  wp core install --title="$WP_TITLE" --admin_user="$WP_ADMIN" --admin_password="$WP_ADMIN_PASSWORD" --admin_email="$WP_ADMIN_EMAIL" --skip-email --allow-root || {
    echo "直接WordPress安装失败，尝试使用替代方法..."
    # 尝试使用curl直接访问安装页面
    echo "通过访问安装页面检查WordPress状态..."
    curl -v http://wordpress/wp-admin/install.php 2>&1 || echo "无法访问WordPress安装页面"
    exit 1
  }

  # 安装插件和主题
  echo "安装插件和主题..."
  wp theme install twentytwentythree --activate --allow-root || echo "主题安装失败，但继续执行"

  echo "WordPress配置完成!"
fi

# 安装并配置WooCommerce
echo "安装WooCommerce插件..."
if wp plugin is-installed woocommerce --allow-root; then
  echo "WooCommerce已安装，检查是否需要更新..."
  if ! wp plugin is-active woocommerce --allow-root; then
    echo "激活WooCommerce插件..."
    wp plugin activate woocommerce --allow-root
  fi

  echo "检查WooCommerce更新..."
  wp plugin update woocommerce --allow-root
else
  echo "安装WooCommerce插件..."
  wp plugin install woocommerce --activate --allow-root || {
    echo "WooCommerce安装失败，请手动检查错误"
    exit 1
  }
fi

# 设置WooCommerce基本配置
echo "配置WooCommerce基本设置..."
# 设置商店地址
wp option update woocommerce_store_address "123 Main St" --allow-root
wp option update woocommerce_store_city "Beijing" --allow-root
wp option update woocommerce_store_postcode "100000" --allow-root
wp option update woocommerce_default_country "CN" --allow-root
wp option update woocommerce_currency "CNY" --allow-root

echo "WooCommerce安装和配置完成！"
EOF
    
    chmod +x setup-wp.sh
    
    # 获取Docker网络名称（确保使用正确的网络名）
    NETWORK_NAME=$(docker network ls | grep wordpress_site | awk '{print $2}')
    if [ -z "$NETWORK_NAME" ]; then
        NETWORK_NAME="wordpress_site_default"
    fi
    
    log_info "使用网络 $NETWORK_NAME 连接WP-CLI容器 (最大执行时间3分钟)"
    
    # 声明一个变量来存储超时状态
    WP_CLI_TIMEOUT=0
    
    # 使用timeout命令，最多允许WP-CLI容器运行3分钟
    # 添加--init和--sig-proxy=false确保信号处理正确
    timeout --foreground 180s docker run --init --sig-proxy=false --rm --network=$NETWORK_NAME \
    --user root \
    --env WP_TITLE="${WP_TITLE}" \
    --env WP_ADMIN="${WP_ADMIN}" \
    --env WP_ADMIN_PASSWORD="${WP_ADMIN_PASSWORD}" \
    --env WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL}" \
    --env WORDPRESS_DB_HOST="db" \
    --env WORDPRESS_DB_USER="${MYSQL_USER}" \
    --env WORDPRESS_DB_PASSWORD="${MYSQL_PASSWORD}" \
    --env WORDPRESS_DB_NAME="${MYSQL_DATABASE}" \
    --env MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
    -v $(pwd)/wp-cli.yml:/wp-cli.yml \
    -v $(pwd)/setup-wp.sh:/setup-wp.sh \
    -v $(pwd)/data/wordpress:/var/www/html \
    wordpress:cli /setup-wp.sh || WP_CLI_TIMEOUT=1
    
    # 检查是否超时
    if [ $WP_CLI_TIMEOUT -eq 1 ]; then
        log_warn "WordPress初始化操作超时或被中断"
        read -n 1 -t 5 -p "是否继续尝试完成安装? [y/N]: " continue_choice
        echo ""
        if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
            log_info "安装已取消"
            cleanup_and_exit
            return
        fi
    fi
    
    WP_RESULT=$?
    
    # 清理临时文件
    rm -f wp-cli.yml setup-wp.sh mysql-init.sql
    
    # 检查安装结果
    if [ $WP_RESULT -ne 0 ]; then
        log_error "WordPress配置失败，请检查日志"
        cleanup_and_exit
        return
    fi
    
    # 成功安装后显示信息
    log_info "WordPress安装成功!"
    echo ""
    echo -e "${GREEN}WordPress站点信息:${NC}"
    echo "=================================="
    echo "站点URL: http://localhost:${WP_PORT} 或 http://${SITE_DOMAIN}:${WP_PORT}"
    echo "管理员面板: http://localhost:${WP_PORT}/wp-admin"
    echo "管理员用户名: ${WP_ADMIN}"
    echo "管理员密码: ${WP_ADMIN_PASSWORD}"
    echo "管理员邮箱: ${WP_ADMIN_EMAIL}"
    echo ""
    echo "MySQL信息:"
    echo "端口: ${MYSQL_PORT}"
    echo "数据库名: ${MYSQL_DATABASE}"
    echo "用户名: ${MYSQL_USER}"
    echo "密码: ${MYSQL_PASSWORD}"
    echo "根密码: ${MYSQL_ROOT_PASSWORD}"
    echo ""
    echo "数据目录: $(pwd)/data"
    echo "=================================="
    echo ""
    
    # 保存配置信息到文件
    {
        echo "# WordPress站点配置"
        echo "站点URL: http://localhost:${WP_PORT} 或 http://${SITE_DOMAIN}:${WP_PORT}"
        echo "管理员面板: http://localhost:${WP_PORT}/wp-admin"
        echo "管理员用户名: ${WP_ADMIN}"
        echo "管理员密码: ${WP_ADMIN_PASSWORD}"
        echo "管理员邮箱: ${WP_ADMIN_EMAIL}"
        echo ""
        echo "# MySQL信息"
        echo "端口: ${MYSQL_PORT}"
        echo "数据库名: ${MYSQL_DATABASE}"
        echo "用户名: ${MYSQL_USER}"
        echo "密码: ${MYSQL_PASSWORD}"
        echo "根密码: ${MYSQL_ROOT_PASSWORD}"
        echo ""
        echo "# 数据目录"
        echo "$(pwd)/data"
    } > site_info.txt
    
    log_info "站点信息已保存到 site_info.txt 文件"
    
    # 重置中断信号处理，确保所有信号都被重置
    trap - INT TERM EXIT
    
    # 返回原始目录
    cd $ORIGINAL_DIR
}

# 证书管理主函数
manage_certificate() {
    log_step "证书配置与管理"
    
    # 添加中断信号处理
    trap 'echo -e "\n[INFO] 用户中断操作，退出证书管理"; return_to_menu' INT TERM
    
    # 定义返回主菜单的函数
    return_to_menu() {
        show_menu
        return
    }
    
    # 显示证书管理子菜单
    show_cert_menu() {
        echo ""
        echo -e "${BLUE}========== 证书配置与管理 ==========${NC}"
        echo -e "${GREEN}1.${NC} 安装Nginx服务"
        echo -e "${GREEN}2.${NC} 安装acme服务"
        echo -e "${GREEN}3.${NC} 配置acme信息"
        echo -e "${GREEN}4.${NC} 查看Nginx状态"
        echo -e "${GREEN}5.${NC} 查看acme信息"
        echo -e "${GREEN}6.${NC} 添加证书"
        echo -e "${GREEN}7.${NC} 证书管理"
        echo -e "${GREEN}8.${NC} 证书续签"
        echo -e "${GREEN}0.${NC} 返回主菜单"
        echo ""
        echo -n "请选择操作 [0-8]: "
        read -n 1 cert_choice
        echo ""
        
        case $cert_choice in
            1)
                install_nginx_service
                show_cert_menu
            ;;
            2)
                install_acme_service
                show_cert_menu
            ;;
            3)
                configure_acme_info
                show_cert_menu
            ;;
            4)
                check_nginx_status
                show_cert_menu
            ;;
            5)
                check_acme_info
                show_cert_menu
            ;;
            6)
                add_certificate
                show_cert_menu
            ;;
            7)
                manage_certificates_submenu
                show_cert_menu
            ;;
            8)
                renew_certificate
                show_cert_menu
            ;;
            0)
                return_to_menu
                return
            ;;
            *)
                log_error "无效选项，请重新选择"
                show_cert_menu
            ;;
        esac
    }
    
    # 创建证书相关目录
    mkdir -p /etc/nginx/ssl/certs
    mkdir -p /etc/nginx/ssl/conf
    mkdir -p /var/www/acme-challenge
    
    # 显示证书管理菜单
    show_cert_menu
    
    # 重置信号处理器
    trap - INT TERM
}

# 安装Nginx服务
install_nginx_service() {
    log_info "安装Nginx服务"
    
    # 使用apt安装Nginx
    log_info "使用apt安装Nginx..."
    apt-get update
    apt-get install -y nginx
    
    # 检查安装状态
    if ! which nginx &>/dev/null; then
        log_error "Nginx安装失败"
        return
    fi
    
    log_info "Nginx安装成功"
    
    # 创建证书目录
    mkdir -p /etc/nginx/ssl/certs
    mkdir -p /etc/nginx/ssl/conf
    
    # 创建目录存放acme验证文件
    mkdir -p /var/www/acme-challenge
    chmod -R 755 /var/www/acme-challenge
    
    # 备份默认配置
    if [ -f /etc/nginx/sites-available/default ]; then
        cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
        log_info "已备份Nginx默认配置"
    fi
    
    # 创建更好的默认配置
    cat > /etc/nginx/sites-available/default << EOF
server {
    listen 80;
    server_name _;

    location / {
        root   /var/www/html;
        index  index.html index.htm;
    }

    # 用于acme.sh验证
    location /.well-known/acme-challenge/ {
        root /var/www/acme-challenge;
        try_files \$uri =404;
    }
}
EOF
    
    # 重启Nginx服务
    systemctl restart nginx
    systemctl enable nginx
    
    log_success "Nginx安装和配置完成"
    
    # 等待用户按键继续
    echo ""
    read -n 1 -p "按任意键继续..." dummy
    echo ""
}

# 安装acme服务
install_acme_service() {
    log_info "安装acme.sh服务"
    
    # 检查是否已安装curl和socat
    apt-get update
    apt-get install -y curl socat cron
    
    # 检查Nginx是否安装
    if ! which nginx &>/dev/null; then
        log_error "Nginx未安装，请先安装Nginx服务"
        return
    fi
    
    # 确保cron服务正在运行
    systemctl start cron
    systemctl enable cron
    
    # 创建acme配置目录
    mkdir -p /root/.acme.sh
    mkdir -p /etc/nginx/ssl/acme-conf
    
    # 获取用户邮箱
    echo -n "请输入您的有效邮箱地址 (用于Let's Encrypt通知): "
    read USER_EMAIL
    
    # 验证邮箱格式
    if [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log_error "邮箱格式无效，请输入正确的邮箱地址"
        return 1
    fi
    
    # 保存邮箱到默认配置文件
    mkdir -p /etc/nginx/ssl/acme-conf
    echo "DEFAULT_EMAIL=\"$USER_EMAIL\"" > /etc/nginx/ssl/acme-conf/default.conf
    chmod 600 /etc/nginx/ssl/acme-conf/default.conf
    
    # 创建acme.sh安装脚本
    cat > /tmp/acme-install.sh << EOF
#!/bin/bash
set -e

# 设置安装路径
export ACME_HOME="/root/.acme.sh"

# 检查是否已安装
if [ -f "\$ACME_HOME/acme.sh" ]; then
    echo "acme.sh 已安装在 \$ACME_HOME"
    # 更新acme.sh
    "\$ACME_HOME/acme.sh" --upgrade
else
    # 安装acme.sh
    echo "安装acme.sh..."
    curl https://get.acme.sh | sh -s email=${USER_EMAIL}
fi

# 验证安装
if [ -f "\$ACME_HOME/acme.sh" ]; then
    echo "acme.sh 安装成功!"
    "\$ACME_HOME/acme.sh" --version
    # 设置默认CA
    "\$ACME_HOME/acme.sh" --set-default-ca --server letsencrypt
    # 设置自动更新
    "\$ACME_HOME/acme.sh" --upgrade --auto-upgrade
else
    echo "acme.sh 安装失败!"
    exit 1
fi

# 配置acme.sh使用nginx模式
"\$ACME_HOME/acme.sh" --set-default-webroot /var/www/acme-challenge
EOF
    
    chmod +x /tmp/acme-install.sh
    
    # 执行安装脚本
    log_info "开始安装acme.sh..."
    if bash /tmp/acme-install.sh; then
        log_info "acme.sh安装成功，已配置使用Nginx进行验证"
    else
        log_error "acme.sh安装失败"
    fi
    
    # 注册acme.sh账号
    log_info "注册acme.sh账号..."
    /root/.acme.sh/acme.sh --register-account -m "$USER_EMAIL"
    
    # 清理临时文件
    rm -f /tmp/acme-install.sh
    
    # 等待用户按键继续
    echo ""
    read -n 1 -p "按任意键继续..." dummy
    echo ""
}

# 配置acme信息
configure_acme_info() {
    log_info "配置acme.sh信息"
    
    # 检查Nginx是否已安装
    if ! which nginx &>/dev/null; then
        log_error "Nginx未安装，请先安装Nginx服务"
        return 1
    fi
    
    # 检查acme.sh是否已安装
    if [ ! -f "/root/.acme.sh/acme.sh" ]; then
        log_error "acme.sh未安装，请先安装acme服务"
        return 1
    fi
    
    # 创建配置目录
    mkdir -p /etc/nginx/ssl/acme-conf
    
    # 显示配置选项
    echo "请选择DNS API配置:"
    echo "1. Cloudflare DNS API"
    echo "2. 阿里云DNS API"
    echo "3. 腾讯云DNS API"
    echo "4. 配置默认参数"
    echo "0. 返回上级菜单"
    
    read -p "请选择 [0-4]: " config_option
    
    case $config_option in
        1)
            echo "配置Cloudflare DNS API:"
            read -p "请输入Cloudflare 全局API Key: " cf_key
            read -p "请输入Cloudflare 邮箱: " cf_email
            
            # 保存Cloudflare配置
            cat > /etc/nginx/ssl/acme-conf/cloudflare.conf << EOF
export CF_Key="$cf_key"
export CF_Email="$cf_email"
EOF
            chmod 600 /etc/nginx/ssl/acme-conf/cloudflare.conf
            log_success "Cloudflare DNS API配置已保存"
        ;;
        
        2)
            echo "配置阿里云DNS API:"
            read -p "请输入阿里云AccessKey ID: " ali_key
            read -p "请输入阿里云AccessKey Secret: " ali_secret
            
            # 保存阿里云配置
            cat > /etc/nginx/ssl/acme-conf/aliyun.conf << EOF
export Ali_Key="$ali_key"
export Ali_Secret="$ali_secret"
EOF
            chmod 600 /etc/nginx/ssl/acme-conf/aliyun.conf
            log_success "阿里云DNS API配置已保存"
        ;;
        
        3)
            echo "配置腾讯云DNS API:"
            read -p "请输入腾讯云SecretId: " tencent_id
            read -p "请输入腾讯云SecretKey: " tencent_key
            
            # 保存腾讯云配置
            cat > /etc/nginx/ssl/acme-conf/tencent.conf << EOF
export TENCENT_SecretId="$tencent_id"
export TENCENT_SecretKey="$tencent_key"
EOF
            chmod 600 /etc/nginx/ssl/acme-conf/tencent.conf
            log_success "腾讯云DNS API配置已保存"
        ;;
        
        4)
            echo "配置默认参数:"
            read -p "请输入默认邮箱: " default_email
            
            # 保存默认配置
            cat > /etc/nginx/ssl/acme-conf/default.conf << EOF
DEFAULT_EMAIL="$default_email"
EOF
            chmod 600 /etc/nginx/ssl/acme-conf/default.conf
            
            # 注册acme.sh账号
            /root/.acme.sh/acme.sh --register-account -m "$default_email"
            
            # 设置默认CA为Let's Encrypt
            /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
            
            log_success "默认参数已配置"
        ;;
        
        0)
            return 0
        ;;
        
        *)
            log_error "无效选项"
        ;;
    esac
    
    # 等待用户按键继续
    echo ""
    read -n 1 -p "按任意键继续..." dummy
    echo ""
    
    return 0
}

# 查看Nginx状态
check_nginx_status() {
    log_info "查看Nginx状态"
    
    # 检查Nginx是否已安装
    if ! which nginx &> /dev/null; then
        log_error "Nginx未安装，请先安装Nginx服务"
        return 1
    fi
    
    # 检查Nginx服务是否运行
    if ! systemctl is-active --quiet nginx; then
        log_error "Nginx服务未运行"
        echo "1. 启动Nginx服务"
        echo "2. 返回上一级菜单"
        echo -n "请选择 [1-2]: "
        read -n 1 nginx_choice
        echo ""
        
        case $nginx_choice in
            1)
                log_info "启动Nginx服务..."
                systemctl start nginx
                sleep 2
                # 再次检查服务状态
                if ! systemctl is-active --quiet nginx; then
                    log_error "无法启动Nginx服务，可能是配置文件有误"
                    return 1
                fi
            ;;
            2|*)
                return 0
            ;;
        esac
    fi
    
    # 显示Nginx状态
    echo -e "${BLUE}Nginx服务状态:${NC}"
    systemctl status nginx --no-pager
    
    # 显示Nginx配置
    echo -e "\n${BLUE}Nginx配置文件:${NC}"
    ls -la /etc/nginx/sites-enabled/
    ls -la /etc/nginx/conf.d/ 2>/dev/null || true
    
    # 显示证书信息
    if [ -d "/etc/nginx/ssl/certs" ] && [ "$(ls -A /etc/nginx/ssl/certs 2>/dev/null)" ]; then
        echo -e "\n${BLUE}已安装的证书:${NC}"
        ls -la /etc/nginx/ssl/certs
        
        # 检查证书的过期时间
        for cert in /etc/nginx/ssl/certs/*.pem; do
            if [ -f "$cert" ] && [[ "$cert" == *".pem" ]]; then
                echo -e "\n${BLUE}证书 $cert 信息:${NC}"
                openssl x509 -in "$cert" -noout -dates -issuer -subject 2>/dev/null || echo "无法读取证书信息"
            fi
        done
    else
        log_info "未找到已安装的证书"
    fi
    
    # 等待用户按键继续
    echo ""
    read -n 1 -p "按任意键继续..." dummy
    echo ""
    return 0
}

# 检查acme信息
check_acme_info() {
    log_info "检查acme信息"
    
    # 检查acme.sh是否已安装
    if [ ! -f "/root/.acme.sh/acme.sh" ]; then
        log_error "acme.sh未安装，请先安装acme服务"
        return 1
    fi
    
    echo "==== acme.sh账号信息 ===="
    /root/.acme.sh/acme.sh --info
    echo ""
    
    echo "==== DNS API配置状态 ===="
    if [ -f "/etc/nginx/ssl/acme-conf/cloudflare.conf" ]; then
        echo "Cloudflare DNS API: 已配置"
    else
        echo "Cloudflare DNS API: 未配置"
    fi
    
    if [ -f "/etc/nginx/ssl/acme-conf/aliyun.conf" ]; then
        echo "阿里云DNS API: 已配置"
    else
        echo "阿里云DNS API: 未配置"
    fi
    
    if [ -f "/etc/nginx/ssl/acme-conf/tencent.conf" ]; then
        echo "腾讯云DNS API: 已配置"
    else
        echo "腾讯云DNS API: 未配置"
    fi
    echo ""
    
    echo "==== 默认配置状态 ===="
    if [ -f "/etc/nginx/ssl/acme-conf/default.conf" ]; then
        echo "默认配置: 已配置"
        source /etc/nginx/ssl/acme-conf/default.conf
        echo "默认邮箱: $DEFAULT_EMAIL"
    else
        echo "默认配置: 未配置"
    fi
    echo ""
    
    echo "==== 已安装的证书 ===="
    /root/.acme.sh/acme.sh --list
    echo ""
    
    # 等待用户按键继续
    read -n 1 -p "按任意键继续..." dummy
    echo ""
    
    return 0
}

# 添加证书
add_certificate() {
    log_info "添加证书"
    
    # 检查Nginx是否已安装
    if ! which nginx &> /dev/null; then
        log_error "Nginx未安装，请先安装Nginx服务"
        return 1
    fi
    
    # 检查Nginx服务是否运行
    if ! systemctl is-active --quiet nginx; then
        log_error "Nginx服务未运行，请先启动Nginx服务"
        return 1
    fi
    
    # 检查acme.sh是否已安装
    if [ ! -f "/root/.acme.sh/acme.sh" ]; then
        log_error "acme.sh未安装，请先安装acme服务"
        return 1
    fi
    
    # 获取域名
    echo -n "请输入域名 (例如: example.com): "
    read DOMAIN
    if [ -z "$DOMAIN" ]; then
        log_error "域名不能为空"
        return 1
    fi
    
    # 选择验证方式
    echo ""
    echo "请选择证书验证方式:"
    echo "1. HTTP验证 (需要域名已正确解析到服务器IP)"
    echo "2. DNS验证 (通过DNS解析验证域名所有权)"
    echo "0. 取消"
    echo ""
    echo -n "请选择验证方式 [0-2]: "
    read -n 1 validation_choice
    echo ""
    
    case $validation_choice in
        1)
            # HTTP验证
            log_info "使用HTTP验证申请证书..."
            
            # 更新Nginx配置
            cat > /etc/nginx/conf.d/${DOMAIN}.conf << EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    # 用于acme.sh验证
    location /.well-known/acme-challenge/ {
        root /var/www/acme-challenge;
        try_files \$uri =404;
    }
}
EOF
            
            # 重载Nginx配置
            systemctl reload nginx
            
            # 验证DNS是否已解析
            echo -e "${YELLOW}提示: 确保域名 $DOMAIN 已正确解析到此服务器IP${NC}"
            echo -n "确认DNS已正确设置? [Y/n]: "
            read -n 1 dns_confirm
            echo ""
            if [[ "$dns_confirm" =~ ^[Nn]$ ]]; then
                log_info "请先设置DNS记录，然后再申请证书"
                return 1
            fi
            
            # 申请证书
            log_info "开始申请证书..."
            /root/.acme.sh/acme.sh --issue -d ${DOMAIN} -w /var/www/acme-challenge --force
            
            if [ $? -ne 0 ]; then
                log_error "证书申请失败，请检查错误信息"
                return 1
            fi
            
            # 安装证书到Nginx目录
            log_info "安装证书到Nginx..."
            mkdir -p /etc/nginx/ssl/certs
            /root/.acme.sh/acme.sh --install-cert -d ${DOMAIN} \
            --key-file       /etc/nginx/ssl/certs/${DOMAIN}_key.pem \
            --fullchain-file /etc/nginx/ssl/certs/${DOMAIN}_cert.pem \
            --reloadcmd     "systemctl reload nginx"
            
            if [ $? -ne 0 ]; then
                log_error "证书安装失败，请检查错误信息"
                return 1
            fi
            
            # 更新Nginx配置支持HTTPS
            log_info "配置Nginx支持HTTPS..."
            cat > /etc/nginx/conf.d/${DOMAIN}.conf << EOF
server {
    listen 80;
    server_name ${DOMAIN};

    # 重定向HTTP到HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }

    # 用于acme.sh验证
    location /.well-known/acme-challenge/ {
        root /var/www/acme-challenge;
        try_files \$uri =404;
    }
}

server {
    listen 443 ssl;
    server_name ${DOMAIN};

    ssl_certificate     /etc/nginx/ssl/certs/${DOMAIN}_cert.pem;
    ssl_certificate_key /etc/nginx/ssl/certs/${DOMAIN}_key.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
}
EOF
            
            # 重载Nginx配置
            systemctl reload nginx
            
            log_info "证书申请和安装成功!"
        ;;
        2)
            # DNS验证
            log_info "使用DNS验证申请证书..."
            
            # 检查是否有已配置的DNS提供商
            if [ ! -d "/etc/nginx/ssl/acme-conf" ] || [ ! "$(ls -A /etc/nginx/ssl/acme-conf 2>/dev/null)" ]; then
                log_error "未配置DNS提供商，请先配置acme信息"
                return 1
            fi
            
            echo "已配置的DNS提供商:"
            dns_providers=()
            dns_config_files=()
            index=1
            
            if [ -f "/etc/nginx/ssl/acme-conf/cloudflare.conf" ]; then
                echo "$index. Cloudflare"
                dns_providers[$index]="dns_cf"
                dns_config_files[$index]="cloudflare.conf"
                index=$((index+1))
            fi
            
            if [ -f "/etc/nginx/ssl/acme-conf/aliyun.conf" ]; then
                echo "$index. 阿里云DNS"
                dns_providers[$index]="dns_ali"
                dns_config_files[$index]="aliyun.conf"
                index=$((index+1))
            fi
            
            if [ -f "/etc/nginx/ssl/acme-conf/tencent.conf" ]; then
                echo "$index. 腾讯云DNS"
                dns_providers[$index]="dns_dp"
                dns_config_files[$index]="tencent.conf"
                index=$((index+1))
            fi
            
            if [ ${#dns_providers[@]} -eq 0 ]; then
                log_error "未找到已配置的DNS提供商"
                return 1
            fi
            
            echo -n "请选择DNS提供商 [1-$((index-1))]: "
            read dns_provider_choice
            
            if [[ ! "$dns_provider_choice" =~ ^[0-9]+$ ]] || [ "$dns_provider_choice" -lt 1 ] || [ "$dns_provider_choice" -ge "$index" ]; then
                log_error "无效选择"
                return 1
            fi
            
            DNS_PROVIDER="${dns_providers[$dns_provider_choice]}"
            DNS_CONFIG_FILE="${dns_config_files[$dns_provider_choice]}"
            
            # 加载DNS提供商配置
            log_info "加载DNS配置: ${DNS_CONFIG_FILE}"
            source "/etc/nginx/ssl/acme-conf/${DNS_CONFIG_FILE}"
            
            # 申请证书
            log_info "开始申请证书..."
            /root/.acme.sh/acme.sh --issue --dns ${DNS_PROVIDER} -d ${DOMAIN} --force
            
            if [ $? -ne 0 ]; then
                log_error "证书申请失败，请检查错误信息"
                return 1
            fi
            
            # 安装证书到Nginx目录
            log_info "安装证书到Nginx..."
            mkdir -p /etc/nginx/ssl/certs
            /root/.acme.sh/acme.sh --install-cert -d ${DOMAIN} \
            --key-file       /etc/nginx/ssl/certs/${DOMAIN}_key.pem \
            --fullchain-file /etc/nginx/ssl/certs/${DOMAIN}_cert.pem \
            --reloadcmd     "systemctl reload nginx"
            
            if [ $? -ne 0 ]; then
                log_error "证书安装失败，请检查错误信息"
                return 1
            fi
            
            # 更新Nginx配置支持HTTPS
            log_info "配置Nginx支持HTTPS..."
            cat > /etc/nginx/conf.d/${DOMAIN}.conf << EOF
server {
    listen 80;
    server_name ${DOMAIN};

    # 重定向HTTP到HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }

    # 用于acme.sh验证
    location /.well-known/acme-challenge/ {
        root /var/www/acme-challenge;
        try_files \$uri =404;
    }
}

server {
    listen 443 ssl;
    server_name ${DOMAIN};

    ssl_certificate     /etc/nginx/ssl/certs/${DOMAIN}_cert.pem;
    ssl_certificate_key /etc/nginx/ssl/certs/${DOMAIN}_key.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
}
EOF
            
            # 重载Nginx配置
            systemctl reload nginx
            
            log_info "证书申请和安装成功!"
        ;;
        0|*)
            log_info "取消添加证书"
        ;;
    esac
    
    # 等待用户按键继续
    echo ""
    read -n 1 -p "按任意键继续..." dummy
    echo ""
    return 0
}

# 证书管理子菜单
manage_certificates_submenu() {
    log_info "证书管理"
    
    # 检查Nginx是否已安装
    if ! which nginx &> /dev/null; then
        log_error "Nginx未安装，请先安装Nginx服务"
        return 1
    fi
    
    # 检查Nginx服务是否运行
    if ! systemctl is-active --quiet nginx; then
        log_error "Nginx服务未运行，请先启动Nginx服务"
        return 1
    fi
    
    # 检查acme.sh是否已安装
    if [ ! -f "/root/.acme.sh/acme.sh" ]; then
        log_error "acme.sh未安装，请先安装acme服务"
        return 1
    fi
    
    # 检查是否有证书
    if ! /root/.acme.sh/acme.sh --list | grep -q "Domain:"; then
        log_error "未找到任何证书，请先添加证书"
        return 1
    fi
    
    # 获取证书列表
    echo -e "${BLUE}已安装的证书:${NC}"
    CERT_LIST=$(/root/.acme.sh/acme.sh --list | grep "Main_Domain:" | awk '{print $2}')
    
    if [ -z "$CERT_LIST" ]; then
        log_error "未找到已安装的证书"
        return 1
    fi
    
    # 显示证书列表
    domains=()
    index=1
    
    for domain in $CERT_LIST; do
        domains[$index]="$domain"
        echo "$index. $domain"
        index=$((index+1))
    done
    
    echo "0. 返回上级菜单"
    echo -n "请选择要管理的证书 [0-$((index-1))]: "
    read cert_choice
    
    if [[ ! "$cert_choice" =~ ^[0-9]+$ ]] || [ "$cert_choice" -lt 0 ] || [ "$cert_choice" -ge "$index" ]; then
        log_error "无效选择"
        return 1
    fi
    
    if [ "$cert_choice" -eq 0 ]; then
        return 0
    fi
    
    SELECTED_DOMAIN="${domains[$cert_choice]}"
    
    # 显示证书管理选项
    echo ""
    echo "证书管理选项 ($SELECTED_DOMAIN):"
    echo "1. 查看证书信息"
    echo "2. 删除证书"
    echo "0. 返回"
    echo ""
    echo -n "请选择操作 [0-2]: "
    read -n 1 cert_manage_choice
    echo ""
    
    case $cert_manage_choice in
        1)
            # 查看证书信息
            log_info "查看证书信息: $SELECTED_DOMAIN"
            
            # 显示acme.sh中的证书信息
            echo -e "\n============= acme.sh 证书信息 =============\n"
            /root/.acme.sh/acme.sh --list --domain ${SELECTED_DOMAIN}
            
            # 显示证书详细信息
            if [ -f "/etc/nginx/ssl/certs/${SELECTED_DOMAIN}_cert.pem" ]; then
                echo -e "\n============= 证书详细信息 =============\n"
                openssl x509 -in "/etc/nginx/ssl/certs/${SELECTED_DOMAIN}_cert.pem" -noout -text
            else
                echo "证书文件不存在: /etc/nginx/ssl/certs/${SELECTED_DOMAIN}_cert.pem"
            fi
        ;;
        2)
            # 删除证书
            log_info "删除证书: $SELECTED_DOMAIN"
            
            echo -e "${YELLOW}警告: 删除证书将会移除HTTPS配置${NC}"
            echo -n "确认删除证书? [y/N]: "
            read -n 1 confirm
            echo ""
            
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                log_info "取消删除证书"
                return 0
            fi
            
            # 删除acme.sh中的证书
            log_info "从acme.sh中移除证书..."
            /root/.acme.sh/acme.sh --remove -d ${SELECTED_DOMAIN} --force
            
            # 删除Nginx中的证书文件
            log_info "删除Nginx证书文件..."
            rm -f "/etc/nginx/ssl/certs/${SELECTED_DOMAIN}_cert.pem"
            rm -f "/etc/nginx/ssl/certs/${SELECTED_DOMAIN}_key.pem"
            
            # 更新Nginx配置为HTTP
            log_info "更新Nginx配置为HTTP..."
            cat > "/etc/nginx/conf.d/${SELECTED_DOMAIN}.conf" << EOF
server {
    listen 80;
    server_name ${SELECTED_DOMAIN};

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    # 用于acme.sh验证
    location /.well-known/acme-challenge/ {
        root /var/www/acme-challenge;
        try_files \$uri =404;
    }
}
EOF
            
            # 重载Nginx配置
            systemctl reload nginx
            
            log_info "证书删除成功!"
        ;;
        0|*)
            # 返回
        ;;
    esac
    
    # 等待用户按键继续
    echo ""
    read -n 1 -p "按任意键继续..." dummy
    echo ""
    return 0
}

# 证书续签
renew_certificate() {
    log_info "证书续签"
    
    # 检查Nginx是否已安装
    if ! which nginx &> /dev/null; then
        log_error "Nginx未安装，请先安装Nginx服务"
        return 1
    fi
    
    # 检查Nginx服务是否运行
    if ! systemctl is-active --quiet nginx; then
        log_error "Nginx服务未运行，请先启动Nginx服务"
        return 1
    fi
    
    # 检查acme.sh是否已安装
    if [ ! -f "/root/.acme.sh/acme.sh" ]; then
        log_error "acme.sh未安装，请先安装acme服务"
        return 1
    fi
    
    # 检查是否有证书
    if ! /root/.acme.sh/acme.sh --list | grep -q "Domain:"; then
        log_error "未找到任何证书，请先添加证书"
        return 1
    fi
    
    # 显示所有证书
    echo -e "${BLUE}已申请的证书列表:${NC}"
    /root/.acme.sh/acme.sh --list
    
    # 加载DNS配置
    log_info "加载DNS配置..."
    for conf in /etc/nginx/ssl/acme-conf/*.conf; do
        if [ -f "$conf" ]; then
            log_info "加载配置: $conf"
            source "$conf"
        fi
    done
    
    # 执行自动续签
    log_info "执行自动续签..."
    export DEBUG=1
    /root/.acme.sh/acme.sh --cron --home /root/.acme.sh
    
    # 列出所有证书和状态
    echo -e "\n证书续签完成，当前证书状态:"
    /root/.acme.sh/acme.sh --list
    
    # 设置定时自动续签
    log_info "设置定时自动续签任务..."
    /root/.acme.sh/acme.sh --install-cronjob
    
    # 等待用户按键继续
    echo ""
    read -n 1 -p "按任意键继续..." dummy
    echo ""
    return 0
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