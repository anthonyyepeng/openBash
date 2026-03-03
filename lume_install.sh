#!/bin/bash

# 遇到错误立即停止
set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' 

echo -e "${BLUE}🚀 开始配置 Lume 一键开发环境...${NC}"

# 1. 环境检查 (Homebrew & Lume)
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if ! command -v lume &> /dev/null; then
    brew install trycua/lume/lume
fi

# 2. 交互式获取参数 (修复管道下 read 失效问题)
echo -e "\n${BLUE}📝 请输入虚拟机配置信息:${NC}"
read -p "虚拟机名称 [默认: openclaw-dev]: " VM_NAME < /dev/tty
VM_NAME=${VM_NAME:-openclaw-dev}

read -p "登录用户名 [默认: admin]: " USER_NAME < /dev/tty
USER_NAME=${USER_NAME:-admin}

echo -n "设置虚拟机登录密码: "
# 强制从终端读取密码，并处理可能包含的特殊字符
read -s USER_PWD < /dev/tty
echo -e "\n"

# 3. 生成 JSON (修复引号冲突的关键点)
# 注意：password 这里直接引用变量，由于变量可能含空格，JSON 要求必须有双引号包裹
# 如果你之前输入的是 echo -e "n"，这里生成的 JSON 必须是 "echo -e \"n\""
cat <<EOF > .lume_temp_config.json
{
  "hostname": "$VM_NAME",
  "username": "$USER_NAME",
  "password": "$USER_PWD",
  "install_rosetta": true,
  "boot_wait": 10,
  "boot_commands": [],
  "commands": [
    "NONINTERACTIVE=1 /bin/bash -c \\"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\\\"",
    "eval \\"\$(/opt/homebrew/bin/brew shellenv)\\\"",
    "echo 'eval \\"\\\$(\/opt/homebrew\/bin\/brew shellenv)\\"' >> /Users/$USER_NAME/.zprofile",
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

# 4. 执行初始化
# 注意：如果之前报错说没有 create 命令，请确认版本，通常是 lume run
lume create "$VM_NAME" --os macos --ipsw latest --disk-size 80GB --memory 16GB --unattended .lume_temp_config.json

# 5. 清理
rm .lume_temp_config.json

echo -e "\n${GREEN}✨ 脚本执行完毕！${NC}"
