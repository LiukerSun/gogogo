#!/bin/bash

# 等待MySQL服务启动
until mysql -h localhost -u "${WORDPRESS_DB_USER}" -p"${WORDPRESS_DB_PASSWORD}" -e 'select 1'; do
    echo "等待MySQL服务启动..."
    sleep 1
done

# 等待WordPress安装目录创建
until [ -f /var/www/html/wp-config.php ]; do
    echo "等待WordPress配置文件创建..."
    sleep 1
done

# 设置WordPress管理员账户
wp core install --path=/var/www/html --url=http://localhost:8080 \
--title="${WORDPRESS_SITE_TITLE}" \
--admin_user="${WORDPRESS_ADMIN_USER}" \
--admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
--admin_email="${WORDPRESS_ADMIN_EMAIL}" \
--skip-email

# 设置站点语言为中文
wp language core install zh_CN --path=/var/www/html
wp language core activate zh_CN --path=/var/www/html

# 设置默认主题
wp theme install twentytwentythree --activate --path=/var/www/html

echo "WordPress初始化完成！"