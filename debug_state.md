# Debug State — Blackhole: GLFW → Win32+WGL 迁移

## 当前状态
编译 ✅ (2026-06-28)
黑洞渲染 ✅ — DPI 修复后正常

## 已解决的问题

### 问题 A: 渲染不显示 (已修复)
**根因**: `WS_EX_NOREDIRECTIONBITMAP` 在 CreateWindowEx 时就设置了，阻止了 DWM 为 OpenGL 双缓冲窗口创建合成表面。

**修复**: 从窗口创建参数中移除 `WS_EX_NOREDIRECTIONBITMAP`，精简 ShowWindow 后的 DWM 刷新操作。

### 问题 B: 屏幕放大/只有左上角 (已修复)
**根因**: 程序未声明 DPI 感知。`GetSystemMetrics` 在高 DPI 屏上返回虚拟化坐标(如 1280x720)，而不是物理分辨率(1920x1080)，导致窗口尺寸错误。

**修复**: 在 main() 开头调用 `SetProcessDPIAware()`。

## 仍然存在的问题
- Win11 黄边框（DWM 边框颜色设置可能需要调整时机）
- 诊断代码（红屏测试、日志文件）尚在代码中，后续清理
