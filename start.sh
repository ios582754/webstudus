#!/bin/bash
# FaaS 启动脚本

# 设置工作目录
cd "${COZE_WORKSPACE_PATH:-/workspace/projects}"

# 设置 Python 路径
export PYTHONPATH="${COZE_WORKSPACE_PATH:-/workspace/projects}:${PYTHONPATH}"

# 启动服务（使用 Python 脚本处理依赖）
exec python3 start_faas.py
