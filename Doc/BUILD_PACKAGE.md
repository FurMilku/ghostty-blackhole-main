# Blakhole UI 编译与打包指南

## 环境要求

| 组件 | 版本/路径 |
|------|-----------|
| Qt | 6.11.1 MinGW 64-bit (`C:\Qt\6.11.1\mingw_64`) |
| MSYS2 | `C:\msys64\ucrt64` (用于编译 blackhole.exe) |
| CMake | ≥3.16 (Qt 自带或独立安装) |
| MinGW | Qt 自带: `C:\Qt\6.11.1\mingw_64\bin` |

---

## 一、编译

### 1.1 编译 blackhole.exe

使用 MSYS2 UCRT64 环境:

```powershell
# 在项目根目录执行
.\build_blackhole.ps1
```

输出: `build\blackhole.exe`

所需依赖 (MSYS2):
- glfw3
- opengl32, gdi32, d3d11, dxgi, dwmapi

### 1.2 编译 appBlakholeUI.exe (Qt UI)

```powershell
# 1. 进入 UI 目录
cd Blakhole_UI

# 2. 配置 CMake (Release)
cmake -B build/Desktop_Qt_6_11_1_MinGW_64_bit-Release `
      -DCMAKE_BUILD_TYPE=Release `
      -DCMAKE_PREFIX_PATH=C:/Qt/6.11.1/mingw_64 `
      -G "MinGW Makefiles"

# 3. 编译
cmake --build build/Desktop_Qt_6_11_1_MinGW_64_bit-Release --config Release
```

输出: `Blakhole_UI\build\Desktop_Qt_6_11_1_MinGW_64_bit-Release\appBlakholeUI.exe`

> **注意**: Debug 编译将 `Release` 替换为 `Debug`，输出在对应 Debug 目录。

### 1.3 QtCreator 编译 (推荐)

直接在 QtCreator 中打开 `Blakhole_UI\CMakeLists.txt`，选择 MinGW 64-bit Kit，点击构建。

---

## 二、打包到 release 目录

### 2.1 一键打包脚本

在项目根目录创建 `package_release.ps1`:

```powershell
$ErrorActionPreference = "Stop"

# 路径配置
$ProjectRoot = $PSScriptRoot
$QtDir      = "C:\Qt\6.11.1\mingw_64"
$QtBin      = "$QtDir\bin"
$BuildDir   = "$ProjectRoot\Blakhole_UI\build\Desktop_Qt_6_11_1_MinGW_64_bit-Release"
$ReleaseDir = "$ProjectRoot\release"

# 1. 清理旧 release
Write-Host "[1/5] 清理 release 目录..."
if (Test-Path $ReleaseDir) {
    Remove-Item "$ReleaseDir\*" -Recurse -Force -ErrorAction SilentlyContinue
} else {
    New-Item -ItemType Directory -Path $ReleaseDir | Out-Null
}

# 2. 复制 appBlakholeUI.exe
Write-Host "[2/5] 复制 appBlakholeUI.exe..."
Copy-Item "$BuildDir\appBlakholeUI.exe" $ReleaseDir -Force

# 3. 复制 blackhole.exe (从 build 目录)
Write-Host "[3/5] 复制 blackhole.exe..."
Copy-Item "$ProjectRoot\build\blackhole.exe" $ReleaseDir -Force
Copy-Item "$ProjectRoot\build\libwinpthread-1.dll" $ReleaseDir -Force -ErrorAction SilentlyContinue

# 4. windeployqt — 自动收集 Qt DLL/插件/QML
Write-Host "[4/5] 运行 windeployqt..."
& "$QtBin\windeployqt.exe" "$ReleaseDir\appBlakholeUI.exe" `
    --qmldir "$ProjectRoot\Blakhole_UI" `
    --no-compiler-runtime `
    --no-translations

# 5. 复制 shader 和配置文件
Write-Host "[5/5] 复制 shader 和配置..."
Copy-Item "$ProjectRoot\release\shaders\*" "$ReleaseDir\shaders\" -Force -ErrorAction SilentlyContinue
Copy-Item "$ProjectRoot\release\blackhole.glsl"    $ReleaseDir -Force -ErrorAction SilentlyContinue
Copy-Item "$ProjectRoot\release\blackhole_preview.glsl" $ReleaseDir -Force -ErrorAction SilentlyContinue
Copy-Item "$ProjectRoot\release\blackhole.ico"     $ReleaseDir -Force -ErrorAction SilentlyContinue
Copy-Item "$ProjectRoot\release\blackhole_ui.ico"  $ReleaseDir -Force -ErrorAction SilentlyContinue
Copy-Item "$ProjectRoot\release\icon.ico"          $ReleaseDir -Force -ErrorAction SilentlyContinue

Write-Host "打包完成: $ReleaseDir"
Get-ChildItem $ReleaseDir -Filter "*.exe" | Select-Object Name, @{N="MB";E={[math]::Round($_.Length/1MB,1)}}
```

### 2.2 手动步骤

如果脚本不可用，按以下顺序手动操作:

```
1. 清理 release\
2. 复制 Blakhole_UI\build\...\Release\appBlakholeUI.exe → release\
3. 复制 build\blackhole.exe → release\
4. 运行: windeployqt release\appBlakholeUI.exe --qmldir Blakhole_UI
5. 复制以下文件到 release\:
   ├── release\shaders\*       (如果被 windeployqt 覆盖, 从源码重新复制)
   ├── release\blackhole.glsl
   ├── release\blackhole_preview.glsl
   ├── release\blackhole.ico
   ├── release\blackhole_ui.ico
   └── release\icon.ico
```

### 2.3 windeployqt 说明

`windeployqt` 自动处理:
- Qt 核心 DLL (Qt6Core, Qt6Gui, Qt6Quick, ...)
- QML 模块 (Controls, Layouts, Effects, ...)
- 平台插件 (platforms/qwindows.dll)
- 图片格式插件 (imageformats/)
- 样式插件 (styles/)
- QML 工具 (qmltooling/)
- OpenGL 软件渲染回退 (opengl32sw.dll)

`--qmldir Blakhole_UI` 确保扫描所有 QML 文件中的 import 依赖。

---

## 三、release 目录最终结构

```
release/
├── appBlakholeUI.exe         # Qt UI 主程序
├── blackhole.exe             # OpenGL 桌面渲染器
│
├── blackhole.glsl            # 桌面版 shader
├── blackhole_preview.glsl    # 预览版 shader
├── blackhole_presets.txt     # 预设配置 (运行时生成)
├── blackhole_debug.txt       # 调试日志 (运行时生成)
│
├── shaders/                  # Shader 头文件 (运行时加载)
│   ├── vert.glsl
│   ├── frag_desktop_header.glsl
│   └── frag_preview_header.glsl
│
├── *.ico                     # 图标文件
│
├── Qt6*.dll                  # Qt 运行时库
├── D3Dcompiler_47.dll        # Direct3D 编译器
├── glfw3.dll                 # OpenGL 窗口库
├── libgcc_s_seh-1.dll        # GCC 运行时
├── libstdc++-6.dll           # C++ 标准库
├── libwinpthread-1.dll       # POSIX 线程
├── opengl32sw.dll            # 软件 OpenGL 回退
│
├── platforms/                # Qt 平台插件
├── imageformats/             # 图片格式插件
├── styles/                   # Qt 样式插件
├── qml/                      # QML 模块
├── qmltooling/               # QML 调试工具
├── generic/                  # 通用插件
├── iconengines/              # 图标引擎
├── networkinformation/       # 网络信息
├── tls/                      # SSL/TLS
├── translations/             # 翻译文件
└── fonts/                    # 字体
```

---

## 四、常见问题

### Q: windeployqt 报错找不到 Qt 模块
确保使用与编译时相同的 Qt 版本的 windeployqt:
```powershell
C:\Qt\6.11.1\mingw_64\bin\windeployqt.exe
```

### Q: 运行时缺少 DLL
检查是否缺少 MSYS2 运行时 DLL:
- `libgcc_s_seh-1.dll`
- `libstdc++-6.dll`
- `libwinpthread-1.dll`
这些文件在 `C:\msys64\ucrt64\bin\` 中。

### Q: 预览显示红屏或橙屏
说明 shader 加载失败。检查:
- `release/shaders/vert.glsl` 是否存在
- `release/shaders/frag_preview_header.glsl` 是否存在
- `release/blackhole_preview.glsl` 是否存在
- 文件编码是否为 UTF-8 without BOM

### Q: 点击"启动黑洞"找不到 blackhole.exe
UI 会在以下路径搜索 (相对于 appBlakholeUI.exe):
- `./blackhole.exe`
- `../blackhole.exe`
- `../../blackhole.exe`
- `../../../blackhole.exe`
- `../../../build/blackhole.exe`
- `../../../release/blackhole.exe`

打包到同一目录下即可避免此问题。