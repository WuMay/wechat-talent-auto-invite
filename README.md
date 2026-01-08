# 微信小店达人自动邀约脚本

简洁实用的自动化脚本，用于在微信小店达人广场自动发送带货邀请。

## 功能特点

- ✅ 自动遍历达人列表，逐条邀约
- ✅ 自动翻页处理
- ✅ 避免重复邀约
- ✅ 简洁高效，无需复杂配置

## 快速开始

### 1. 准备按钮截图

在脚本目录创建 `images` 文件夹，并放入7个按钮截图：

```
your-folder/
├── wechat_talent_invite.ahk
├── images/
│   ├── detail_button.png         # 详情按钮
│   ├── invite_button.png         # 邀请带货按钮
│   ├── add_product_button.png   # 添加商品按钮
│   ├── confirm_button.png       # 确认按钮
│   ├── send_invite_button.png    # 发送邀约按钮
│   ├── confirm_send_button.png  # 确认发送按钮
│   └── next_page_button.png     # 下一页按钮
```

详细截图说明请参考 `SNAPSHOT_GUIDE.md`

### 2. 运行脚本

1. 安装 AutoHotKey：https://www.autohotkey.com/
2. 打开Chrome浏览器，登录微信小店，进入达人广场
3. 双击运行 `wechat_talent_invite.ahk`
4. 按 **F3** 启动
5. 按 **F4** 停止

## 工作流程

```
达人广场 → 点击"详情"
    ↓
达人详情页 → 点击"邀请带货"
    ↓
邀约页 → 点击"添加上次邀约商品"
    ↓
点击"确认"
    ↓
点击"发送邀约"
    ↓
点击"确认发送" → Ctrl+W 关闭窗口
    ↓
回到达人广场 → 下一个达人
    ↓
当前页完成 → 翻页 → 继续处理
```

## 配置选项

脚本开头可调整以下参数：

```autohotkey
; 等待时间（毫秒）
WAIT_CLICK := 1500      ; 点击后等待
WAIT_LOAD := 3000       ; 页面加载等待

; 循环控制
MAX_DAILY := 50         ; 每日最大邀约数量
MAX_RETRY := 3          ; 最大重试次数
TIMEOUT := 3000         ; 图像搜索超时
TOLERANCE := 30         ; 图像识别容差
```

### 调整建议

- **网络较慢**：增加 `WAIT_LOAD` 到 4000-5000
- **避免被封**：减少 `MAX_DAILY` 到 20-30
- **识别不准确**：调整 `TOLERANCE` 容差值

## 注意事项

1. **首次测试**：建议先设置 `MAX_DAILY := 5` 测试流程
2. **保持浏览器在前台**：脚本需要操作鼠标
3. **不要干扰运行**：运行期间不要移动鼠标或切换窗口
4. **避免被封**：
   - 建议每日邀约不超过50个
   - 邀约之间保持合理时间间隔

## 常见问题

**Q: 脚本找不到按钮？**
A: 检查截图是否正确，参考 `SNAPSHOT_GUIDE.md` 重新截图

**Q: 页面加载慢导致失败？**
A: 增加 `WAIT_LOAD` 参数

**Q: 如何重新开始？**
A: 删除 `invite_record.txt` 文件

**Q: 会重复邀约吗？**
A: 不会，脚本会记录已邀约达人

## 文件说明

```
.
├── wechat_talent_invite.ahk      # 主脚本
├── README.md                     # 本文档
├── SNAPSHOT_GUIDE.md             # 截图指南
├── images/                       # 按钮截图目录
└── invite_record.txt             # 邀约记录（自动生成）
```

## 免责声明

- 本脚本仅供学习和个人使用
- 使用本脚本产生的任何后果由用户自行承担
- 请遵守微信小店的使用规则
