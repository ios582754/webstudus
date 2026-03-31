#!/bin/bash
# ===========================================
# 股票智能分析系统 - 宝塔一键安装脚本
# ===========================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=========================================="
echo "股票智能分析系统 - 一键安装脚本"
echo -e "==========================================${NC}"

# 配置变量
PROJECT_DIR="/www/wwwroot/daily-stock-analysis"
GIT_REPO="https://github.com/ios582754/webstudus.git"

# 检测系统类型
if [ -f /etc/redhat-release ]; then
    OS="centos"
    PKG_MANAGER="yum"
else
    OS="ubuntu"
    PKG_MANAGER="apt"
fi

echo -e "${YELLOW}检测到系统: $OS${NC}"

# 1. 安装系统依赖
echo -e "${GREEN}[1/6] 安装系统依赖...${NC}"
if [ "$OS" = "centos" ]; then
    yum install -y git python3 python3-pip wget unzip
else
    apt update
    apt install -y git python3 python3-pip python3-venv wget unzip
fi

# 2. 清理并克隆代码
echo -e "${GREEN}[2/6] 克隆代码...${NC}"
rm -rf $PROJECT_DIR
mkdir -p /www/wwwroot

cd /www/wwwroot

# 尝试克隆，失败则下载 ZIP
if git clone $GIT_REPO daily-stock-analysis 2>/dev/null; then
    echo -e "${GREEN}Git 克隆成功${NC}"
else
    echo -e "${YELLOW}Git 克隆失败，尝试下载 ZIP...${NC}"
    wget -O main.zip "https://ghproxy.com/https://github.com/ios582754/webstudus/archive/refs/heads/main.zip" || \
    wget -O main.zip "https://github.com/ios582754/webstudus/archive/refs/heads/main.zip"
    unzip -o main.zip
    mv webstudus-main daily-stock-analysis
    rm -f main.zip
fi

# 验证克隆成功
if [ ! -f "$PROJECT_DIR/requirements.txt" ]; then
    echo -e "${RED}错误: requirements.txt 文件不存在，克隆可能失败${NC}"
    exit 1
fi

echo -e "${GREEN}代码克隆成功${NC}"

# 3. 创建虚拟环境
echo -e "${GREEN}[3/6] 创建 Python 虚拟环境...${NC}"
cd $PROJECT_DIR
python3 -m venv venv
source venv/bin/activate

# 4. 安装 Python 依赖
echo -e "${GREEN}[4/6] 安装 Python 依赖（可能需要几分钟）...${NC}"
pip install --upgrade pip -q
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple -q

# 5. 创建配置文件
echo -e "${GREEN}[5/6] 创建配置文件...${NC}"
cat > .env << 'EOF'
# ===================================
# AI 模型配置（必需）
# ===================================
# DeepSeek API Key
DEEPSEEK_API_KEY=sk-dad0a23941d247169412403435bd2642

# ===================================
# 搜索引擎配置（必需）
# ===================================
# Tavily API Key（用于新闻搜索）
TAVILY_API_KEYS=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

# ===================================
# 股票列表配置
# ===================================
# 自选股列表（逗号分隔）
STOCK_LIST=600519,300750,002594

# ===================================
# Web 服务配置
# ===================================
WEBUI_HOST=127.0.0.1
WEBUI_PORT=5000

# ===================================
# 数据库配置
# ===================================
DATABASE_PATH=./data/stock_analysis.db

# ===================================
# 日志配置
# ===================================
LOG_DIR=./logs
LOG_LEVEL=INFO
EOF

echo -e "${GREEN}配置文件已创建: $PROJECT_DIR/.env${NC}"

# 6. 创建必要目录
echo -e "${GREEN}[6/6] 创建必要目录...${NC}"
mkdir -p data logs

# 7. 配置 Supervisor
echo -e "${GREEN}配置 Supervisor 进程守护...${NC}"
cat > /etc/supervisor/conf.d/daily-stock-analysis.conf << EOF
[program:daily-stock-analysis]
directory=$PROJECT_DIR
command=$PROJECT_DIR/venv/bin/python -m uvicorn api.app:app --host 127.0.0.1 --port 5000
autostart=true
autorestart=true
startsecs=3
stopwaitsecs=10
stderr_logfile=/var/log/daily-stock-analysis.err.log
stdout_logfile=/var/log/daily-stock-analysis.out.log
user=root
environment=PYTHONPATH="$PROJECT_DIR"
EOF

# 创建日志文件
touch /var/log/daily-stock-analysis.err.log
touch /var/log/daily-stock-analysis.out.log

# 重载 Supervisor
supervisorctl reread 2>/dev/null || true
supervisorctl update 2>/dev/null || true

# 8. 创建部署脚本
cat > $PROJECT_DIR/deploy.sh << 'DEPLOY_EOF'
#!/bin/bash
# 快速部署脚本
cd /www/wwwroot/daily-stock-analysis
git pull origin main
source venv/bin/activate
pip install -r requirements.txt -q -i https://pypi.tuna.tsinghua.edu.cn/simple
supervisorctl restart daily-stock-analysis
echo "部署完成！"
DEPLOY_EOF
chmod +x $PROJECT_DIR/deploy.sh

# 完成
echo ""
echo -e "${GREEN}=========================================="
echo "✅ 安装完成！"
echo -e "==========================================${NC}"
echo ""
echo "项目目录: $PROJECT_DIR"
echo ""
echo -e "${YELLOW}下一步操作：${NC}"
echo ""
echo "1. 启动服务："
echo "   supervisorctl start daily-stock-analysis"
echo ""
echo "2. 查看状态："
echo "   supervisorctl status daily-stock-analysis"
echo ""
echo "3. 查看日志："
echo "   tail -f /var/log/daily-stock-analysis.out.log"
echo ""
echo "4. 验证服务："
echo "   curl http://127.0.0.1:5000/api/health"
echo ""
echo "5. 配置 Nginx 反向代理："
echo "   宝塔面板 -> 网站 -> 添加站点 -> 设置 -> 反向代理"
echo "   目标URL: http://127.0.0.1:5000"
echo ""
echo "6. 修改配置（可选）："
echo "   nano $PROJECT_DIR/.env"
echo "   修改后重启: supervisorctl restart daily-stock-analysis"
echo ""
