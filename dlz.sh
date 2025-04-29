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
    echo -e "${GREEN}6.${NC} 查看独立站信息"
    echo -e "${GREEN}7.${NC} 证书配置与管理"
    echo -e "${GREEN}0.${NC} 退出"
    echo ""
    echo -n "请输入选项 [0-7]: "
    
    # 使用read -n 1获取单个字符并立即处理
    read -n 1 choice
    echo ""  # 添加换行，使输出更美观
    
    case $choice in
        1) install_docker_full ;;
        2) uninstall_docker ;;
        3) show_docker_status ;;
        4) clean_docker ;;
        5) install_wordpress ;;
        6) show_wordpress_info ;;
        7) manage_certificate ;;
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
    
    # 检查Nginx是否已安装
    if ! which nginx &> /dev/null; then
        log_info "Nginx未安装，开始安装Nginx..."
        apt-get update
        apt-get install -y nginx
        
        if [ $? -ne 0 ]; then
            log_error "Nginx安装失败"
            show_menu
            return
        fi
        
        # 创建Nginx配置目录
        mkdir -p /etc/nginx/conf.d
        mkdir -p /var/www/acme-challenge
        
        # 配置Nginx默认站点
        cat > /etc/nginx/conf.d/default.conf << EOF
server {
    listen 80;
    server_name _;

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
        
        # 启动Nginx服务
        systemctl start nginx
        systemctl enable nginx
        log_info "Nginx安装完成并已启动"
    fi
    
    # 检查acme.sh是否已安装
    if [ ! -f "/root/.acme.sh/acme.sh" ]; then
        log_info "acme.sh未安装，开始安装acme.sh..."
        
        # 安装依赖
        apt-get install -y curl socat
        
        # 获取用户邮箱并验证
        while true; do
            echo -n "请输入您的有效邮箱地址 (用于Let's Encrypt通知): "
            read USER_EMAIL
            
            # 验证邮箱格式
            if [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                log_error "邮箱格式无效，请输入正确的邮箱地址"
                continue
            fi
            
            # 验证邮箱域名
            EMAIL_DOMAIN=$(echo "$USER_EMAIL" | cut -d'@' -f2)
            if [[ "$EMAIL_DOMAIN" == "example.com" || "$EMAIL_DOMAIN" == "localhost" ]]; then
                log_error "不允许使用example.com或localhost作为邮箱域名"
                continue
            fi
            
            # 确认邮箱
            echo -n "确认使用邮箱 $USER_EMAIL? [Y/n]: "
            read -n 1 confirm
            echo ""
            
            if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
                break
            fi
        done
        
        # 获取Cloudflare API信息
        echo -e "${BLUE}配置Cloudflare API信息${NC}"
        echo "=================================="
        echo "您需要提供Cloudflare的API信息以进行DNS验证"
        echo "1. 登录Cloudflare控制台"
        echo "2. 进入'我的个人资料' -> 'API令牌'"
        echo "3. 创建新的API令牌，选择'编辑区域DNS'权限"
        echo ""
        
        while true; do
            echo -n "请输入Cloudflare API令牌: "
            read CF_API_TOKEN
            
            if [ -z "$CF_API_TOKEN" ]; then
                log_error "API令牌不能为空"
                continue
            fi
            
            # 验证API令牌格式
            if [[ ! "$CF_API_TOKEN" =~ ^[a-zA-Z0-9]{40}$ ]]; then
                log_error "API令牌格式无效，请检查是否正确"
                continue
            fi
            
            # 确认API令牌
            echo -n "确认使用此API令牌? [Y/n]: "
            read -n 1 confirm
            echo ""
            
            if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
                break
            fi
        done
        
        # 创建配置目录
        # 安装acme.sh
        log_info "正在安装acme.sh..."
        curl https://get.acme.sh | sh -s email=${USER_EMAIL}
        
        if [ $? -ne 0 ]; then
            log_error "acme.sh安装失败"
            show_menu
            return
        fi
        
        # 设置默认CA
        /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        
        # 设置自动更新
        /root/.acme.sh/acme.sh --upgrade --auto-upgrade
        
        log_info "acme.sh安装完成"
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
    
    echo -n "WordPress管理员邮箱: (默认: liukersun@gmail.com) "
    read WP_ADMIN_EMAIL
    WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL:-liukersun@gmail.com}
    
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
    
    # 创建wp-cli.yml配置文件
    log_info "创建wp-cli配置..."
    cat > wp-cli.yml << EOF
path: /var/www/html
url: https://${SITE_DOMAIN}
EOF
    
    # 创建WordPress配置脚本
    log_info "创建WordPress配置脚本..."
    cat > setup-wp.sh << 'EOF'
#!/bin/bash
cd /var/www/html

# 等待数据库准备就绪
echo "等待数据库准备就绪..."
until wp db check --allow-root 2>/dev/null; do
  echo "等待数据库连接..."
  sleep 2
done

# 检查WordPress是否已安装
echo "检查WordPress安装状态..."
if wp core is-installed --allow-root; then
  echo "WordPress已安装，更新配置..."
  # 更新站点信息
  wp option update blogname "$WP_TITLE" --allow-root || echo "更新站点标题失败"
  wp option update siteurl "https://${SITE_DOMAIN}" --allow-root || echo "更新站点URL失败"
  wp option update home "https://${SITE_DOMAIN}" --allow-root || echo "更新站点首页URL失败"

  # 配置SSL设置
  wp config set FORCE_SSL_ADMIN true --allow-root || echo "设置强制管理员SSL失败"
  wp config set FORCE_SSL_LOGIN true --allow-root || echo "设置强制登录SSL失败"
  wp config set WP_HOME "https://${SITE_DOMAIN}" --allow-root || echo "设置WP_HOME失败"
  wp config set WP_SITEURL "https://${SITE_DOMAIN}" --allow-root || echo "设置WP_SITEURL失败"
else
  # 安装WordPress核心
  echo "安装WordPress核心..."
  wp core install --url="https://${SITE_DOMAIN}" --title="$WP_TITLE" --admin_user="$WP_ADMIN" --admin_password="$WP_ADMIN_PASSWORD" --admin_email="$WP_ADMIN_EMAIL" --skip-email --allow-root || {
    echo "WordPress安装失败"
    exit 1
  }

  # 配置SSL设置
  wp config set FORCE_SSL_ADMIN true --allow-root || echo "设置强制管理员SSL失败"
  wp config set FORCE_SSL_LOGIN true --allow-root || echo "设置强制登录SSL失败"
  wp config set WP_HOME "https://${SITE_DOMAIN}" --allow-root || echo "设置WP_HOME失败"
  wp config set WP_SITEURL "https://${SITE_DOMAIN}" --allow-root || echo "设置WP_SITEURL失败"
fi

# 刷新重写规则
wp rewrite flush --allow-root
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
    
    # 配置Nginx反向代理
    log_info "配置Nginx反向代理..."
    
    # 创建Nginx配置文件
    cat > /etc/nginx/conf.d/${SITE_DOMAIN}.conf << EOF
server {
    listen 80;
    server_name ${SITE_DOMAIN};

    # 强制所有HTTP请求重定向到HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name ${SITE_DOMAIN};

    # SSL配置
    ssl_certificate ${CERT_DIR}/cert.pem;
    ssl_certificate_key ${CERT_DIR}/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;

    # HSTS设置
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    # 代理设置
    location / {
        proxy_pass http://localhost:${WP_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port 443;

        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # 缓冲区设置
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;

        # 启用WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # 修复WordPress重定向问题
        proxy_redirect http://\$host:${WP_PORT}/ https://\$host/;
        proxy_redirect https://\$host:${WP_PORT}/ https://\$host/;
    }

    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        proxy_pass http://localhost:${WP_PORT};
        proxy_set_header X-Forwarded-Proto https;
        proxy_cache_valid 200 302 60m;
        proxy_cache_valid 404 1m;
        proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504;
        proxy_cache_bypass \$http_pragma;
        proxy_cache_revalidate on;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    # 错误页面
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF
    
    # 测试Nginx配置
    if ! nginx -t; then
        log_error "Nginx配置测试失败，请检查配置文件"
        return
    fi
    
    # 重载Nginx配置
    systemctl reload nginx
    
    if [ $? -ne 0 ]; then
        log_error "Nginx重载失败，请检查错误信息"
        return
    fi
    
    log_info "SSL证书配置完成，现在可以通过 https://${SITE_DOMAIN} 访问您的网站"
    
    # 保存配置信息到文件
    {
        echo "# WordPress站点配置"
        echo "站点URL: http://${SITE_DOMAIN} 或 https://${SITE_DOMAIN} (如果已配置SSL)"
        echo "管理员面板: http://${SITE_DOMAIN}/wp-admin"
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
        echo "# Nginx配置"
        echo "配置文件: /etc/nginx/conf.d/${SITE_DOMAIN}.conf"
        if [ -f "/etc/nginx/ssl/${SITE_DOMAIN}/cert.pem" ]; then
            echo "SSL证书: /etc/nginx/ssl/${SITE_DOMAIN}/cert.pem"
            echo "SSL密钥: /etc/nginx/ssl/${SITE_DOMAIN}/key.pem"
        fi
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
        echo -e "${GREEN}1.${NC} acme信息管理"
        echo -e "${GREEN}2.${NC} 证书申请"
        echo -e "${GREEN}3.${NC} 证书管理"
        echo -e "${GREEN}4.${NC} 证书续签"
        echo -e "${GREEN}5.${NC} 为WordPress站点申请证书"
        echo -e "${GREEN}0.${NC} 返回主菜单"
        echo ""
        echo -n "请选择操作 [0-5]: "
        read -n 1 cert_choice
        echo ""
        
        case $cert_choice in
            1)
                manage_acme_info
                show_cert_menu
            ;;
            2)
                add_certificate
                show_cert_menu
            ;;
            3)
                manage_certificates_submenu
                show_cert_menu
            ;;
            4)
                renew_certificate
                show_cert_menu
            ;;
            5)
                add_wordpress_certificate
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

# 为WordPress站点申请证书
add_wordpress_certificate() {
    log_info "为WordPress站点申请证书"
    
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
    
    # 检查acme.sh账号是否已注册
    if [ ! -f "/root/.acme.sh/account.conf" ] || ! grep -q "ACCOUNT_EMAIL=" "/root/.acme.sh/account.conf"; then
        log_error "acme.sh账号未注册，请先配置acme信息"
        return 1
    fi
    
    # 检查Cloudflare配置是否存在
    if [ ! -f "/etc/nginx/ssl/acme-conf/cloudflare.conf" ]; then
        log_error "Cloudflare配置未找到，请先配置acme信息"
        return 1
    fi
    
    # 获取WordPress站点信息
    echo -e "${BLUE}请输入WordPress站点信息${NC}"
    echo "=================================="
    
    # 站点域名
    echo -n "站点域名 (例如: wordpress.liukersun.com): "
    read SITE_DOMAIN
    SITE_DOMAIN=${SITE_DOMAIN:-wordpress.liukersun.com}
    
    
    # WordPress端口
    echo -n "WordPress访问端口 (默认: 8080): "
    read WP_PORT
    WP_PORT=${WP_PORT:-8080}
    
    # 检查证书是否已存在且未过期
    CERT_DIR="/etc/nginx/ssl/${SITE_DOMAIN}"
    if [ -f "${CERT_DIR}/cert.pem" ] && [ -f "${CERT_DIR}/key.pem" ]; then
        log_info "检测到已存在的证书，跳过申请步骤"
        log_info "证书路径: ${CERT_DIR}"
    else
        # 验证域名解析
        log_info "验证域名解析..."
        if ! dig +short ${SITE_DOMAIN} | grep -q '^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$'; then
            log_error "域名 ${SITE_DOMAIN} 未正确解析到服务器IP"
            echo -n "是否继续申请证书? [y/N]: "
            read -n 1 continue_choice
            echo ""
            if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
                log_info "取消SSL证书申请"
                return
            fi
        fi
        
        # 显示申请证书的提示信息
        echo -e "${YELLOW}即将申请SSL证书，请确认以下信息：${NC}"
        echo "1. 域名: ${SITE_DOMAIN}"
        echo "2. 验证方式: DNS验证 (Cloudflare)"
        echo "3. 证书类型: Let's Encrypt ECC证书"
        echo "4. 证书有效期: 90天"
        echo ""
        echo -n "是否继续申请SSL证书? [Y/n]: "
        read -n 1 ssl_confirm
        echo ""
        
        if [[ "$ssl_confirm" =~ ^[Nn]$ ]]; then
            log_info "取消SSL证书申请"
            return
        fi
        
        # 使用acme.sh申请证书
        log_info "使用acme.sh申请证书..."
        
        # 加载Cloudflare配置
        if [ -f "/etc/nginx/ssl/acme-conf/cloudflare.conf" ]; then
            source /etc/nginx/ssl/acme-conf/cloudflare.conf
        else
            log_error "Cloudflare配置未找到，请先配置acme信息"
            return
        fi
        
        # 创建证书目录
        mkdir -p "${CERT_DIR}"
        
        # 申请证书
        /root/.acme.sh/acme.sh --issue --dns dns_cf -d "${SITE_DOMAIN}" -d "*.${SITE_DOMAIN}" --keylength ec-256
        
        if [ $? -ne 0 ]; then
            log_error "SSL证书申请失败，请检查以下可能的原因："
            echo "1. 域名未在Cloudflare上正确配置"
            echo "2. Cloudflare API令牌权限不足"
            echo "3. 域名解析未生效"
            echo "4. 网络连接问题"
            echo "5. acme.sh账号配置有误"
            return
        fi
        
        # 安装证书
        /root/.acme.sh/acme.sh --install-cert -d ${SITE_DOMAIN} \
        --key-file ${CERT_DIR}/key.pem \
        --fullchain-file ${CERT_DIR}/cert.pem \
        --reloadcmd "systemctl reload nginx"
        
        if [ $? -ne 0 ]; then
            log_error "证书安装失败，请检查错误信息"
            return
        fi
        
        # 设置证书权限
        chmod 600 "${CERT_DIR}/key.pem"
        chmod 644 "${CERT_DIR}/cert.pem"
    fi
    
    # 更新Nginx配置支持HTTPS
    log_info "配置Nginx支持HTTPS..."
    cat > /etc/nginx/conf.d/${SITE_DOMAIN}.conf << EOF
server {
    listen 80;
    server_name ${SITE_DOMAIN};

    # 强制所有HTTP请求重定向到HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name ${SITE_DOMAIN};

    # SSL配置
    ssl_certificate ${CERT_DIR}/cert.pem;
    ssl_certificate_key ${CERT_DIR}/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;

    # HSTS设置
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    # 代理设置
    location / {
        proxy_pass http://localhost:${WP_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port 443;

        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # 缓冲区设置
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;

        # 启用WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # 修复WordPress重定向问题
        proxy_redirect http://\$host:${WP_PORT}/ https://\$host/;
        proxy_redirect https://\$host:${WP_PORT}/ https://\$host/;
    }

    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        proxy_pass http://localhost:${WP_PORT};
        proxy_set_header X-Forwarded-Proto https;
        proxy_cache_valid 200 302 60m;
        proxy_cache_valid 404 1m;
        proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504;
        proxy_cache_bypass \$http_pragma;
        proxy_cache_revalidate on;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    # 错误页面
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF
    
    # 测试Nginx配置
    if ! nginx -t; then
        log_error "Nginx配置测试失败，请检查配置文件"
        return
    fi
    
    # 重载Nginx配置
    systemctl reload nginx
    
    if [ $? -ne 0 ]; then
        log_error "Nginx重载失败，请检查错误信息"
        return
    fi
    
    log_info "SSL证书配置完成，现在可以通过 https://${SITE_DOMAIN} 访问您的网站"
    
    # 等待用户按键继续
    echo ""
    read -n 1 -p "按任意键继续..." dummy
    echo ""
    
    return 0
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
    while true; do
        echo -n "请输入您的有效邮箱地址 (用于Let's Encrypt通知): "
        read USER_EMAIL
        
        # 验证邮箱格式
        if [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            log_error "邮箱格式无效，请输入正确的邮箱地址"
            continue
        fi
        
        # 验证邮箱域名
        EMAIL_DOMAIN=$(echo "$USER_EMAIL" | cut -d'@' -f2)
        if [[ "$EMAIL_DOMAIN" == "example.com" || "$EMAIL_DOMAIN" == "localhost" ]]; then
            log_error "不允许使用example.com或localhost作为邮箱域名"
            continue
        fi
        
        # 确认邮箱
        echo -n "确认使用邮箱 $USER_EMAIL? [Y/n]: "
        read -n 1 confirm
        echo ""
        
        if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
            break
        fi
    done
    
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
EOF
    
    chmod +x /tmp/acme-install.sh
    
    # 执行安装脚本
    log_info "开始安装acme.sh..."
    if bash /tmp/acme-install.sh; then
        log_info "acme.sh安装成功"
        
        # 保存账号信息
        echo "ACCOUNT_EMAIL=$USER_EMAIL" > /root/.acme.sh/account.conf
        echo "ACCOUNT_KEY_PATH=/root/.acme.sh/account.key" >> /root/.acme.sh/account.conf
        log_success "账号信息已保存"
    else
        log_error "acme.sh安装失败"
    fi
    
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
    
    # 获取有效邮箱地址的函数
    get_valid_email() {
        while true; do
            echo -n "请输入您的有效邮箱地址 (用于Let's Encrypt通知): "
            read USER_EMAIL
            
            # 验证邮箱格式
            if [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                log_error "邮箱格式无效，请输入正确的邮箱地址"
                continue
            fi
            
            # 验证邮箱域名
            EMAIL_DOMAIN=$(echo "$USER_EMAIL" | cut -d'@' -f2)
            if [[ "$EMAIL_DOMAIN" == "example.com" || "$EMAIL_DOMAIN" == "localhost" ]]; then
                log_error "不允许使用example.com或localhost作为邮箱域名"
                continue
            fi
            
            # 确认邮箱
            echo -n "确认使用邮箱 $USER_EMAIL? [Y/n]: "
            read -n 1 confirm
            echo ""
            
            if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
                break
            fi
        done
    }
    
    # 检查账号是否已注册
    if ! /root/.acme.sh/acme.sh --info | grep -q "Account Email:"; then
        log_info "未检测到acme.sh账号，需要注册新账号"
        get_valid_email
        
        # 注册acme.sh账号
        log_info "注册acme.sh账号..."
        /root/.acme.sh/acme.sh --register-account -m "$USER_EMAIL" --server letsencrypt
        
        if [ $? -ne 0 ]; then
            log_error "账号注册失败，请检查以下可能的原因："
            echo "1. 邮箱格式不正确"
            echo "2. 网络连接问题"
            echo "3. Let's Encrypt服务器暂时不可用"
            return 1
        fi
        
        # 保存账号信息
        echo "ACCOUNT_EMAIL=$USER_EMAIL" > /root/.acme.sh/account.conf
        echo "ACCOUNT_KEY_PATH=/root/.acme.sh/account.key" >> /root/.acme.sh/account.conf
        log_success "账号注册成功"
    else
        # 显示当前账号信息
        CURRENT_EMAIL=$(/root/.acme.sh/acme.sh --info | grep "Account Email:" | cut -d: -f2 | xargs)
        log_info "当前账号邮箱: $CURRENT_EMAIL"
        
        # 如果当前邮箱是example.com，强制更新
        if [[ "$CURRENT_EMAIL" == *"example.com"* ]]; then
            log_warn "检测到无效的邮箱地址，需要更新"
            get_valid_email
            NEW_EMAIL=$USER_EMAIL
        else
            # 询问是否修改账号
            echo -n "是否修改账号邮箱? [y/N]: "
            read -n 1 change_email
            echo ""
            
            if [[ "$change_email" =~ ^[Yy]$ ]]; then
                get_valid_email
                NEW_EMAIL=$USER_EMAIL
            else
                return 0
            fi
        fi
        
        # 更新账号
        log_info "更新acme.sh账号..."
        /root/.acme.sh/acme.sh --update-account --accountemail "$NEW_EMAIL" --server letsencrypt
        
        if [ $? -ne 0 ]; then
            log_error "账号更新失败"
            return 1
        fi
        
        # 更新配置文件
        sed -i "s/ACCOUNT_EMAIL=.*/ACCOUNT_EMAIL=$NEW_EMAIL/" /root/.acme.sh/account.conf
        log_success "账号更新成功"
    fi
    
    # 配置DNS提供商
    echo -e "${BLUE}选择DNS提供商:${NC}"
    echo "1. Cloudflare"
    echo "2. 阿里云"
    echo "3. 腾讯云"
    echo "0. 返回"
    echo -n "请选择 [0-3]: "
    read -n 1 dns_choice
    echo ""
    
    case $dns_choice in
        1)
            # Cloudflare配置
            echo -e "${BLUE}配置Cloudflare API信息${NC}"
            echo "=================================="
            echo "您需要提供Cloudflare的API信息以进行DNS验证"
            echo "1. 登录Cloudflare控制台"
            echo "2. 进入'我的个人资料' -> 'API令牌'"
            echo "3. 创建新的API令牌，选择'编辑区域DNS'权限"
            echo ""
            
            while true; do
                echo -n "请输入Cloudflare API令牌: "
                read CF_API_TOKEN
                
                if [ -z "$CF_API_TOKEN" ]; then
                    log_error "API令牌不能为空"
                    continue
                fi
                # 确认API令牌
                echo -n "确认使用此API令牌? [Y/n]: "
                read -n 1 confirm
                echo ""
                
                if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
                    break
                fi
            done
            
            # 保存Cloudflare配置
            cat > /etc/nginx/ssl/acme-conf/cloudflare.conf << EOF
export CF_Key="$CF_API_TOKEN"
export CF_Email="$USER_EMAIL"
EOF
            chmod 600 /etc/nginx/ssl/acme-conf/cloudflare.conf
            log_success "Cloudflare DNS API配置已保存"
        ;;
        2)
            # 阿里云配置
            echo -e "${BLUE}配置阿里云API信息${NC}"
            echo "=================================="
            echo "您需要提供阿里云的API信息以进行DNS验证"
            echo "1. 登录阿里云控制台"
            echo "2. 进入'AccessKey管理'"
            echo "3. 创建AccessKey"
            echo ""
            
            while true; do
                echo -n "请输入阿里云AccessKey ID: "
                read ALI_KEY
                echo -n "请输入阿里云AccessKey Secret: "
                read ALI_SECRET
                
                if [ -z "$ALI_KEY" ] || [ -z "$ALI_SECRET" ]; then
                    log_error "AccessKey不能为空"
                    continue
                fi
                
                # 确认AccessKey
                echo -n "确认使用此AccessKey? [Y/n]: "
                read -n 1 confirm
                echo ""
                
                if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
                    break
                fi
            done
            
            # 保存阿里云配置
            cat > /etc/nginx/ssl/acme-conf/aliyun.conf << EOF
export Ali_Key="$ALI_KEY"
export Ali_Secret="$ALI_SECRET"
EOF
            chmod 600 /etc/nginx/ssl/acme-conf/aliyun.conf
            log_success "阿里云DNS API配置已保存"
        ;;
        3)
            # 腾讯云配置
            echo -e "${BLUE}配置腾讯云API信息${NC}"
            echo "=================================="
            echo "您需要提供腾讯云的API信息以进行DNS验证"
            echo "1. 登录腾讯云控制台"
            echo "2. 进入'访问管理' -> 'API密钥管理'"
            echo "3. 创建API密钥"
            echo ""
            
            while true; do
                echo -n "请输入腾讯云SecretId: "
                read TXY_SECRETID
                echo -n "请输入腾讯云SecretKey: "
                read TXY_SECRETKEY
                
                if [ -z "$TXY_SECRETID" ] || [ -z "$TXY_SECRETKEY" ]; then
                    log_error "SecretId和SecretKey不能为空"
                    continue
                fi
                
                # 确认API信息
                echo -n "确认使用此API信息? [Y/n]: "
                read -n 1 confirm
                echo ""
                
                if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
                    break
                fi
            done
            
            # 保存腾讯云配置
            cat > /etc/nginx/ssl/acme-conf/tencent.conf << EOF
export TXY_SecretId="$TXY_SECRETID"
export TXY_SecretKey="$TXY_SECRETKEY"
EOF
            chmod 600 /etc/nginx/ssl/acme-conf/tencent.conf
            log_success "腾讯云DNS API配置已保存"
        ;;
        0)
            return 0
        ;;
        *)
            log_error "无效选项"
            return 1
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
    if ! which nginx &>/dev/null; then
        log_error "Nginx未安装，请先安装Nginx服务"
        return 1
    fi
    
    # 检查acme.sh是否已安装
    if [ ! -f "/root/.acme.sh/acme.sh" ]; then
        log_error "acme.sh未安装，请先安装acme服务"
        return 1
    fi
    
    # 检查acme.sh账号是否已注册
    if [ ! -f "/root/.acme.sh/account.conf" ] || ! grep -q "ACCOUNT_EMAIL=" "/root/.acme.sh/account.conf"; then
        log_error "acme.sh账号未注册，请先配置acme信息"
        return 1
    fi
    
    # 获取acme.sh账号信息
    ACME_EMAIL=$(grep "ACCOUNT_EMAIL=" /root/.acme.sh/account.conf | cut -d'=' -f2)
    if [[ "$ACME_EMAIL" == "example.com" || -z "$ACME_EMAIL" ]]; then
        log_error "acme.sh账号邮箱无效，请先修改acme信息"
        return 1
    fi
    
    # 检查Cloudflare配置是否存在
    if [ ! -f "/etc/nginx/ssl/acme-conf/cloudflare.conf" ]; then
        log_error "Cloudflare配置未找到，请先配置acme信息"
        return 1
    fi
    
    # 获取域名
    while true; do
        echo -n "请输入要申请证书的域名 (例如: example.com): "
        read DOMAIN
        
        # 验证域名格式
        if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9](\.[a-zA-Z]{2,})+$ ]]; then
            log_error "域名格式无效，请输入正确的域名"
            continue
        fi
        
        # 确认域名
        echo -n "确认使用域名 $DOMAIN? [Y/n]: "
        read -n 1 confirm
        echo ""
        
        if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
            break
        fi
    done
    
    # 创建证书目录
    mkdir -p "/etc/nginx/ssl/$DOMAIN"
    
    # 加载Cloudflare配置
    source /etc/nginx/ssl/acme-conf/cloudflare.conf
    
    # 显示验证信息
    echo -e "${BLUE}证书申请信息:${NC}"
    echo "域名: $DOMAIN"
    echo "验证方式: Cloudflare DNS验证"
    echo "证书类型: ECC证书 (ec-256)"
    echo "acme.sh账号: $ACME_EMAIL"
    echo ""
    echo -e "${YELLOW}注意:${NC}"
    echo "1. 请确保域名已在Cloudflare上正确配置"
    echo "2. 请确保Cloudflare API令牌具有足够的权限"
    echo "3. 验证过程可能需要几分钟时间"
    echo ""
    echo -n "确认开始申请证书? [Y/n]: "
    read -n 1 confirm
    echo ""
    
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        log_info "取消证书申请"
        return 0
    fi
    
    # 申请证书
    log_info "正在申请证书..."
    /root/.acme.sh/acme.sh --issue --dns dns_cf -d "$DOMAIN" -d "*.$DOMAIN" --keylength ec-256
    
    if [ $? -ne 0 ]; then
        log_error "证书申请失败，请检查以下可能的原因："
        echo "1. 域名未在Cloudflare上正确配置"
        echo "2. Cloudflare API令牌权限不足"
        echo "3. 域名解析未生效"
        echo "4. 网络连接问题"
        echo "5. acme.sh账号配置有误"
        return 1
    fi
    
    # 安装证书
    log_info "正在安装证书..."
    /root/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
    --key-file "/etc/nginx/ssl/$DOMAIN/key.pem" \
    --fullchain-file "/etc/nginx/ssl/$DOMAIN/cert.pem" \
    --reloadcmd "systemctl reload nginx"
    
    # 设置证书权限
    chmod 600 "/etc/nginx/ssl/$DOMAIN/key.pem"
    chmod 644 "/etc/nginx/ssl/$DOMAIN/cert.pem"
    
    # 更新Nginx配置支持HTTPS
    log_info "配置Nginx支持HTTPS..."
    cat > /etc/nginx/conf.d/${DOMAIN}.conf << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name ${DOMAIN};

    ssl_certificate /etc/nginx/ssl/${DOMAIN}/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/${DOMAIN}/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;

    location / {
        proxy_pass http://localhost:${WP_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # 增加超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # 修复重定向问题
        proxy_redirect http://\$host:${WP_PORT}/ https://\$host/;
        proxy_redirect https://\$host:${WP_PORT}/ https://\$host/;
    }
}
EOF
    
    # 测试Nginx配置
    if ! nginx -t; then
        log_error "Nginx配置测试失败，请检查配置文件"
        return 1
    fi
    
    # 重载Nginx配置
    systemctl reload nginx
    
    if [ $? -ne 0 ]; then
        log_error "Nginx重载失败，请检查错误信息"
        return 1
    fi
    
    log_success "证书已成功申请并安装"
    echo ""
    echo -e "${GREEN}证书信息:${NC}"
    echo "域名: $DOMAIN"
    echo "证书文件: /etc/nginx/ssl/$DOMAIN/cert.pem"
    echo "密钥文件: /etc/nginx/ssl/$DOMAIN/key.pem"
    echo "Nginx配置: /etc/nginx/conf.d/${DOMAIN}.conf"
    echo ""
    echo "您现在可以通过 https://${DOMAIN} 访问您的网站"
    echo "HTTP请求将自动重定向到HTTPS"
    
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

# 管理acme信息
manage_acme_info() {
    log_info "管理acme信息"
    
    # 检查acme.sh是否已安装
    if [ ! -f "/root/.acme.sh/acme.sh" ]; then
        log_error "acme.sh未安装，请先安装acme服务"
        return 1
    fi
    
    # 显示acme管理菜单
    show_acme_menu() {
        echo ""
        echo -e "${BLUE}========== acme信息管理 ==========${NC}"
        echo -e "${GREEN}1.${NC} 查看acme账号信息"
        echo -e "${GREEN}2.${NC} 修改acme账号邮箱"
        echo -e "${GREEN}3.${NC} 查看DNS API配置"
        echo -e "${GREEN}4.${NC} 修改Cloudflare API信息"
        echo -e "${GREEN}0.${NC} 返回上级菜单"
        echo ""
        echo -n "请选择操作 [0-4]: "
        read -n 1 acme_choice
        echo ""
        
        case $acme_choice in
            1)
                # 查看acme账号信息
                log_info "acme.sh账号信息:"
                /root/.acme.sh/acme.sh --info
            ;;
            2)
                # 修改acme账号邮箱
                while true; do
                    echo -n "请输入新的邮箱地址: "
                    read NEW_EMAIL
                    
                    # 验证邮箱格式
                    if [[ ! "$NEW_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                        log_error "邮箱格式无效，请输入正确的邮箱地址"
                        continue
                    fi
                    
                    # 验证邮箱域名
                    EMAIL_DOMAIN=$(echo "$NEW_EMAIL" | cut -d'@' -f2)
                    if [[ "$EMAIL_DOMAIN" == "example.com" || "$EMAIL_DOMAIN" == "localhost" ]]; then
                        log_error "不允许使用example.com或localhost作为邮箱域名"
                        continue
                    fi
                    
                    # 确认邮箱
                    echo -n "确认使用邮箱 $NEW_EMAIL? [Y/n]: "
                    read -n 1 confirm
                    echo ""
                    
                    if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
                        break
                    fi
                done
                
                # 更新acme.sh账号
                log_info "更新acme.sh账号..."
                /root/.acme.sh/acme.sh --update-account --accountemail "$NEW_EMAIL"
                
                # 更新Cloudflare配置中的邮箱
                if [ -f "/etc/nginx/ssl/acme-conf/cloudflare.conf" ]; then
                    sed -i "s/export CF_Email=.*/export CF_Email=\"$NEW_EMAIL\"/" /etc/nginx/ssl/acme-conf/cloudflare.conf
                    log_info "已更新Cloudflare配置中的邮箱"
                fi
                
                log_success "acme.sh账号邮箱已更新"
            ;;
            3)
                # 查看DNS API配置
                log_info "DNS API配置状态:"
                if [ -f "/etc/nginx/ssl/acme-conf/cloudflare.conf" ]; then
                    echo "Cloudflare DNS API: 已配置"
                    echo "配置内容:"
                    cat /etc/nginx/ssl/acme-conf/cloudflare.conf
                else
                    echo "Cloudflare DNS API: 未配置"
                fi
            ;;
            4)
                # 修改Cloudflare API信息
                if [ ! -f "/etc/nginx/ssl/acme-conf/cloudflare.conf" ]; then
                    log_error "Cloudflare配置未找到，请先配置acme信息"
                    return 1
                fi
                
                # 获取当前配置
                source /etc/nginx/ssl/acme-conf/cloudflare.conf
                
                echo -e "${BLUE}当前Cloudflare配置:${NC}"
                echo "邮箱: $CF_Email"
                echo "API令牌: ${CF_Key:0:4}...${CF_Key: -4}"
                
                while true; do
                    echo -n "请输入新的Cloudflare API令牌: "
                    read NEW_CF_TOKEN
                    
                    if [ -z "$NEW_CF_TOKEN" ]; then
                        log_error "API令牌不能为空"
                        continue
                    fi
                    
                    # 验证API令牌格式
                    if [[ ! "$NEW_CF_TOKEN" =~ ^[a-zA-Z0-9]{40}$ ]]; then
                        log_error "API令牌格式无效，请检查是否正确"
                        continue
                    fi
                    
                    # 确认API令牌
                    echo -n "确认使用此API令牌? [Y/n]: "
                    read -n 1 confirm
                    echo ""
                    
                    if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
                        break
                    fi
                done
                
                # 更新Cloudflare配置
                cat > /etc/nginx/ssl/acme-conf/cloudflare.conf << EOF
export CF_Key="$NEW_CF_TOKEN"
export CF_Email="$CF_Email"
EOF
                chmod 600 /etc/nginx/ssl/acme-conf/cloudflare.conf
                log_success "Cloudflare API信息已更新"
            ;;
            0)
                return 0
            ;;
            *)
                log_error "无效选项，请重新选择"
            ;;
        esac
        
        # 等待用户按键继续
        echo ""
        read -n 1 -p "按任意键继续..." dummy
        echo ""
        
        # 返回菜单
        show_acme_menu
    }
    
    # 显示acme管理菜单
    show_acme_menu
    
    return 0
}

# 查看WordPress独立站信息
show_wordpress_info() {
    log_step "查看WordPress独立站信息"
    
    # 检查WordPress目录是否存在
    if [ ! -d "./wordpress_site" ]; then
        log_error "未找到WordPress站点目录"
        show_menu
        return
    fi
    
    # 检查site_info.txt文件是否存在
    if [ ! -f "./wordpress_site/site_info.txt" ]; then
        log_error "未找到站点信息文件"
        show_menu
        return
    fi
    
    # 显示站点信息
    echo -e "${BLUE}========== WordPress站点信息 ==========${NC}"
    cat ./wordpress_site/site_info.txt
    
    # 检查Docker容器状态
    echo -e "\n${BLUE}========== Docker容器状态 ==========${NC}"
    cd ./wordpress_site
    docker-compose ps
    cd ..
    
    # 检查Nginx配置
    echo -e "\n${BLUE}========== Nginx配置状态 ==========${NC}"
    if [ -f "/etc/nginx/conf.d/$(grep "站点URL:" ./wordpress_site/site_info.txt | cut -d' ' -f2 | cut -d'/' -f3).conf" ]; then
        echo "Nginx配置文件存在"
        nginx -t
    else
        echo "未找到Nginx配置文件"
    fi
    
    # 检查SSL证书状态
    echo -e "\n${BLUE}========== SSL证书状态 ==========${NC}"
    DOMAIN=$(grep "站点URL:" ./wordpress_site/site_info.txt | cut -d' ' -f2 | cut -d'/' -f3)
    if [ -f "/etc/nginx/ssl/${DOMAIN}/cert.pem" ]; then
        echo "SSL证书已安装"
        echo "证书路径: /etc/nginx/ssl/${DOMAIN}/cert.pem"
        echo "密钥路径: /etc/nginx/ssl/${DOMAIN}/key.pem"
        echo "证书信息:"
        openssl x509 -in "/etc/nginx/ssl/${DOMAIN}/cert.pem" -noout -dates
    else
        echo "未找到SSL证书"
    fi
    
    # 等待用户按键继续
    echo ""
    read -n 1 -p "按任意键继续..." dummy
    echo ""
    
    show_menu
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