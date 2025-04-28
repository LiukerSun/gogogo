#!/bin/bash
set -euo pipefail

# 启动MySQL服务并初始化
/usr/local/bin/init-mysql.sh

# 执行原始的WordPress入口点脚本
docker-entrypoint.sh apache2-foreground &

# 等待WordPress安装完成
until [ -f /var/www/html/wp-config.php ]; do
  echo "等待WordPress配置文件创建..."
  sleep 1
done

# 执行初始化脚本
/usr/local/bin/init-wordpress.sh

# 保持容器运行
wait 