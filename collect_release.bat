@echo off
chcp 65001 >nul
echo ========================================
echo   Flutter 构建发布文件收集脚本
echo ========================================
echo.

:: 设置版本号（可修改）
set VERSION=1.0.0

:: 创建发布文件夹
echo [1/4] 创建发布文件夹...
if not exist "release_files" mkdir "release_files"
if not exist "release_files\windows" mkdir "release_files\windows"

:: 复制 Android AAB 文件
echo.
echo [2/4] 复制 Android AAB 文件...
if exist "build\app\outputs\bundle\release\app-release.aab" (
    copy "build\app\outputs\bundle\release\app-release.aab" "release_files\white_space_qwen-v%VERSION%-android.aab" >nul
    echo ✓ Android AAB 文件已复制
) else (
    echo ✗ 未找到 Android AAB 文件，请先运行：flutter build appbundle --release
)

:: 复制 Windows 可执行文件
echo.
echo [3/4] 复制 Windows 可执行文件...
if exist "build\windows\x64\runner\Release\white_space_qwen.exe" (
    copy "build\windows\x64\runner\Release\white_space_qwen.exe" "release_files\windows\" >nul
    echo ✓ Windows 可执行文件已复制
) else (
    echo ✗ 未找到 Windows 可执行文件
)

:: 收集 Windows 依赖文件
echo.
echo [4/4] 收集 Windows 依赖文件...

:: 复制 flutter_windows.dll
if exist "windows\flutter\ephemeral\flutter_windows.dll" (
    copy "windows\flutter\ephemeral\flutter_windows.dll" "release_files\windows\" >nul
    echo ✓ flutter_windows.dll 已复制
)

:: 复制 ICU 数据文件
if exist "build\windows\x64\runner\Release\data" (
    xcopy /E /I /Y "build\windows\x64\runner\Release\data" "release_files\windows\data" >nul
    echo ✓ ICU 数据文件已复制
)

echo.
echo ========================================
echo   发布文件收集完成！
echo ========================================
echo.
echo 发布文件位置：release_files\
echo   - Android: white_space_qwen-v%VERSION%-android.aab
echo   - Windows: release_files\windows\
echo.
echo 下一步操作:
echo   1. 访问 https://github.com/qianqiuyueying/whiteSpace/releases
echo   2. 点击 "Create a new release"
echo   3. 创建标签 v%VERSION%
echo   4. 上传 release_files 中的文件
echo   5. 发布 Release
echo.
pause
