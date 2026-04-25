#!/bin/bash
# Hermes Railway 一键部署脚本

echo "🚀 Hermes Railway 部署脚本"
echo "=========================="

# 检查是否已登录
echo "1. 检查 Railway 登录状态..."
npx @railway/cli whoami 2>/dev/null || {
    echo "请先登录 Railway:"
    echo "npx @railway/cli login"
    exit 1
}

# 初始化项目
echo "2. 初始化 Railway 项目..."
npx @railway/cli init

# 部署
echo "3. 开始部署..."
npx @railway/cli up

# 提示配置环境变量
echo ""
echo "✅ 部署完成！"
echo ""
echo "⚠️  重要：请配置环境变量"
echo "   npx @railway/cli variables set OPENAI_API_KEY=sk-your-key"
echo ""
echo "🌐 获取访问链接:"
echo "   npx @railway/cli domain"
