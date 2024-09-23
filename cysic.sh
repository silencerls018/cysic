#!/bin/bash

# Cysic节点安装路径
CYSIC_PATH="$HOME/cysic-verifier"

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 安装必要的依赖
function install_dependencies() {
    apt update && apt upgrade -y
    apt install curl wget jq make gcc nano -y
}

# 安装 Node.js 和 npm
function install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js 已安装，版本: $(node -v)"
    else
        echo "Node.js 未安装，正在安装..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    if command -v npm > /dev/null 2>&1; then
        echo "npm 已安装，版本: $(npm -v)"
    else
        echo "npm 未安装，正在安装..."
        sudo apt-get install -y npm
    fi
}

# 安装 PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 已安装，版本: $(pm2 -v)"
    else
        echo "PM2 未安装，正在安装..."
        npm install pm2@latest -g
    fi
}

# 安装Cysic验证者节点
function install_cysic_node() {
    install_dependencies
    install_nodejs_and_npm
    install_pm2
    
    # 创建Cysic验证者目录
    rm -rf $CYSIC_PATH
    mkdir -p $CYSIC_PATH
    cd $CYSIC_PATH

    # 下载验证者程序
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -L https://cysic-verifiers.oss-accelerate.aliyuncs.com/verifier_linux > $CYSIC_PATH/verifier
        curl -L https://cysic-verifiers.oss-accelerate.aliyuncs.com/libzkp.so > $CYSIC_PATH/libzkp.so
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        curl -L https://cysic-verifiers.oss-accelerate.aliyuncs.com/verifier_mac > $CYSIC_PATH/verifier
        curl -L https://cysic-verifiers.oss-accelerate.aliyuncs.com/libzkp.dylib > $CYSIC_PATH/libzkp.dylib
    else
        echo "不支持的操作系统"
        exit 1
    fi

    # 设置权限
    chmod +x $CYSIC_PATH/verifier

    # 创建配置文件
    read -p "请输入您的奖励领取地址(ERC-20,ETH钱包地址): " CLAIM_REWARD_ADDRESS
    cat <<EOF > $CYSIC_PATH/config.yaml
chain:
  endpoint: "testnet-node-1.prover.xyz:9090"
  chain_id: "cysicmint_9000-1"
  gas_coin: "cysic"
  gas_price: 10
claim_reward_address: "$CLAIM_REWARD_ADDRESS"

server:
  cysic_endpoint: "https://api-testnet.prover.xyz"
EOF

    # 创建启动脚本
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    cat << EOF > $CYSIC_PATH/start.sh
#!/bin/bash
export LD_LIBRARY_PATH=.:~/miniconda3/lib:$LD_LIBRARY_PATH
export CHAIN_ID=534352
$CYSIC_PATH/verifier
EOF
elif [[ "$OSTYPE" == "darwin"* ]]; then
    cat << EOF > $CYSIC_PATH/start.sh
#!/bin/bash
export DYLD_LIBRARY_PATH=".:~/miniconda3/lib:$DYLD_LIBRARY_PATH"
export CHAIN_ID=534352
$CYSIC_PATH/verifier
EOF
fi
chmod +x $CYSIC_PATH/start.sh

# 切换到 Cysic 验证者目录
cd $CYSIC_PATH

# 使用PM2启动验证者节点
pm2 start $CYSIC_PATH/start.sh --name "cysic-verifier"

    echo "Cysic验证者节点已启动。您可以使用 'pm2 logs cysic-verifier' 查看日志。"
}

# 查看节点日志
function check_node() {
    pm2 logs cysic-verifier
}

# 停止节点
function stop_node() {
    pm2 stop cysic-verifier
    echo "节点已停止。"
}

# 运行节点
function run_node() {
    pm2 start $CYSIC_PATH/start.sh --name "cysic-verifier"
    echo "节点已运行。"
}

# 卸载节点
function uninstall_node() {
    pm2 delete cysic-verifier && rm -rf $CYSIC_PATH
    echo "Cysic验证者节点已删除。"
}

# 主菜单
function main_menu() {
    clear
    echo "脚本以及教程由推特用户大赌哥 @y95277777 编写，免费开源，请勿相信收费"
    echo "========================= Cysic 验证者节点安装 ======================================="
    echo "请选择要执行的操作:"
    echo "1. 安装 Cysic 验证者节点"
    echo "2. 查看节点日志"
    echo "3. 删除节点"
    echo "4. 停止节点"
    echo "5. 运行节点"
    read -p "请输入选项（1-5）: " OPTION
    case $OPTION in
    1) install_cysic_node ;;
    2) check_node ;;
    3) uninstall_node ;;
    4) stop_node ;;
    5) run_node ;;
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
