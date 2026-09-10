-- Celestial Garden Defense: server-authoritative map, progression, combat, and remote gateway.
local Players=game:GetService("Players"); local ReplicatedStorage=game:GetService("ReplicatedStorage"); local RunService=game:GetService("RunService")
local Config=require(ReplicatedStorage.Modules.GameConfig); local Rarities=require(ReplicatedStorage.Modules.RarityConfig); local Characters=require(ReplicatedStorage.Modules.CharacterConfig); local Plants=require(ReplicatedStorage.Modules.PlantConfig); local Eggs=require(ReplicatedStorage.Modules.EggConfig); local Gears=require(ReplicatedStorage.Modules.GearConfig)
local Data=require(script.Services.DataService); local Inventory=require(script.Services.InventoryService); local Economy=require(script.Services.EconomyService); local Combat=require(script.Services.CombatService)
local remotes=Instance.new("Folder"); remotes.Name="Remotes"; remotes.Parent=ReplicatedStorage
local Action=Instance.new("RemoteFunction"); Action.Name="Action"; Action.Parent=remotes
local State=Instance.new("RemoteEvent"); State.Name="State"; State.Parent=remotes
local world=Instance.new("Folder"); world.Name="Bases"; world.Parent=workspace
local bases, playerBases, activeEnemies, defenders={}, {}, {}, {}; local rng=Random.new()
local function part(parent,name,size,pos,color)
 local p=Instance.new("Part"); p.Name=name;p.Size=size;p.Position=pos;p.Anchored=true;p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Parent=parent;return p
end
local function label(adornee,text,color)
 local gui=Instance.new("BillboardGui");gui.Size=UDim2.fromOffset(180,40);gui.StudsOffset=Vector3.new(0,4,0);gui.AlwaysOnTop=true;gui.Adornee=adornee;gui.Parent=adornee
 local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=.25;l.BackgroundColor3=Color3.fromRGB(18,22,36);l.TextColor3=color or Color3.new(1,1,1);l.TextScaled=true;l.Font=Enum.Font.GothamBold;l.Text=text;l.Parent=gui;return l
end
for b=1,Config.MaxBases do
 local root=Instance.new("Model");root.Name="Base"..b;root.Parent=world; local x=(b-1)*Config.BaseSpacing; part(root,"Floor",Vector3.new(160,1,125),Vector3.new(x,0,0),Color3.fromRGB(31,38,55))
 local base={Id=b,Root=root,Center=Vector3.new(x,1,0),Owner=nil,Lanes={},Stations={}}
 base.Spawn=part(root,"PlayerSpawn",Vector3.new(9,1,9),Vector3.new(x,-.2,-48),Color3.fromRGB(65,177,255)); label(base.Spawn,"UNCLAIMED BASE")
 for name,z in pairs({EggShop=42,HatchBay=25,GearShop=-25,SellPortal=-42}) do local s=part(root,name,Vector3.new(24,1,14),Vector3.new(x,1,z),Color3.fromRGB(60,80,120)); base.Stations[name]=s; label(s,name,Color3.fromRGB(255,215,112)) end
 for lane=1,Config.LaneCount do
  local z=-32+(lane-1)*13; local path=part(root,"Lane"..lane,Vector3.new(130,.5,9),Vector3.new(x,1,z),Color3.fromRGB(52,63,77)); local spawn=Vector3.new(x+62,3,z); local finish=Vector3.new(x-62,3,z)
  base.Lanes[lane]={Path=path,Spawn=spawn,Finish=finish,Defenders={}}; label(path,"LANE "..lane.."  •  0/5",Color3.fromRGB(215,225,240))
 end
 bases[b]=base
end
local function stationNear(player,base,station)
 local char=player.Character; local root=char and char:FindFirstChild("HumanoidRootPart"); return root and (root.Position-base.Stations[station].Position).Magnitude<28
end
local function getBase(player) return playerBases[player] end
local function snapshot(player)
 local p=Data.Get(player); local base=getBase(player); if not p then return {} end
 local copy={Money=p.Money,UnlockedLanes=p.UnlockedLanes,Eggs=p.Eggs,Characters=p.Characters,Plants=p.Plants,Gear=p.Gear,Index=p.Index,Hatch=p.Hatch,BaseId=base and base.Id}
 return copy
end
local function push(player) State:FireClient(player,"State",snapshot(player)) end
local function makeEnemy(base,lane, plantId)
 local cfg=Plants[plantId]; local m=part(base.Root,"Enemy_"..plantId,Vector3.new(5,5,5),base.Lanes[lane].Spawn,cfg.Color);m.Shape=Enum.PartType.Ball; label(m,cfg.Name.."\n"..cfg.Health.." HP",Rarities[cfg.Rarity].Color)
 activeEnemies[base.Id..":"..lane]={Model=m,Base=base,Lane=lane,Id=plantId,Health=cfg.Health,MaxHealth=cfg.Health,Speed=cfg.Speed,Reward=cfg.MoneyReward,Dead=false}; Inventory.Discover(Data.Get(base.Owner),"Plants",plantId)
end
local plantList={"Pebblebud","VineMaw","ThornLily","BloomBrute","Sunroot","Moonbriar","Worldsprout"}
local function rollPlant(profile)
 local level=profile.UnlockedLanes; local r=rng:NextNumber(); if r<.004 then return "Worldsprout" elseif r<.018 then return "Moonbriar" elseif r<.06 then return "Sunroot" elseif r<.16 then return "BloomBrute" elseif r<.34 then return "ThornLily" elseif r<.6 then return "VineMaw" else return "Pebblebud" end
end
local function clearEnemy(enemy,killed)
 if enemy.Dead then return end; enemy.Dead=true; activeEnemies[enemy.Base.Id..":"..enemy.Lane]=nil
 if enemy.Model then enemy.Model:Destroy() end
 local owner=enemy.Base.Owner; if killed and owner then
  local profile=Data.Get(owner); local bonus=1+((profile.Gear.CoinSigil or 0)*.15); Economy.Add(owner,enemy.Reward*bonus); Inventory.Add(profile,"Plants",enemy.Id); push(owner)
 end
end
local function place(player,id,lane)
 local profile=Data.Get(player); local base=getBase(player); lane=math.floor(tonumber(lane) or 0); if not base or lane<1 or lane>profile.UnlockedLanes then return false,"Lane locked" end
 local item=Inventory.Find(profile,"Characters",id); local l=base.Lanes[lane]; if not item or item.Placed then return false,"Character unavailable" end; if #l.Defenders>=Config.LaneCapacity then return false,"Lane is full" end
 local cfg=Characters[item.Type]; local idx=#l.Defenders+1; local m=part(base.Root,"Defender_"..id,Vector3.new(4,6,4),Vector3.new(base.Center.X-35+(idx-1)*13,4,l.Path.Position.Z),cfg.Color); label(m,cfg.Name.."\n"..cfg.Damage.." DMG",Rarities[cfg.Rarity].Color)
 item.Placed=true; item.Lane=lane; table.insert(l.Defenders,{Id=id,Model=m,Damage=cfg.Damage*(1+.1*(item.Level-1)),Cooldown=cfg.AttackCooldown,Range=cfg.Range,Crit=cfg.CriticalChance,CritMultiplier=cfg.CriticalMultiplier,NextAttack=0}); return true
end
local function removePlaced(player,id)
 local base=getBase(player); local profile=Data.Get(player); local item=Inventory.Find(profile,"Characters",id); if not base or not item or not item.Placed then return false,"Not placed" end
 local list=base.Lanes[item.Lane].Defenders; for i,d in ipairs(list) do if d.Id==id then d.Model:Destroy();table.remove(list,i);break end end;item.Placed=nil;item.Lane=nil;return true
end
Action.OnServerInvoke=function(player,kind,a,b)
 local p=Data.Get(player);local base=getBase(player);if not p or not base then return false,"No profile" end
 if kind=="Snapshot" then return true,snapshot(player)
 elseif kind=="BuyEgg" then local e=Eggs[a];if not e or not stationNear(player,base,"EggShop") then return false,"Visit Egg Shop" end;if not Economy.Spend(player,e.Price) then return false,"Not enough money" end;local it=Inventory.Add(p,"Eggs",a);Inventory.Discover(p,"Eggs",a);push(player);return true,it
 elseif kind=="StartHatch" then local egg=Inventory.Find(p,"Eggs",a);if not egg or p.Hatch or not stationNear(player,base,"HatchBay") then return false,"Visit Hatch Bay / select an egg" end; local cfg=Eggs[egg.Type];p.Hatch={EggId=egg.Id,EndsAt=os.time()+math.ceil(cfg.HatchDuration*(1-(p.Gear.HatchDrive or 0)*.12))};push(player);return true,p.Hatch
 elseif kind=="ClaimHatch" then if not stationNear(player,base,"HatchBay") then return false,"Visit Hatch Bay" end;if not p.Hatch or os.time()<p.Hatch.EndsAt then return false,"Hatch still incubating" end;local egg=Inventory.Remove(p,"Eggs",p.Hatch.EggId);if not egg then p.Hatch=nil;return false,"Egg missing" end;local rarity=Rarities.Roll(Eggs[egg.Type].Pool,rng);local choices={};for id,c in pairs(Characters) do if c.Rarity==rarity then table.insert(choices,id) end end;local result=choices[rng:NextInteger(1,#choices)];local item=Inventory.Add(p,"Characters",result,{Level=1});Inventory.Discover(p,"Characters",result);p.Hatch=nil;push(player);return true,item
 elseif kind=="Place" then local ok,msg=place(player,a,b);push(player);return ok,msg
 elseif kind=="Remove" then local ok,msg=removePlaced(player,a);push(player);return ok,msg
 elseif kind=="UnlockLane" then local nextLane=p.UnlockedLanes+1;if nextLane>6 then return false,"All lanes unlocked" end;local cost=Config.LaneUnlockCosts[nextLane];if not Economy.Spend(player,cost) then return false,"Need "..cost.." coins" end;p.UnlockedLanes=nextLane;push(player);return true,nextLane
 elseif kind=="BuyGear" then local g=Gears[a];local level=p.Gear[a] or 0;if not g or level>=g.MaxLevel then return false,"Unavailable" end;local price=g.Price*(level+1);if not stationNear(player,base,"GearShop") or not Economy.Spend(player,price) then return false,"Visit Gear Shop / need coins" end;p.Gear[a]=level+1;push(player);return true,p.Gear[a]
 elseif kind=="Sell" then local collection=(a=="Character") and "Characters" or "Plants";local item=Inventory.Find(p,collection,b);if not item or item.Placed then return false,"Item unavailable" end;local cfg=(collection=="Characters" and Characters or Plants)[item.Type];if not stationNear(player,base,"SellPortal") then return false,"Visit Sell Portal" end;Inventory.Remove(p,collection,b);Economy.Add(player,math.floor(cfg.Value*.6));push(player);return true,math.floor(cfg.Value*.6)
 end; return false,"Unknown action"
end
Players.PlayerAdded:Connect(function(player)
 Data.Load(player); local claimed
 for _,base in ipairs(bases) do if not base.Owner then claimed=base;base.Owner=player;playerBases[player]=base;break end end
 if not claimed then player:Kick("All four garden bases are occupied. Please try another server.");return end
 claimed.Spawn:FindFirstChildOfClass("BillboardGui").TextLabel.Text=player.Name.."'S BASE"
 local function teleport(c) task.wait(); local root=c:WaitForChild("HumanoidRootPart",8);if root then root.CFrame=CFrame.new(claimed.Spawn.Position+Vector3.new(0,5,0)) end end
 player.CharacterAdded:Connect(teleport); if player.Character then task.spawn(teleport,player.Character) end; task.defer(push,player)
end)
Players.PlayerRemoving:Connect(function(player) local base=playerBases[player];if base then for lane=1,Config.LaneCount do local enemy=activeEnemies[base.Id..":"..lane];if enemy then clearEnemy(enemy,false) end end;for _,lane in ipairs(base.Lanes) do for _,d in ipairs(lane.Defenders) do d.Model:Destroy() end;lane.Defenders={} end;base.Owner=nil;base.Spawn:FindFirstChildOfClass("BillboardGui").TextLabel.Text="UNCLAIMED BASE";playerBases[player]=nil end;Data.Remove(player) end)
task.spawn(function() while task.wait(Config.SpawnInterval) do for _,base in ipairs(bases) do if base.Owner then local p=Data.Get(base.Owner);for lane=1,p.UnlockedLanes do if not activeEnemies[base.Id..":"..lane] then makeEnemy(base,lane,rollPlant(p)) end end end end end end)
RunService.Heartbeat:Connect(function(dt) for key,enemy in pairs(activeEnemies) do if enemy.Dead then continue end; enemy.Model.Position+=Vector3.new(-enemy.Speed*dt,0,0); if enemy.Model.Position.X<=enemy.Base.Lanes[enemy.Lane].Finish.X then clearEnemy(enemy,false) else for _,d in ipairs(enemy.Base.Lanes[enemy.Lane].Defenders) do Combat.TryAttack(d,enemy,os.clock()) end;if enemy.Health<=0 then clearEnemy(enemy,true) end end end end)
game:BindToClose(function() for _,p in ipairs(Players:GetPlayers()) do Data.Save(p) end task.wait(2) end)
