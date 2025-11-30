#!/bin/bash

echo "--- 正在设置 Verilog 仿真与检查环境 (iverilog & verilator) ---"

# 1. 更新软件包列表
sudo apt-get update -y

# --- 安装 iverilog ---
# 2. 安装 iverilog
echo "--- 安装 iverilog ---"
sudo apt-get install -y iverilog

# 3. 检查 iverilog 安装
if command -v iverilog &> /dev/null
then
    echo "iverilog 安装成功，版本信息："
    iverilog -V
else
    echo "错误：iverilog 安装失败！"
    exit 1
fi

# --- 安装 Verilator ---
# 4. 安装 verilator (通常也是一个系统包)
echo "--- 安装 verilator ---"
sudo apt-get install -y verilator

# 5. 检查 verilator 安装
if command -v verilator &> /dev/null
then
    echo "verilator 安装成功，版本信息："
    # Verilator 的版本信息输出较多，通常只取第一行
    verilator --version | head -n 1
else
    echo "错误：verilator 安装失败！"
    exit 1
fi

echo "--- 所有环境设置完成 ---"

# 退出脚本并返回成功代码
exit 0
