; ================================================================
; 微信小店达人广场自动邀约脚本 - 图像识别版
; 优势：使用图像识别，不依赖固定坐标，更稳定
; 使用说明：
; 1. 首次运行需要截图各个按钮，保存到 images/ 目录
; 2. 在Chrome浏览器登录好达人广场页面
; 3. 按F3启动脚本，按F4停止脚本
; ================================================================

#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SendMode Input
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

; ================== 配置区域 ==================
; 图像文件路径
IMAGES_DIR := A_ScriptDir . "\images"

; 邀约记录文件路径
INVITE_RECORD_FILE := A_ScriptDir . "\invite_record.txt"

; 图像识别容差（0-255，越大越宽松）
IMAGE_TOLERANCE := 30

; 各按钮点击后的等待时间（毫秒）
WAIT_TIME_CLICK := 1500      ; 普通点击后的等待时间
WAIT_TIME_PAGE_LOAD := 3000  ; 页面加载等待时间
WAIT_TIME_INVITE := 2000     ; 发送邀约后的等待时间

; 延迟设置
DELAY_CLICK := 500           ; 点击之间的延迟

; 循环控制
MAX_DALIY_INVITE := 50       ; 每日最大邀约数量
MAX_RETRY := 3               ; 每个操作最大重试次数
MAX_IMAGE_SEARCH_TIME := 3000  ; 图像搜索超时时间

; ================== 状态变量 ==================
isRunning := false
inviteCount := 0
currentPage := 1
invitedTalents := {}
failedCount := 0
failedList := ""
lastClickY := 0  ; 记录上一次点击的Y坐标，避免重复处理

; ================== 图像文件名配置 ==================
; 这些文件需要在 images/ 目录下存在
IMAGE_DETAIL_BTN := "detail_button.png"          ; 详情按钮
IMAGE_INVITE_BTN := "invite_button.png"          ; 邀请带货按钮
IMAGE_ADD_PRODUCT_BTN := "add_product_button.png"  ; 添加商品按钮
IMAGE_CONFIRM_BTN := "confirm_button.png"        ; 确认按钮
IMAGE_SEND_INVITE_BTN := "send_invite_button.png"  ; 发送邀约按钮
IMAGE_CONFIRM_SEND_BTN := "confirm_send_button.png"  ; 确认发送邀约按钮
IMAGE_NEXT_PAGE_BTN := "next_page_button.png"    ; 下一页按钮
IMAGE_CLOSE_TAB_BTN := "close_tab_button.png"    ; 关闭标签按钮（已弃用，使用Ctrl+W）

; ================== 热键定义 ==================
F3::
    if (!isRunning) {
        StartScript()
    }
return

F4::
    if (isRunning) {
        StopScript()
    }
return

; ================== 主逻辑 ==================

; 启动脚本
StartScript() {
    global isRunning

    ; 检查图像目录
    if (!FileExist(IMAGES_DIR)) {
        MsgBox, 16, 错误, 未找到 images/ 目录！`n`n请按照以下步骤操作：`n1. 在脚本目录创建 images 文件夹`n2. 截图各个按钮并保存到 images/ 目录`n3. 文件名必须与脚本中定义的相同
        return
    }

    ; 检查必需的图像文件
    requiredImages := IMAGE_DETAIL_BTN . "," . IMAGE_INVITE_BTN . "," . IMAGE_ADD_PRODUCT_BTN . "," . IMAGE_CONFIRM_BTN . "," . IMAGE_SEND_INVITE_BTN . "," . IMAGE_CONFIRM_SEND_BTN . "," . IMAGE_NEXT_PAGE_BTN . "," . IMAGE_CLOSE_TAB_BTN

    missingImages := ""
    Loop, Parse, requiredImages, `,
    {
        imagePath := IMAGES_DIR . "\" . A_LoopField
        if (!FileExist(imagePath)) {
            missingImages := missingImages . A_LoopField . "`n"
        }
    }

    if (missingImages != "") {
        MsgBox, 16, 错误, 缺少以下图像文件：`n`n%missingImages%`n请确保所有按钮截图都已保存到 images/ 目录
        return
    }

    isRunning := true

    MsgBox, 64, 脚本启动, 微信小店达人邀约脚本（图像识别版）已启动！`n`n提示：`n1. 请确保Chrome浏览器已在达人广场页面`n2. 请确保浏览器窗口在前台`n3. 按F4可随时停止脚本`n`n3秒后开始运行...,, 3

    ; 加载邀约记录
    LoadInviteRecord()

    ; 开始主循环
    MainLoop()
}

; 停止脚本
StopScript() {
    global isRunning
    isRunning := false

    ; 保存邀约记录
    SaveInviteRecord()

    MsgBox, 64, 脚本停止, 脚本已停止！`n`n本次邀约数量：%inviteCount%`n失败数量：%failedCount%,, 5
}

; 主循环
MainLoop() {
    global isRunning, inviteCount, currentPage, MAX_DALIY_INVITE

    Loop {
        if (!isRunning)
            break

        if (inviteCount >= MAX_DALIY_INVITE) {
            MsgBox, 64, 提示, 已达到每日最大邀约数量 %MAX_DALIY_INVITE%！`n脚本将停止运行。,, 3
            isRunning := false
            break
        }

        ; 获取当前页面的达人列表
        ProcessCurrentPage()

        ; 检查是否需要翻页
        if (isRunning) {
            currentPage++
            ToolTip, 翻到第 %currentPage% 页..., 10, 10
            if (!GoToNextPage()) {
                MsgBox, 64, 提示, 已处理完所有页面！`n脚本将停止运行。,, 3
                isRunning := false
            }
        }
    }
}

; 处理当前页面的所有达人
ProcessCurrentPage() {
    global isRunning, inviteCount, MAX_RETRY, IMAGES_DIR, IMAGE_DETAIL_BTN, lastClickY

    ; 重置起始搜索位置
    lastClickY := 0

    ; 在当前页面循环查找并点击"详情"按钮
    Loop {
        if (!isRunning)
            break

        ; 尝试在当前页面查找下一个"详情"按钮
        found := false
        retryCount := 0

        Loop {
            if (retryCount >= MAX_RETRY)
                break

            ; 查找"详情"按钮（从上一次点击位置下方开始搜索，避免重复）
            if (FindAndClickImage(IMAGES_DIR . "\" . IMAGE_DETAIL_BTN, lastClickY)) {
                found := true

                ; 获取点击位置作为达人ID（简化处理）
                MouseGetPos, clickedX, clickedY
                talentId := currentPage . "_" . clickedX . "_" . clickedY

                ; 记录本次点击的Y坐标（加20像素偏移，避免重复点击同一个）
                lastClickY := clickedY + 20

                ; 检查是否已经邀约过
                if (!IsAlreadyInvited(talentId)) {
                    ; 邀约该达人
                    success := false
                    retryInvite := 0

                    Loop {
                        if (retryInvite >= MAX_RETRY)
                            break

                        result := InviteTalent(talentId)
                        if (result = true) {
                            success := true
                            break
                        } else if (result = -1) {
                            ; 跳过该达人（没有邀约按钮），不要重试
                            ToolTip, 已跳过一个无邀约按钮的达人, 10, 10
                            Sleep, 500
                            ToolTip
                            break
                        } else {
                            ; 失败，重试
                            retryInvite++
                            Sleep, 1000
                        }
                    }

                    if (success) {
                        inviteCount++
                        ToolTip, 已邀约: %inviteCount% 个达人, 10, 10
                    } else if (result != -1) {
                        ; 只有在不是跳过的情况下才计入失败
                        failedCount++
                        failedList := failedList . "第" . currentPage . "页某个达人`n"

                        ; 尝试返回达人广场
                        TryReturnToSquare()
                    }
                } else {
                    ToolTip, 跳过已邀约达人, 10, 10
                }

                Sleep, DELAY_CLICK
                break
            } else {
                ; 未找到"详情"按钮，可能已经处理完当前页
                retryCount++
                Sleep, 500
            }
        }

        if (!found) {
            ToolTip, 当前页面已处理完成, 10, 10
            Sleep, 1000
            ToolTip
            break
        }
    }
}

; 邀约单个达人
InviteTalent(talentId) {
    global IMAGES_DIR, WAIT_TIME_CLICK, WAIT_TIME_PAGE_LOAD, WAIT_TIME_INVITE

    ; 步骤1：已在ProcessCurrentPage中点击"详情"，等待页面加载
    Sleep, WAIT_TIME_PAGE_LOAD

    ; 步骤2：查找并点击"邀请带货"按钮
    if (!FindAndClickImage(IMAGES_DIR . "\" . IMAGE_INVITE_BTN)) {
        ToolTip, 未找到邀约按钮，跳过该达人, 10, 10
        Sleep, 1500
        ToolTip
        ; 使用Ctrl+W关闭窗口，跳过该达人
        CloseCurrentTab()
        ; 返回-1表示跳过（不是失败，不要重试）
        return -1
    }

    Sleep, WAIT_TIME_PAGE_LOAD

    ; 步骤3：查找并点击"添加上次邀约商品"按钮
    if (!FindAndClickImage(IMAGES_DIR . "\" . IMAGE_ADD_PRODUCT_BTN)) {
        ToolTip, 未找到添加商品按钮, 10, 10
        Sleep, 1000
        ToolTip
        CloseCurrentTab()
        return false
    }

    Sleep, WAIT_TIME_CLICK

    ; 步骤4：查找并点击"确认"按钮
    if (!FindAndClickImage(IMAGES_DIR . "\" . IMAGE_CONFIRM_BTN)) {
        ToolTip, 未找到确认按钮, 10, 10
        Sleep, 1000
        ToolTip
        CloseCurrentTab()
        return false
    }

    Sleep, WAIT_TIME_CLICK

    ; 步骤5：查找并点击"发送邀约"按钮
    if (!FindAndClickImage(IMAGES_DIR . "\" . IMAGE_SEND_INVITE_BTN)) {
        ToolTip, 未找到发送邀约按钮, 10, 10
        Sleep, 1000
        ToolTip
        CloseCurrentTab()
        return false
    }

    Sleep, WAIT_TIME_CLICK

    ; 步骤6：查找并点击"确认发送邀约"按钮
    if (!FindAndClickImage(IMAGES_DIR . "\" . IMAGE_CONFIRM_SEND_BTN)) {
        ToolTip, 未找到确认发送邀约按钮, 10, 10
        Sleep, 1000
        ToolTip
        CloseCurrentTab()
        return false
    }

    Sleep, WAIT_TIME_INVITE

    ; 步骤7：关闭当前标签页（使用 Ctrl+W）
    if (!CloseCurrentTab()) {
        return false
    }

    Sleep, WAIT_TIME_CLICK

    ; 记录已邀约的达人
    RecordInvitedTalent(talentId)

    return true
}

; 翻页到下一页
GoToNextPage() {
    global IMAGES_DIR, WAIT_TIME_PAGE_LOAD

    if (!FindAndClickImage(IMAGES_DIR . "\" . IMAGE_NEXT_PAGE_BTN)) {
        ToolTip, 未找到下一页按钮，可能已到最后一页, 10, 10
        Sleep, 2000
        ToolTip
        return false
    }

    Sleep, WAIT_TIME_PAGE_LOAD
    return true
}

; 关闭当前标签页
CloseCurrentTab() {
    global WAIT_TIME_CLICK

    ; 使用快捷键 Ctrl+W 关闭当前标签页
    ; 注意：不使用图像识别方式，因为关闭按钮位置可能变化
    Send, ^w
    Sleep, WAIT_TIME_CLICK
    return true
}

; 尝试返回达人广场
TryReturnToSquare() {
    ; 等待一段时间让用户手动处理
    Sleep, 2000
    ; 或者按ESC键关闭弹窗
    Send, {Esc}
    Sleep, 1000
}

; 查找并点击图像
; startY: 可选参数，指定搜索起始Y坐标（用于避免重复点击）
FindAndClickImage(imagePath, startY = 0) {
    global IMAGE_TOLERANCE, MAX_IMAGE_SEARCH_TIME

    if (!FileExist(imagePath)) {
        ToolTip, 图像文件不存在：%imagePath%, 10, 10
        return false
    }

    startTime := A_TickCount

    Loop {
        ; 检查是否超时
        if ((A_TickCount - startTime) > MAX_IMAGE_SEARCH_TIME) {
            ToolTip, 查找图像超时，3秒后重试, 10, 10
            Sleep, 3000
            ToolTip
            return false
        }

        ; 搜索图像（从指定Y坐标开始搜索，避免重复）
        ImageSearch, foundX, foundY, 0, %startY%, A_ScreenWidth, A_ScreenHeight, *%IMAGE_TOLERANCE% %imagePath%

        if (ErrorLevel = 0) {
            ; 找到图像，点击
            foundX := foundX + 10  ; 点击图像中心偏右一点
            foundY := foundY + 10
            MouseMove, foundX, foundY, 10
            Sleep, 200
            Click
            return true
        } else if (ErrorLevel = 1) {
            ; 未找到图像，继续搜索
            Sleep, 200
        } else {
            ; 图像加载失败
            ToolTip, 图像加载失败，3秒后重试, 10, 10
            Sleep, 3000
            ToolTip
            return false
        }
    }
}

; ================== 邀约记录管理 ==================

; 检查是否已经邀约过
IsAlreadyInvited(talentId) {
    global invitedTalents
    return invitedTalents.HasKey(talentId)
}

; 记录已邀约的达人
RecordInvitedTalent(talentId) {
    global invitedTalents
    invitedTalents[talentId] := true
}

; 加载邀约记录
LoadInviteRecord() {
    global invitedTalents, INVITE_RECORD_FILE

    if (FileExist(INVITE_RECORD_FILE)) {
        FileRead, content, %INVITE_RECORD_FILE%
        Loop, Parse, content, `n
        {
            if (A_LoopField != "") {
                invitedTalents[A_LoopField] := true
            }
        }
    }
}

; 保存邀约记录
SaveInviteRecord() {
    global invitedTalents, INVITE_RECORD_FILE

    content := ""
    for talentId, value in invitedTalents {
        content := content . talentId . "`n"
    }

    FileDelete, %INVITE_RECORD_FILE%
    FileAppend, %content%, %INVITE_RECORD_FILE%
}
