# Blakhole UI 技术文档

## 项目概述

Blakhole UI 是 blackhole.exe 的 Qt6/QML 配置面板，提供可视化的黑洞参数调节和实时预览。

```
┌─────────────────────────────────────────────────┐
│                  Blakhole_UI                     │
│  ┌──────────┐  ┌──────────────┐  ┌───────────┐ │
│  │ QML 页面 │  │  C++ Core    │  │ Shader预览 │ │
│  │ 滑块/按钮│◄─│ BlackHoleCore│──│ PreviewFBO │ │
│  └──────────┘  └──────┬───────┘  └───────────┘ │
│                       │ 启动/停止                │
└───────────────────────┼─────────────────────────┘
                        │ QProcess
                        ▼
              ┌─────────────────┐
              │  blackhole.exe  │
              │  (OpenGL桌面渲染)│
              └─────────────────┘
```

---

## 一、项目结构

```
Blakhole_UI/
├── main.cpp                    # 入口, 注册C++类型到QML
├── Main.qml                    # 主窗口 (无边框, 缩放, 托盘)
├── src.qrc                     # Qt资源文件
│
├── core/
│   ├── blackholecore.h/cpp     # 核心: 配置管理 + 进程控制
│   ├── blackholepreviewfbo.h/cpp # FBO预览: OpenGL Shader渲染
│   └── systemtray.h/cpp        # 系统托盘
│
├── pages/
│   ├── BlackholeConfig.qml     # 黑洞配置页 (14个滑块 + 预设列表)
│   ├── AdvancedConfig.qml      # 高级设置页
│   ├── ScheduleConfig.qml      # 定时配置页
│   └── IdleListConfig.qml      # 空闲列表配置页
│
└── components/
    ├── ESlider.qml             # 通用滑块组件 (双属性架构)
    ├── EButton.qml             # 按钮组件
    ├── EBlurCard.qml           # 毛玻璃卡片
    ├── BlackholePreviewArea.qml # 小预览区域
    ├── BlackholeLargePreview.qml # 放大预览弹窗
    └── ...
```

---

## 二、配置数据流

### 2.1 参数传递链路

```
用户拖拽滑块
    │
    ▼
ESlider (userChanged信号)
    │ newValue
    ▼
BlackholeConfig.qml
    │ configPage.diskXxx = newValue
    │ bhCore.updateCurrentPresetParam("diskXxx", newValue)
    ▼
BlackHoleCore (C++)
    │ PresetModel::updateParam() → 更新内存数据
    │ refreshCurrentPresetProps() → emit currentPresetChanged()
    ▼
┌──────────────────┬──────────────────┐
│  实时预览更新     │   blackhole.exe  │
│  (Shader FBO)    │   (停止后重启)   │
└──────────────────┴──────────────────┘
```

### 2.2 14个可调参数

| QML属性 | C++属性 | Shader Uniform | 默认值 | 范围 |
|---------|---------|---------------|--------|------|
| diskTemp | diskTemp | uPresetTemp[0] | 5500 | 1000-30000 |
| diskIncl | diskIncl | uPresetIncl[0] | 1.50 | 0-3 |
| diskRoll | diskRoll | uPresetRoll[0] | 0.35 | -1~1 |
| diskInner | diskInner | uPresetInner[0] | 1.8 | 0.5-10 |
| diskOuter | diskOuter | uPresetOuter[0] | 8.0 | 1-30 |
| diskOpac | diskOpac | uPresetOpac[0] | 0.90 | 0-1 |
| diskDopp | diskDopp | uPresetDopp[0] | 0.60 | 0-1.5 |
| diskBeam | diskBeam | uPresetBeam[0] | 2.5 | 0.5-10 |
| diskGain | diskGain | uPresetGain[0] | 2.2 | 0-5 |
| diskContr | diskContr | uPresetContr[0] | 1.6 | 0-3 |
| diskWind | diskWind | uPresetWind[0] | 7.0 | 1-15 |
| diskSpeed | diskSpeed | uPresetSpd[0] | 5.0 | 0.5-10 |
| diskExpo | diskExpo | uPresetExpo[0] | 1.40 | 0.1-3 |
| diskStar | diskStar | uPresetStar[0] | 0.0 | 0-1 |

---

## 三、黑洞预览 (Shader FBO)

### 3.1 架构

```
QML BlackholePreviewArea
    │ 14个属性 (diskTemp/diskIncl/...)
    ▼
C++ BlackholePreviewFBO (QQuickFramebufferObject)
    │ setDiskXxx() → m_diskXxx → update()
    ▼
BlackholePreviewRenderer (Scene Graph 渲染线程)
    │ synchronize(): 拷贝参数到渲染线程
    │ render(): 设置uniform → glDrawArrays
    ▼
OpenGL Shader (blackhole_preview.glsl)
    │ 实时渲染黑洞 (引力透镜 + 吸积盘)
    ▼
屏幕显示
```

### 3.2 Shader文件

| 文件 | 用途 |
|------|------|
| `shaders/vert.glsl` | 顶点着色器 (全屏四边形) |
| `shaders/frag_preview_header.glsl` | 预览专用uniform声明 (无桌面纹理) |
| `shaders/blackhole_preview.glsl` | 预览shader主体 (← 修改了LOOK_DEFAULT) |
| `release/` 下同名文件 | 运行时加载副本 |

### 3.3 关键修复: LOOK_DEFAULT

原始shader中 `LOOK_DEFAULT` 使用 `const float` 编译期常量作为9个参数值，
导致C++传入的 `uPreset*[0]` uniform数组被忽略。

修复: 改为直接读取uniform数组:
```glsl
DiskLook LOOK_DEFAULT = DiskLook(
    uPresetTemp[0], uPresetIncl[0], uPresetRoll[0], ...);
```

### 3.4 Shader路径解析

`BlackholePreviewRenderer::resolveShaderPath()` 按以下顺序搜索:
1. `<appDir>/shaders/vert.glsl` + `<appDir>/blackhole_preview.glsl`
2. `<appDir>/release/shaders/` + `<appDir>/blackhole_preview.glsl`
3. 回退到相对路径 `shaders/vert.glsl`

---

## 四、预设管理系统

### 4.1 数据结构

```
m_allLists: QVector<QVector<PresetData>>   # 多个预设列表
m_listNames: QStringList                    # 列表名称
m_currentListIndex: int                     # 当前列表索引

每个列表:
  PresetData[0..N]: 预设数据
    - name: QString
    - diskTemp..diskStar: 14个float参数
```

### 4.2 预设操作

| 操作 | 槽函数 | 说明 |
|------|--------|------|
| 选择预设 | selectPreset(index) | 切换到指定索引的预设 |
| 修改参数 | updateCurrentPresetParam(param, value) | 实时更新当前预设参数 |
| 新建预设 | createPreset() | 复制当前预设创建新项 |
| 删除预设 | removePreset(index) | 至少保留1个 |
| 复制/粘贴 | copyPreset()/pastePreset() | 跨预设复制参数 |
| 拖拽排序 | movePreset(from, to) | 预设列表重排 |
| 恢复默认 | resetDefaults() | 比较并强制还原16个规范预设 |

### 4.3 配置文件格式 (blackhole_presets.txt)

```
# Blackhole Presets v4
0 300 5.250 1 0 0          # mode idleSec slotSec playMode videoAsIdle autoStart
16                          # 预设数量
Inferno                     # 预设名
5500 1.50 0.35 1.8 8.0 ...  # temp incl roll inner outer opac dopp beam gain contr wind speed expo star
Gargantua
4500 1.52 0.10 2.2 7.0 ...
...
```

写配置: `saveConfig()` → 保存到 `<appDir>/blackhole_presets.txt`  
读配置: `loadConfig()` → 从文件恢复所有列表和预设  
启动blackhole.exe时: 复制配置文件到exe所在目录

---

## 五、blackhole.exe 对接

### 5.1 启动流程

```
用户点击"启动黑洞"
    │
    ▼
BlackHoleCore::startRenderer()
    │
    ├─ saveConfig()              # 保存当前配置到文件
    ├─ 查找 blackhole.exe        # 多级上溯搜索
    ├─ 复制 blackhole_presets.txt 到 exe 目录
    └─ QProcess::start("blackhole.exe", ["--render"])
```

### 5.2 搜索路径

从 UI 的 appDir 开始，逐级上溯:
- `./blackhole.exe`
- `../blackhole.exe`
- `../../blackhole.exe`
- `../../../blackhole.exe`
- `../../../build/blackhole.exe`
- `../../../release/blackhole.exe`

### 5.3 停止

`stopRenderer()` → `QProcess::terminate()` (3秒超时) → `kill()`

---

## 六、ESlider 双属性架构

### 6.1 问题背景

ESlider 需要同时满足:
1. 用户拖拽时 → 实时更新预览 + 写入C++模型
2. 程序赋值时 (如预设切换) → 只更新UI, 不触发C++写入

原始 `onValueChanged` 无法区分这两种情况。

### 6.2 双属性方案

```
externalValue (接收外部绑定, 永不直接赋值)
    │ binding: externalValue: configPage.diskContr
    │ onExternalValueChanged → root.value = externalValue
    ▼
root.value (内部跟踪值)
    │ binding: Slider.value: root.value
    ▼
Slider (UI控件)
    │ 用户拖拽 → slider.pressed=true → userChanged信号
    ▼
外部处理: configPage.diskContr = newValue + updateCurrentPresetParam
```

### 6.3 关键信号

| 信号 | 触发条件 | 作用 |
|------|----------|------|
| userChanged(newValue) | 仅用户拖拽 (slider.pressed) | 传播到C++模型 |
| onExternalValueChanged | 外部绑定更新 | 同步内部value |
| onValueChanged | 内部value变化 | 同步Slider控件 |

---

## 七、关键修复记录

| 编号 | 问题 | 根因 | 修复方式 |
|------|------|------|----------|
| B1 | displayMode偏移 | C++默认值1→0 | 对齐blackhole.exe |
| B5 | 恢复默认重复创建 | initDefaultPresets()无条件追加 | 检测已是否存在 |
| B6 | 缺少删除配置按钮 | - | 新增deleteCurrentList() |
| B7 | 信号级联滑块不更新 | currentPresetChanged自触发14次 | m_refreshingProps防护 |
| B8 | 切换预设写入旧值 | onValueChanged无差别触发 | userChanged信号分流 |
| B9 | 拖拽后滑块不响应外部 | root.value赋值打破绑定 | 双属性externalValue |
| S1 | 预览参数不生效 | shader中const常量 | LOOK_DEFAULT改用uniform |