# DLZ Docker管理工具

一个功能强大的Shell脚本，用于在Ubuntu和Debian系统上安装和管理Docker。

## 功能特点

- 自动检测系统类型和配置
- 提供简单直观的交互式菜单
- 支持Docker的安装、卸载和状态管理
- 提供Docker系统清理功能
- 彩色输出，提高可读性
- 良好的错误处理和用户反馈
- 高度模块化设计，易于扩展

## 系统要求

- Ubuntu或Debian系统
- root权限
- bash shell环境

## 安装方法

1. 下载脚本文件：

```bash
wget https://raw.githubusercontent.com/yourusername/dlz/main/dlz.sh
```

2. 赋予脚本执行权限：

```bash
chmod +x dlz.sh
```

## 使用方法

使用root权限运行脚本：

```bash
sudo ./dlz.sh
```

脚本将自动检测您的系统类型和配置，然后显示主菜单，您可以选择以下操作：

1. 安装Docker
2. 卸载Docker
3. 查看Docker状态
4. 清理Docker系统
0. 退出

## 功能说明

### 1. 安装Docker

选择此选项将执行完整的Docker安装流程：
- 安装必要的依赖包
- 添加Docker的GPG密钥
- 设置Docker APT仓库
- 安装Docker Engine
- 配置Docker服务自启动
- 将当前用户添加到docker组
- 验证安装

### 2. 卸载Docker

完全卸载Docker及其组件：
- 卸载Docker相关包
- 删除Docker数据目录
- 移除Docker仓库配置

### 3. 查看Docker状态

显示Docker的详细信息：
- Docker版本
- Docker服务状态
- Docker镜像列表
- 运行中的容器

### 4. 清理Docker系统

提供多种清理选项：
- 删除所有停止的容器
- 删除所有未使用的镜像
- 删除所有未使用的数据卷
- 删除所有未使用的网络
- 一键清理所有

## 扩展与定制

该脚本采用模块化设计，每个功能都被封装为独立的函数，您可以根据需要轻松添加或修改功能。

如果您需要添加新功能，只需创建相应的函数并在show_menu函数中添加菜单选项即可。

## 许可证

MIT

## 贡献

欢迎提交问题报告和改进建议。如需贡献代码，请提交拉取请求。 