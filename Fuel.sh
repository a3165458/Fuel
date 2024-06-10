#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/Fuel.sh"

# 自动设置快捷键的功能
function check_and_set_alias() {
    local alias_name="fuel"
    local profile_file="$HOME/.profile"

    # 检查快捷键是否已经设置
    if ! grep -q "$alias_name" "$profile_file"; then
        echo "设置快捷键 '$alias_name' 到 $profile_file"
        echo "alias $alias_name='bash $SCRIPT_PATH'" >> "$profile_file"
        # 添加提醒用户激活快捷键的信息
        echo "快捷键 '$alias_name' 已设置。请运行 'source $profile_file' 来激活快捷键，或重新登录。"
    else
        # 如果快捷键已经设置，提供一个提示信息
        echo "快捷键 '$alias_name' 已经设置在 $profile_file。"
        echo "如果快捷键不起作用，请尝试运行 'source $profile_file' 或重新登录。"
    fi
}

function install_node() {

# 安装基本组件
sudo apt update
sudo apt install screen git -y

# 安装Rust
echo "正在安装Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# 安装Fuel服务
echo "正在安装Fuel服务..."
yes y | curl https://install.fuel.network | sh
sleep 5
source /root/.bashrc

# 生成P2P密钥
source /root/.bashrc
export PATH=$HOME/.fuelup/bin:$PATH
echo "正在生成P2P密钥..."
KEY_OUTPUT=$(fuel-core-keygen new --key-type peering)
echo "${KEY_OUTPUT}"
read -p "请从上方输出中复制'secret'值，并在此粘贴: " SECRET

# 克隆chain information
git clone https://github.com/FuelLabs/chain-configuration.git

# 用户输入节点名称和RPC地址
read -p "请输入您的ETH Sepolia RPC地址: " RPC

# 开始配置并运行节点
echo "开始配置并启动您的fuel节点..."

screen -dmS Fuel bash -c "source /root/.bashrc; fuel-core run \
--service-name=fuel-sepolia-testnet-node \
--keypair ${SECRET} \
--relayer ${RPC} \
--ip=0.0.0.0 --port=4000 --peering-port=30333 \
--db-path=~/.fuel-sepolia-testnet \
--snapshot ~/chain-configuration/ignition \
--utxo-validation --poa-instant false --enable-p2p \
--reserved-nodes /dns4/p2p-testnet.fuel.network/tcp/30333/p2p/16Uiu2HAmDxoChB7AheKNvCVpD4PHJwuDGn8rifMBEHmEynGHvHrf \
--sync-header-batch-size 100 \
--enable-relayer \
--relayer-v2-listening-contracts=0x01855B78C1f8868DE70e84507ec735983bf262dA \
--relayer-da-deploy-height=5827607 \
--relayer-log-page-size=500 \
--sync-block-stream-buffer-size 30
"

echo "节点配置完成并尝试启动。请使用screen -r Fuel 以确认节点状态。"

}

function check_service_status() {
    screen -r Fuel

}


# 主菜单
function main_menu() {
    clear
    echo "脚本以及教程由推特用户大赌哥 @y95277777 编写，免费开源，请勿相信收费"
    echo "================================================================"
    echo "节点社区 Telegram 群组:https://t.me/niuwuriji"
    echo "节点社区 Telegram 频道:https://t.me/niuwuriji"
    echo "请选择要执行的操作:"
    echo "1. 安装常规节点"
    echo "2. 查看节点日志"
    echo "3. 设置快捷键"
    
    read -p "请输入选项（1-3）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;  
    3)check_and_set_alias ;;
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
