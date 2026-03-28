#!/bin/bash
# 启动 Web 服务

export WEBUI_HOST=0.0.0.0
export WEBUI_PORT=5000
export API_HOST=0.0.0.0
export API_PORT=5000
export CORS_ALLOW_ALL=true

exec python3 webui.py
