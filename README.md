# 微信小店达人自动邀约脚本

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![AutoHotKey](https://img.shields.io/badge/AutoHotKey-1.1+-green.svg)](https://www.autohotkey.com/)

## 功能介绍

这个脚本用于自动在微信小店的达人广场页面邀请达人带货，支持：

- ✅ 自动遍历达人列表
- ✅ 自动点击详情、邀请带货、添加商品、发送邀约、确认发送邀约
- ✅ 避免重复邀约（记录已邀约达人）
- ✅ 自动翻页处理
- ✅ 每日邀约数量限制（防止被封）
- ✅ 失败自动重试机制
- ✅ 使用 Ctrl+W 关闭窗口（不依赖按钮位置）
- ✅ 两种版本：坐标版和图像识别版

## 版本说明

### 1. 坐标版 (wechat_talent_invite.ahk)
- 使用固定坐标点击按钮
- 适合屏幕分辨率固定的环境
- 需要使用Window Spy调整坐标
- 配置简单，首次运行需要调整坐标

### 2. 图像识别版 (wechat_talent_v2_image.ahk) ⭐ 推荐
- 使用按钮截图进行图像识别
- 更稳定，不依赖固定坐标
- 需要先截取8个按钮的图片（7个必需）
- 适应性强，支持不同分辨率
- 使用 Ctrl+W 关闭窗口（更可靠）

## 使用方法

### 第一步：安装AutoHotKey

1. 下载并安装 AutoHotKey：https://www.autohotkey.com/
2. 确保安装后可以运行 .ahk 文件

### 第二步：准备脚本

#### 如果你选择坐标版：
- 直接使用 `wechat_talent_invite.ahk`
- 首次运行需要调整坐标配置（见下方"坐标配置"）

#### 如果你选择图像识别版（推荐）：
1. 在脚本目录创建 `images` 文件夹
2. 参照 `SNAPSHOT_GUIDE.md` 截取7个按钮的图片
3. 确保图片命名正确并放在 `images/` 目录下

### 第三步：运行脚本

1. 打开Chrome浏览器，登录微信小店
2. 进入达人广场页面
3. 确保浏览器窗口在前台（不要最小化）
4. 双击运行脚本（.ahk文件）
5. 按 **F3** 启动脚本
6. 按 **F4** 停止脚本

## 坐标配置（仅坐标版需要）

**重要**：首次使用前必须调整坐标配置。

### 使用Window Spy获取坐标
1. 安装AutoHotKey后，运行 "Window Spy"（开始菜单搜索）
2. 将鼠标移动到各个按钮上，记录下坐标
3. 修改脚本中的以下坐标变量：

```autohotkey
; 达人广场页面
DETAIL_BUTTON_X := 1200      ; 详情按钮X坐标
LIST_START_Y := 300          ; 达人列表起始Y坐标
LIST_ITEM_HEIGHT := 120      ; 每个达人项的高度

; 达人详情页
INVITE_BUTTON_X := 1200      ; 邀请带货按钮X坐标
INVITE_BUTTON_Y := 300       ; 邀请带货按钮Y坐标

; 邀约页
ADD_PRODUCT_BUTTON_X := 600  ; 添加上次邀约商品按钮X坐标
ADD_PRODUCT_BUTTON_Y := 400  ; 添加上次邀约商品按钮Y坐标
CONFIRM_BUTTON_X := 700      ; 确认按钮X坐标
CONFIRM_BUTTON_Y := 500      ; 确认按钮Y坐标
SEND_INVITE_BUTTON_X := 800  ; 发送邀约按钮X坐标
SEND_INVITE_BUTTON_Y := 600  ; 发送邀约按钮Y坐标

; 翻页
NEXT_PAGE_BUTTON_X := 1300   ; 下一页按钮X坐标
NEXT_PAGE_BUTTON_Y := 800    ; 下一页按钮Y坐标

; 关闭页面
CLOSE_BUTTON_X := 1600       ; 关闭标签页按钮X坐标
CLOSE_BUTTON_Y := 50         ; 关闭标签页按钮Y坐标
```

## 配置选项

脚本开头有以下可配置选项：

```autohotkey
; 邀约记录文件路径
INVITE_RECORD_FILE := A_ScriptDir . "\invite_record.txt"

; 等待时间（毫秒）
WAIT_TIME_CLICK := 1500      ; 普通点击后的等待时间
WAIT_TIME_PAGE_LOAD := 3000  ; 页面加载等待时间
WAIT_TIME_INVITE := 2000     ; 发送邀约后的等待时间
DELAY_CLICK := 500           ; 点击之间的延迟

; 循环控制
MAX_DALIY_INVITE := 50       ; 每日最大邀约数量
MAX_RETRY := 3               ; 每个操作最大重试次数
```

### 调整建议：
- **网络较慢**：增加 WAIT_TIME_PAGE_LOAD 到 4000-5000
- **电脑性能较差**：增加所有 WAIT_TIME_* 参数
- **避免被封**：减少 MAX_DALIY_INVITE 到 20-30
- **更稳定的运行**：增加 DELAY_CLICK 到 800-1000

## 脚本执行流程

```
开始 → 进入达人广场 → 点击"详情"
  ↓
进入达人详情页 → 查找"邀请带货"按钮
  ↓
[分支判断]
  ├─ 找到邀约按钮 → 进入邀约流程
  │                 ↓
  │               点击"添加上次邀约商品"
  │                 ↓
  │               点击"确认" → 点击"发送邀约"
  │                 ↓
  │               点击"确认发送邀约" → Ctrl+W 关闭页面
  │                 ↓
  │               返回达人广场 → 继续下一个达人
  │
  └─ 未找到邀约按钮 → Ctrl+W 关闭页面 → 跳过该达人 → 继续下一个达人
                      （该达人可能已邀约或不支持邀约）
```

### ⚠️ 跳过逻辑说明
- 如果达人详情页没有"邀请带货"按钮（可能是已邀约或不支持邀约），脚本会：
  1. 显示"未找到邀约按钮，跳过该达人"提示
  2. 执行 Ctrl+W 关闭当前窗口
  3. 不重试，直接继续处理下一个达人
  4. 不计入失败次数

## 注意事项

### ⚠️ 重要提示
1. **首次运行务必在小范围测试**：建议先设置 MAX_DALIY_INVITE := 5 测试流程
2. **保持浏览器在前台**：脚本需要操作鼠标，浏览器必须在最前面
3. **不要干扰脚本运行**：运行期间不要移动鼠标或切换窗口
4. **检查邀约记录**：邀约记录保存在 invite_record.txt，可查看已邀约达人
5. **避免被平台限制**：
   - 建议每日邀约不超过50个
   - 邀约之间保持合理时间间隔
   - 避免短时间大量邀约

## 常见问题

**Q: 脚本点击位置不对怎么办？**
A:
- 坐标版：使用Window Spy获取准确坐标，修改脚本中的坐标配置
- 图像版：参考 SNAPSHOT_GUIDE.md 重新截图

**Q: 页面加载慢导致脚本失败？**
A: 增加 WAIT_TIME_PAGE_LOAD 参数的值

**Q: 如何重新开始邀约？**
A: 删除 invite_record.txt 文件，重新运行脚本

**Q: 脚本会重复邀约同一个达人吗？**
A: 不会，脚本会记录已邀约达人ID，自动跳过

**Q: 如何暂停脚本？**
A: 按 F4 停止脚本，再次按 F3 重新启动

**Q: 可以同时运行多个Chrome窗口吗？**
A: 不建议，确保只有一个Chrome窗口在达人广场页面

## 故障排查

### 1. 脚本启动但没反应
- 检查Chrome是否在前台
- 检查坐标配置是否正确（坐标版）
- 检查按钮截图是否正确（图像版）
- 使用Window Spy确认按钮位置

### 2. 脚本运行到一半停止
- 可能是网络问题，增加等待时间
- 可能是页面元素变化，需要更新坐标/截图

### 3. 重复邀约
- 删除invite_record.txt重新开始
- 检查记录功能是否正常工作

### 4. 图像识别失败
- 检查截图是否清晰
- 检查截图是否包含了按钮的关键特征
- 尝试调整 IMAGE_TOLERANCE 容差值

## 文件说明

```
.
├── wechat_talent_invite.ahk       # 坐标版脚本
├── wechat_talent_v2_image.ahk     # 图像识别版脚本（推荐）
├── README.md                      # 本文件
├── SNAPSHOT_GUIDE.md              # 图像截图指南
├── images/                        # 按钮截图目录（图像版需要）
│   ├── detail_button.png
│   ├── invite_button.png
│   ├── add_product_button.png
│   ├── confirm_button.png
│   ├── send_invite_button.png
│   ├── next_page_button.png
│   └── close_tab_button.png
└── invite_record.txt              # 邀约记录（自动生成）
```

## 系统要求

- **操作系统**：Windows 7/8/10/11
- **AutoHotKey版本**：v1.1+ 或 v2.0+
- **浏览器**：Chrome（推荐）
- **屏幕分辨率**：建议 1920x1080 或更高
- **浏览器缩放**：建议 100%

## 免责声明

- 本脚本仅供学习和个人使用
- 使用本脚本产生的任何后果由用户自行承担
- 请遵守微信小店的使用规则
- 建议在合规范围内使用

## 技术支持

如遇到问题，请检查：
1. AutoHotKey版本（建议v1.1+）
2. 浏览器缩放比例（建议100%）
3. 屏幕分辨率（建议1920x1080）
4. 网络连接稳定性

## 开源协议

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

---

**祝使用愉快！**
