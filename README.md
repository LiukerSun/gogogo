# WordPress Docker 快速部署

这是一个使用 Docker 快速部署 WordPress 独立站的项目，支持通过环境变量完全自定义配置。

## 系统要求

- Docker

## 快速开始

### 1. 构建镜像

```bash
docker build -t my-wordpress .
```

### 2. 运行容器

```bash
# 使用自定义配置
docker run -d \
  -p 8080:80 \
  -p 3306:3306 \
  -v wordpress_data:/var/www/html \
  -v mysql_data:/var/lib/mysql \
  -e WORDPRESS_DB_HOST=localhost \
  -e WORDPRESS_DB_NAME=mydb \
  -e WORDPRESS_DB_USER=myuser \
  -e WORDPRESS_DB_PASSWORD=mypassword \
  -e MYSQL_ROOT_PASSWORD=myrootpassword \
  -e WORDPRESS_ADMIN_USER=myadmin \
  -e WORDPRESS_ADMIN_PASSWORD=admin123 \
  -e WORDPRESS_ADMIN_EMAIL=admin@example.com \
  -e WORDPRESS_SITE_TITLE="我的网站" \
  my-wordpress
```

3. 访问 http://localhost:8080 使用您的 WordPress 站点

## 环境变量配置

### 必填配置
- `WORDPRESS_DB_HOST`: 数据库主机地址 (默认: `localhost`)
- `WORDPRESS_DB_NAME`: 数据库名称
- `WORDPRESS_DB_USER`: 数据库用户名
- `WORDPRESS_DB_PASSWORD`: 数据库密码
- `MYSQL_ROOT_PASSWORD`: MySQL root密码

### WordPress管理员配置
- `WORDPRESS_ADMIN_USER`: 管理员用户名
- `WORDPRESS_ADMIN_PASSWORD`: 管理员密码
- `WORDPRESS_ADMIN_EMAIL`: 管理员邮箱
- `WORDPRESS_SITE_TITLE`: 网站标题

## 默认功能

- 自动完成WordPress安装和配置
- 默认中文语言
- 预装主题: Twenty Twenty-Three

## 数据持久化

- WordPress数据: `/var/www/html` → `wordpress_data`卷
- MySQL数据: `/var/lib/mysql` → `mysql_data`卷

## 注意事项

- 所有环境变量必须通过`-e`参数传入
- 首次启动时会自动完成初始化
- 生产环境请修改默认密码

## 数据库访问

- MySQL 服务监听在 3306 端口
- 可以通过以下方式连接数据库：
  ```bash
  # 使用MySQL客户端连接
  mysql -h localhost -P 3306 -u wordpress -p
  ```
- 数据库连接信息：
  - 主机：localhost
  - 端口：3306
  - 用户名：由 WORDPRESS_DB_USER 环境变量指定
  - 密码：由 WORDPRESS_DB_PASSWORD 环境变量指定
  - 数据库名：由 WORDPRESS_DB_NAME 环境变量指定

## 停止服务

```bash
# 查找容器ID
docker ps

# 停止容器
docker stop <容器ID>

# 删除容器
docker rm <容器ID>
```

## 配置说明

- WordPress 默认运行在 8080 端口
- 数据库配置：
  - 数据库主机：localhost
  - 数据库名：由 WORDPRESS_DB_NAME 环境变量指定
  - 数据库用户：由 WORDPRESS_DB_USER 环境变量指定
  - 数据库密码：由 WORDPRESS_DB_PASSWORD 环境变量指定

## 数据持久化

- WordPress 数据存储在 `wordpress_data` 卷中
- MySQL 数据存储在 `mysql_data` 卷中

## 停止服务

```bash
docker-compose down
```

## 注意事项

- 首次启动时会自动完成 WordPress 的安装和配置
- 建议在生产环境中修改默认的密码
- 如需修改端口，请编辑 docker-compose.yml 文件中的 ports 配置 