# 🔐 CI/CD 配置说明

## 📋 概述

本项目已配置 GitHub Actions 自动构建和发布流程。每次 push 到 main 分支或创建新 tag 时，会自动构建 APK、AAB 和 Windows 版本。

---

## 🚀 触发条件

### 自动触发
- **Push 到 main/master 分支**: 构建并上传为 Artifacts（保留 30 天）
- **创建 Tag (v*.*.*)**: 构建并自动创建 GitHub Release

### 示例
```bash
# 推送代码到 main 分支（构建但不发布 Release）
git push origin main

# 创建并推送 tag（会自动创建 Release）
git tag v1.0.1
git push origin v1.0.1
```

---

## 📦 构建产物

### Android
| 文件 | 用途 | 位置 |
|------|------|------|
| `white_space_qwen-android.apk` | 直接安装 | Release 附件 / Artifacts |
| `white_space_qwen.aab` | Google Play | Release 附件 / Artifacts |

### Windows
| 文件 | 用途 | 位置 |
|------|------|------|
| `white_space_qwen-windows.zip` | Windows 安装包 | Release 附件 / Artifacts |

---

## 🔧 配置 Android 签名（可选但推荐）

当前配置使用 debug 签名。如果要发布到生产环境，建议配置正式签名。

### 步骤 1: 创建 Keystore

```bash
keytool -genkey -v -keystore white_space_qwen.keystore -alias white_space_qwen -keyalg RSA -keysize 2048 -validity 10000
```

### 步骤 2: 在 GitHub 设置 Secrets

访问：`https://github.com/qianqiuyueying/whiteSpace/settings/secrets/actions`

添加以下 Secrets：

| Secret 名称 | 值 |
|------------|-----|
| `KEYSTORE_FILE` | keystore 文件的 Base64 编码 |
| `KEYSTORE_PASSWORD` | 密钥库密码 |
| `KEY_ALIAS` | 密钥别名 |
| `KEY_PASSWORD` | 密钥密码 |

### 步骤 3: 编码 Keystore

```bash
# Linux/Mac
base64 white_space_qwen.keystore > keystore_base64.txt

# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("white_space_qwen.keystore")) | Out-File keystore_base64.txt
```

### 步骤 4: 修改 android/app/build.gradle.kts

在 `android` 块中添加：

```kotlin
signingConfigs {
    create("release") {
        storeFile = file("../../keystore.jks")
        storePassword = System.getenv("KEYSTORE_PASSWORD")
        keyAlias = System.getenv("KEY_ALIAS")
        keyPassword = System.getenv("KEY_PASSWORD")
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

---

## 📝 查看构建状态

### GitHub Actions 页面
访问：`https://github.com/qianqiuyueying/whiteSpace/actions`

### 下载 Artifacts
1. 点击对应的构建任务
2. 滚动到页面底部
3. 在 "Artifacts" 区域下载

---

## 🎯 使用示例

### 发布新版本

```bash
# 1. 更新版本号 (pubspec.yaml)
# version: 1.0.1+2

# 2. 提交更改
git add .
git commit -m "release: v1.0.1 - 新功能说明"

# 3. 推送并创建 tag
git push origin main
git tag v1.0.1
git push origin v1.0.1
```

### 查看 Release
推送 tag 后，访问：`https://github.com/qianqiuyueying/whiteSpace/releases`

---

## ⚙️ 自定义工作流

### 修改触发分支
编辑 `.github/workflows/build-and-release.yml`:

```yaml
on:
  push:
    branches:
      - main      # 修改为你想要的分支
      - develop   # 添加更多分支
```

### 添加更多构建任务
可以在工作流中添加：
- iOS 构建（需要 macOS runner）
- Linux 构建
- Web 构建
- 自动测试

---

## 🔍 故障排查

### 构建失败常见原因

1. **依赖问题**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Java 版本不匹配**
   - 确认使用 Java 17

3. **签名配置错误**
   - 检查 Secrets 是否正确配置

4. **磁盘空间不足**
   - GitHub Actions 提供 14GB 空间

### 查看构建日志
1. 访问 Actions 页面
2. 点击对应的构建任务
3. 展开查看详细的构建日志

---

## 📊 当前工作流配置

```yaml
触发条件:
  - push 到 main/master
  - tag: v*.*.*
  - pull request

构建平台:
  - Android (APK + AAB)
  - Windows (EXE)

发布方式:
  - Tag 推送 → 自动创建 Release
  - 普通推送 → 上传 Artifacts
```

---

**配置完成！现在每次 push 都会自动构建和发布。** 🎉
