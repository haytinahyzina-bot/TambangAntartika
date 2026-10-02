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
-- DIPASANG MALAS: cuma pas toggle ON, biar execute polos tidak ganggu menu game
local BlockRemote = {
  NPCStartedNoticing = true, NPCFullyNoticed = true,
  NoticedPlayerVibrate = true, LayedEyesUponItem = true,
  CaughtPlayer = true,
}
local HookInstalled = false
local function InstallHook()
  if HookInstalled then return true end
  local ok = pcall(function()
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
      local okB, nm = pcall(function() return tostring(self.Name) end)
      if Cfg.AntiPenjaga and okB and BlockRemote[nm] then
        local okM, method = pcall(getnamecallmethod)
        if okM and method == "FireServer" then return nil end
      end
      return old(self, ...)
    end)
    setreadonly(mt, true)
  end)
  if ok then HookInstalled = true end
  return ok
end

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
      local anyESP = Cfg.ESP_Steal or Cfg.ESP_Penting or Cfg.ESP_NPC
      if not anyESP then task.wait(0.5) return end
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

-- ============ UI MODERN MINIMALIST (tab + grup) ============
local gui = Instance.new("ScreenGui") gui.Name = "MerampokNo1No2" gui.ResetOnSpawn = false
gui.DisplayOrder = 1 gui.IgnoreGuiInset = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP.PlayerGui end

local ACC = Color3.fromRGB(90,140,255)
local BG = Color3.fromRGB(13,15,22)
local SIDE = Color3.fromRGB(9,11,17)
local CARD = Color3.fromRGB(22,25,35)
local TXT = Color3.fromRGB(225,228,238)
local DIM = Color3.fromRGB(140,148,165)

local main = Instance.new("Frame")
main.Size = UDim2.new(0,560,0,360) main.Position = UDim2.new(0.5,-280,0.5,-180)
main.BackgroundColor3 = BG main.BorderSizePixel = 0
main.Active = true main.Draggable = true main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)
local stroke = Instance.new("UIStroke") stroke.Color = Color3.fromRGB(32,37,52) stroke.Thickness = 1 stroke.Parent = main

local side = Instance.new("Frame")
side.Size = UDim2.new(0,140,1,0) side.BackgroundColor3 = SIDE
side.BorderSizePixel = 0 side.Parent = main
Instance.new("UICorner", side).CornerRadius = UDim.new(0,12)

local sideT = Instance.new("TextLabel")
sideT.Size = UDim2.new(1,0,0,46) sideT.BackgroundTransparency = 1
sideT.Text = "  MERAMPOK" sideT.Font = Enum.Font.GothamBold sideT.TextSize = 14
sideT.TextColor3 = TXT sideT.TextXAlignment = Enum.TextXAlignment.Left sideT.Parent = side
local sideS = Instance.new("TextLabel")
sideS.Size = UDim2.new(1,0,0,16) sideS.Position = UDim2.new(0,0,0,32)
sideS.BackgroundTransparency = 1 sideS.Text = "  v2 • minimalist"
sideS.Font = Enum.Font.Gotham sideS.TextSize = 10 sideS.TextColor3 = DIM
sideS.TextXAlignment = Enum.TextXAlignment.Left sideS.Parent = side

local content = Instance.new("Frame")
content.Size = UDim2.new(1,-148,1,-44) content.Position = UDim2.new(0,144,0,8)
content.BackgroundTransparency = 1 content.Parent = main
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1,-148,0,20) status.Position = UDim2.new(0,144,1,-26)
status.BackgroundTransparency = 1 status.Font = Enum.Font.Code status.TextSize = 11
status.TextColor3 = DIM status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "..." status.Parent = main

local pages, tabBtns = {}, {}
local tabNames = {"Farm","Teleport","ESP","Silent","System"}
for i, tn in ipairs(tabNames) do
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(1,-12,0,32) b.Position = UDim2.new(0,6,0,56+(i-1)*38)
  b.BackgroundColor3 = CARD b.Text = "  "..tn
  b.Font = Enum.Font.Gotham b.TextSize = 12 b.TextColor3 = DIM
  b.TextXAlignment = Enum.TextXAlignment.Left b.Parent = side
  Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
  local pg = Instance.new("ScrollingFrame")
  pg.Size = UDim2.new(1,0,1,0) pg.BackgroundTransparency = 1
  pg.ScrollBarThickness = 3 pg.CanvasSize = UDim2.new(0,0,0,500)
  pg.Visible = (i==1) pg.Parent = content
  local lay = Instance.new("UIListLayout") lay.Padding = UDim.new(0,8) lay.Parent = pg
  pages[tn] = pg tabBtns[tn] = b
  b.MouseButton1Click:Connect(function()
    for _, p in pairs(pages) do p.Visible = false end
    for _, x in pairs(tabBtns) do x.BackgroundColor3 = CARD x.TextColor3 = DIM end
    pg.Visible = true b.BackgroundColor3 = Color3.fromRGB(30,42,70) b.TextColor3 = TXT
  end)
end
tabBtns["Farm"].BackgroundColor3 = Color3.fromRGB(30,42,70) tabBtns["Farm"].TextColor3 = TXT

local function Sec(pg, t)
  local l = Instance.new("TextLabel")
  l.Size = UDim2.new(1,-4,0,16) l.BackgroundTransparency = 1 l.Text = string.upper(t)
  l.Font = Enum.Font.GothamBold l.TextSize = 10 l.TextColor3 = DIM
  l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = pg
end
local function Tog(pg, t, get, set)
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(1,-4,0,32) b.BackgroundColor3 = CARD
  b.Text = "" b.AutoButtonColor = false b.Parent = pg
  Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
  local lab = Instance.new("TextLabel")
  lab.Size = UDim2.new(1,-52,1,0) lab.Position = UDim2.new(0,10,0,0)
  lab.BackgroundTransparency = 1 lab.Text = t lab.Font = Enum.Font.Gotham
  lab.TextSize = 12 lab.TextColor3 = TXT lab.TextXAlignment = Enum.TextXAlignment.Left lab.Parent = b
  local pill = Instance.new("Frame")
  pill.Size = UDim2.new(0,32,0,18) pill.Position = UDim2.new(1,-40,0.5,-9)
  pill.BackgroundColor3 = Color3.fromRGB(45,50,65) pill.BorderSizePixel = 0 pill.Parent = b
  Instance.new("UICorner", pill).CornerRadius = UDim.new(1,0)
  local dot = Instance.new("Frame")
  dot.Size = UDim2.new(0,14,0,14) dot.Position = UDim2.new(0,2,0.5,-7)
  dot.BackgroundColor3 = Color3.fromRGB(160,165,180) dot.BorderSizePixel = 0 dot.Parent = pill
  Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
  local function ref()
    local on = get()
    pill.BackgroundColor3 = on and Color3.fromRGB(45,160,90) or Color3.fromRGB(45,50,65)
    dot.Position = on and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
    dot.BackgroundColor3 = Color3.new(1,1,1)
  end ref()
  b.MouseButton1Click:Connect(function() set(not get()) ref() end)
  return b
end
local function Btn(pg, t, cb, primary)
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(1,-4,0,30) b.BackgroundColor3 = primary and Color3.fromRGB(50,90,160) or CARD
  b.Font = Enum.Font.Gotham b.TextSize = 12 b.TextColor3 = TXT b.Text = t b.Parent = pg
  Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
  b.MouseButton1Click:Connect(function() pcall(cb, b) end)
  return b
end
local function Stepper(pg, t, get, set, min, max, step)
  local f = Instance.new("Frame")
  f.Size = UDim2.new(1,-4,0,32) f.BackgroundColor3 = CARD f.Parent = pg
  Instance.new("UICorner", f).CornerRadius = UDim.new(0,8)
  local lab = Instance.new("TextLabel")
  lab.Size = UDim2.new(0.6,0,1,0) lab.Position = UDim2.new(0,10,0,0)
  lab.BackgroundTransparency = 1 lab.Font = Enum.Font.Gotham lab.TextSize = 12
  lab.TextColor3 = TXT lab.TextXAlignment = Enum.TextXAlignment.Left lab.Parent = f
  local minus = Instance.new("TextButton")
  minus.Size = UDim2.new(0,28,0,22) minus.Position = UDim2.new(1,-62,0.5,-11)
  minus.BackgroundColor3 = Color3.fromRGB(38,42,58) minus.Text = "−"
  minus.Font = Enum.Font.GothamBold minus.TextSize = 14 minus.TextColor3 = TXT minus.Parent = f
  Instance.new("UICorner", minus).CornerRadius = UDim.new(0,6)
  local plus = Instance.new("TextButton")
  plus.Size = UDim2.new(0,28,0,22) plus.Position = UDim2.new(1,-30,0.5,-11)
  plus.BackgroundColor3 = Color3.fromRGB(38,42,58) plus.Text = "+"
  plus.Font = Enum.Font.GothamBold plus.TextSize = 14 plus.TextColor3 = TXT plus.Parent = f
  Instance.new("UICorner", plus).CornerRadius = UDim.new(0,6)
  local function ref() lab.Text = t..": "..tostring(get()) end ref()
  minus.MouseButton1Click:Connect(function() set(math.max(min, get()-step)) ref() end)
  plus.MouseButton1Click:Connect(function() set(math.min(max, get()+step)) ref() end)
end

-- ===== isi tab =====
do local pg = pages["Farm"]
  Sec(pg, "Auto")
  Tog(pg, "Auto E — semua prompt", function() return Cfg.AutoE end, function(v) Cfg.AutoE = v end)
  Tog(pg, "Auto Steal", function() return Cfg.AutoSteal end, function(v) Cfg.AutoSteal = v end)
  Tog(pg, "Auto HACK", function() return Cfg.AutoHack end, function(v) Cfg.AutoHack = v end)
  Tog(pg, "Auto Door", function() return Cfg.AutoDoor end, function(v) Cfg.AutoDoor = v end)
  Sec(pg, "Jarak")
  Stepper(pg, "Steal radius", function() return Cfg.StealRadius end, function(v) Cfg.StealRadius = v end, 8, 25, 1)
  Stepper(pg, "E radius", function() return Cfg.ERadius end, function(v) Cfg.ERadius = v end, 8, 25, 1)
end
do local pg = pages["Teleport"]
  Sec(pg, "Manual — tekan sekali jalan")
  Btn(pg, "Money terdekat", function() local p = NearestSteal("money") if p then TPto(p) end end, true)
  Btn(pg, "Gem terdekat", function() local p = NearestSteal("gem") if p then TPto(p) end end, true)
  Btn(pg, "HACK terdekat", function()
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
  Sec(pg, "Exfil")
  Btn(pg, "Truck (setor)", function() local p = NamedPos("CollectTruck") if p then TPto(p) end end)
  Btn(pg, "Vault", function() local p = NamedPos("VaultsPositions") if p then TPto(p) end end)
  Btn(pg, "Heli", function() local p = NamedPos("HelicopterDrop") if p then TPto(p) end end)
end
do local pg = pages["ESP"]
  Sec(pg, "Visual")
  Tog(pg, "Steal", function() return Cfg.ESP_Steal end, function(v) Cfg.ESP_Steal = v if not v then ClearESP("MR_STEAL") end end)
  Tog(pg, "Truck / Vault / Heli", function() return Cfg.ESP_Penting end, function(v) Cfg.ESP_Penting = v if not v then ClearESP("MR_PENTING") end end)
  Tog(pg, "NPC / Police", function() return Cfg.ESP_NPC end, function(v) Cfg.ESP_NPC = v if not v then ClearESP("MR_NPC") end end)
  Btn(pg, "Bersihkan semua", function() ClearESP("MR_STEAL") ClearESP("MR_PENTING") ClearESP("MR_NPC") end)
end
do local pg = pages["Silent"]
  Sec(pg, "Tidak terlihat")
  Tog(pg, "Anti penjaga (block remote)", function() return Cfg.AntiPenjaga end, function(v) Cfg.AntiPenjaga = v if v then InstallHook() end end)
  Tog(pg, "Anti cam / suara", function() return Cfg.AntiCam end, function(v) Cfg.AntiCam = v end)
  Sec(pg, "Serang")
  Tog(pg, "Auto hit kasir / NPC", function() return Cfg.AutoHit end, function(v) Cfg.AutoHit = v end)
end
do local pg = pages["System"]
  Sec(pg, "Reward")
  Tog(pg, "Auto claim 30s", function() return Cfg.AutoClaim end, function(v) Cfg.AutoClaim = v end)
  Sec(pg, "Gerak")
  Tog(pg, "Kunci speed", function() return Cfg.SpeedLock end, function(v)
    Cfg.SpeedLock = v
    if not v then pcall(function()
      local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
      if h then h.WalkSpeed = 16 end
    end) end
  end)
  Stepper(pg, "Speed", function() return Cfg.Speed end, function(v) Cfg.Speed = v end, 21, 120, 7)
  Tog(pg, "Noclip", function() return Cfg.Noclip end, function(v) Cfg.Noclip = v end)
  Tog(pg, "Inf jump", function() return Cfg.InfJump end, function(v) Cfg.InfJump = v end)
  Sec(pg, "GUI")
  Btn(pg, "Sembunyikan (RightShift)", function() main.Visible = false end)
  Btn(pg, "Hapus + matikan semua", function()
    for k in pairs(Cfg) do if type(Cfg[k]) == "boolean" then Cfg[k] = false end end
    ClearESP("MR_STEAL") ClearESP("MR_PENTING") ClearESP("MR_NPC")
    pcall(function() gui:Destroy() end)
  end)
end

local mini = Instance.new("TextButton")
mini.Size = UDim2.new(0,56,0,26) mini.Position = UDim2.new(0,16,0,12)
mini.BackgroundColor3 = BG mini.Font = Enum.Font.GothamBold
mini.TextSize = 11 mini.TextColor3 = TXT mini.Text = "MR"
mini.Parent = gui
Instance.new("UICorner", mini).CornerRadius = UDim.new(0,8)
mini.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)
do
  local UIS2 = game:GetService("UserInputService")
  UIS2.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightShift then
      main.Visible = not main.Visible
    end
  end)
end

task.spawn(function()
  while gui.Parent do
    pcall(function()
      local m = Map()
      local ns = StealFolder() and #StealFolder():GetChildren() or 0
      local susp = m and m:FindFirstChild("SuspiciousAmount")
      status.Text = ns .. " steal  •  susp " .. tostring(susp and susp.Value or "?")
    end)
    task.wait(1)
  end
end)

print("[Merampok No1+No2] loaded, semua OFF, teleport manual pisah.")
