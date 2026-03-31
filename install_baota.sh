#!/bin/bash
# ===========================================
# 宝塔面板一键安装脚本
# ===========================================

# 配置变量
PROJECT_DIR="/www/wwwroot/daily-stock-analysis"
DOMAIN="your-domain.com"  # 改成你的域名

echo "=========================================="
echo "开始安装 Daily Stock Analysis"
echo "=========================================="

# 1. 创建项目目录
echo "[1/7] 创建项目目录..."
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# 2. 检查并克隆代码
if [ ! -f "main.py" ]; then
    echo "[2/7] 克隆代码..."
    git clone https://github.com/ZhuLinsen/daily_stock_analysis.git .
else
    echo "[2/7] 代码已存在，跳过克隆"
fi

# 3. 创建虚拟环境
echo "[3/7] 创建 Python 虚拟环境..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# 4. 激活虚拟环境并安装依赖
echo "[4/7] 安装依赖（可能需要几分钟）..."
source venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple -q

# 5. 创建环境变量文件
echo "[5/7] 配置环境变量..."
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo ""
    echo "⚠️  请编辑 .env 文件，填入你的 API Keys："
    echo "   nano $PROJECT_DIR/.env"
    echo ""
    echo "必需配置："
    echo "   DEEPSEEK_API_KEY=sk-xxx"
    echo "   TAVILY_API_KEYS=tvly-xxx"
fi

# 6. 创建 Supervisor 配置
echo "[6/7] 配置 Supervisor..."
cat > /etc/supervisor/conf.d/daily-stock-analysis.conf << 'EOF'
[program:daily-stock-analysis]
directory=/www/wwwroot/daily-stock-analysis
command=/www/wwwroot/daily-stock-analysis/venv/bin/python -m uvicorn api.app:app --host 127.0.0.1 --port 5000
autostart=true
autorestart=true
startsecs=3
stopwaitsecs=10
stderr_logfile=/var/log/daily-stock-analysis.err.log
stdout_logfile=/var/log/daily-stock-analysis.out.log
user=root
environment=PYTHONPATH="/www/wwwroot/daily-stock-analysis"
EOF

# 创建日志目录
mkdir -p /var/log
touch /var/log/daily-stock-analysis.err.log
touch /var/log/daily-stock-analysis.out.log

# 7. 创建 Nginx 配置
echo "[7/7] 配置 Nginx..."
cat > /www/server/panel/vhost/nginx/stock-api.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    
    client_max_body_size 50M;
}
EOF

echo ""
echo "=========================================="
echo "安装完成！"
echo "=========================================="
echo ""
echo "下一步操作："
echo ""
echo "1. 配置 API Keys："
echo "   nano /www/wwwroot/daily-stock-analysis/.env"
echo ""
echo "2. 启动服务："
echo "   supervisorctl reread"
echo "   supervisorctl update"
echo "   supervisorctl start daily-stock-analysis"
echo ""
echo "3. 重载 Nginx："
echo "   nginx -t && nginx -s reload"
echo ""
echo "4. 访问地址："
echo "   http://$DOMAIN/"
echo ""
