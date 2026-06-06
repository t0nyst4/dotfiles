# Dotfiles

WSL Ubuntu 24.04 环境配置。

## 快速部署

```bash
git clone <repo-url> ~/dotfiles
bash ~/dotfiles/setup.sh
```

## 包含配置

| 文件 | 用途 |
|------|------|
| `.config/ghostty/config` | Ghostty 终端 |
| `.config/yazi/yazi.toml` | Yazi 文件管理器 |
| `.config/fcitx5/` | fcitx5 输入法 |
| `.config/starship.toml` | Starship prompt |
| `.config/lazygit/config.yml` | Lazygit |
| `.config/nvim/` | Neovim (独立仓库 [t0nyst4/lazyvim](https://github.com/t0nyst4/lazyvim)) |
| `.gitconfig.template` | Git 配置模板 |
| `.tmux.conf` | tmux |
| `.bashrc` | Shell 环境 |
| `setup.sh` | 一键部署脚本 |

## Ghostty 快捷方式

Windows 快捷方式目标：

```
C:\Program Files\WSL\wslg.exe" -d Ubuntu-24.04 --cd "~" -- /bin/bash -lic "GDK_BACKEND=x11 GDK_SCALE=2 GALLIUM_DRIVER=d3d12 GTK_IM_MODULE=fcitx XMODIFIERS=@im=fcitx exec /snap/bin/ghostty"
```

## 已知限制

- Ghostty X11 模式：窗口不能拖动/缩放
- WSLg 弹窗有层级 bug（等待微软修复）
- 等 Ghostty 原生 Windows 版本
