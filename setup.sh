#!/bin/bash
# ==========================================
#  WSL Ubuntu 24.04 一键环境部署脚本
#  Usage: bash ~/dotfiles/setup.sh
# ==========================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

DOTFILES="$HOME/dotfiles"

# ==========================================
#  1. APT 换源（阿里云镜像）
# ==========================================
setup_apt_mirror() {
    info "配置 APT 阿里云镜像源..."
    sudo cp /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.bak 2>/dev/null || true
    sudo tee /etc/apt/sources.list.d/ubuntu.sources > /dev/null << 'SOURCES'
Types: deb
URIs: https://mirrors.aliyun.com/ubuntu/
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: https://mirrors.aliyun.com/ubuntu/
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
SOURCES
}

# ==========================================
#  2. APT 包安装
# ==========================================
install_apt_packages() {
    info "更新 APT 并安装包..."
    sudo apt update && sudo apt upgrade -y

    sudo apt install -y \
        build-essential git curl wget unzip \
        software-properties-common apt-transport-https ca-certificates \
        gnupg lsb-release

    sudo apt install -y \
        tmux fzf ripgrep fd-find chafa \
        neovim python3-pynvim

    sudo apt install -y \
        fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk3 fcitx5-frontend-gtk4

    sudo apt install -y \
        python3 python3-pip python3-venv python3-dev \
        jq tree htop
}

# ==========================================
#  3. Node.js 20 (NodeSource)
# ==========================================
install_nodejs() {
    command -v node &>/dev/null && { info "Node.js 已安装: $(node -v)"; return; }
    info "安装 Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
}

# ==========================================
#  4. GitHub CLI
# ==========================================
install_github_cli() {
    command -v gh &>/dev/null && { info "GitHub CLI 已安装"; return; }
    info "安装 GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli-stable.list > /dev/null
    sudo apt update && sudo apt install -y gh
}

# ==========================================
#  5. Snap 包
# ==========================================
install_snap_packages() {
    info "安装 Snap 包..."
    snap list ghostty &>/dev/null || sudo snap install ghostty --classic 2>/dev/null || warn "Ghostty 安装失败"
}

# ==========================================
#  6. 字体
# ==========================================
install_fonts() {
    local FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"

    if ls "$FONT_DIR"/MapleMono-NF-CN-*.ttf &>/dev/null; then
        info "Maple Mono NF CN 字体已安装"
        return
    fi

    info "安装 Maple Mono NF CN 字体..."
    local VER=$(curl -s "https://api.github.com/repos/subframe7536/maple-font/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo /tmp/MapleMono-NF-CN.zip \
        "https://github.com/subframe7536/maple-font/releases/latest/download/MapleMono-NF-CN-unhinted.zip"
    unzip -o /tmp/MapleMono-NF-CN.zip -d "$FONT_DIR" "*.ttf" 2>/dev/null
    rm -f /tmp/MapleMono-NF-CN.zip
    fc-cache -f
    info "字体安装完成"
}

# ==========================================
#  7. 独立工具
# ==========================================
install_tools() {
    # Starship
    command -v starship &>/dev/null || { info "安装 Starship..."; curl -sS https://starship.rs/install.sh | sh -s -- -y; }

    # Lazygit
    if ! command -v lazygit &>/dev/null; then
        info "安装 Lazygit..."
        VER=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${VER}_Linux_x86_64.tar.gz"
        tar xf /tmp/lazygit.tar.gz -C /tmp lazygit && sudo install /tmp/lazygit /usr/local/bin/ && rm -f /tmp/lazygit /tmp/lazygit.tar.gz
    fi

    # uv
    command -v uv &>/dev/null || { info "安装 uv..."; curl -LsSf https://astral.sh/uv/install.sh | sh; }

    # npm 全局包
    info "安装 npm 全局包..."
    npm install -g neovim @anthropic-ai/claude-code opencode-ai 2>/dev/null || warn "部分 npm 包安装失败"
}

# ==========================================
#  7. 配置文件 symlink
# ==========================================
setup_configs() {
    info "Symlink 配置文件..."
    mkdir -p ~/.config/ghostty ~/.config/yazi ~/.config/fcitx5/conf

    ln -sf "$DOTFILES/.config/ghostty/config"              ~/.config/ghostty/config
    ln -sf "$DOTFILES/.config/yazi/yazi.toml"               ~/.config/yazi/yazi.toml
    ln -sf "$DOTFILES/.config/fcitx5/profile"               ~/.config/fcitx5/profile
    ln -sf "$DOTFILES/.config/fcitx5/config"                ~/.config/fcitx5/config
    ln -sf "$DOTFILES/.config/fcitx5/conf/classicui.conf"   ~/.config/fcitx5/conf/classicui.conf
    ln -sf "$DOTFILES/.config/starship.toml"                ~/.config/starship.toml
    ln -sf "$DOTFILES/.config/lazygit/config.yml"           ~/.config/lazygit/config.yml
    ln -sf "$DOTFILES/.tmux.conf"                           ~/.tmux.conf
    ln -sf "$DOTFILES/.bashrc"                              ~/.bashrc

    # Neovim (独立 git 仓库)
    if [ ! -d ~/.config/nvim/.git ]; then
        info "Clone Neovim 配置..."
        git clone https://github.com/t0nyst4/lazyvim.git ~/.config/nvim
    else
        info "Neovim 配置已存在"
    fi

    # Git 配置模板
    if [ ! -f ~/.gitconfig ]; then
        info "创建 .gitconfig（请修改 user.name 和 user.email）"
        cp "$DOTFILES/.gitconfig.template" ~/.gitconfig
    fi

    info "配置文件 symlink 完成"
}

# ==========================================
#  主流程
# ==========================================
main() {
    info "========================================="
    info "  WSL Ubuntu 24.04 环境部署"
    info "========================================="
    echo ""

    setup_apt_mirror
    install_apt_packages
    install_fonts
    install_nodejs
    install_github_cli
    install_snap_packages
    install_tools
    setup_configs

    echo ""
    info "========================================="
    info "  部署完成！"
    info "  Ghostty 快捷方式需在 Windows 手动配置："
    info "  C:\\Program Files\\WSL\\wslg.exe -d Ubuntu-24.04 --cd \"~\" -- /bin/bash -lic \"GDK_BACKEND=x11 GDK_SCALE=2 GALLIUM_DRIVER=d3d12 GTK_IM_MODULE=fcitx XMODIFIERS=@im=fcitx exec /snap/bin/ghostty\""
    info "========================================="
}

main "$@"
