#!/bin/bash
# ==========================================
#  环境验证脚本
#  Usage: bash ~/dotfiles/test.sh
# ==========================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

PASS=0
FAIL=0
WARN=0

check_command() {
    if command -v "$1" &>/dev/null; then
        pass "$1 ($(command -v $1))"
        ((PASS++))
    else
        fail "$1 未安装"
        ((FAIL++))
    fi
}

check_file() {
    if [ -f "$1" ] || [ -L "$1" ]; then
        pass "$1"
        ((PASS++))
    else
        fail "$1 不存在"
        ((FAIL++))
    fi
}

check_symlink() {
    if [ -L "$1" ]; then
        local target=$(readlink "$1")
        pass "$1 -> $target"
        ((PASS++))
    elif [ -f "$1" ]; then
        warn "$1 存在但不是 symlink"
        ((WARN++))
    else
        fail "$1 不存在"
        ((FAIL++))
    fi
}

echo "========================================="
echo "  环境验证"
echo "========================================="
echo ""

# ========== 命令行工具 ==========
echo "--- 命令行工具 ---"
check_command git
check_command curl
check_command wget
check_command node
check_command npm
check_command nvim
check_command tmux
check_command fzf
check_command rg
check_command fd
check_command chafa
check_command starship
check_command lazygit
check_command uv
check_command gh
check_command python3
check_command pip3
check_command jq
check_command ghostty
echo ""

# ========== 版本信息 ==========
echo "--- 版本信息 ---"
command -v node &>/dev/null && echo "  Node.js: $(node -v)"
command -v npm &>/dev/null && echo "  npm: $(npm -v)"
command -v nvim &>/dev/null && echo "  Neovim: $(nvim --version | head -1)"
command -v tmux &>/dev/null && echo "  tmux: $(tmux -V)"
command -v python3 &>/dev/null && echo "  Python: $(python3 --version)"
echo ""

# ========== npm 全局包 ==========
echo "--- npm 全局包 ---"
for pkg in neovim @anthropic-ai/claude-code opencode-ai; do
    if npm list -g "$pkg" &>/dev/null; then
        pass "npm: $pkg"
        ((PASS++))
    else
        fail "npm: $pkg 未安装"
        ((FAIL++))
    fi
done
echo ""

# ========== 配置文件 ==========
echo "--- 配置文件 (symlink) ---"
check_symlink ~/.config/ghostty/config
check_symlink ~/.config/yazi/yazi.toml
check_symlink ~/.config/fcitx5/profile
check_symlink ~/.config/fcitx5/config
check_symlink ~/.config/fcitx5/conf/classicui.conf
check_symlink ~/.config/starship.toml
check_symlink ~/.config/lazygit/config.yml
check_symlink ~/.tmux.conf
check_symlink ~/.bashrc
echo ""

# ========== Neovim 配置 ==========
echo "--- Neovim 配置 ---"
if [ -d ~/.config/nvim/.git ]; then
    pass "~/.config/nvim (git repo)"
    ((PASS++))
else
    fail "~/.config/nvim 不是 git 仓库"
    ((FAIL++))
fi
echo ""

# ========== 输入法 ==========
echo "--- fcitx5 输入法 ---"
if pgrep -x fcitx5 &>/dev/null; then
    pass "fcitx5 进程运行中"
    ((PASS++))
else
    warn "fcitx5 未运行"
    ((WARN++))
fi
if fcitx5-remote &>/dev/null; then
    pass "fcitx5-remote 可连接"
    ((PASS++))
else
    warn "fcitx5-remote 无法连接"
    ((WARN++))
fi
echo ""

# ========== 环境变量 ==========
echo "--- 环境变量 ---"
[ -n "$GTK_IM_MODULE" ] && pass "GTK_IM_MODULE=$GTK_IM_MODULE" && ((PASS++)) || { fail "GTK_IM_MODULE 未设置"; ((FAIL++)); }
[ -n "$XMODIFIERS" ] && pass "XMODIFIERS=$XMODIFIERS" && ((PASS++)) || { fail "XMODIFIERS 未设置"; ((FAIL++)); }
echo ""

# ========== tmux ==========
echo "--- tmux ---"
if tmux show-option -g allow-passthrough 2>/dev/null | grep -q "all"; then
    pass "tmux allow-passthrough = all"
    ((PASS++))
else
    warn "tmux allow-passthrough 未设置为 all"
    ((WARN++))
fi
echo ""

# ========== 字体 ==========
echo "--- 字体 ---"
if fc-list 2>/dev/null | grep -qi "Maple Mono NF CN"; then
    pass "Maple Mono NF CN 已安装"
    ((PASS++))
else
    fail "Maple Mono NF CN 未安装"
    ((FAIL++))
fi
echo ""

# ========== GPU ==========
echo "--- GPU 渲染 ---"
if glxinfo 2>/dev/null | grep -q "D3D12"; then
    pass "OpenGL 渲染器: D3D12 (GPU 加速)"
    ((PASS++))
elif glxinfo 2>/dev/null | grep -q "llvmpipe"; then
    warn "OpenGL 渲染器: llvmpipe (软件渲染)"
    ((WARN++))
else
    warn "无法检测 OpenGL 渲染器"
    ((WARN++))
fi
echo ""

# ========== dotfiles 仓库 ==========
echo "--- dotfiles 仓库 ---"
if [ -d ~/dotfiles/.git ]; then
    local_commit=$(cd ~/dotfiles && git log --oneline -1)
    pass "dotfiles: $local_commit"
    ((PASS++))
else
    fail "~/dotfiles 不是 git 仓库"
    ((FAIL++))
fi
echo ""

# ========== 总结 ==========
echo "========================================="
echo -e "  ${GREEN}PASS: $PASS${NC}  ${RED}FAIL: $FAIL${NC}  ${YELLOW}WARN: $WARN${NC}"
if [ $FAIL -eq 0 ]; then
    echo -e "  ${GREEN}环境验证通过！${NC}"
else
    echo -e "  ${RED}有 $FAIL 项未通过，请检查${NC}"
fi
echo "========================================="
