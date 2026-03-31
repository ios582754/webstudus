#!/bin/bash
# FaaS 启动脚本

# 设置工作目录
cd "${COZE_WORKSPACE_PATH:-/workspace/projects}"

# 在运行时安装依赖（FaaS 构建环境和运行环境分离）
# 使用最小化依赖加快启动速度
pip3 install -r requirements-minimal.txt --quiet 2>/dev/null || pip3 install -r requirements.txt --quiet

# 启动服务
exec python3 -m uvicorn api.app:app --host 0.0.0.0 --port "${DEPLOY_RUN_PORT:-5000}"
