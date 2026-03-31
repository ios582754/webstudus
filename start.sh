#!/bin/bash
# FaaS 启动脚本

# 设置工作目录
cd "${COZE_WORKSPACE_PATH:-/workspace/projects}"

# 启动服务
exec python3 -m uvicorn api.app:app --host 0.0.0.0 --port "${DEPLOY_RUN_PORT:-5000}"
