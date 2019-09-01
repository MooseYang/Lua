
local MeleeResultUI={}
require "Lua.Utils.utils"
local MeleeManager= require "Lua.PlayModuleUI.MeleeUI.MeleeManager"
--排名grid
local RankGrid
--背景
local FormTex
--确认按钮
local CloseObj
--我的队伍积分文本
local MyTeamIntegralLab
--我的队伍排名文本
local MyTeamRankLab

function MeleeResultUI.OnStart()
    RankGrid = MeleeResultUI.self:GetChildUI("UIGrid", "scrollview/grid")
    RankGrid:BindCustomCallBack(MeleeResultUI.UpdateRank)
    RankGrid:StartCustom()
    FormTex = MeleeResultUI.self:GetChildUI("UITexture", "From")
    CloseObj = MeleeResultUI.self:GetChildObject("closeBtn")
    MyTeamIntegralLab = MeleeResultUI.self:GetChildUI("UILabel", "MyJiFen")
    MyTeamRankLab = MeleeResultUI.self:GetChildUI("UILabel", "MyRank")
end
function MeleeResultUI.OnShow(obj)
    RankGrid:ClearCustomData()
    local time=obj:GetInt(3)
    local count = (obj:GetCount() - 4) / 3
    local index = 4
    local myIntegral=0
    local myRank=0
    for i = 1, count do
        local data = {}
        data.Rank = i
        data.TeamId = obj:GetInt(index)
        index = index + 1
        data.TeamCaptain = obj:GetString(index)
        index = index + 1
        data.Integral = obj:GetString(index)
        index = index + 1
        if CS.TeamTableManager.IsInTeamByName(data.TeamCaptain)==true then
            myIntegral=data.Integral
            myRank=data.Rank
        end
        RankGrid:AddCustomData(data)
    end
    obj:Destroy()
    RankGrid:UpdateCustomView()
    if MyTeamIntegralLab~=nil then
        MyTeamIntegralLab.text=CS.TextManager.GetString("Melee_MyTeamIntegral",myIntegral)
    end
    if MyTeamRankLab~=nil then
        MyTeamRankLab.text=CS.TextManager.GetString("Melee_MyTeamRank",myRank)
    end
    CS.TimerTool.AddTimerCount("MeleeResultUICount",time,MeleeResultUI.UpdateTime)
end
function MeleeResultUI.UpdateTime( count,args )
    if count<=0 then
        CS.GUITool.DestroyView("MeleeResultUI")
    end
end
function MeleeResultUI.OnClick(sender, param)
    if sender == CloseObj then
        CS.GUITool.DestroyView("MeleeResultUI")
        local var = CS.VarBank.CreateVarBank()
        var:AddInt(CLIENT_CUSTOMMSG_FREE_FOR_ALL)
        var:AddInt(E_CLIENT_CUSTOMMSG_SUB_FFA_QUIT)
        CS.CommandTool.LuaSend(var)
    end
end
--更新信息
function MeleeResultUI.UpdateRank(item)
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
    local my = item.mScripts[3]
    local ItemGrid = item.mScripts[6]
    rank.text = tostring(Info.Rank)
    name.text = Info.TeamCaptain
    Jifen.text = Info.Integral
    my.gameObject:SetActive(CS.TeamTableManager.IsInTeamByName(Info.TeamCaptain))
    ItemGrid:BindCustomCallBack(MeleeResultUI.UpdateItem)
    ItemGrid:StartCustom()
    local localInfo=MeleeManager.GetlocalRankInfoBuyRank(Info.Rank)
    if localInfo==nil then
        return
    end
    local Awardsheet=CS.TaskManager.GetAwardById(localInfo.AwardId)
    local SimpleDatalist=CS.AwardManager.ToList(Awardsheet)
    for i,value in pairs(SimpleDatalist) do
        local ItemInfo=CS.ItemTool.CompletionItem(value.strID, value.iCount, value.bBind, value.iQuality)
        ItemGrid:AddCustomData(ItemInfo)
    end
    ItemGrid:UpdateCustomView()
end
--更新信息
function MeleeResultUI.UpdateItem(item)
    if (item == nil or item.mScripts == nil or item.oData == nil) then
        return
    end
    local info = item.oData
    if (info == nil) then
        return
    end
    local Grid = FindInParents("UIGrid", item.gameObject)
    CS.ItemObjectShow.ItemShowUI(
        info,
        item.transform,
        CS.ItemLableType.E_SHOW_MYCOUNT_CUSTOM_ZERO,
        nil,
        true,
        true,
        Grid:GetShaderClicpRange(),
        RankGrid:GetShaderClicpRange()
    )
    CS.UIEventListener.Get(item.gameObject).onClick = MeleeResultUI.ClickItem
end
function MeleeResultUI.ClickItem(go)
    local item = FindInParents("UIGridItem", go)
    if (item == nil or item.oData == nil) then
        return
    end
    CS.ItemTipsUI.ShowTips(item.oData)
end
function MeleeResultUI.OnDestroy()
    if (FormTex ~= nil) then
        CS.CacheObjects.PopCache(FormTex.material)
    end
    if RankGrid ~= nil then
        RankGrid:ClearAllData()
    end
    CS.GUITool.DestroyView("MeleeUI")
    CS.TimerTool.Destroy("MeleeResultUICount")
end
return MeleeResultUI
