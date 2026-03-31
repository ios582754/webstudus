#!/usr/bin/env python3
"""
FaaS 启动入口脚本
确保在正确的目录下启动 uvicorn 服务
"""
import os
import sys

# 确保工作目录正确
work_dir = os.environ.get('COZE_WORKSPACE_PATH', '/workspace/projects')
if os.path.exists(work_dir):
    os.chdir(work_dir)

# 添加项目路径到 Python path
if work_dir not in sys.path:
    sys.path.insert(0, work_dir)

# 启动 uvicorn
import uvicorn

if __name__ == "__main__":
    port = int(os.environ.get('DEPLOY_RUN_PORT', '5000'))
    uvicorn.run(
        "api.app:app",
        host="0.0.0.0",
        port=port,
        log_level="info"
    )
