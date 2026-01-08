; ================================================================
; 微信小店达人自动邀约脚本 - 简洁版
; 功能：自动遍历达人列表，逐条点击邀约
; 使用方法：
; 1. 在脚本目录创建 images 文件夹
; 2. 截图7个按钮保存到 images/ 目录（参考 SNAPSHOT_GUIDE.md）
; 3. 在Chrome浏览器登录达人广场
; 4. 按F3启动，F4停止
; ================================================================

#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
SendMode Input
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen

; ================== 配置区域 ==================
IMAGES_DIR := A_ScriptDir . "\images"
INVITE_RECORD_FILE := A_ScriptDir . "\invite_record.txt"

; 等待时间（毫秒）
WAIT_CLICK := 1500      ; 点击后等待
WAIT_LOAD := 3000       ; 页面加载等待

; 循环控制
MAX_DAILY := 50         ; 每日最大邀约数量
MAX_RETRY := 3          ; 最大重试次数
TIMEOUT := 3000         ; 图像搜索超时
TOLERANCE := 30         ; 图像识别容差

; 状态变量
isRunning := false
inviteCount := 0
invitedTalents := {}
lastClickY := 0         ; 记录上一次点击Y坐标，避免重复

; ================== 图像文件名 ==================
IMAGE_DETAIL := "detail_button.png"         ; 详情按钮
IMAGE_INVITE := "invite_button.png"         ; 邀请带货按钮
IMAGE_ADD_PRODUCT := "add_product_button.png" ; 添加商品按钮
IMAGE_CONFIRM := "confirm_button.png"       ; 确认按钮
IMAGE_SEND := "send_invite_button.png"      ; 发送邀约按钮
IMAGE_SEND_CONFIRM := "confirm_send_button.png" ; 确认发送按钮
IMAGE_NEXT_PAGE := "next_page_button.png"     ; 下一页按钮

; ================== 热键 ==================
F3::
    if (!isRunning) {
        isRunning := true
        LoadRecord()
        MsgBox, 64, 启动, 开始运行...按F4停止, 2
        MainLoop()
    }
return

F4::
    isRunning := false
    MsgBox, 64, 停止, 已停止！邀约数量：%inviteCount%, 2
return

; ================== 主循环 ==================
MainLoop() {
    global isRunning, inviteCount, MAX_DAILY

    Loop {
        if (!isRunning or inviteCount >= MAX_DAILY) {
            break
        }
        
        ProcessPage()
        
        if (isRunning) {
            if (!NextPage()) {
                MsgBox, 64, 完成, 所有页面处理完成！, 2
                break
            }
        }
    }
    
    SaveRecord()
    isRunning := false
}

; ================== 处理当前页 ==================
ProcessPage() {
    global isRunning, MAX_RETRY, IMAGES_DIR, IMAGE_DETAIL, lastClickY
    
    lastClickY := 0
    
    Loop {
        if (!isRunning)
            break
        
        found := false
        
        Loop {
            if (FindAndClick(IMAGES_DIR . "\" . IMAGE_DETAIL, lastClickY)) {
                found := true
                MouseGetPos, x, y
                talentId := x . "_" . y
                lastClickY := y + 30
                
                if (!invitedTalents.HasKey(talentId)) {
                    if (InviteTalent(talentId)) {
                        inviteCount++
                        invitedTalents[talentId] := true
                        ToolTip, 已邀约: %inviteCount%, 10, 10
                    } else {
                        CloseTab()
                    }
                }
                
                Sleep, 500
                break
            }
        }
        
        if (!found) {
            ToolTip, 当前页处理完成, 10, 10
            Sleep, 1000
            ToolTip
            break
        }
    }
}

; ================== 邀约单个达人 ==================
InviteTalent(talentId) {
    global IMAGES_DIR, WAIT_CLICK, WAIT_LOAD
    
    Sleep, WAIT_LOAD
    
    ; 点击"邀请带货"
    if (!FindAndClick(IMAGES_DIR . "\" . IMAGE_INVITE)) {
        ToolTip, 未找到邀请带货按钮，跳过, 10, 10
        Sleep, 1000
        ToolTip
        CloseTab()
        return false
    }
    
    Sleep, WAIT_LOAD
    
    ; 点击"添加商品"
    if (!FindAndClick(IMAGES_DIR . "\" . IMAGE_ADD_PRODUCT)) {
        ToolTip, 未找到添加商品按钮, 10, 10
        Sleep, 1000
        ToolTip
        CloseTab()
        return false
    }
    
    Sleep, WAIT_CLICK
    
    ; 点击"确认"
    if (!FindAndClick(IMAGES_DIR . "\" . IMAGE_CONFIRM)) {
        ToolTip, 未找到确认按钮, 10, 10
        Sleep, 1000
        ToolTip
        CloseTab()
        return false
    }
    
    Sleep, WAIT_CLICK
    
    ; 点击"发送邀约"
    if (!FindAndClick(IMAGES_DIR . "\" . IMAGE_SEND)) {
        ToolTip, 未找到发送邀约按钮, 10, 10
        Sleep, 1000
        ToolTip
        CloseTab()
        return false
    }
    
    Sleep, WAIT_CLICK
    
    ; 点击"确认发送"
    if (!FindAndClick(IMAGES_DIR . "\" . IMAGE_SEND_CONFIRM)) {
        ToolTip, 未找到确认发送按钮, 10, 10
        Sleep, 1000
        ToolTip
        CloseTab()
        return false
    }
    
    Sleep, WAIT_CLICK
    
    ; Ctrl+W 关闭窗口
    CloseTab()
    
    return true
}

; ================== 翻页 ==================
NextPage() {
    global IMAGES_DIR, WAIT_LOAD, IMAGE_NEXT_PAGE
    
    if (!FindAndClick(IMAGES_DIR . "\" . IMAGE_NEXT_PAGE)) {
        ToolTip, 未找到下一页按钮, 10, 10
        Sleep, 2000
        ToolTip
        return false
    }
    
    Sleep, WAIT_LOAD
    return true
}

; ================== 关闭标签页 ==================
CloseTab() {
    Send, ^w
    Sleep, 500
}

; ================== 查找并点击图像 ==================
FindAndClick(imagePath, startY = 0) {
    global TOLERANCE, TIMEOUT
    
    if (!FileExist(imagePath)) {
        ToolTip, 图像不存在: %imagePath%, 10, 10
        return false
    }
    
    start := A_TickCount
    
    Loop {
        if ((A_TickCount - start) > TIMEOUT)
            break
        
        ImageSearch, x, y, 0, %startY%, A_ScreenWidth, A_ScreenHeight, *%TOLERANCE% %imagePath%
        
        if (ErrorLevel = 0) {
            x := x + 10
            y := y + 10
            MouseMove, x, y, 10
            Sleep, 100
            Click
            return true
        }
        
        Sleep, 100
    }
    
    return false
}

; ================== 记录管理 ==================
LoadRecord() {
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

SaveRecord() {
    global invitedTalents, INVITE_RECORD_FILE
    
    content := ""
    for id in invitedTalents {
        content := content . id . "`n"
    }
    FileDelete, %INVITE_RECORD_FILE%
    FileAppend, %content%, %INVITE_RECORD_FILE%
}
