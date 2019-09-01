
local MeleeBeginUI={}
local MeleeManager= require "Lua.PlayModuleUI.MeleeUI.MeleeManager"
require "Lua.Define.ClientDefine"
--进入按钮
local CheerObj
--规则按钮
local RuleObj
--奖励按钮
local AwardObj
--倒计时文本
local TimeLab
--进入按钮文本
local EnterLab
--退出按钮
local CloseObj
--背景底
local UIFormBg1
--背景底
local UIFormBg2
--倒计时
local fTime = 0

function MeleeBeginUI.OnStart()
    CheerObj = MeleeBeginUI.self:GetChildObject("FunctionBtn")
    RuleObj = MeleeBeginUI.self:GetChildObject("Guize")
    AwardObj = MeleeBeginUI.self:GetChildObject("award")
    TimeLab = MeleeBeginUI.self:GetChildUI("UILabel", "Time")
    UIFormBg1 = MeleeBeginUI.self:GetChildUI("UITexture", "UIFrame/UIFrame/UIBack/UIFrameMaterial")
    UIFormBg2 = MeleeBeginUI.self:GetChildUI("UITexture", "UIFrame/UIFrame/UIBack/bg")
    if TimeLab ~= nil then
        TimeLab.text = ""
    end
    EnterLab = MeleeBeginUI.self:GetChildUI("UILabel", "FunctionBtn/FunctionLab")
    CloseObj = MeleeBeginUI.self:GetChildObject("closeBtn")
    CS.HelpTools.SetMainTexture(UIFormBg1, "Textures/Melee/tlzhch01")
    CS.HelpTools.SetMainTexture(UIFormBg2, "Textures/PeerageTex/jwzb_rcd")
end

function MeleeBeginUI.OnShow(obj)
    if (TimeLab ~= null) then
        TimeLab.text = string.Empty
    end
    if (EnterLab ~= null) then
        EnterLab.text = CS.TextManager.GetString("Melee_ToOpen")
    end
    MeleeManager.RegistCustomCall(E_SERVER_CUSTOMMSG_SUB_FFA_READY_TIME, MeleeBeginUI.BeginTime)
    local var = CS.VarBank.CreateVarBank()
    var:AddInt(CLIENT_CUSTOMMSG_FREE_FOR_ALL)
    var:AddInt(E_CLIENT_CUSTOMMSG_SUB_FFA_QUERY_READY_TIME)
    CS.CommandTool.LuaSend(var)
end
function MeleeBeginUI.OnClick(sender, param)
    if (sender == CloseObj) then
        CS.GUITool.DestroyView("MeleeBeginUI")
    elseif (sender == RuleObj) then
        CS.GUITool.ShowView("HelpUI", "MeleeBeginUI")
    elseif (sender == AwardObj) then
        CS.GUITool.ShowView("MeleeAwardUI")
    elseif (sender == CheerObj) then
        if (not(CS.TeamTableManager.IsExitTeam())) then --判断是否组队
            CS.SystemHintUI.ShowMsgBox(
                CS.TextManager.GetUIString("UI_Common_009"),
                CS.TextManager.GetString("Melee_Tips1"),
                CS.PromptState.CANCEL,
                MeleeBeginUI.TeanCall,nil,MeleeBeginUI.Enter,nil,false,0,"Team_AddTeam","Melee_Enter"
            )
        else
            MeleeBeginUI.Enter()
        end
    end
end
 function MeleeBeginUI.TeanCall()
    local var = CS.VarBank.CreateVarBank()
    var:AddInt(CS.DefineClient.CLIENT_CUSTOMMSG_TEAM)
    var:AddInt("1")
    var:AddString(table.concat( {"4","0"}, ","))
    var:AddString(table.concat( {"60","-1"}, ","))
    CS.CommandTool.LuaSend(var)
    if (not(CS.GUITool.HasView("TeamUI"))) then
        CS.GUITool.ShowView("TeamUI", "1")
    end
end
 function MeleeBeginUI.Enter()
    local var = CS.VarBank.CreateVarBank()
    var:AddInt(CLIENT_CUSTOMMSG_FREE_FOR_ALL)
    var:AddInt(E_CLIENT_CUSTOMMSG_SUB_FFA_ENTRY)
    CS.CommandTool.LuaSend(var)
end
--[[
	/// <summary>
	/// 开启倒计时
    /// </summary>
    ]]
function MeleeBeginUI.BeginTime(var)
    fTime = var:GetInt(3)
    MeleeBeginUI.UpdateTime()
    CS.TimerTool.AddTimerRepeat("MeleeBeginUITime", 1, MeleeBeginUI.UpdateTime)
end
--更新倒计时
function MeleeBeginUI.UpdateTime()
    if fTime <= 0 then
        if (EnterLab ~= null) then
            EnterLab.text = CS.TextManager.GetString("Team_EnterGame")
        end
        if (TimeLab ~= null) then
            TimeLab.text = ""
        end
        return
    end
    fTime = fTime - 1
    --服务器0点之后总秒数
    local iDay, iHour, iMinute, iSecond = CS.GameTimeManager.ConvertSecondToDate(fTime)
    if (TimeLab == null) then
        return
    end
    if (iDay > 0) then
        TimeLab.text = CS.TextManager.GetString("Peerage_BattleTime", iDay, iHour)
    elseif (iHour > 0) then
        TimeLab.text = CS.TextManager.GetString("Peerage_BattleTime1", iHour, iMinute)
    else
        TimeLab.text = CS.TextManager.GetString("Peerage_BattleTime2", iMinute, iSecond)
    end
end

function MeleeBeginUI.OnDestroy()
    if (UIFormBg1 ~= nil) then
        CS.CacheObjects.PopCache(UIFormBg1.material)
    end
    if (UIFormBg2 ~= nil) then
        CS.CacheObjects.PopCache(UIFormBg2.material)
    end
    MeleeManager.UnRegistCustomCall(E_SERVER_CUSTOMMSG_SUB_FFA_READY_TIME)
    CS.TimerTool.Destroy("MeleeBeginUITime")
end
return MeleeBeginUI
