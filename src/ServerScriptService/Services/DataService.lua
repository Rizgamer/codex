local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Store = DataStoreService:GetDataStore("CelestialGardenDefense_1")
local DataService = {Profiles={}}
local function default()
 return {Money=350,UnlockedLanes=1,Eggs={},Characters={},Plants={},Gear={},Index={Characters={},Plants={},Eggs={}},Settings={Music=true},Hatch=nil}
end
local function sanitize(d)
 d = type(d)=="table" and d or default()
 local base=default(); for k,v in pairs(base) do if d[k]==nil then d[k]=v end end
 d.Money=math.max(0,math.floor(tonumber(d.Money) or base.Money)); d.UnlockedLanes=math.clamp(math.floor(tonumber(d.UnlockedLanes) or 1),1,6)
 return d
end
function DataService.Load(player)
 local ok,result=pcall(function() return Store:GetAsync("p_"..player.UserId) end)
 DataService.Profiles[player]=sanitize(ok and result or nil)
end
function DataService.Get(player) return DataService.Profiles[player] end
function DataService.Save(player)
 local profile=DataService.Profiles[player]; if not profile then return end
 for attempt=1,3 do
  local ok=pcall(function() Store:UpdateAsync("p_"..player.UserId,function() return profile end) end)
  if ok then break end task.wait(attempt)
 end
end
function DataService.Remove(player) DataService.Save(player); DataService.Profiles[player]=nil end
return DataService
