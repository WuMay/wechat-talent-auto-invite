; ================================================================
; 微信小店达人广场自动邀约脚本
; 使用说明：
; 1. 在Chrome浏览器登录好达人广场页面
; 2. 按F3启动脚本
; 3. 按F4停止脚本
; 4. 首次运行需要调整各按钮的坐标位置
; ================================================================

#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SendMode Input
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

; ================== 配置区域 ==================
; 邀约记录文件路径（用于记录已邀约的达人，避免重复）
INVITE_RECORD_FILE := A_ScriptDir . "\invite_record.txt"

; 各按钮点击后的等待时间（毫秒）
WAIT_TIME_CLICK := 1500      ; 普通点击后的等待时间
WAIT_TIME_PAGE_LOAD := 3000  ; 页面加载等待时间
WAIT_TIME_INVITE := 2000     ; 发送邀约后的等待时间

; 延迟设置（根据网络情况调整）
DELAY_CLICK := 500           ; 点击之间的延迟

; 循环控制
MAX_DALIY_INVITE := 50       ; 每日最大邀约数量（防止被封）
MAX_RETRY := 3               ; 每个操作最大重试次数

; ================== 状态变量 ==================
isRunning := false
inviteCount := 0
currentPage := 1
invitedTalents := {}
failedList := ""

; ================== 坐标配置 ==================
; 注意：这些坐标需要根据你的屏幕分辨率和浏览器缩放比例进行调整
; 建议使用AutoHotKey的Window Spy工具获取准确坐标

; 达人广场页面相关坐标
LIST_START_Y := 300          ; 达人列表起始Y坐标（第一个达人）
LIST_ITEM_HEIGHT := 120      ; 每个达人项的高度
DETAIL_BUTTON_X := 1200      ; 详情按钮X坐标
DETAIL_BUTTON_Y_OFFSET := 20 ; 详情按钮Y坐标偏移量

; 达人详情页相关坐标
INVITE_BUTTON_X := 1200      ; 邀请带货按钮X坐标
INVITE_BUTTON_Y := 300       ; 邀请带货按钮Y坐标

; 邀约页相关坐标
ADD_PRODUCT_BUTTON_X := 600  ; 添加上次邀约商品按钮X坐标
ADD_PRODUCT_BUTTON_Y := 400  ; 添加上次邀约商品按钮Y坐标
CONFIRM_BUTTON_X := 700      ; 确认按钮X坐标
CONFIRM_BUTTON_Y := 500      ; 确认按钮Y坐标
SEND_INVITE_BUTTON_X := 800  ; 发送邀约按钮X坐标
SEND_INVITE_BUTTON_Y := 600  ; 发送邀约按钮Y坐标
CONFIRM_SEND_BUTTON_X := 900  ; 确认发送邀约按钮X坐标
CONFIRM_SEND_BUTTON_Y := 700  ; 确认发送邀约按钮Y坐标

; 翻页相关坐标
NEXT_PAGE_BUTTON_X := 1300   ; 下一页按钮X坐标
NEXT_PAGE_BUTTON_Y := 800    ; 下一页按钮Y坐标

; 关闭页面相关坐标
CLOSE_BUTTON_X := 1600       ; 关闭标签页按钮X坐标（右上角）
CLOSE_BUTTON_Y := 50         ; 关闭标签页按钮Y坐标

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
    isRunning := true

    MsgBox, 64, 脚本启动, 微信小店达人邀约脚本已启动！`n`n提示：`n1. 请确保Chrome浏览器已在达人广场页面`n2. 请确保浏览器窗口在前台`n3. 按F4可随时停止脚本`n`n3秒后开始运行...,, 3

    ; 加载邀约记录
    LoadInviteRecord()

    ; 开始主循环
    MainLoop()
}

; 停止脚本
StopScript() {
    global isRunning
    isRunning := false
    MsgBox, 64, 脚本停止, 脚本已停止！`n`n本次邀约数量：%inviteCount%`n失败数量：%failedCount%,, 5

    ; 保存邀约记录
    SaveInviteRecord()
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
            if (!GoToNextPage()) {
                MsgBox, 64, 提示, 已处理完所有页面！`n脚本将停止运行。,, 3
                isRunning := false
            }
        }
    }
}

; 处理当前页面的所有达人
ProcessCurrentPage() {
    global isRunning, inviteCount, LIST_START_Y, LIST_ITEM_HEIGHT
    global DETAIL_BUTTON_X, DETAIL_BUTTON_Y_OFFSET, MAX_RETRY

    currentItemIndex := 0
    hasMoreItems := true

    Loop {
        if (!isRunning || !hasMoreItems)
            break

        ; 计算当前达人的位置
        itemY := LIST_START_Y + (currentItemIndex * LIST_ITEM_HEIGHT)
        detailButtonY := itemY + DETAIL_BUTTON_Y_OFFSET

        ; 检查是否超出页面范围
        if (itemY > 800) {
            hasMoreItems := false
            break
        }

        ; 获取达人唯一标识（这里简化为Y坐标，实际可以读取达人名称）
        talentId := currentPage . "_" . itemY

        ; 检查是否已经邀约过
        if (IsAlreadyInvited(talentId)) {
            currentItemIndex++
            Sleep, 200
            continue
        }

        ; 处理单个达人
        retryCount := 0
        success := false

        Loop {
            if (retryCount >= MAX_RETRY)
                break

            if (InviteTalent(itemY, detailButtonY, talentId)) {
                success := true
                break
            } else {
                retryCount++
                Sleep, 1000
            }
        }

        if (success) {
            inviteCount++
            ToolTip, 已邀约: %inviteCount% 个达人, 10, 10
            Sleep, DELAY_CLICK
        } else {
            global failedList
            failedCount := failedCount + 1
            failedList := failedList . "第" . currentPage . "页第" . (currentItemIndex + 1) . "个达人`n"

            ; 尝试返回达人广场
            TryReturnToSquare()
        }

        currentItemIndex++
    }
}

; 邀约单个达人
InviteTalent(itemY, detailButtonY, talentId) {
    ; 步骤1：点击详情按钮进入达人详情页
    if (!ClickAt(DETAIL_BUTTON_X, detailButtonY, "点击详情")) {
        return false
    }

    Sleep, WAIT_TIME_PAGE_LOAD

    ; 步骤2：在达人详情页点击"邀请带货"
    global INVITE_BUTTON_X, INVITE_BUTTON_Y
    if (!ClickAt(INVITE_BUTTON_X, INVITE_BUTTON_Y, "点击邀请带货")) {
        CloseCurrentTab()
        return false
    }

    Sleep, WAIT_TIME_PAGE_LOAD

    ; 步骤3：点击"添加上次邀约商品"
    global ADD_PRODUCT_BUTTON_X, ADD_PRODUCT_BUTTON_Y
    if (!ClickAt(ADD_PRODUCT_BUTTON_X, ADD_PRODUCT_BUTTON_Y, "添加上次邀约商品")) {
        CloseCurrentTab()
        return false
    }

    Sleep, WAIT_TIME_CLICK

    ; 步骤4：点击确认按钮
    global CONFIRM_BUTTON_X, CONFIRM_BUTTON_Y
    if (!ClickAt(CONFIRM_BUTTON_X, CONFIRM_BUTTON_Y, "点击确认")) {
        CloseCurrentTab()
        return false
    }

    Sleep, WAIT_TIME_CLICK

    ; 步骤5：点击发送邀约
    global SEND_INVITE_BUTTON_X, SEND_INVITE_BUTTON_Y
    if (!ClickAt(SEND_INVITE_BUTTON_X, SEND_INVITE_BUTTON_Y, "发送邀约")) {
        CloseCurrentTab()
        return false
    }

    Sleep, WAIT_TIME_CLICK

    ; 步骤6：点击确认发送邀约
    global CONFIRM_SEND_BUTTON_X, CONFIRM_SEND_BUTTON_Y
    if (!ClickAt(CONFIRM_SEND_BUTTON_X, CONFIRM_SEND_BUTTON_Y, "确认发送邀约")) {
        CloseCurrentTab()
        return false
    }

    Sleep, WAIT_TIME_INVITE

    ; 步骤7：关闭当前页面（使用 Ctrl+W）
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
    global NEXT_PAGE_BUTTON_X, NEXT_PAGE_BUTTON_Y

    if (!ClickAt(NEXT_PAGE_BUTTON_X, NEXT_PAGE_BUTTON_Y, "翻到下一页")) {
        return false
    }

    Sleep, WAIT_TIME_PAGE_LOAD
    return true
}

; 关闭当前标签页
CloseCurrentTab() {
    ; 使用快捷键 Ctrl+W 关闭当前标签页
    ; 注意：不使用坐标点击方式，因为关闭按钮位置可能变化
    Send, ^w
    Sleep, 1000
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

; 在指定坐标点击
ClickAt(x, y, description) {
    MouseMove, x, y, 10
    Sleep, 200
    Click
    Sleep, 500
    return true
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
