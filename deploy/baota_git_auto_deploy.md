# 宝塔面板 Git 自动部署指南

## 方法一：使用宝塔 WebHook（推荐）

### 第一步：安装宝塔 WebHook 插件

1. 宝塔面板 -> 【软件商店】
2. 搜索 **「宝塔WebHook」** 并安装

### 第二步：生成 SSH 密钥

```bash
# 生成 SSH 密钥（用于拉取私有仓库）
ssh-keygen -t rsa -C "your_email@example.com"
# 一路回车使用默认设置

# 查看公钥
cat ~/.ssh/id_rsa.pub
```

### 第三步：添加公钥到 GitHub/Gitee

**GitHub：**
1. 打开 https://github.com/settings/keys
2. 点击【New SSH key】
3. 粘贴公钥内容，保存

**Gitee：**
1. 打开 https://gitee.com/profile/sshkeys
2. 点击【添加公钥】
3. 粘贴公钥内容，保存

### 第四步：测试 Git 连接

```bash
# GitHub
ssh -T git@github.com

# Gitee
ssh -T git@gitee.com
```

### 第五步：创建 WebHook

1. 宝塔面板 -> 【软件商店】->【宝塔WebHook】->【设置】
2. 点击【添加】
3. 填写：
   - 名称：`daily-stock-analysis`
   - 脚本内容：

```bash
#!/bin/bash

# 项目路径
PROJECT_DIR="/www/wwwroot/daily-stock-analysis"
LOG_FILE="/var/log/git-deploy.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始部署" >> $LOG_FILE

# 进入项目目录
cd $PROJECT_DIR

# 拉取最新代码
git pull origin main >> $LOG_FILE 2>&1

# 激活虚拟环境
source venv/bin/activate

# 更新依赖
pip install -r requirements.txt -q -i https://pypi.tuna.tsinghua.edu.cn/simple

# 重启服务
supervisorctl restart daily-stock-analysis

echo "$(date '+%Y-%m-%d %H:%M:%S') - 部署完成" >> $LOG_FILE
```

4. 点击【提交】保存

### 第六步：获取 WebHook URL

添加成功后，点击【查看密钥】，获取类似这样的 URL：
```
http://你的服务器IP:8888/hook?access_key=xxxxxxxxxxxxxx
```

### 第七步：配置 GitHub/Gitee WebHook

**GitHub：**
1. 打开仓库 -> 【Settings】->【Webhooks】
2. 点击【Add webhook】
3. 填写：
   - Payload URL：`http://你的服务器IP:8888/hook?access_key=xxx`
   - Content type：`application/json`
   - Secret：留空
   - 触发事件：选择 `Just the push event`
4. 点击【Add webhook】

**Gitee：**
1. 打开仓库 -> 【管理】->【WebHooks】
2. 点击【添加 WebHook】
3. 填写：
   - URL：`http://你的服务器IP:8888/hook?access_key=xxx`
   - 密码：留空
   - 勾选：Push
4. 点击【添加】

---

## 方法二：使用定时任务拉取

### 配置计划任务

1. 宝塔面板 -> 【计划任务】
2. 添加任务：
   - 任务类型：Shell 脚本
   - 任务名称：`git-auto-pull`
   - 执行周期：每小时 或 自定义
   - 脚本内容：

```bash
#!/bin/bash

PROJECT_DIR="/www/wwwroot/daily-stock-analysis"
LOG_FILE="/var/log/git-deploy.log"

cd $PROJECT_DIR

# 检查是否有更新
git fetch origin
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ $LOCAL != $REMOTE ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 发现更新，开始部署" >> $LOG_FILE
    
    git pull origin main >> $LOG_FILE 2>&1
    
    source venv/bin/activate
    pip install -r requirements.txt -q -i https://pypi.tuna.tsinghua.edu.cn/simple
    supervisorctl restart daily-stock-analysis
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 部署完成" >> $LOG_FILE
fi
```

---

## 方法三：手动部署脚本

创建 `deploy.sh`：

```bash
#!/bin/bash
# 项目部署脚本

PROJECT_DIR="/www/wwwroot/daily-stock-analysis"
LOG_FILE="/var/log/git-deploy.log"

echo "=========================================="
echo "开始部署 Daily Stock Analysis"
echo "=========================================="

cd $PROJECT_DIR

echo "[1/4] 拉取最新代码..."
git pull origin main

echo "[2/4] 更新依赖..."
source venv/bin/activate
pip install -r requirements.txt -q -i https://pypi.tuna.tsinghua.edu.cn/simple

echo "[3/4] 重启服务..."
supervisorctl restart daily-stock-analysis

echo "[4/4] 检查状态..."
supervisorctl status daily-stock-analysis

echo ""
echo "部署完成！"
echo "日志文件: $LOG_FILE"
```

使用方式：
```bash
chmod +x deploy.sh
./deploy.sh
```

---

## 常见问题

### 1. 权限问题

```bash
# 给项目目录授权
chown -R www:www /www/wwwroot/daily-stock-analysis

# 给 git 目录授权
chmod -R 755 /www/wwwroot/daily-stock-analysis/.git
```

### 2. SSH 密钥问题

```bash
# 测试 SSH 连接
ssh -T git@github.com

# 如果失败，手动添加 known_hosts
ssh-keyscan github.com >> ~/.ssh/known_hosts
ssh-keyscan gitee.com >> ~/.ssh/known_hosts
```

### 3. 查看部署日志

```bash
# 查看实时日志
tail -f /var/log/git-deploy.log

# 查看 Supervisor 日志
tail -f /var/log/daily-stock-analysis.out.log
tail -f /var/log/daily-stock-analysis.err.log
```

### 4. 手动触发部署

```bash
# 通过 WebHook URL 手动触发
curl "http://你的服务器IP:8888/hook?access_key=xxx"
```

---

## 完整流程图

```
Git Push → GitHub/Gitee WebHook → 宝塔 WebHook 接收 → 执行部署脚本
                                                          ↓
                                                    git pull
                                                          ↓
                                                    pip install
                                                          ↓
                                                supervisorctl restart
                                                          ↓
                                                    服务更新完成
```
