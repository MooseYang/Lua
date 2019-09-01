
local MeleeManager={}
require "Lua.Define.ServerDefine"
require "Lua.Define.PathDefine"
require "Lua.Utils.utils"
-- 请求活动时间
E_CLIENT_CUSTOMMSG_SUB_FFA_QUERY_READY_TIME = 0
--请求退出活动
E_CLIENT_CUSTOMMSG_SUB_FFA_QUIT = 1
-- 请求进入活动
E_CLIENT_CUSTOMMSG_SUB_FFA_ENTRY = 2
--领取目标奖励
E_CLIENT_CUSTOMMSG_SUB_FFA_TARGET_REWARD = 3
-- 通知客户端开始时间 倒计时 秒
E_SERVER_CUSTOMMSG_SUB_FFA_START_TIME = 0
-- 活动结算时间 倒计时 秒
E_SERVER_CUSTOMMSG_SUB_FFA_SETTLE_TIME = 1
-- 活动结算数据 [int队伍id][string队长名][int队伍积分]
E_SERVER_CUSTOMMSG_SUB_FFA_SETTLE = 2
-- 积分榜数据 [int队伍id][string队长名][int队伍积分]
E_SERVER_CUSTOMMSG_SUB_FFA_SCORE_DATA = 3
-- 通知客户端准备时间 倒计时 秒
E_SERVER_CUSTOMMSG_SUB_FFA_READY_TIME = 4
-- 通知客户端连杀 [int击杀数]
E_SERVER_CUSTOMMSG_SUB_FFA_CONTINUE_KILL = 5
-- xx终结了xx的xx杀
E_SERVER_CUSTOMMSG_SUB_FFA_END_CONTINUE_KILL = 6
--通知客户端双倍区域位置 [float posX] [flaot posZ]
E_SERVER_CUSTOMMSG_SUB_FFA_AREA_NPC_POS = 7
--[[
    // 连续击杀类型
    enum
    {
        E_FFA_CONTINUE_KILL_TYPE_NONE = 0,
        E_FFA_CONTINUE_KILL_TYPE_THERE, // 三杀
        E_FFA_CONTINUE_KILL_TYPE_FIVE, // 五杀
        E_FFA_CONTINUE_KILL_TYPE_SEVEN, // 七杀
    
        E_FFA_CONTINUE_KILL_TYPE_MAX
    };
]]
--回调集合
local CallList = {}
--配置排名数据
local localInfoRankList = nil
--配置积分数据
local localInfoIntegralList = nil
--初始化大乱斗管理
function MeleeManager.InitMeleeManager()
    CS.CMessageTool.RegistCustomCallback(SERVER_CUSTOMMSG__FREE_FOR_ALL, MeleeManager.SeverCall,true)
    MeleeManager.RegistCustomCall(E_SERVER_CUSTOMMSG_SUB_FFA_START_TIME, MeleeManager.OpenMeleeUI)
    MeleeManager.RegistCustomCall(E_SERVER_CUSTOMMSG_SUB_FFA_SETTLE_TIME, MeleeManager.OpenMeleeUI)
    MeleeManager.RegistCustomCall(E_SERVER_CUSTOMMSG_SUB_FFA_SCORE_DATA, MeleeManager.OpenMeleeUI)
    MeleeManager.RegistCustomCall(E_SERVER_CUSTOMMSG_SUB_FFA_CONTINUE_KILL, MeleeManager.OpenMeleeUI)
    MeleeManager.RegistCustomCall(E_SERVER_CUSTOMMSG_SUB_FFA_END_CONTINUE_KILL, MeleeManager.OpenMeleeUI)
    MeleeManager.RegistCustomCall(E_SERVER_CUSTOMMSG_SUB_FFA_AREA_NPC_POS, MeleeManager.OpenMeleeUI)
end
--注册回调
function MeleeManager.RegistCustomCall(key, action)
    CallList[key] = action
end
--取消注册回调
function MeleeManager.UnRegistCustomCall(key)
    local acti = CallList[key]
    if acti == nil then
        return
    end
    CallList[key] = nil
end
--打开界面
function MeleeManager.OpenMeleeUI(var)
    if not(CS.GUITool.HasView("MeleeUI")) then
        CS.GUITool.ShowView("MeleeUI")
        CS.GUITool.CallViewFunc("MeleeUI", MeleeManager.UpdateData, var)
    else
        local view = CS.GUITool.GetView("MeleeUI")
        MeleeManager.UpdateData(view, var)
    end
   
end
--更新乱斗战场数据
function MeleeManager.UpdateData(view, args)
    local key = args:GetInt(2)
    if key == E_SERVER_CUSTOMMSG_SUB_FFA_SETTLE_TIME then
        local time = args:GetInt(3)
        view.mLuaTable.OpenTime(time)
    elseif key == E_SERVER_CUSTOMMSG_SUB_FFA_SCORE_DATA then
        view.mLuaTable.UpdateRank(args)
    elseif key == E_SERVER_CUSTOMMSG_SUB_FFA_START_TIME then
        local time = args:GetInt(3)
        view.mLuaTable.UpdateprepareTime(time)
    elseif key == E_SERVER_CUSTOMMSG_SUB_FFA_CONTINUE_KILL then
        view.mLuaTable.SetBroadcastQue(args)
    elseif key == E_SERVER_CUSTOMMSG_SUB_FFA_END_CONTINUE_KILL then
        view.mLuaTable.SetBroadcastQueEnd(args)
    elseif key == E_SERVER_CUSTOMMSG_SUB_FFA_AREA_NPC_POS then
       
    end
    args:Destroy()
end
--服务器回调
function MeleeManager.SeverCall(var)
    local key = var:GetInt(2)
    local action = CallList[key]
    if action ~= nil then
        action(var)
    end
end
--获取大乱斗排名奖励配置
function MeleeManager.GetlocalInfoRankList()
    if localInfoRankList == nil then
        CS.ResourceTool.LoadBytesConfig(PATH_CONFIG_MELEERANKAWARD, MeleeManager.LoadMeleeRankConfig)
    end
    return localInfoRankList
end
--获取大乱斗积分奖励配置
function MeleeManager.GetlocalInfoIntegralList()
    if localInfoIntegralList == nil then
        CS.ResourceTool.LoadBytesConfig(PATH_CONFIG_MINMELEESCOREAWARD, MeleeManager.LoadMeleeIntegralConfig)
    end
    return localInfoIntegralList
end
--获取大乱斗排名奖励配置
function MeleeManager.GetlocalRankInfoBuyRank(rank)
    if localInfoRankList == nil then
        CS.ResourceTool.LoadBytesConfig(PATH_CONFIG_MELEERANKAWARD, MeleeManager.LoadMeleeRankConfig)
    end
    local info = nil
    for i, value in pairs(localInfoRankList) do
        if tonumber(value.Rank) == rank then
            info = value
            break
        end
    end
    return info
end
--加载大乱斗排名奖励配置
function MeleeManager.LoadMeleeRankConfig(asset, obj)
    local MeleeInfo = nil
    localInfoRankList = {}
    if nil ~= asset then
        local ass = asset
        if nil ~= ass then
            for i, n in pairs(ass) do
                MeleeInfo = {}
                MeleeInfo.AwardType = 0
                MeleeInfo.Rank = n:GetStringValue("Rank")
                MeleeInfo.AwardId = n:GetStringValue("AwardId")
                localInfoRankList[#localInfoRankList + 1] = MeleeInfo
            end
        end
    end
end
--加载大乱斗积分奖励配置
function MeleeManager.LoadMeleeIntegralConfig(asset, obj)
    local MeleeInfo = nil
    localInfoIntegralList = {}
    if nil ~= asset then
        local ass = asset
        if nil ~= ass then
            for i, n in pairs(ass) do
                MeleeInfo = {}
                MeleeInfo.AwardType = 1
                MeleeInfo.Rank = n:GetStringValue("NeedTeamScore")
                MeleeInfo.AwardId = n:GetStringValue("AwardId")
                table.insert(localInfoIntegralList, 1, MeleeInfo)
            end
        end
    end
end
return MeleeManager
