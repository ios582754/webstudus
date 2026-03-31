#!/usr/bin/env python3
"""
FaaS 启动入口脚本
自动处理依赖缺失问题
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

def pip_install(package):
    """安装 Python 包"""
    try:
        subprocess.check_call([
            sys.executable, '-m', 'pip', 'install', 
            '--quiet', '--disable-pip-version-check', package
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        return False

def ensure_dependencies():
    """确保核心依赖已安装"""
    # 最小依赖集
    packages = [
        'fastapi',
        'uvicorn[standard]',
        'python-multipart',
        'python-dotenv',
    ]
    
    for pkg in packages:
        import_name = pkg.replace('[standard]', '').split('==')[0].split('>')[0].split('<')[0]
        try:
            __import__(import_name.replace('-', '_'))
        except ImportError:
            print(f"Installing {pkg}...")
            pip_install(pkg)

def main():
    # 确保核心依赖
    ensure_dependencies()
    
    # 导入并启动 uvicorn
    import uvicorn
    
    port = int(os.environ.get('DEPLOY_RUN_PORT', '5000'))
    host = os.environ.get('WEBUI_HOST', '0.0.0.0')
    
    print(f"Starting FastAPI server on {host}:{port}...")
    
    uvicorn.run(
        "api.app:app",
        host=host,
        port=port,
        log_level="info"
    )

if __name__ == "__main__":
    main()
