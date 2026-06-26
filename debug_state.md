 # Debug State - Ghostty Blackhole
 
 ## 1. 问题分析
 
 ### 项目结构
 - `blackhole.glsl` — 主着色器文件（Ghostty 运行时加载，无需编译）
 - `claude-token.py` — Python 脚本（Claude Code 桥接，可在 Windows 调试）
 - `tuner/` — macOS SwiftUI 应用（Windows 不可编译）
 - `make-app.sh` — macOS 打包脚本
 - `.vscode/launch.json` — 已存在，残留了一个无关的 Cortex Debug 配置
 
 ### 目标
 配置 VS Code F5 编译调试环境。
 由于项目不含传统可编译代码（C/C++/Rust），需要：
 1. 删除残留的 Cortex Debug 配置
 2. 添加 claude-token.py 的 Python 调试配置
 3. 添加 GLSL 语法检查任务
 4. 推荐相关扩展
 
 ## 2. 解决计划
 
 | 步骤 | 说明 |
|------|------|
| 1 | 创建 `debug_state.md`（本文件） |
| 2 | 修改 `launch.json`：删除 Cortex Debug，添加 Python 调试/运行配置 |
| 3 | 创建 `tasks.json`：添加 Python 检查、运行任务 |
| 4 | 创建 `extensions.json`：推荐 GLSL 语法扩展 |
| 5 | 创建 `settings.json`：设置 Python 路径、编码等 |
| 6 | 验证配置 |
 
 ## 3. 修改状态
 
 - [x] 步骤 1：创建 debug_state.md
 - [x] 步骤 2：修改 launch.json
 - [x] 步骤 3：创建 tasks.json
 - [x] 步骤 4：创建 extensions.json
 - [x] 步骤 5：创建 settings.json
 - [x] 步骤 6：配置完成
