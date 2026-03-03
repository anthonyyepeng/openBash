#!/bin/bash
###
 # @Author: yepeng.anthony
 # @Date: 2026-03-03 15:55:15
 # @LastEditTime: 2026-03-03 16:53:36
 # @Description: file content
###

# 遇到错误立即停止
set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

echo -e "${BLUE}🚀 开始配置 Lume 一键开发环境...${NC}"

# 1. 检查并安装宿主机 Homebrew
if ! command -v brew &> /dev/null; then
    echo "📦 正在安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo -e "${GREEN}✅ Homebrew 已安装${NC}"
fi

# 2. 检查并安装宿主机 Lume
if ! command -v lume &> /dev/null; then
    echo "💻 正在安装 Lume..."
    brew install trycua/lume/lume
else
    echo -e "${GREEN}✅ Lume 已安装${NC}"
fi

# 3. 交互式获取参数
echo -e "\n${BLUE}📝 请输入虚拟机配置信息:${NC}"
read -p "虚拟机名称 [默认: openclaw-dev]: " VM_NAME
VM_NAME=${VM_NAME:-openclaw-dev}

read -p "登录用户名 [默认: admin]: " USER_NAME
USER_NAME=${USER_NAME:-admin}

read -s -p "设置虚拟机登录密码: " USER_PWD

# 4. 生成临时的自动化配置文件
# 包含：Brew, NVM(Node LTS), PNPM, Python 3.11, OpenClaw 别名
cat <<EOF > .lume_temp_config.json
{
  "hostname": "$VM_NAME",
  "username": "$USER_NAME",
  "password": "$USER_PWD",
  "install_rosetta": true,
  "boot_wait": 10,
  "boot_commands": [],
  "commands": [
    "NONINTERACTIVE=1 /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"",
    "eval \"\$(/opt/homebrew/bin/brew shellenv)\"",
    "echo 'eval \"\$(/opt/homebrew/bin/brew shellenv)\"' >> /Users/$USER_NAME/.zprofile",
    "mkdir -p /Users/$USER_NAME/.nvm",
    "brew install nvm pnpm yarn git python@3.11",
    "echo 'export NVM_DIR=\"\$HOME/.nvm\"' >> /Users/$USER_NAME/.zshrc",
    "echo '[ -s \"/opt/homebrew/opt/nvm/nvm.sh\" ] && . \"/opt/homebrew/opt/nvm/nvm.sh\"' >> /Users/$USER_NAME/.zshrc",
    "echo '[ -s \"/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm\" ] && . \"/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm\"' >> /Users/$USER_NAME/.zshrc",
    "echo 'alias python=/opt/homebrew/bin/python3.11' >> /Users/$USER_NAME/.zprofile",
    "echo 'alias pip=/opt/homebrew/bin/pip3.11' >> /Users/$USER_NAME/.zprofile",
    "export NVM_DIR=\"/Users/$USER_NAME/.nvm\" && [ -s \"/opt/homebrew/opt/nvm/nvm.sh\" ] && . \"/opt/homebrew/opt/nvm/nvm.sh\" && nvm install --lts && nvm use --lts && nvm alias default 'lts/*'"
  ]
}
EOF

# 5. 执行初始化
echo -e "${BLUE}🛠 正在初始化虚拟机 (下载依赖可能耗时较长)...${NC}"
lume create "$VM_NAME" --os macos --ipsw latest --disk-size 80GB --memory 16GB --unattended .lume_temp_config.json

# 6. 清理现场
rm .lume_temp_config.json

# echo -e "\n${GREEN}✨ 全部安装完成！${NC}"
# echo -e "👉 启动虚拟机并挂载代码目录:"
# echo -e "${BLUE}lume run $VM_NAME --shared-dir /Users/$(whoami)/YourCodePath${NC}\n"
