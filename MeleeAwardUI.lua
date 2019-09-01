
local MeleeAwardUI={}
require "Lua.Utils.utils"
local MeleeManager = require "Lua.PlayModuleUI.MeleeUI.MeleeManager"

local BtnType = {["Rank"] = 0 --[[排行奖励]], ["Integral"] = 1 --[[积分奖励]]}

--关闭按钮
local closeObj
--奖励grid
local awardGrid
--页签组
local VerticalTab = nil

--初始化函数
function MeleeAwardUI.OnStart()
    closeObj = MeleeAwardUI.self:GetChildObject("CloseObj")
    awardGrid = MeleeAwardUI.self:GetChildUI("UIGrid", "AwardScrollView/Grid")
    awardGrid:BindCustomCallBack(MeleeAwardUI.UpdateItem)
    awardGrid:StartCustom()
    VerticalTab = MeleeAwardUI.self:GetChildUI("SingleSelectionButton", "Btn")
end
--显示函数
function MeleeAwardUI.OnShow(obj)
    MeleeAwardUI.InitSet(BtnType.Rank)
end
--点击函数
function MeleeAwardUI.OnClick(sender, obj)
    if sender == closeObj then
        CS.GUITool.DestroyView("MeleeAwardUI")
    end
end
--初始化设置函数
function MeleeAwardUI.InitSet(index)
    VerticalTab:Init()
    VerticalTab.touchEvent = MeleeAwardUI.on_TabClickCallBack
    VerticalTab:SetCurrentIndex(index)
    MeleeAwardUI.on_TabClickCallBack(index, nil)
end
--点击页签函数
function MeleeAwardUI.on_TabClickCallBack(index, go)
    local Tab = {[BtnType.Rank] = MeleeAwardUI.ClickRank, [BtnType.Integral] = MeleeAwardUI.ClickIntegral}
    return switch(Tab, index)
end
--点击排名页签
function MeleeAwardUI.ClickRank()
    local localInfoList = MeleeManager.GetlocalInfoRankList()
    if localInfoList == nil then
        return false
    end
    awardGrid:ClearCustomData()
    for i, value in pairs(localInfoList) do
        awardGrid:AddCustomData(value)
    end
    awardGrid:UpdateCustomView()
    return true
end
--点击积分页签
function MeleeAwardUI.ClickIntegral()
    local localInfoList = MeleeManager.GetlocalInfoIntegralList()
    if localInfoList == nil then
        return false
    end
    awardGrid:ClearCustomData()
    for i, value in ipairs(localInfoList) do
        awardGrid:AddCustomData(value)
    end
    awardGrid:UpdateCustomView()
    return true
end
--更新item
function MeleeAwardUI.UpdateItem(item)
    if item == nil or item.oData == nil or item.mScripts == nil then
        return
    end
    local info = item.oData
    if info == nil then
        return
    end
    local Itemlist = {}
    local Awardsheet = CS.TaskManager.GetAwardById(info.AwardId)
    local list = {}
    local SimpleDatalist = CS.AwardManager.ToList(Awardsheet)
    for i, value in pairs(SimpleDatalist) do
        list[#list + 1] = value
    end
    local ItemGrid = item.mScripts[0]
    if ItemGrid ~= nil then
        ItemGrid:BindCustomCallBack(MeleeAwardUI.OnUpdateAwardGrid)
        ItemGrid.bTwoGrid=true
        ItemGrid:UpdateCustomDataList(list)
    end
    local TopThere = item.mScripts[1]
    local NoTopThere = item.mScripts[2]
    --local rankarry = string_split(info.Rank, ":")
    if info.Rank == "1" then
        TopThere.gameObject:SetActive(true)
        TopThere.spriteName = "icon_pm01"
        NoTopThere.gameObject:SetActive(false)
    elseif info.Rank == "2" then
        TopThere.gameObject:SetActive(true)
        TopThere.spriteName = "icon_pm02"
        NoTopThere.gameObject:SetActive(false)
    elseif info.Rank == "3" then
        TopThere.gameObject:SetActive(true)
        TopThere.spriteName = "icon_pm03"
        NoTopThere.gameObject:SetActive(false)
    else
        TopThere.gameObject:SetActive(false)
        NoTopThere.gameObject:SetActive(true)
        local NumLabel = item.mScripts[3]
        local NumLabel1 = item.mScripts[4]
        local NumLabel2 = item.mScripts[5]
        local ScoreLab = item.mScripts[6]
        if info.AwardType == 0 then --排行
            NumLabel.text = ""
            NumLabel1.text = ""
            ScoreLab.text=""
            NumLabel2:WriteConstomNumText(info.Rank, "JWJL")
        else--积分
            NumLabel2.text=""
            ScoreLab.text=CS.TextManager.GetString("Melee_MinAward",info.Rank)
        end
    end
end
--更新奖励单元数据
function MeleeAwardUI.OnUpdateAwardGrid(item)
    if (item == nil or item.oData == nil) then
        return
    end
    local grid = FindInParents("UIGrid", item.transform)
    local Info = item.oData
    if Info == nil then
        return
    end
    local ItemInfo = CS.ItemTool.CompletionItem(Info.strID, Info.iCount, Info.bBind, Info.iQuality)
    CS.ItemObjectShow.ItemShowUI(
        ItemInfo,
        item.transform,
        CS.ItemLableType.E_NORMAL,
        nil,
        false,
        true,
        grid:GetShaderClicpRange(),
        awardGrid:GetShaderClicpRange()
    )
    CS.UIEventListener.Get(item.gameObject).onClick = MeleeAwardUI.ClickItem
end
--点击道具
function MeleeAwardUI.ClickItem(obj)
    local item = FindInParents("UIGridItem", obj)
    if (item == nil or item.oData == nil) then
        return
    end
    local Info = item.oData
    if Info == nil then
        return
    end
    CS.ItemTipsUI.ShowTips(Info.strID, Info.iQuality, Info.bBind, CS.TipOpenType.Preview, nil, CS.eBUTTONTYPE.None)
end
function MeleeAwardUI.OnDestroy()
    if awardGrid ~= nil then
        awardGrid:ClearAllData()
    end
end
return MeleeAwardUI
