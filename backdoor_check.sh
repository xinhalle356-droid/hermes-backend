#!/bin/bash
# 后门检查脚本
# 使用方法: chmod +x backdoor_check.sh && ./backdoor_check.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "     🔍 后门安全检查脚本"
echo "     检查时间: $(date)"
echo "=========================================="
echo ""

# 1. 检查 SSH 后门
echo "🔐 1. 检查 SSH 后门..."
if [ -f ~/.ssh/authorized_keys ]; then
    KEY_COUNT=$(wc -l < ~/.ssh/authorized_keys)
    if [ "$KEY_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  发现 ${KEY_COUNT} 个 SSH 公钥:${NC}"
        cat ~/.ssh/authorized_keys
        echo ""
        echo "请确认以上公钥是否为你自己添加的！"
    else
        echo -e "${GREEN}✅ authorized_keys 为空${NC}"
    fi
else
    echo -e "${GREEN}✅ 没有 authorized_keys 文件${NC}"
fi

if [ -f ~/.ssh/config ]; then
    echo -e "${YELLOW}⚠️  发现 SSH config 文件，请检查:${NC}"
    cat ~/.ssh/config
fi
echo ""

# 2. 检查启动项
echo "🚀 2. 检查启动项..."
echo "用户级启动项:"
ls ~/Library/LaunchAgents/ 2>/dev/null | grep -v "^com\.apple" || echo -e "${GREEN}✅ 无异常${NC}"
echo ""

echo "系统级启动项 (需要 sudo):"
ls /Library/LaunchAgents/ 2>/dev/null | grep -v "^com\.apple" || echo -e "${GREEN}✅ 无异常${NC}"
ls /Library/LaunchDaemons/ 2>/dev/null | grep -v "^com\.apple" || echo -e "${GREEN}✅ 无异常${NC}"
echo ""

# 3. 检查 Cron 任务
echo "⏰ 3. 检查 Cron 任务..."
CRON=$(crontab -l 2>/dev/null)
if [ -n "$CRON" ]; then
    echo -e "${YELLOW}⚠️  发现 Cron 任务:${NC}"
    echo "$CRON"
else
    echo -e "${GREEN}✅ 没有用户 Cron 任务${NC}"
fi
echo ""

# 4. 检查 Shell 配置文件
echo "🐚 4. 检查 Shell 配置文件..."
SUSPICIOUS_PATTERNS="curl|wget|nc |nc\t|bash -i|/dev/tcp|python.*-c|perl.*-e|ruby.*-e"

for file in ~/.bashrc ~/.bash_profile ~/.zshrc ~/.zprofile; do
    if [ -f "$file" ]; then
        MATCHES=$(grep -E "$SUSPICIOUS_PATTERNS" "$file" 2>/dev/null)
        if [ -n "$MATCHES" ]; then
            echo -e "${RED}🚨 ${file} 中发现可疑内容:${NC}"
            echo "$MATCHES"
            echo ""
        fi
    fi
done
echo -e "${GREEN}✅ Shell 配置文件检查完成${NC}"
echo ""

# 5. 检查系统命令是否被替换
echo "🔧 5. 检查系统命令完整性..."
if [ -f /usr/bin/ssh ] && [ -f /usr/bin/.ssh_backup ]; then
    echo -e "${RED}🚨 SSH 命令可能被替换！发现备份文件${NC}"
fi
if [ -f /usr/bin/sudo ] && [ -f /usr/bin/.sudo_backup ]; then
    echo -e "${RED}🚨 Sudo 命令可能被替换！发现备份文件${NC}"
fi

# 检查 SSH 和 Sudo 的修改时间
if [ -f /usr/bin/ssh ]; then
    SSH_TIME=$(stat -f "%Sm" /usr/bin/ssh 2>/dev/null || stat -c "%y" /usr/bin/ssh 2>/dev/null)
    echo "SSH 命令最后修改: $SSH_TIME"
fi
if [ -f /usr/bin/sudo ]; then
    SUDO_TIME=$(stat -f "%Sm" /usr/bin/sudo 2>/dev/null || stat -c "%y" /usr/bin/sudo 2>/dev/null)
    echo "Sudo 命令最后修改: $SUDO_TIME"
fi
echo ""

# 6. 检查可疑进程
echo "🔍 6. 检查可疑进程..."
echo "网络连接:"
netstat -an 2>/dev/null | grep ESTABLISHED | head -10 || ss -tunap 2>/dev/null | grep ESTABLISHED | head -10
echo ""

echo "监听端口:"
lsof -iTCP -sTCP:LISTEN 2>/dev/null | grep -v "127.0.0.1" || netstat -tlnp 2>/dev/null | grep -v "127.0.0.1"
echo ""

# 7. 检查 DNS 设置
echo "🌐 7. 检查 DNS 设置..."
echo "当前 DNS:"
cat /etc/resolv.conf 2>/dev/null | grep nameserver
echo ""

# 8. 检查最近修改的系统文件
echo "📁 8. 检查最近7天修改的系统文件..."
find /usr/bin /usr/sbin /bin /sbin -mtime -7 -type f 2>/dev/null | head -10
echo ""

# 9. 检查隐藏文件
echo "👻 9. 检查用户目录隐藏文件..."
ls -la ~ | grep "^\." | grep -v "^\.$\|^\.\.$" | grep -v ".DS_Store\|.Trash\|.bash\|.zsh\|.ssh\|.vim\|.gitconfig\|.npm\|.config\|.cache\|.local\|.m2\|.gradle\|.docker\|.kube\|.minikube\|.terraform.d\|.vscode\|.cursor\|.openclaw\|.hermes"
echo ""

# 10. 检查网络流量
echo "📊 10. 检查网络活动..."
echo "当前网络连接数:"
netstat -an 2>/dev/null | grep ESTABLISHED | wc -l || ss -tunap 2>/dev/null | grep ESTABLISHED | wc -l
echo ""

echo "=========================================="
echo "     ✅ 检查完成"
echo "=========================================="
echo ""
echo "如果发现可疑内容，请:"
echo "1. 不要立即删除，先拍照记录"
echo "2. 断开网络连接"
echo "3. 寻求专业安全人员帮助"
echo ""
