# 📦 构建和发布指南

## ✅ 当前构建状态

### Android
- **AAB 文件**: `build/app/outputs/bundle/release/app-release.aab` (46.5MB)
- **位置**: `G:\vscode\projects\white_space_qwen\build\app\outputs\bundle\release\app-release.aab`
- **用途**: 上传到 Google Play Store

### Windows
- **可执行文件**: `build/windows/x64/runner/Release/white_space_qwen.exe` (93KB)
- **位置**: `G:\vscode\projects\white_space_qwen\build\windows\x64\runner\Release\white_space_qwen.exe`
- **注意**: 需要同时复制依赖的 DLL 文件才能运行

---

## 📤 方法一：通过 GitHub Web 界面上传 Release（推荐）

### 步骤 1: 准备发布文件

1. **创建一个文件夹用于存放发布文件**
   ```bash
   # 在项目根目录创建 release 文件夹
   mkdir release_files
   ```

2. **复制 Android AAB 文件**
   ```bash
   copy build\app\outputs\bundle\release\app-release.aab release_files\white_space_qwen-v1.0.0-android.aab
   ```

3. **复制 Windows 可执行文件**
   ```bash
   copy build\windows\x64\runner\Release\white_space_qwen.exe release_files\white_space_qwen-v1.0.0-windows.exe
   ```

### 步骤 2: 创建 GitHub Release

1. **访问你的仓库**
   - 打开 https://github.com/qianqiuyueying/whiteSpace

2. **进入 Releases 页面**
   - 点击右侧边栏的 **"Releases"**
   - 或者直接访问 https://github.com/qianqiuyueying/whiteSpace/releases

3. **创建新 Release**
   - 点击 **"Create a new release"** 或 **"Draft a new Release"** 按钮

4. **填写 Release 信息**
   - **Choose a tag**: 输入 `v1.0.0` (第一次创建时会自动创建标签)
   - **Target**: 选择 `main` 或 `master` 分支
   - **Release title**: 输入 `v1.0.0 - 初始版本`
   - **Description**: 填写版本说明，例如：
     ```
     ## 新功能
     - 初始版本发布
     - 支持 Android 和 Windows 平台
     - GitHub Gist 同步功能
     - Markdown 日记功能

     ## 安装说明
     - Android: 通过 Google Play Store 安装 (AAB 格式)
     - Windows: 下载 exe 文件直接运行
     ```

5. **上传文件**
   - 点击 **"Attach binaries by dropping them here or selecting them"**
   - 将 `release_files` 文件夹中的文件拖拽到上传区域
   - 或者点击选择文件并上传

6. **发布**
   - 勾选 **"Set as the latest release"**
   - 点击 **"Publish release"** 按钮

---

## 📤 方法二：使用 GitHub CLI 上传（高级）

### 安装 GitHub CLI

1. 访问 https://cli.github.com/ 下载并安装 gh

2. 验证安装
   ```bash
   gh --version
   ```

3. 登录 GitHub
   ```bash
   gh auth login
   ```

### 创建 Release 并上传文件

```bash
# 创建 release 并上传 Android 文件
gh release create v1.0.0 \
  --title "v1.0.0 - 初始版本" \
  --notes "## 新功能\n- 初始版本发布\n- 支持 Android 和 Windows 平台" \
  --target main \
  build/app/outputs/bundle/release/app-release.aab#white_space_qwen-v1.0.0-android.aab \
  build/windows/x64/runner/Release/white_space_qwen.exe#white_space_qwen-v1.0.0-windows.exe
```

---

## 📤 方法三：使用第三方工具（gh-release）

### 使用 Node.js 的 gh-release

```bash
# 安装 gh-release
npm install -g gh-release

# 创建 release
gh-release --owner qianqiuyueying --repo whiteSpace --tag v1.0.0 --name "v1.0.0" --body "初始版本发布"

# 上传文件（使用 gh release upload 命令）
gh release upload v1.0.0 build/app/outputs/bundle/release/app-release.aab
gh release upload v1.0.0 build/windows/x64/runner/Release/white_space_qwen.exe
```

---

## 🔧 关于 Windows 可执行文件的说明

当前 Windows 构建只生成了 exe 文件，但运行可能需要以下依赖：

1. **Flutter 运行时 DLL**
2. **插件相关的 DLL 文件**

### 完整打包 Windows 版本

如果需要创建完整的 Windows 安装包，建议：

1. **使用 Flutter 的官方打包方法**
   ```bash
   # 需要先解决 CMake 安装权限问题
   flutter build windows --release
   ```

2. **或者手动收集所有依赖**
   - 复制 `build/windows/x64/runner/Release/` 下的所有文件
   - 包括 exe、dll、数据文件等

3. **使用安装程序创建工具**
   - [Inno Setup](https://jrsoftware.org/isdl.php)
   - [Advanced Installer](https://www.advancedinstaller.com/)
   - 将 exe 和依赖文件打包成 setup.exe

---

## 📝 版本命名规范

建议遵循 [语义化版本](https://semver.org/lang/zh-CN/) 规范：

- `v1.0.0` - 主版本。次版本。修订版本
- 格式：`v{主版本}.{次版本}.{修订版本}`

示例：
- `v1.0.0` - 初始发布
- `v1.0.1` - Bug 修复
- `v1.1.0` - 新功能
- `v2.0.0` - 重大更新

---

## ⚠️ 注意事项

1. **Android AAB vs APK**
   - AAB (Android App Bundle): 用于上传到 Google Play Store
   - APK (Android Package): 用于直接安装或分发
   - 当前构建的是 AAB 格式

2. **Windows 依赖**
   - Windows 可执行文件可能需要 Visual C++ Redistributable
   - 建议在发布说明中告知用户安装要求

3. **代码签名**
   - Windows: 建议对 exe 进行代码签名以避免安全警告
   - Android: 确保使用正确的签名密钥

---

## 🎯 快速操作清单

- [ ] 创建 `release_files` 文件夹
- [ ] 复制 AAB 文件到 `release_files`
- [ ] 复制 Windows exe 文件到 `release_files`
- [ ] 访问 GitHub Releases 页面
- [ ] 创建新 Release (标签 v1.0.0)
- [ ] 填写版本说明
- [ ] 上传文件
- [ ] 发布 Release
- [ ] 验证下载链接可用

---

**祝你发布顺利！** 🎉
