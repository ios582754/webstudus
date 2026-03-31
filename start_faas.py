#!/usr/bin/env python3
"""
FaaS 启动入口脚本 - 极简版
仅安装最核心的依赖，快速启动服务
"""
import os
import sys
import subprocess

# 设置工作目录
work_dir = os.environ.get('COZE_WORKSPACE_PATH', '/workspace/projects')
if os.path.exists(work_dir):
    os.chdir(work_dir)
    if work_dir not in sys.path:
        sys.path.insert(0, work_dir)

def quick_install(package):
    """快速安装单个包"""
    try:
        subprocess.run(
            [sys.executable, '-m', 'pip', 'install', '-q', package],
            check=True,
            capture_output=True,
            timeout=30  # 30秒超时
        )
        return True
    except:
        return False

# 核心依赖 - 只安装启动服务必需的
CORE_PACKAGES = ['fastapi', 'uvicorn', 'python-multipart']

def ensure_core_deps():
    for pkg in CORE_PACKAGES:
        name = pkg.replace('-', '_')
        try:
            __import__(name)
        except ImportError:
            print(f"Installing {pkg}...")
            quick_install(pkg)

def main():
    ensure_core_deps()
    
    # 动态导入，避免启动时加载失败
    import uvicorn
    
    port = int(os.environ.get('DEPLOY_RUN_PORT', '5000'))
    
    uvicorn.run(
        "api.app:app",
        host="0.0.0.0",
        port=port,
        log_level="warning"  # 减少日志输出
    )

if __name__ == "__main__":
    main()
