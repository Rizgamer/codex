local HttpService=game:GetService("HttpService")
local Data=require(script.Parent.DataService)
local Inventory={}
function Inventory.Add(profile, kind, id, extra)
 local item={Id=HttpService:GenerateGUID(false),Type=id,CreatedAt=os.time()}; for k,v in pairs(extra or {}) do item[k]=v end
 table.insert(profile[kind],item); return item
end
function Inventory.Find(profile,kind,id) for i,item in ipairs(profile[kind]) do if item.Id==id then return item,i end end end
function Inventory.Remove(profile,kind,id) local _,i=Inventory.Find(profile,kind,id); if i then return table.remove(profile[kind],i) end end
function Inventory.Discover(profile, kind, id) profile.Index[kind][id]=true end
function Inventory.Count(profile, kind) return #profile[kind] end
return Inventory
