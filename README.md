# DLZ Docker管理工具

一个用于Ubuntu和Debian系统的Docker管理工具，提供Docker安装、管理和WordPress部署功能。

## 功能特点

- Docker全生命周期管理
  - 一键安装Docker
  - Docker状态监控
  - Docker系统清理
  - Docker卸载
- WordPress独立站部署
  - 基于Docker Compose
  - 自动配置MySQL数据库
  - 支持自定义管理员账户
  - 自动安装WooCommerce插件

## 系统要求

- Ubuntu 18.04或更高版本
- Debian 9或更高版本
- 至少2GB内存
- 至少20GB磁盘空间

## 使用方法

1. 下载脚本：
```bash
wget https://raw.githubusercontent.com/yourusername/dlz/master/dlz.sh
```

2. 添加执行权限：
```bash
chmod +x dlz.sh
```

3. 运行脚本：
```bash
sudo ./dlz.sh
```

## 菜单选项

1. 安装Docker
   - 自动检测系统环境
   - 安装最新版Docker
   - 配置Docker服务自启动

2. 卸载Docker
   - 完全移除Docker
   - 清理相关配置文件

3. 查看Docker状态
   - 显示Docker版本
   - 显示运行中的容器
   - 显示Docker镜像列表

4. 清理Docker系统
   - 删除未使用的镜像
   - 清理停止的容器
   - 清理未使用的数据卷
   - 清理未使用的网络

5. 安装WordPress独立站
   - 配置MySQL数据库
   - 安装WordPress
   - 自动安装WooCommerce
   - 生成站点信息文件

## 注意事项

- 运行脚本需要root权限
- 安装WordPress前请确保系统有足够资源
- 建议在干净的系统中使用

## 许可证

MIT License 