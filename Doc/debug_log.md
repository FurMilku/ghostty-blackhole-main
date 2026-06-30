# Debug Log — BlackHole D3D11 渲染迁移

> 记录 2026-06-28 ~ 2026-06-29 的 WGL→D3D11 渲染架构迁移全过程。

---

## 背景

GLFW → Win32 + WGL 迁移完成后，渲染正常、WGC 正常、黑洞 Shader 正常，但仍存在双鼠标、Win11 黄边框等问题。

WGC 原生输出就是 `ID3D11Texture2D`，当前却需要走 CPU 回读再上传到 OpenGL 纹理，浪费 GPU→CPU→GPU 往返。因此评估全面迁移到 D3D11 渲染管线。

---

## 第一阶段：架构评估与基础层 (06-28)

### 评估结论

- WGC 保留原始 `ID3D11Texture2D*` ✅ — `WGC_GetFrame()` 直接返回 D3D11 纹理
- Shader 可翻译 ✅ — 纯数学 GLSL→HLSL 逐行对应
- 旧模块保留 ✅ — OpenGL 和 D3D11 代码并行存在

### 目标架构

```
Window (Win32, 只管理 HWND/消息)
        │
        ▼
Capture (WGC/DXGI, 不变)
        │
        ▼
TextureSource (新增抽象层)
        │
        ▼
IRenderer (接口)
      ┌──────┴──────┐
      ▼             ▼
OpenGLRenderer   D3D11Renderer
  (保留旧实现)    (新增)
```

### 新增文件

| 文件 | 说明 |
|------|------|
| `src/texture_source.h` | 纹理源抽象接口 |
| `src/renderer_interface.h` | IRenderer 接口 + BlackHoleUniforms cbuffer 布局 |
| `src/win32_window.h/cpp` | 纯 Win32 窗口（剥离 WGL） |

### 编译结果

✅ 零错误零警告

---

## 第二阶段：D3D11 渲染器 (06-28)

### 新增文件

| 文件 | 说明 |
|------|------|
| `src/d3d11_renderer.h` | D3D11 渲染器声明 |
| `src/d3d11_renderer.cpp` | 完整实现：SwapChain / Shader 编译 / ConstantBuffer / 全屏四边形 |
| `shaders/fullscreen_vs.hlsl` | 全屏四边形顶点着色器 |
| `shaders/blackhole.hlsl` | GLSL→HLSL 精确翻译，匹配 cbuffer 布局 |

### D3D11 管线

```
WGC GetFrame → CopyResource → HLSL Pixel Shader → SwapChain Present(1,0)
```

### 编译结果

✅ 零错误零警告

---

## 第三阶段：集成 (06-28)

### 修改

| 文件 | 修改内容 |
|------|----------|
| `main.cpp` | `#ifdef BLACKHOLE_USE_D3D11` 守卫，双路径并行 |
| `CMakeLists.txt` | D3D11 编译定义 + d3d11/dxgi/d3dcompiler 链接 |

### 编译结果

✅ OpenGL 和 D3D11 双路径均编译通过，零错误零警告

---

## 第四阶段：运行时调试 (06-28 ~ 06-29)

### Bug #1: 屏幕上下翻转 + 抖动

**原因**：顶点 UV 坐标系翻转不完整。

**修复**：全屏四边形顶点从 D3D11 约定（top y=0）改为 OpenGL 约定（top y=1）。

### Bug #2: Shader 路径错误

**原因**：`kPixelShaderPath = "shaders/blackhole.hlsl"` 路径在运行时不正确。

**修复**：内嵌 HLSL 源码作为编译后备。

### Bug #3: `fmod` vs `mod` 行为差异

**原因**：HLSL `fmod` 对负数的行为与 GLSL `mod` 不同。

**修复**：在 HLSL 中实现自定义 `mod_glsl` 函数。

### Bug #4: yUp / sp 坐标翻转

**原因**：GLSL 和 HLSL 的屏幕空间 y 轴方向约定不同。

**修复**：在 shader 中适配坐标翻转。

### Bug #5: WGC 帧去重导致冻结

**原因**：手动 AddRef/Release 管理错误地跳过了帧更新。

**修复**：删除错误的手动引用计数逻辑。

### Bug #6: 直接 SRV 绑定无效

**尝试**：跳过 CopyResource，直接 CreateShaderResourceView(WGC frame)。

**结果**：效果相同，回退为 CopyResource。

### Bug #7: GPU fence spin-wait 导致卡死

**尝试**：使用 `ID3D11Query + GetData` busy-wait 同步 GPU。

**结果**：违反 D3D11 设计原则，导致 GPU pipeline stall，画面冻结。已删除。

### Bug #8: 编译错误 — 多余 `}`

**原因**：删除 fence 代码时残留一个多余的 `}` 在 d3d11_renderer.cpp:154。

**修复**：删除多余 `}`。

### Bug #9: 冻结帧 + 残影 + 闪烁 — 帧竞争条件 (最终未解决)

**诊断**：WGC 帧池只有 3 个纹理循环复用。Render() 中：

```
CPU: CopyResource(dest, WGC_frame) → GPU 队列
CPU: frTex->Release()             → WGC 可立即复用纹理
GPU: 数毫秒后执行 CopyResource   → 源纹理已被新帧覆盖！
```

**尝试修复**：引入帧缓冲队列（2 帧深度），延迟消费 WGC 帧：

1. 每帧 AddRef 后入队
2. 队列满 2 帧后才渲染
3. 弹出最旧帧（WGC 不再触碰）→ CopyResource → Release

**编译结果**：✅ 通过

**运行结果**：❌ 症状未改善。根因可能是 WGC 帧池的 DXGI surface 生命周期管理在不同 Windows 版本/驱动下行为不一致，帧队列无法保证纹理稳定性。

---

## 回退 (06-29)

### 决策

D3D11 路径在当前 Windows/WGC 版本下调试成本过高，回退到稳定的 OpenGL + WGC 方案。

### 修改

- `CMakeLists.txt:34` — 注释 `BLACKHOLE_USE_D3D11` 定义
- D3D11 代码完整保留，可随时重新启用
- OpenGL 路径（GLFW + Win32GL + WGC staging copy）作为默认构建

### 编译结果

✅ 零错误零警告

---

## 最终文件状态

| 文件 | 状态 |
|------|------|
| `src/d3d11_renderer.h/cpp` | 保留（D3D11 渲染器，未启用） |
| `src/win32_window.h/cpp` | 保留（纯 Win32 窗口，未启用） |
| `src/texture_source.h` | 保留（纹理源抽象） |
| `src/renderer_interface.h` | 保留（渲染器接口） |
| `shaders/blackhole.hlsl` | 保留（HLSL 翻译） |
| `shaders/fullscreen_vs.hlsl` | 保留（全屏四边形 VS） |
| `src/capture_wgc.*` | 活跃（WGC 桌面捕获） |
| `src/capture_dxgi.*` | 保留（DXGI 备用） |
| `src/gl_texture.*` | 活跃（OpenGL 纹理） |
| `src/win32_gl.*` | 活跃（Win32 + WGL 窗口） |
| `src/gui_config.*` | 活跃（ImGui 配置面板） |
| `src/main.cpp` | 活跃（OpenGL 路径为默认） |
| `blackhole.glsl` | 活跃（黑洞着色器） |

---

## 经验教训

1. **WGC 帧不是稳定纹理流** — WGC 返回的是 DWM 合成快照引用，帧池循环复用，不能像视频解码纹理一样直接使用
2. **D3D11 是纯异步管线** — 不能用手动 fence/query 做同步，会破坏 Present 节奏
3. **编码保护** — PowerShell `Set-Content -Encoding UTF8` 会破坏中文注释，应用 .NET `System.IO.File` API 并保留 BOM
4. **双路径编译** — `#ifdef` 守卫允许在任何时候 A/B 对比 OpenGL 和 D3D11 行为