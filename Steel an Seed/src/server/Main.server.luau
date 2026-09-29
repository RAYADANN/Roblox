local Players=game:GetService('Players')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local DataStoreService=game:GetService('DataStoreService')
local Config=require(ReplicatedStorage.shared.Config)
local world=workspace:WaitForChild('StealASeedWorld_Final')
local remotes=ReplicatedStorage:FindFirstChild('StealASeedRemotes') or Instance.new('Folder',ReplicatedStorage);remotes.Name='StealASeedRemotes'
local function remote(n)local r=remotes:FindFirstChild(n) or Instance.new('RemoteEvent',remotes);r.Name=n;return r end
local notify=remote('Notify');local request=remote('RequestAction');local store=DataStoreService:GetDataStore('StealASeed_v2')
local plots={};local function msg(p,s)notify:FireClient(p,s)end
local function plantPart(name,pos,size,color,parent)
 local p=Instance.new('Part',parent);p.Name=name;p.Anchored=true;p.CanCollide=false;p.Shape=Enum.PartType.Ball;p.Position=pos;p.Size=size;p.Color=color;p.Material=Enum.Material.Neon;return p
end
local seeds={Sunflower={value=5,grow=8,color=Color3.fromRGB(255,210,40)},Berry={value=14,grow=12,color=Color3.fromRGB(210,55,120)},Crystal={value=40,grow=18,color=Color3.fromRGB(70,210,255)},MoonBloom={value=120,grow=28,color=Color3.fromRGB(170,100,255)}}
for _,s in ipairs(world.SeedMarket:GetChildren()) do
 local q=s:FindFirstChildOfClass('ProximityPrompt');local n=s:GetAttribute('SeedType')
 if q and n and seeds[n] then q.Triggered:Connect(function(plr)if plr:GetAttribute('CarryingSeed')~='' then msg(plr,'Your hands are full. Plant your seed first!');return end;plr:SetAttribute('CarryingSeed',n);msg(plr,'Stole '..n..' seed. Run to your claimed garden!')end)end
end
for _,plot in ipairs(world:GetChildren()) do
 if plot:IsA('Model') and plot.Name:match('GardenPlot_') then
  local gate=plot:FindFirstChild('ClaimGate');if gate then local q=gate:FindFirstChildOfClass('ProximityPrompt') or Instance.new('ProximityPrompt',gate);q.ActionText='CLAIM GARDEN';q.ObjectText=plot.Name;q.HoldDuration=.4;q.MaxActivationDistance=12;q.Triggered:Connect(function(plr)local owner=gate:GetAttribute('OwnerUserId') or 0;if owner==0 then gate:SetAttribute('OwnerUserId',plr.UserId);plots[plr]=plot;msg(plr,'Garden claimed! Steal rare seeds from the market.')elseif owner==plr.UserId then msg(plr,'This is your garden.')else msg(plr,'That garden belongs to another farmer.')end end)end
 end
end
local function save(plr)local ls=plr:FindFirstChild('leaderstats');if ls then pcall(function()store:SetAsync('p'..plr.UserId,{Coins=ls.Coins.Value,Rebirths=ls.Rebirths.Value,Speed=plr:GetAttribute('SpeedLevel') or 1})end)end end
Players.PlayerAdded:Connect(function(plr)local ls=Instance.new('Folder',plr);ls.Name='leaderstats';local c=Instance.new('IntValue',ls);c.Name='Coins';c.Value=25;local r=Instance.new('IntValue',ls);r.Name='Rebirths';r.Value=0;plr:SetAttribute('CarryingSeed','');plr:SetAttribute('SpeedLevel',1);local ok,d=pcall(function()return store:GetAsync('p'..plr.UserId)end);if ok and d then c.Value=d.Coins or 25;r.Value=d.Rebirths or 0;plr:SetAttribute('SpeedLevel',d.Speed or 1)end end)
Players.PlayerRemoving:Connect(function(plr)save(plr);plots[plr]=nil end)
request.OnServerEvent:Connect(function(plr,action)
 local plot=plots[plr];local ls=plr:FindFirstChild('leaderstats');if not ls then return end
 if action=='Plant' then if not plot then msg(plr,'Claim a garden first.');return end;local n=plr:GetAttribute('CarryingSeed');local d=seeds[n];if not d then msg(plr,'Steal a seed first.');return end;plr:SetAttribute('CarryingSeed','');local base=plot:FindFirstChild('PlotBase');local pos=base.Position+Vector3.new(math.random(-15,15),3,math.random(-10,10));local plant=plantPart(n..'_Plant_'..math.random(10000),pos,Vector3.new(2,2,2),d.color,plot);plant:SetAttribute('OwnerUserId',plr.UserId);plant:SetAttribute('Income',d.value);local mutation=math.random()<=.03 and 'Prismatic' or (math.random()<=.12 and 'Golden' or 'Normal');plant:SetAttribute('Mutation',mutation);if mutation~='Normal' then plant.Size*=1.35;plant.Color=Color3.fromRGB(255,220,80)end;msg(plr,'Growing '..n..' ('..mutation..')...');task.spawn(function()for i=1,3 do task.wait(d.grow/3);if plant.Parent then plant.Size+=Vector3.new(2,2,2);plant.Position+=Vector3.new(0,1,0)end end;if plant.Parent then msg(plr,n..' matured! +'..d.value..' / sec')end end)
 elseif action=='Speed' then local lvl=plr:GetAttribute('SpeedLevel') or 1;local cost=50*lvl;if ls.Coins.Value>=cost then ls.Coins.Value-=cost;plr:SetAttribute('SpeedLevel',lvl+1);msg(plr,'Speed upgraded to '..(lvl+1)..'!')else msg(plr,'Need '..cost..' coins for speed.')end
 elseif action=='Rebirth' then if ls.Coins.Value>=Config.RebirthCost then ls.Coins.Value-=Config.RebirthCost;ls.Rebirths.Value+=1;msg(plr,'Rebirth complete! Income multiplier increased.')else msg(plr,'Need '..Config.RebirthCost..' coins to rebirth.')end end
end)
task.spawn(function()while true do task.wait(1);for plr,plot in pairs(plots) do local income=0;for _,o in ipairs(plot:GetChildren())do if o:IsA('BasePart') and o:GetAttribute('OwnerUserId')==plr.UserId then local mult=({Normal=1,Golden=2,Prismatic=5})[o:GetAttribute('Mutation')] or 1;income+=math.floor((o:GetAttribute('Income') or 0)*mult)end end;plr.leaderstats.Coins.Value+=income*(1+plr.leaderstats.Rebirths.Value)end end end)
task.spawn(function()while true do task.wait(180);notify:FireAllClients('WEATHER EVENT: Golden Rain! Plant income doubled for 30 seconds.');task.wait(30)end end)
