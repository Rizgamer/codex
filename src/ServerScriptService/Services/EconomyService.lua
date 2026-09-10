local Data=require(script.Parent.DataService)
local Economy={}
function Economy.Balance(player) local p=Data.Get(player); return p and p.Money or 0 end
function Economy.Add(player,amount) local p=Data.Get(player); if not p then return false end p.Money=math.max(0,p.Money+math.floor(amount)); return true end
function Economy.Spend(player,amount) local p=Data.Get(player); amount=math.floor(tonumber(amount) or -1); if not p or amount<0 or p.Money<amount then return false end p.Money-=amount return true end
return Economy
