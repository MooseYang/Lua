
local MeleeUI = {}
local MeleeManager = require "Lua.PlayModuleUI.MeleeUI.MeleeManager"
require "Lua.Define.ClientDefine"
require "Lua.Utils.utils"
require "Lua.Define.PropDefine"
--离开按钮
local CloseBtn
--剩余时间文本
local SurplusTime
--收缩按钮
local ShrinkObj
--左边排行榜
local LeftObj
--积分排名Grid
local Grid
--方向控制变量
local bDirection = false
--结算倒计时
local lTime
--连杀播报文本容器
local Broadcastlist
--当前等待播报容器
local WaitingList = {}
--等待延时销毁容器
local WaitingDes = {}
--状态位
local bBroadcast = true
--击杀数文本
local KillLab = nil
--被杀数文本
local DeadLab = nil
--奖励root
local AwardObj = nil
--奖励本地配置
local ConfigAward = {}
--积分文本
local IntegralLab = nil
--道具
local Itemobj = nil
--我当前的积分
local Integral = 0
local bInit = false
--动画延时时间
local TimeDelay = 0
--特效
local HangupEffect
--初始化函数
function MeleeUI.OnStart()
    CS.ResourceTool.LoadBytesConfig(PATH_CONFIG_MINMELEESCOREAWARD, MeleeUI.LoadMeleeIntegralAwardConfig)
    CloseBtn = MeleeUI.self:GetChildObject("LogicRight/ExitBtn")
    SurplusTime = MeleeUI.self:GetChildUI("UILabel", "LogicRight/UI/ExitTime")
    ShrinkObj = MeleeUI.self:GetChildObject("LogicLeft/Root/MoveBtn")
    LeftObj = MeleeUI.self:GetChildObject("LogicLeft/Root")
    Grid = MeleeUI.self:GetChildUI("UIGrid", "LogicLeft/Root/scrollview/grid")
    Grid:BindCustomCallBack(MeleeUI.UpdateRankItem)
    Grid:StartCustom()
    Broadcastlist = {}
    local lab = MeleeUI.self:GetChildUI("UILabel", "BroadcastObj/Broadcast1")
    lab.gameObject:SetActive(false)
    table.insert(Broadcastlist, 1, lab)
    --[[lab = self:GetChildUI("UILabel", "BroadcastObj/Broadcast2")
    lab.text = ""
    table.insert(Broadcastlist, 1, lab)
    lab = self:GetChildUI("UILabel", "BroadcastObj/Broadcast3")
    lab.text = ""
    table.insert(Broadcastlist, 1, lab)]]
    KillLab = MeleeUI.self:GetChildUI("UILabel", "LogicLeft/Root/MyRecord/kill/Num")
    DeadLab = MeleeUI.self:GetChildUI("UILabel", "LogicLeft/Root/MyRecord/Dead/Num")
    AwardObj = MeleeUI.self:GetChildObject("LogicRight/Award")
    IntegralLab = MeleeUI.self:GetChildUI("UILabel", "LogicRight/Award/Value")
    Itemobj = MeleeUI.self:GetChildUI("UIGridItem", "LogicRight/Award/OnlineRewardUI/Solt")
end
--显示函数
function MeleeUI.OnShow(obj)
    local flagInfo=CS.FlagWarInfo()
    flagInfo.PosX=-24.26--args:GetFloat(3)
    flagInfo.Posz=10--args:GetFloat(4)
    flagInfo.AreaRadius=25
    flagInfo.iWidth=82
    flagInfo.iHight=82
    flagInfo.bArea=true
    flagInfo.strID="Platoon_DoubleArea"
    flagInfo.strIcon="Platoon_DoubleArea"
    flagInfo.Name=CS.TextManager.GetString("Melee_Area")
    CS.FlagWarManager.SetFlag(CS.EFLAGSTATE.E_UpdatePos,flagInfo)
    CS.PropTool.BindProp(CS.UnitManager.mRole, Prop_ffa_kill_num, MeleeUI.KillNumChange)
    CS.PropTool.BindProp(CS.UnitManager.mRole, Prop_ffa_Dead_num, MeleeUI.DeadNumChange)
    CS.PropTool.BindProp(CS.UnitManager.mRole, Prop_ffa_target_reward_idx, MeleeUI.AwardChange)
    MeleeManager.RegistCustomCall(E_SERVER_CUSTOMMSG_SUB_FFA_SETTLE, MeleeUI.OpenResultUI)
    if SurplusTime ~= nil then
        SurplusTime.gameObject:SetActive(false)
    end
end
--点击函数
function MeleeUI.OnClick(sender, param)
    if sender == CloseBtn then
        CS.SystemHintUI.ShowMsgBox(
            CS.TextManager.GetUIString("UI_Common_009"),
            CS.TextManager.GetUIString("Melee_Tips"),
            CS.PromptState.CANCEL,
            MeleeUI.CloseThis
        )
    elseif sender == ShrinkObj then
        MeleeUI.SetLeftDirection()
    end
end
--击杀数变化
function MeleeUI.KillNumChange(unit, prop)
    if KillLab ~= nil then
        local b1, num = unit.mDataObject:QueryPropInt(Prop_ffa_kill_num)
        KillLab.text = tostring(num)
    end
end
--死亡数变化
function MeleeUI.DeadNumChange(unit, prop)
    if DeadLab ~= nil then
        local b1, num = unit.mDataObject:QueryPropInt(Prop_ffa_Dead_num)
        DeadLab.text = tostring(num)
    end
end
--奖励变化
function MeleeUI.AwardChange(unit, prop)
    if AwardObj == nil then
        return
    end
    local b1, index = unit.mDataObject:QueryPropInt(Prop_ffa_target_reward_idx)
    local data = ConfigAward[index]
    if data ~= nil then
        AwardObj.gameObject:SetActive(true)
        Itemobj.oData = data
        MeleeUI.ItemChange(Itemobj)
    else
        AwardObj.gameObject:SetActive(false)
    end
end
--更新道具
function MeleeUI.ItemChange(item)
    if (item == nil or item.mScripts == nil or item.oData == nil) then
        return
    end
    local Info = item.oData
    if Info == nil then
        return
    end
    local Jifen = item.mScripts[0]
    local Color = item.mScripts[1]
    local Effect = item.mScripts[2]
    local Awardsheet = CS.TaskManager.GetAwardById(Info.AwardId)
    local SimpleDatalist = CS.AwardManager.ToList(Awardsheet)
    local itemdata = SimpleDatalist[0]
    local ItemInfo = CS.ItemTool.CompletionItem(itemdata.strID, itemdata.iCount, itemdata.bBind, itemdata.iQuality)
    CS.ItemObjectShow.ItemShowUI(ItemInfo, item.transform, CS.ItemLableType.E_NORMAL, nil, false, false)
    Jifen.text = tostring(Info.Integral)
    if Info.Integral < Integral then
        Effect.gameObject:SetActive(true)
    else
        Effect.gameObject:SetActive(false)
    end
    CS.UIEventListener.Get(item.gameObject).onClick = MeleeUI.ClickItem
end
--点击道具
function MeleeUI.ClickItem(obj)
    local item = FindInParents("UIGridItem", obj)
    if (item == nil or item.oData == nil) then
        return
    end
    local var = CS.VarBank.CreateVarBank()
    var:AddInt(CLIENT_CUSTOMMSG_FREE_FOR_ALL)
    var:AddInt(E_CLIENT_CUSTOMMSG_SUB_FFA_TARGET_REWARD)
    CS.CommandTool.LuaSend(var)
end
--退出
function MeleeUI.CloseThis()
    CS.GUITool.DestroyView("MeleeUI")
    local var = CS.VarBank.CreateVarBank()
    var:AddInt(CLIENT_CUSTOMMSG_FREE_FOR_ALL)
    var:AddInt(E_CLIENT_CUSTOMMSG_SUB_FFA_QUIT)
    CS.CommandTool.LuaSend(var)
end
--打开结算界面
function MeleeUI.OpenResultUI(var)
    if not (CS.GUITool.HasView("MeleeResultUI")) then
        CS.GUITool.ShowView("MeleeResultUI", var)
    end
end
--更新积分榜
function MeleeUI.UpdateRank(var)
    if Grid == nil then
        return
    end
    local count = (var:GetCount() - 3) / 3
    local index = 3
    local list = {}
    for i = 1, count do
        local data = {}
        data.Rank = i
        data.TeamId = var:GetString(index)
        index = index + 1
        data.TeamCaptain = var:GetString(index)
        index = index + 1
        data.Integral = var:GetString(index)
        index = index + 1
        local bMyTeam = CS.TeamTableManager.IsLeaderByName(data.TeamCaptain)
        if bMyTeam == true then
            Integral = tonumber(data.Integral)
        end
        list[#list + 1] = data
    end
    MeleeUI.ItemChange(Itemobj)
    Grid:UpdateCustomDataList(list)
end
--更新item
function MeleeUI.UpdateRankItem(item)
    if (item == nil or item.mScripts == nil or item.oData == nil) then
        return
    end
    local Info = item.oData
    if Info == nil then
        return
    end
    local rank = item.mScripts[0]
    local name = item.mScripts[1]
    local Jifen = item.mScripts[2]
    rank.text = tostring(Info.Rank)
    name.text = Info.TeamCaptain
    Jifen.text = Info.Integral
end
--更新准备倒计时
function MeleeUI.UpdateprepareTime(lTime)
    if lTime <= 0 then
        return
    end
    if (not (CS.GUITool.HasView("BattleCountdownUI"))) then
        local VAR = CS.VarBank.CreateVarBank()
        VAR:AddInt(lTime)
        VAR:AddObject(nil)
        VAR:AddInt(0)
        VAR:AddInt(10)
        VAR:AddString("Melee_TimeValue")
        CS.GUITool.ShowView("BattleCountdownUI", VAR)
    end
end
--设置播放队列
function MeleeUI.SetBroadcastQue(var)
    local info = {}
    info.name = var:GetString(3)
    info.num = var:GetInt(4)
    info.bEnd = false
    if info.num == 3 or info.num == 5 or info.num >= 7 then
        if info.num > 7 then
            info.num = 7
        end
        if not (CS.TimerTool.IsHaveTimer("UpdateAnimon")) then
            CS.TimerTool.AddTimerRepeat("UpdateAnimon", 0.02, MeleeUI.UpdateAnimon)
        end
        --[[if bBroadcast then
            SetBroadcast(info)
        else
        end]]
        WaitingList[#WaitingList + 1] = info
    end
end
--设置终结播放队列
function MeleeUI.SetBroadcastQueEnd(var)
    local info = {}
    info.name = var:GetString(3)
    info.name1 = var:GetString(4)
    local type = var:GetInt(5)
     --终结类型
    if type == 1 then
        info.num = 3
    elseif type == 2 then
        info.num = 5
    elseif type == 3 then
        info.num = 7
    end
    info.bEnd = true
    --[[if bBroadcast then
        SetBroadcast(info)
    else
    end]]
    if not (CS.TimerTool.IsHaveTimer("UpdateAnimon")) then
        CS.TimerTool.AddTimerRepeat("UpdateAnimon", 0.02, MeleeUI.UpdateAnimon)
    end
    WaitingList[#WaitingList + 1] = info
end
--设置播放效果
function MeleeUI.SetBroadcast(info)
    bBroadcast = false
    local obj = Broadcastlist[1]
    obj.gameObject:SetActive(true)
    --[[if #Broadcastlist <= 0 then
        local loca = WaitingDes[#WaitingDes]
        local loca1 = loca.Obj
        CS.TimerTool.Destroy(loca1.name)
        table.insert(Broadcastlist, 1, loca1)
        table.remove(WaitingDes, #WaitingDes)
    end
    --local obj = Broadcastlist[1]
    table.remove(Broadcastlist, 1)
    info.Obj = obj
    table.insert(WaitingDes, 1, info)
    Sort()]]
    --obj.transform.localScale = CS.UnityEngine.Vector3.one * 2
    --obj.transform.localPosition = CS.UnityEngine.Vector3(0, 0, 0)
    local endlab = obj.transform:Find("End"):GetComponent("UILabel")
    if not (info.bEnd) then
        obj.text = CS.TextManager.GetString(table.concat({"Melee_Broadcast_", info.num}), info.name)
        endlab.text = ""
    else
        obj.text = ""
        endlab.text = CS.TextManager.GetString(table.concat({"Melee_BroadcastEnd_", info.num}), info.name, info.name1)
    end
    if HangupEffect ~= nil then
        CS.CacheObjects.DestroyClone(HangupEffect)
    end
    if info.bEnd then
        return
    end
    local parent = obj.transform:Find("Effect")
    local EffectName = ""
    if info.num == 3 then
        EffectName = "UI_dashatesha"
    elseif info.num == 5 then
        EffectName = "UI_sharenruma"
    elseif info.num == 7 then
        EffectName = "UI_chaoshen"
    end
    CS.GUITool.InstantiateUIEffectCustom(
        parent,
        obj,
        EffectName,
        CS.UnityEngine.Vector3.one,
        CS.UnityEngine.Vector3.zero,
        MeleeUI.CallEffect,
        -1,
        1,
        1
    )
    --local tween = CS.TweenScale.Begin(obj.gameObject, 0.3, CS.UnityEngine.Vector3.one * 0.5)
    --tween.method = CS.UITweener.Method.EaseInOut
    --CS.TimerTool.AddTimer("MoveCallBack", 0.3, MoveCallBack)
end
function MeleeUI.CallEffect(go)
    HangupEffect = go
end
--更新播报动画
function MeleeUI.UpdateAnimon()
    local num = #WaitingList
    if not (bBroadcast) then
        TimeDelay = TimeDelay + 0.02
        if num > 5 then
            if TimeDelay < 0.75 then
                return
            else
                bBroadcast = true
                table.remove(WaitingList, 1)
            end
        else
            if TimeDelay < 1.5 then
                return
            else
                bBroadcast = true
                table.remove(WaitingList, 1)
            end
        end
    end
    if #WaitingList == 0 then
        local obj = Broadcastlist[1]
        if obj ~= nil then
            obj.gameObject:SetActive(false)
        end
        return
    end
    TimeDelay = 0
    local info = WaitingList[1]
    MeleeUI.SetBroadcast(info)
end
--[[播放效果结束 刷新排序
function MoveCallBack()
    CS.TimerTool.Destroy("MoveCallBack")
    bBroadcast = true
    if #WaitingList > 0 and #WaitingDes < 4 then
        local info = WaitingList[1]
        table.remove(WaitingList, 1)
        SetBroadcast(info)
    end
end]]
--[[展示效果结束 刷新排序
function ShowMoveCallBack(args)
    local obj = args[0].Obj
    obj.text = ""
    table.insert(Broadcastlist, 1, obj)
    table.remove(WaitingDes, #WaitingDes)
end]]
--[[排序
function Sort()
    for i, value in ipairs(WaitingDes) do
        local obj = value.Obj
        obj.transform.localPosition = CS.UnityEngine.Vector3(0, 0 + (i - 1) * 50, 0)
    end
end]]
--打开倒计时
function MeleeUI.OpenTime(Time)
    lTime = tonumber(Time)
    MeleeUI.UpdateTime(lTime)
    CS.TimerTool.AddTimerRepeat("UpdateTime", 1, MeleeUI.UpdateTime)
end
--更新倒计时
function MeleeUI.UpdateTime()
    if SurplusTime ~= nil then
        SurplusTime.gameObject:SetActive(true)
    end
    if lTime <= 0 then
        CS.TimerTool.Destroy("UpdateTime")
        return
    end
    local iDay, iHour, iMinute, iSecond = CS.GameTimeManager.ConvertSecondToDate(lTime)
    if SurplusTime ~= nil then
        if (iDay == 0 and iHour == 0 and iMinute == 0 and iSecond <= 30) then
            SurplusTime.text = CS.TextManager.GetString("PKCopy_SurplusTime2", iMinute, iSecond)
        else
            SurplusTime.text = CS.TextManager.GetString("PKCopy_SurplusTime", iMinute, iSecond)
        end
    end
    lTime = lTime - 1
end
--设置排行榜缩进缩出
function MeleeUI.SetLeftDirection()
    if not (bDirection) then
        CS.TweenPosition.Begin(LeftObj, 0.3, CS.UnityEngine.Vector3(358, LeftObj.transform.localPosition.y, 0))
        CS.TimerTool.AddTimer("PeerageBattleLeftObjTweenTime", 0.3,MeleeUI.Left)
        bDirection = not (bDirection)
    else
        MeleeUI.Right()
    end
end
--向左
function MeleeUI.Left()
    ShrinkObj.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, -90)
    CS.TweenPosition.Begin(ShrinkObj, 0.5, CS.UnityEngine.Vector3(-347, ShrinkObj.transform.localPosition.y, 0))
end
--向右
function MeleeUI.Right()
    ShrinkObj.transform.eulerAngles = CS.UnityEngine.Vector3(0, 0, 90)
    ShrinkObj.transform.localPosition = CS.UnityEngine.Vector3(-383.5, ShrinkObj.transform.localPosition.y, 0)
    CS.TweenPosition.Begin(LeftObj, 0.3, CS.UnityEngine.Vector3(639, LeftObj.transform.localPosition.y, 0))
    bDirection = not (bDirection)
end
--销毁函数
function MeleeUI.OnDestroy()
    CS.TimerTool.Destroy("UpdateAnimon")
    --CS.TimerTool.Destroy("MoveCallBack")
    --CS.TimerTool.Destroy("ShowMoveCallBack")
    CS.TimerTool.Destroy("UpdateTime")
    CS.PropTool.UnBindProp(CS.UnitManager.mRole, Prop_ffa_kill_num, MeleeUI.KillNumChange)
    CS.PropTool.UnBindProp(CS.UnitManager.mRole, Prop_ffa_Dead_num, MeleeUI.DeadNumChange)
    CS.PropTool.UnBindProp(CS.UnitManager.mRole, Prop_ffa_target_reward_idx, MeleeUI.AwardChange)
    if HangupEffect ~= nil then
        CS.CacheObjects.DestroyClone(HangupEffect)
    end
    if Grid ~= nil then
        Grid:ClearAllData()
    end
    if (CS.GUITool.HasView("BattleCountdownUI")) then
        CS.GUITool.DestroyView("BattleCountdownUI")
    end
    Index = 1
    MeleeManager.UnRegistCustomCall(E_SERVER_CUSTOMMSG_SUB_FFA_SETTLE)
end
--加载大乱斗积分奖励配置
function MeleeUI.LoadMeleeIntegralAwardConfig(asset, obj)
    local MeleeInfo = nil
    ConfigAward = {}
    if nil ~= asset then
        local ass = asset
        if nil ~= ass then
            for i, n in pairs(ass) do
                MeleeInfo = {}
                MeleeInfo.Integral = n:GetIntValue("NeedTeamScore")
                MeleeInfo.AwardId = n:GetStringValue("AwardId")
                ConfigAward[i] = MeleeInfo
            end
        end
    end
end
return MeleeUI
