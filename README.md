# Terminal Setup

面向 **Arch Linux**、**WSL Arch** 与 **原生 Windows** 的终端环境安装脚本。参考 [terminal-setup](https://github.com/lewislulu/terminal-setup)

## 支持平台

| 平台 | 状态 | 说明 |
| --- | --- | --- |
| WSL Arch | 主维护平台 | 推荐场景 |
| 原生 Arch Linux | 完整支持 | 次要场景 |
| 原生 Windows | 支持 | 通过 PowerShell + winget 安装 |
| 其他 Linux / macOS | 不支持 | 项目不维护这些平台 |

## 快速开始

### WSL Arch

```bash
cd terminal-setup
./setup.sh --dry-run --fish
./setup.sh --fish
```

### 原生 Arch Linux

```bash
cd terminal-setup
./setup.sh --dry-run --zsh
./setup.sh --zsh
```

### 原生 Windows

使用 PowerShell 运行 Windows bootstrap。首次执行建议先 dry-run，确认会执行的 winget 安装与配置部署步骤：

```powershell
cd terminal-setup
.\setup.ps1 -DryRun
.\setup.ps1
```

可选跳过部分步骤：

```powershell
.\setup.ps1 -SkipPackages
.\setup.ps1 -SkipProfile
```

Windows 脚本会通过 `winget` 安装以下包：

| winget ID | 说明 |
| --- | --- |
| `Microsoft.WindowsTerminal.Preview` | Windows Terminal Preview |
| `Starship.Starship` | 跨 Shell 提示符 |
| `Microsoft.PowerShell` | PowerShell |
| `eza-community.eza` | `ls` 替代 |
| `astral-sh.uv` | Python 工具链 |
| `Schniz.fnm` | Node 版本管理 |
| `sharkdp.fd` | `find` 替代 |
| `Git.Git` | Git |
| `junegunn.fzf` | 模糊查找 |
| `ajeetdsouza.zoxide` | 智能目录跳转 |
| `FxSound.FxSound` | Windows 音频增强 |

PowerShell 配置会做这些事：

- 部署 `configs/starship.toml` 到 `~/.config/starship.toml`
- 将 `configs/windows/Microsoft.PowerShell_profile.ps1` 复制到 `$PROFILE`
- 如果 `$PROFILE` 已存在，直接覆盖；如果不存在，创建目录后复制
- 初始化 `starship`、`fnm`、`zoxide`、`fzf`
- 配置 `ls`、`ll`、`lt`、`cat`、`find`、`cd` 等函数
- 对 PSReadLine 预测、历史和快捷键做非交互环境保护，避免重定向或自动化执行时报错

## 可选参数

```bash
./setup.sh --fish
./setup.sh --zsh
./setup.sh --dry-run
```

Windows 参数：

```powershell
.\setup.ps1 -DryRun
.\setup.ps1 -SkipPackages
.\setup.ps1 -SkipProfile
```

## 安装内容

1. 初始化 `pacman-key`、执行系统更新、手动切换中国镜像源，并使用 `reflector` 生成中国镜像列表后安装基础依赖
2. 在原生 Arch 上安装 Ghostty，WSL Arch 仅提示 Windows 侧终端方案，原生 Windows 安装 Windows Terminal Preview
3. 安装 Fish 或 Zsh
4. 安装 CLI 工具：`bat`、`eza`、`fd`、`ripgrep`、`jq`、`fzf`、`btop`、`zoxide`、`tealdeer`、`git-delta`、`lazygit`
5. 安装 `starship`
6. 可选安装 `fnm` 与 Node.js LTS
7. 可选安装 `zellij`
8. 部署 Fish / Zsh / Ghostty / Starship 配置；原生 Windows 部署 Starship 与 PowerShell Profile 配置文件

## 选择你的 Shell

| | 🐟 Fish | 🐚 Zsh |
|---|---------|---------|
| **POSIX 兼容** | ❌ 自有语法 | ✅ 兼容 |
| **自动补全建议** | ✅ 内置 | ✅ 通过插件 |
| **语法高亮** | ✅ 内置 | ✅ 通过插件 |
| **Node 管理** | fnm（共享） | fnm（共享） |
| **配置文件** | `~/.config/fish/config.fish` | `~/.zshrc` |
| **适合** | 开箱即用，省心，适合把交互体验放在第一位 | 写脚本，POSIX 兼容，更适合脚本兼容场景 |

**补充**： Zsh 可以通过 `zsh-autosuggestions`、`zsh-syntax-highlighting`、`zsh-completions` 补齐交互体验

## 工具栈

| 组件 | 说明 |
|------|------|
| **[Ghostty](https://ghostty.org)** | GPU 加速终端模拟器 |
| **Fish** 或 **Zsh** | Shell（你选） |
| **[Starship](https://starship.rs)** | 跨 Shell 提示符（Catppuccin Mocha 主题） |
| **MesloLGS NF** | Nerd Font，提供图标和 Powerline 字形 |
| **[bat](https://github.com/sharkdp/bat)** | 带语法高亮和行号的 `cat` |
| **[eza](https://github.com/eza-community/eza)** | 带图标、git 状态、树形视图的 `ls` |
| **[fd](https://github.com/sharkdp/fd)** | 更快更直观的 `find` |
| **[ripgrep](https://github.com/BurntSushi/ripgrep)** | 比 `grep` 快几个数量级 |
| **[fzf](https://github.com/junegunn/fzf)** | 模糊查找器（Ctrl+R / Ctrl+T / Alt+C） |
| **[btop](https://github.com/aristocratos/btop)** | 漂亮的系统监控 |
| **[zoxide](https://github.com/ajeetdsouza/zoxide)** | 智能 `cd`，学习你的习惯 |
| **[jq](https://github.com/jqlang/jq)** | JSON 处理器 |
| **[tldr](https://github.com/tldr-pages/tldr)** | 简化版 man 手册，附带示例 |
| **[delta](https://github.com/dandavison/delta)** | 带语法高亮的 git diff |
| **[lazygit](https://github.com/jesseduffield/lazygit)** | Git 终端 UI |
| **[fnm](https://github.com/Schniz/fnm)** | 快速 Node 版本管理器（Rust 编写） |
| **[Zellij](https://zellij.dev)** | 现代终端复用器（可选） |
| **[uv](https://github.com/astral-sh/uv)** | 用 Rust 实现的高性能 Python 包管理与环境工具    |



## 别名 / 缩写

| 快捷方式 | 展开为 |
|----------|--------|
| `ls` | `eza --icons --group-directories-first` |
| `ll` | `eza -la --icons --group-directories-first` |
| `lt` | `eza --tree --icons --level=2` |
| `cat` | `bat` |
| `find` | `fd` |
| `grep` | `rg` |
| `top` | `btop` |
| `lg` | `lazygit` |

## fzf 快捷键

| 按键 | 功能 |
|------|------|
| `Ctrl+R` | 模糊搜索命令历史 |
| `Ctrl+T` | 模糊查找文件（用 `fd` 作为后端） |
| `Alt+C` | 模糊进入目录 |

## fnm — Node 版本管理

```bash
fnm install 22            # 安装 Node 22
fnm install --lts         # 安装最新 LTS
fnm default 22            # 设置默认版本
fnm use 22                # 当前 shell 切换
echo "22" > .node-version # 进入目录自动切换
```

## SSH Key 切换

两种 Shell 配置都内置了 `set-ssh-key` 函数：

```bash
set-ssh-key my-key-name     # 清空 agent，加载 ~/.ssh/my-key-name
set-ssh-key                 # key 不存在时列出所有可用 key
```

> **最佳实践：** 推荐在 `~/.ssh/config` 里用 `Host` 别名 + `IdentitiesOnly yes` 实现自动匹配。`set-ssh-key` 是兜底方案。

## 技术选型说明

### 为什么同时提供 Fish 和 Zsh？

不同人有不同需求：

- **Fish：** 最佳开箱体验。自动补全、语法高亮、补全全内置，零配置。但它不兼容 POSIX，`bash` 脚本不能直接跑，有些工具假设你用 POSIX shell。
- **Zsh：** POSIX 兼容，所有 bash 脚本和一行命令都能用。装上插件（autosuggestions + syntax-highlighting）后能达到 Fish 90% 的体验。代价：依赖更多组件。

如果你经常需要跑别人的脚本 → **Zsh**。
如果你追求最干净的 Shell 体验，不介意偶尔 `bash script.sh` → **Fish**。

### 为什么选 fnm 而不是 nvm？

| | fnm | nvm |
|---|-----|-----|
| **语言** | Rust | Bash |
| **Shell 启动耗时** | ~1ms | ~200-400ms |
| **Fish 支持** | ✅ 原生 | ❌ 需要 nvm.fish |
| **Zsh 支持** | ✅ 原生 | ✅ 原生 |
| **自动切换** | ✅ `--use-on-cd` | ⚠️ 需要额外 hook |
| **安装方式** | `brew install fnm` / `curl` | curl 脚本 |
| **跨 Shell 共享** | ✅ 共用同一份 Node | ❌ 存储路径不同 |

### 为什么选 uv

- Rust 实现 → **极快（比 pip 快 10~100 倍）**
- 兼容 pip CLI → **迁移成本低**
- 内置 venv + resolver → **工具链收敛**

可以把 uv 理解为一个 " 收敛工具链 "：

|能力|传统工具|uv 对应|
|---|---|---|
|虚拟环境|venv|`uv venv`|
|包安装|pip|`uv pip install`|
|依赖锁定|pip-tools / poetry|`uv pip compile`|
|临时工具执行|pipx|`uvx`|
|Python 管理|pyenv（部分）|`uv python`|
