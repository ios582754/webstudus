# 宝塔面板部署指南

## 一、服务器要求

- 内存：至少 2GB（推荐 4GB）
- 系统：Ubuntu 20.04+ / CentOS 7+
- Python 3.10+

## 二、安装宝塔面板（如未安装）

```bash
# Ubuntu
wget -O install.sh https://download.bt.cn/install/install-ubuntu_6.0.sh && sudo bash install.sh ed8484bec

# CentOS
yum install -y wget && wget -O install.sh http://download.bt.cn/install/install_6.0.sh && sh install.sh ed8484bec
```

## 三、环境准备

### 1. 在宝塔面板安装软件
- Python项目管理器 2.0
- Nginx

### 2. 创建 Python 项目

#### 方法一：使用 Python 项目管理器（推荐）

1. 进入【网站】->【Python项目】
2. 点击【添加Python项目】
3. 填写信息：
   - 项目名称：`daily-stock-analysis`
   - 项目路径：`/www/wwwroot/daily-stock-analysis`
   - Python版本：`3.12`
   - 框架：`FastAPI`
   - 启动方式：`uvicorn`
   - 启动文件：`api.app:app`
   - 端口：`5000`

4. 点击【提交】后，在项目目录执行：
```bash
cd /www/wwwroot/daily-stock-analysis
git clone https://github.com/ZhuLinsen/daily_stock_analysis.git .
pip install -r requirements.txt
```

#### 方法二：手动部署

```bash
# 1. 创建项目目录
mkdir -p /www/wwwroot/daily-stock-analysis
cd /www/wwwroot/daily-stock-analysis

# 2. 克隆代码
git clone https://github.com/ZhuLinsen/daily_stock_analysis.git .

# 3. 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 4. 安装依赖
pip install -r requirements.txt

# 5. 创建环境变量文件
cp .env.example .env
# 编辑 .env 文件，填入你的 API Keys
```

## 四、配置环境变量

编辑 `.env` 文件：

```bash
# AI 模型
DEEPSEEK_API_KEY=sk-dad0a23941d247169412403435bd2642

# 搜索引擎
TAVILY_API_KEYS=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

# 股票列表
STOCK_LIST=600519,300750,002594

# Web 配置
WEBUI_HOST=127.0.0.1
WEBUI_PORT=5000
```

## 五、配置进程守护

### 使用 Supervisor（宝塔自带）

1. 进入【软件商店】->【Supervisor】->【设置】
2. 点击【添加守护进程】
3. 填写信息：
   - 名称：`daily-stock-analysis`
   - 运行目录：`/www/wwwroot/daily-stock-analysis`
   - 启动命令：`/www/wwwroot/daily-stock-analysis/venv/bin/python -m uvicorn api.app:app --host 127.0.0.1 --port 5000`
   - 进程数量：`1`
   - 用户：`root`

### 或创建配置文件

```bash
cat > /etc/supervisor/conf.d/daily-stock-analysis.conf << 'EOF'
[program:daily-stock-analysis]
directory=/www/wwwroot/daily-stock-analysis
command=/www/wwwroot/daily-stock-analysis/venv/bin/python -m uvicorn api.app:app --host 127.0.0.1 --port 5000
autostart=true
autorestart=true
startsecs=3
stderr_logfile=/var/log/daily-stock-analysis.err.log
stdout_logfile=/var/log/daily-stock-analysis.out.log
user=root
environment=PYTHONPATH="/www/wwwroot/daily-stock-analysis"
EOF

supervisorctl reread
supervisorctl update
supervisorctl start daily-stock-analysis
```

## 六、配置 Nginx 反向代理

### 方法一：在宝塔面板配置

1. 进入【网站】->【添加站点】
2. 填写域名，PHP版本选择【纯静态】
3. 点击站点【设置】->【反向代理】->【添加反向代理】
4. 填写：
   - 代理名称：`stock-api`
   - 目标URL：`http://127.0.0.1:5000`
   - 发送域名：`$host`

### 方法二：手动配置 Nginx

```nginx
server {
    listen 80;
    server_name your-domain.com;  # 改成你的域名

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # 增大请求体大小（用于文件上传）
    client_max_body_size 50M;
}
```

重载 Nginx：
```bash
nginx -t && nginx -s reload
```

## 七、配置 SSL（可选）

在宝塔面板：
1. 进入站点【设置】->【SSL】
2. 选择【Let's Encrypt】
3. 申请免费证书
4. 开启【强制HTTPS】

## 八、验证部署

```bash
# 检查服务状态
curl http://127.0.0.1:5000/api/health

# 检查进程
ps aux | grep uvicorn

# 查看日志
tail -f /var/log/daily-stock-analysis.out.log
```

## 九、定时任务（可选）

如果需要定时分析股票：

1. 在宝塔面板【计划任务】
2. 添加任务：
   - 任务类型：Shell脚本
   - 执行周期：每天 18:00
   - 脚本内容：
   ```bash
   cd /www/wwwroot/daily-stock-analysis
   source venv/bin/activate
   python main.py
   ```

## 十、常见问题

### 1. 端口被占用
```bash
# 查看端口占用
lsof -i:5000
# 杀掉进程
kill -9 <PID>
```

### 2. 内存不足
```bash
# 添加交换空间
dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

### 3. 依赖安装失败
```bash
# 使用国内镜像
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

### 4. 启动报错
```bash
# 检查日志
tail -f /var/log/daily-stock-analysis.err.log

# 检查环境变量
cat .env

# 手动测试
cd /www/wwwroot/daily-stock-analysis
source venv/bin/activate
python -m uvicorn api.app:app --host 0.0.0.0 --port 5000
```

## 访问地址

- 前端界面：http://你的域名/
- API 文档：http://你的域名/docs
- 健康检查：http://你的域名/api/health
