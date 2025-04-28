FROM wordpress:latest

# 安装必要的工具
RUN apt-get update && apt-get install -y \
    curl \
    mysql-client \
    mysql-server \
    && rm -rf /var/lib/apt/lists/*

# 安装WordPress CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# 复制初始化脚本
COPY init-wordpress.sh /usr/local/bin/init-wordpress.sh
RUN chmod +x /usr/local/bin/init-wordpress.sh

# 复制MySQL初始化脚本
COPY init-mysql.sh /usr/local/bin/init-mysql.sh
RUN chmod +x /usr/local/bin/init-mysql.sh

# 修改入口点脚本
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 创建数据目录
RUN mkdir -p /var/lib/mysql /var/run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

# 设置必要的环境变量
ENV WORDPRESS_DB_HOST=localhost
ENV WORDPRESS_DB_NAME=
ENV WORDPRESS_DB_USER=
ENV WORDPRESS_DB_PASSWORD=
ENV MYSQL_ROOT_PASSWORD=
ENV WORDPRESS_ADMIN_USER=
ENV WORDPRESS_ADMIN_PASSWORD=
ENV WORDPRESS_ADMIN_EMAIL=
ENV WORDPRESS_SITE_TITLE=

# 暴露端口
EXPOSE 80 3306

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"] 