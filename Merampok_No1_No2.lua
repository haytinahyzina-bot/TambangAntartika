-- MERAMPOK Farm No.1 + ESP No.2 (teleport PISAH, semua ON/OFF)
-- PlaceId 83907398368798 | Map: Workspace.Map
-- Cara pakai: execute di Solara/Xeno. Semua default OFF.
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local Cfg = {
  AutoSteal = false, StealRadius = 15,
  AutoHack = false, HackRadius = 15,
  AutoDoor = false, DoorRadius = 12,
  AutoE = false, ERadius = 12,
  AntiPenjaga = false,
  AntiCam = false, AutoHit = false, HitRadius = 15,
  AutoClaim = false,
  Speed = 21, SpeedLock = false, Noclip = false, InfJump = false,
  ESP_Steal = false, ESP_Penting = false, ESP_NPC = false,
  ShowSusp = true,
}

-- ANTI PENJAGA: block remote lapor ke server (client tidak ngaku lihat/ketahuan)
local BlockRemote = {
  NPCStartedNoticing = true, NPCFullyNoticed = true,
  NoticedPlayerVibrate = true, LayedEyesUponItem = true,
  CaughtPlayer = true,
}
pcall(function()
  local mt = getrawmetatable(game)
  local old = mt.__namecall
  setreadonly(mt, false)
  mt.__namecall = newcclosure(function(self, ...)
    if Cfg.AntiPenjaga and BlockRemote[tostring(self.Name or self)] then
      local method = getnamecallmethod()
      if method == "FireServer" then return nil end
    end
    return old(self, ...)
  end)
  setreadonly(mt, true)
end)

local function HRP() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function Map() return workspace:FindFirstChild("Map") end
local function StealFolder() local m = Map() return m and m:FindFirstChild("StealableItems") end

-- cari prompt dari sebuah instance (item steal / pintu / hack)
local function PromptsOf(inst)
  local t = {}
  if not inst then return t end
  for _, d in ipairs(inst:GetDescendants()) do
    if d:IsA("ProximityPrompt") and d.Enabled then table.insert(t, d) end
  end
  if inst:IsA("BasePart") then
    -- prompt kadang di parent model
    local m = inst:FindFirstAncestorOfClass("Model")
    if m then for _, d in ipairs(m:GetDescendants()) do
      if d:IsA("ProximityPrompt") and d.Enabled then table.insert(t, d) end
    end end
  end
  return t
end

local function PromptPos(pr)
  local pp = pr.Parent
  if pp and pp:IsA("Attachment") then pp = pp.Parent end
  if pp and pp:IsA("BasePart") then return pp.Position end
  local m = pr:FindFirstAncestorOfClass("Model")
  if m then local ok, cf = pcall(function() return m:GetPivot() end) if ok then return cf.Position end end
  return nil
end

local function FireNearby(getTargets, radius)
  local hrp = HRP() if not hrp then return 0 end
  local n = 0
  for _, inst in ipairs(getTargets()) do
    for _, pr in ipairs(PromptsOf(inst)) do
      local p = PromptPos(pr)
      if p and (p - hrp.Position).Magnitude <= radius then
        pcall(function() fireproximityprompt(pr) end)
        n += 1
      end
    end
  end
  return n
end

local function StealTargets()
  local f = StealFolder() if not f then return {} end
  return f:GetChildren()
end
local function HackTargets()
  local m = Map() if not m then return {} end
  local out = {}
  for _, d in ipairs(m:GetDescendants()) do
    if d:IsA("ProximityPrompt") and d.Enabled and string.upper(d.ActionText or ""):find("HACK") then
      local inst = d.Parent
      if inst then table.insert(out, inst) end
    end
  end
  return out
end
local function DoorTargets()
  local m = Map() if not m then return {} end
  local doors = m:FindFirstChild("Doors")
  if doors then return doors:GetChildren() end
  return {}
end

-- LOOPS (tidak ada teleport di sini, murni fire dalam radius)
task.spawn(function()
  while true do
    if Cfg.AutoSteal then pcall(function() FireNearby(StealTargets, Cfg.StealRadius) end) end
    task.wait(0.35)
  end
end)
-- AUTO E umum: semua prompt dalam radius (steal/hack/pintu/cabinet/RING/dll)
task.spawn(function()
  while true do
    if Cfg.AutoE then
      pcall(function()
        local hrp = HRP() local m = Map()
        if hrp and m then
          for _, pr in ipairs(m:GetDescendants()) do
            if pr:IsA("ProximityPrompt") and pr.Enabled then
              local p = PromptPos(pr)
              if p and (p - hrp.Position).Magnitude <= Cfg.ERadius then
                pcall(function() fireproximityprompt(pr) end)
              end
            end
          end
        end
      end)
    end
    task.wait(0.3)
  end
end)
-- ANTI PENJAGA loop: kunci SuspiciousAmount 0 (client) + matikan getaran ketahuan
task.spawn(function()
  while true do
    if Cfg.AntiPenjaga then
      pcall(function()
        local m = Map()
        local s = m and m:FindFirstChild("SuspiciousAmount")
        if s and s.Value ~= 0 then s.Value = 0 end
      end)
    end
    task.wait(0.5)
  end
end)
task.spawn(function()
  while true do
    if Cfg.AutoHack then pcall(function() FireNearby(HackTargets, Cfg.HackRadius) end) end
    task.wait(0.4)
  end
end)
task.spawn(function()
  while true do
    if Cfg.AutoDoor then pcall(function() FireNearby(DoorTargets, Cfg.DoorRadius) end) end
    task.wait(0.5)
  end
end)

-- ANTI KAMERA/SUARA (client-side: matikan sentuhan zona deteksi)
task.spawn(function()
  while true do
    if Cfg.AntiCam then
      pcall(function()
        local m = Map() if not m then return end
        for _, nm in ipairs({"Cameras","CameraMapping","NoiseAreas","BreakableGlass","Colliders"}) do
          local f = m:FindFirstChild(nm)
          if f then for _, p in ipairs(f:GetDescendants()) do
            if p:IsA("BasePart") and (p.CanTouch or p.CanCollide) then
              p.CanTouch = false p.CanCollide = false
            end
          end end
        end
      end)
    end
    task.wait(2)
  end
end)
-- AUTO HIT halangan: kasir + NPC dekat (pakai remote Tools/HitNPC + Utilities/HitCashier)
task.spawn(function()
  while true do
    if Cfg.AutoHit then
      pcall(function()
        local hrp = HRP() local m = Map() if not hrp or not m then return end
        local RS = game:GetService("ReplicatedStorage")
        local rHitNPC = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Tools") and RS.Remotes.Tools:FindFirstChild("HitNPC")
        local rHitCash = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Utilities") and RS.Remotes.Utilities:FindFirstChild("HitCashier")
        local function nearestNPC()
          local best, bd = nil, Cfg.HitRadius
          for _, grp in ipairs({m:FindFirstChild("NPCS"), m:FindFirstChild("Police")}) do
            if grp then for _, npc in ipairs(grp:GetDescendants()) do
              if npc:IsA("Model") and npc:FindFirstChildOfClass("Humanoid") then
                local ok, cf = pcall(function() return npc:GetPivot() end)
                if ok and (cf.Position - hrp.Position).Magnitude <= bd then bd = (cf.Position - hrp.Position).Magnitude best = npc end
              end
            end end
          end
          return best
        end
        local tgt = nearestNPC()
        if tgt then
          if rHitNPC then pcall(function() rHitNPC:FireServer(tgt) end) pcall(function() rHitNPC:FireServer() end) end
          if rHitCash then pcall(function() rHitCash:FireServer(tgt) end) pcall(function() rHitCash:FireServer() end) end
        end
      end)
    end
    task.wait(0.6)
  end
end)
-- AUTO CLAIM 30s: index + round reward + board (best-effort, semua pcall)
task.spawn(function()
  while true do
    if Cfg.AutoClaim then
      pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local R = RS:FindFirstChild("Remotes")
        if R then
          local g = R:FindFirstChild("GetIndexData")
          if g then pcall(function() g:InvokeServer() end) end
          local c = R:FindFirstChild("ClaimIndexReward")
          if c then for i = 1, 20 do pcall(function() c:InvokeServer(i) end) end end
          local rr = R:FindFirstChild("RoundRewardStatus")
          if rr then pcall(function() rr:InvokeServer() end) end
          local q = R:FindFirstChild("Quests") and R.Quests:FindFirstChild("BoardAction")
          if q then pcall(function() q:InvokeServer("ClaimAll") end) pcall(function() q:InvokeServer() end) end
          local pa = R:FindFirstChild("PlayAgain")
          if pa then pcall(function() pa:FireServer() end) end
        end
      end)
    end
    task.wait(30)
  end
end)
-- MOVEMENT: speed lock + noclip + inf jump (kayak Tambang Hub2)
do
  local UIS = game:GetService("UserInputService")
  UIS.JumpRequest:Connect(function()
    if Cfg.InfJump then
      local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
      if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
  end)
  task.spawn(function()
    while true do
      pcall(function()
        local ch = LP.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum and Cfg.SpeedLock and hum.WalkSpeed ~= Cfg.Speed then hum.WalkSpeed = Cfg.Speed end
        if Cfg.Noclip and ch then
          for _, v in ipairs(ch:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
          end
        end
      end)
      task.wait(0.3)
    end
  end)
end

-- ============ ESP (visual saja) ============
local function MkESP(parent, ador, name, text, bg, fg)
  if parent:FindFirstChild(name) then return parent[name] end
  local bb = Instance.new("BillboardGui")
  bb.Name = name bb.Size = UDim2.new(0,160,0,28)
  bb.StudsOffset = Vector3.new(0,3,0) bb.AlwaysOnTop = true
  bb.Adornee = ador bb.Parent = parent
  local tl = Instance.new("TextLabel")
  tl.Name = "Txt" tl.Size = UDim2.new(1,0,1,0)
  tl.BackgroundTransparency = 0.3 tl.BackgroundColor3 = bg
  tl.TextColor3 = fg tl.TextStrokeTransparency = 0
  tl.TextSize = 12 tl.Font = Enum.Font.Code tl.Text = text
  tl.Parent = bb
  return bb
end
local function ClearESP(name)
  for _, d in ipairs(workspace:GetDescendants()) do
    if d.Name == name then pcall(function() d:Destroy() end) end
  end
end

task.spawn(function()
  while true do
    pcall(function()
      local hrp = HRP() local my = hrp and hrp.Position
      -- steal
      if Cfg.ESP_Steal then
        local f = StealFolder()
        if f then for _, m in ipairs(f:GetChildren()) do
          local ador = m:IsA("BasePart") and m or m:FindFirstChildWhichIsA("BasePart", true)
          if ador and not m:FindFirstChild("MR_STEAL") then
            MkESP(m, ador, "MR_STEAL", m.Name, Color3.fromRGB(30,25,10), Color3.new(1,0.85,0.3))
          end
        end end
      else ClearESP("MR_STEAL") end
      -- penting: truck / vault / heli
      if Cfg.ESP_Penting then
        local m = Map()
        if m then
          for _, nm in ipairs({"CollectTruck","VaultsPositions","HelicopterDrop","MainTruckPos"}) do
            local t = m:FindFirstChild(nm, true)
            if t then
              local ador = t:IsA("BasePart") and t or t:FindFirstChildWhichIsA("BasePart", true)
              if ador and not t:FindFirstChild("MR_PENTING") then
                MkESP(t, ador, "MR_PENTING", nm, Color3.fromRGB(10,30,20), Color3.new(0.5,1,0.6))
              end
            end
          end
        end
      else ClearESP("MR_PENTING") end
      -- npc / police
      if Cfg.ESP_NPC then
        local m = Map()
        if m then for _, grp in ipairs({m:FindFirstChild("NPCS"), m:FindFirstChild("Police")}) do
          if grp then for _, npc in ipairs(grp:GetDescendants()) do
            if npc:IsA("Model") and npc:FindFirstChildOfClass("Humanoid") and not npc:FindFirstChild("MR_NPC") then
              local ador = npc:FindFirstChildWhichIsA("BasePart")
              if ador then MkESP(npc, ador, "MR_NPC", npc.Name, Color3.fromRGB(50,10,15), Color3.new(1,0.4,0.4)) end
            end
          end end
        end end
      else ClearESP("MR_NPC") end
      -- update jarak
      if my then
        for _, bb in ipairs(workspace:GetDescendants()) do
          if bb:IsA("BillboardGui") and (bb.Name == "MR_STEAL" or bb.Name == "MR_PENTING") then
            local tl = bb:FindFirstChild("Txt")
            local host = bb.Parent
            if tl and host then
              local ador = bb.Adornee
              if ador then
                local d = math.floor((ador.Position - my).Magnitude)
                tl.Text = host.Name .. " " .. d .. "m"
              end
            end
          end
        end
      end
    end)
    task.wait(2)
  end
end)

-- ============ TELEPORT MANUAL (pisah, tidak auto) ============
local function TPto(pos)
  local hrp = HRP() if not hrp or not pos then return false end
  hrp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
  hrp.Velocity = Vector3.new()
  return true
end
local function FirstBasePart(inst)
  if not inst then return nil end
  if inst:IsA("BasePart") then return inst end
  return inst:FindFirstChildWhichIsA("BasePart", true)
end
local function NearestSteal(nameFilter)
  local hrp = HRP() local f = StealFolder() if not hrp or not f then return nil end
  local best, bd = nil, math.huge
  for _, m in ipairs(f:GetChildren()) do
    if not nameFilter or string.lower(m.Name):find(string.lower(nameFilter)) then
      local p = FirstBasePart(m)
      if p then local d = (p.Position - hrp.Position).Magnitude if d < bd then bd = d best = p.Position end end
    end
  end
  return best
end
local function NamedPos(name)
  local m = Map() if not m then return nil end
  local t = m:FindFirstChild(name, true) if not t then return nil end
  local p = FirstBasePart(t) return p and p.Position or nil
end

-- ============ UI ============
local gui = Instance.new("ScreenGui") gui.Name = "MerampokNo1No2" gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP.PlayerGui end
local main = Instance.new("Frame")
main.Size = UDim2.new(0,250,0,440) main.Position = UDim2.new(0,20,0.5,-220)
main.BackgroundColor3 = Color3.fromRGB(16,18,26) main.BorderSizePixel = 0
main.Active = true main.Draggable = true main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,30) title.BackgroundTransparency = 1
title.Text = "  Merampok No1+No2" title.Font = Enum.Font.GothamBold title.TextSize = 14
title.TextColor3 = Color3.new(1,1,1) title.TextXAlignment = Enum.TextXAlignment.Left title.Parent = main
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-16,1,-70) scroll.Position = UDim2.new(0,8,0,34)
scroll.BackgroundTransparency = 1 scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0,0,0,1100) scroll.Parent = main
local lay = Instance.new("UIListLayout") lay.Padding = UDim.new(0,6) lay.Parent = scroll
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1,-16,0,30) info.Position = UDim2.new(0,8,1,-32)
info.BackgroundTransparency = 1 info.Font = Enum.Font.Code info.TextSize = 11
info.TextColor3 = Color3.new(0.85,0.85,0.85) info.TextXAlignment = Enum.TextXAlignment.Left
info.Text = "..." info.Parent = main

local function Sec(t)
  local l = Instance.new("TextLabel")
  l.Size = UDim2.new(1,-8,0,18) l.BackgroundTransparency = 1 l.Text = t
  l.Font = Enum.Font.GothamBold l.TextSize = 12 l.TextColor3 = Color3.fromRGB(255,200,90)
  l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = scroll
end
local function Tog(t, get, set)
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(1,-8,0,28) b.BackgroundColor3 = Color3.fromRGB(30,33,45)
  b.Font = Enum.Font.Gotham b.TextSize = 12 b.TextColor3 = Color3.new(1,1,1)
  b.TextXAlignment = Enum.TextXAlignment.Left b.Parent = scroll
  Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
  local function ref() b.Text = "  " .. (get() and "[ON]  " or "[OFF] ") .. t end ref()
  b.MouseButton1Click:Connect(function() set(not get()) ref() end)
  return b
end
local function Btn(t, cb, c)
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(1,-8,0,28) b.BackgroundColor3 = c or Color3.fromRGB(50,90,150)
  b.Font = Enum.Font.GothamBold b.TextSize = 12 b.TextColor3 = Color3.new(1,1,1)
  b.Text = t b.Parent = scroll
  Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
  b.MouseButton1Click:Connect(function() pcall(cb) end)
end

Sec("— No.1 FARM (tanpa teleport) —")
Tog("Auto E umum (semua prompt)", function() return Cfg.AutoE end, function(v) Cfg.AutoE = v end)
Tog("TIDAK terlihat penjaga", function() return Cfg.AntiPenjaga end, function(v) Cfg.AntiPenjaga = v end)
Tog("Auto Steal (radius E)", function() return Cfg.AutoSteal end, function(v) Cfg.AutoSteal = v end)
Tog("Auto HACK powerbox", function() return Cfg.AutoHack end, function(v) Cfg.AutoHack = v end)
Tog("Auto Door Open/Locked", function() return Cfg.AutoDoor end, function(v) Cfg.AutoDoor = v end)
Btn("Jarak Steal: 15", function(b)
  Cfg.StealRadius = Cfg.StealRadius >= 25 and 8 or Cfg.StealRadius + 5
  b.Text = "Jarak Steal: " .. Cfg.StealRadius
end)

Sec("— TELEPORT (manual pisah) —")
Btn("TP: Money terdekat", function() local p = NearestSteal("money") if p then TPto(p) end end)
Btn("TP: Gem terdekat", function() local p = NearestSteal("gem") if p then TPto(p) end end)
Btn("TP: HACK terdekat", function()
  local hrp = HRP() if not hrp then return end
  local best, bd = nil, math.huge
  local m = Map() if not m then return end
  for _, d in ipairs(m:GetDescendants()) do
    if d:IsA("ProximityPrompt") and string.upper(d.ActionText or ""):find("HACK") then
      local pp = d.Parent
      if pp and pp:IsA("BasePart") then local dd = (pp.Position - hrp.Position).Magnitude if dd < bd then bd = dd best = pp.Position end end
    end
  end
  if best then TPto(best) end
end)
Btn("TP: Truck (setor)", function() local p = NamedPos("CollectTruck") if p then TPto(p) end end)
Btn("TP: Vault", function() local p = NamedPos("VaultsPositions") if p then TPto(p) end end)
Btn("TP: Heli", function() local p = NamedPos("HelicopterDrop") if p then TPto(p) end end)

Sec("— No.2 ESP —")
Tog("ESP Steal", function() return Cfg.ESP_Steal end, function(v) Cfg.ESP_Steal = v end)
Tog("ESP Truck/Vault/Heli", function() return Cfg.ESP_Penting end, function(v) Cfg.ESP_Penting = v end)
Tog("ESP NPC/Police", function() return Cfg.ESP_NPC end, function(v) Cfg.ESP_NPC = v end)

Sec("— ANTI KAMERA/SUARA + HIT —")
Tog("Anti Cam/Suara (client)", function() return Cfg.AntiCam end, function(v) Cfg.AntiCam = v end)
Tog("Auto Hit kasir/NPC dekat", function() return Cfg.AutoHit end, function(v) Cfg.AutoHit = v end)

Sec("— AUTO CLAIM 30s —")
Tog("Auto Claim index+reward", function() return Cfg.AutoClaim end, function(v) Cfg.AutoClaim = v end)

Sec("— MOVEMENT (kayak Tambang) —")
Tog("Kunci Speed", function() return Cfg.SpeedLock end, function(v)
  Cfg.SpeedLock = v
  if not v then pcall(function()
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = 16 end
  end) end
end)
Tog("Noclip tembus Door", function() return Cfg.Noclip end, function(v) Cfg.Noclip = v end)
Tog("Inf Jump", function() return Cfg.InfJump end, function(v) Cfg.InfJump = v end)
Btn("Speed: 21", function(b)
  Cfg.Speed = Cfg.Speed >= 100 and 21 or Cfg.Speed + 21
  if Cfg.Speed > 100 then Cfg.Speed = 21 end
  b.Text = "Speed: " .. Cfg.Speed
end)

task.spawn(function()
  while gui.Parent do
    pcall(function()
      local m = Map()
      local ns = StealFolder() and #StealFolder():GetChildren() or 0
      local susp = m and m:FindFirstChild("SuspiciousAmount")
      info.Text = ns .. " steal | susp " .. tostring(susp and susp.Value or "?")
    end)
    task.wait(1)
  end
end)

print("[Merampok No1+No2] loaded, semua OFF, teleport manual pisah.")
