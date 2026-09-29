-- Tambang Antartika - HUB v2 (lebar, sub-menu: ESP | Boulder | Swing | Teleport)
-- ESP: gem liar + boulder + player (filter tingkat/harga/jarak)
-- Boulder: target/teleport/auto + Auto Swing SPAM (terpisah dari Swing Speed)
-- Swing: (1) Auto Swing spam rate atur + (2) Swing Speed changer (coba patch PickaxeData/tool)
-- Teleport: input manual ketinggian (meter) + waypoint + Plot/Jual/Pulang
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Cfg = { Gem = true, Boulder = true, Player = false, MaxDist = 400,
    MinRank = 0, MinValue = 0, Auto = false, Swing = false, SwingRate = 0.2,
    SwingSpeed = 0.2, Target = nil }

local RANK = { ["umum"] = 1, ["common"] = 1, ["tidak biasa"] = 2, ["uncommon"] = 2,
    ["langka"] = 3, ["rare"] = 3, ["epik"] = 4, ["epic"] = 4,
    ["legendaris"] = 5, ["legendary"] = 5, ["legend"] = 5,
    ["mistik"] = 6, ["mistis"] = 6, ["mythic"] = 6, ["eksotis"] = 7, ["exotic"] = 7 }
local RANKNAME = { [0] = "Semua", [3] = "Langka+", [4] = "Epik+", [5] = "Legendaris+", [6] = "Mistik" }
local PRICE = { 0, 100000, 500000, 1000000, 5000000 }
local function PriceTxt(v)
    if v >= 1000000 then return "$" .. tostring(v / 1000000):gsub("%.0$", "") .. "jt" end
    if v >= 1000 then return "$" .. tostring(v / 1000):gsub("%.0$", "") .. "rb" end
    return "$" .. tostring(v)
end

local function HRP() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function PivotOf(m)
    local ok, cf = pcall(function() return m:GetPivot() end)
    if ok then return cf.Position end
    local p = m:FindFirstChildWhichIsA("BasePart")
    return p and p.Position or nil
end
local function Alt(p) return p and math.floor((p.Y - 62) / 2) or -1 end
local function RarityOf(m)
    do local mesh = m:FindFirstChild("Mesh_0")
        local gi = mesh and mesh:FindFirstChild("GemInfo")
        local w = gi and gi:FindFirstChild("Weight")
        if w and w:IsA("TextLabel") then
            local t = string.lower(w.Text or "")
            for name, r in pairs(RANK) do if t:find(name, 1, true) then return r, w.Text end end
        end
    end
    local nm = string.lower(m.Name or "")
    for name, r in pairs(RANK) do if nm:find(name, 1, true) then return r, m.Name end end
    return 1, "?"
end
local function ValueOf(m)
    local mesh = m:FindFirstChild("Mesh_0")
    local gi = mesh and mesh:FindFirstChild("GemInfo")
    local v = gi and gi:FindFirstChild("Value")
    if v and v:IsA("TextLabel") then
        local t = tostring(v.Text or "")
        local num, suf = t:match("%$([%d,%.]+)%s*([KMBkmb]?)")
        if num then
            num = tonumber((num:gsub(",", ""))) or 0
            suf = string.upper(suf or "")
            if suf == "K" then num = num * 1000
            elseif suf == "M" then num = num * 1000000
            elseif suf == "B" then num = num * 1000000000 end
            return num
        end
    end
    return 0
end
local function MkBB(parent, ador, name, bg, fg, size)
    local bb = Instance.new("BillboardGui")
    bb.Name = name bb.Size = size or UDim2.new(0,160,0,28)
    bb.StudsOffset = Vector3.new(0,3,0) bb.AlwaysOnTop = true
    bb.Adornee = ador bb.Parent = parent
    local tl = Instance.new("TextLabel")
    tl.Name = "Txt" tl.Size = UDim2.new(1,0,1,0) tl.BackgroundTransparency = 0.4
    tl.BackgroundColor3 = bg tl.TextColor3 = fg tl.TextStrokeTransparency = 0
    tl.TextSize = 12 tl.Font = Enum.Font.Code tl.Parent = bb
    Instance.new("UICorner", bb).CornerRadius = UDim.new(0,8)
    return bb
end
-- Boulder
local function BList()
    local out = {} local b = workspace:FindFirstChild("Boulders") if not b then return out end
    for _, m in ipairs(b:GetChildren()) do
        if m:IsA("Model") then
            local part = m:FindFirstChild("Mesh_0") or m:FindFirstChildWhichIsA("BasePart")
            if part then table.insert(out, { Model = m, Part = part, Name = m.Name }) end
        end
    end
    return out
end
local function BNearest()
    local hrp = HRP() local list = BList() if #list == 0 then return nil end
    if Cfg.Target then for _, e in ipairs(list) do if e.Name == Cfg.Target then return e end end end
    local best, bd = nil, math.huge
    for _, e in ipairs(list) do
        if hrp then local d = (e.Part.Position - hrp.Position).Magnitude if d < bd then bd = d best = e end
        else best = best or e end
    end
    return best
end
local function BHP(e)
    local bar = e.Part:FindFirstChild("HpBar") local tl = bar and bar:FindFirstChild("TextLabel")
    return (tl and tl.Text) or ""
end
local function BGo(e)
    e = e or BNearest() local hrp = HRP()
    if e and hrp then hrp.CFrame = CFrame.new(e.Part.Position + Vector3.new(0,5,5), e.Part.Position) return true end
    return false
end
local function BMine(e)
    e = e or BNearest() if not e then return end
    local pr = e.Part:FindFirstChild("BoulderMine")
    if pr then pcall(function() fireproximityprompt(pr) end) end
end
local function SwingOnce()
    local ch = LP.Character if not ch then return end
    for _, t in ipairs(ch:GetChildren()) do
        if t:IsA("Tool") then pcall(function() t:Activate() end) end
    end
end
local function ClearESP()
    for _, d in ipairs(workspace:GetDescendants()) do
        if d.Name == "TA_GEM_ESP" or d.Name == "TA_BLD_ESP" or d.Name == "TA_PLY_ESP" then
            pcall(function() d:Destroy() end)
        end
    end
end
-- Swing Speed changer: coba patch tabel PickaxeData + atribut/NumberValue di tool
local SwingStat = { found = "belum dicek" }
local function PatchSwing(v)
    local n = 0
    local function patchTable(t, depth)
        if type(t) ~= "table" or (depth or 0) > 2 then return end
        for k, val in pairs(t) do
            if type(val) == "number" and type(k) == "string" then
                local kl = string.lower(k)
                if kl:find("swing") or kl:find("cooldown") or kl:find("delay") or kl:find("attackspeed") or kl:find("attackrate") then
                    pcall(function() t[k] = v end) n += 1
                end
            elseif type(val) == "table" then patchTable(val, (depth or 0) + 1) end
        end
    end
    pcall(function()
        local data = require(RS:WaitForChild("PickaxeData"))
        patchTable(data, 0)
    end)
    local function patchInst(inst)
        for k2, val in pairs(inst:GetAttributes()) do
            if type(val) == "number" then
                local kl = string.lower(k2)
                if kl:find("swing") or kl:find("cooldown") or kl:find("delay") or kl:find("speed") then
                    pcall(function() inst:SetAttribute(k2, v) end) n += 1
                end
            end
        end
        for _, d in ipairs(inst:GetDescendants()) do
            if d:IsA("NumberValue") or d:IsA("IntValue") then
                local kl = string.lower(d.Name)
                if kl:find("swing") or kl:find("cooldown") or kl:find("delay") or kl:find("speed") then
                    pcall(function() d.Value = v end) n += 1
                end
            end
        end
    end
    pcall(function()
        local ch = LP.Character
        if ch then for _, t in ipairs(ch:GetChildren()) do if t:IsA("Tool") then patchInst(t) end end end
        local bp = LP:FindFirstChild("Backpack")
        if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then patchInst(t) end end end
        for _, t in ipairs(RS:FindFirstChild("PickaxeTools"):GetChildren()) do patchInst(t) end
    end)
    if n > 0 then SwingStat.found = "diterapkan ke " .. n .. " field (" .. v .. "s)"
    else SwingStat.found = "field tidak ketemu (game baca dari script)" end
    return n
end

-- Loops
task.spawn(function()
    while true do
        pcall(function()
            local hrp = HRP()
            local myPos = hrp and hrp.Position
            if Cfg.Gem then
                local function TryGem(m)
                    if not m:IsA("Model") then return end
                    if m:FindFirstChild("TA_GEM_ESP") then return end
                    local hasInfo = false
                    for _, d in ipairs(m:GetChildren()) do
                        if d.Name == "Mesh_0" and d:FindFirstChild("GemInfo") then hasInfo = true break end
                    end
                    if not hasInfo then
                        for _, d in ipairs(m:GetDescendants()) do
                            if d.Name == "GemInfo" and d:IsA("BillboardGui") then hasInfo = true break end
                        end
                    end
                    if not hasInfo then return end
                    if RarityOf(m) < Cfg.MinRank then return end
                    if ValueOf(m) < Cfg.MinValue then return end
                    local pos = PivotOf(m)
                    if not pos then return end
                    local d = (myPos and (pos - myPos).Magnitude) or 0
                    if Cfg.MaxDist > 0 and d > Cfg.MaxDist then return end
                    local ador = m:FindFirstChildWhichIsA("BasePart", true)
                    if ador then MkBB(m, ador, "TA_GEM_ESP", Color3.fromRGB(30,25,10), Color3.new(1,0.85,0.3)) end
                end
                local sg = workspace:FindFirstChild("SpawnedGems")
                if sg then for _, m in ipairs(sg:GetChildren()) do TryGem(m) end end
                for _, top in ipairs(workspace:GetChildren()) do
                    if top:IsA("Model") and (top.Name == "Model" or top.Name:find("Mountain") or top.Name:find("Mine") or top.Name:find("Zone")) then
                        for _, m in ipairs(top:GetDescendants()) do
                            if m:IsA("Model") then TryGem(m) end
                        end
                    end
                end
            end
            if Cfg.Boulder then
                for _, e in ipairs(BList()) do
                    if not e.Model:FindFirstChild("TA_BLD_ESP") then
                        MkBB(e.Model, e.Part, "TA_BLD_ESP", Color3.fromRGB(10,20,40), Color3.new(0.5,0.8,1), UDim2.new(0,220,0,50))
                    end
                end
            end
            if Cfg.Player then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character and not p.Character:FindFirstChild("TA_PLY_ESP") then
                        local phrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if phrp then
                            local bb = MkBB(p.Character, phrp, "TA_PLY_ESP", Color3.fromRGB(15,35,20), Color3.new(0.5,1,0.6), UDim2.new(0,160,0,40))
                            bb.StudsOffset = Vector3.new(0,4,0)
                        end
                    end
                end
            end
            if myPos then
                for _, bb in ipairs(workspace:GetDescendants()) do
                    if bb:IsA("BillboardGui") then
                        local m = bb.Parent
                        local t = bb:FindFirstChild("Txt")
                        if bb.Name == "TA_GEM_ESP" and m and t then
                            local pos = PivotOf(m)
                            if pos then
                                local d = math.floor((pos - myPos).Magnitude)
                                if Cfg.MaxDist > 0 and d > Cfg.MaxDist then pcall(function() bb:Destroy() end)
                                elseif ValueOf(m) < Cfg.MinValue then pcall(function() bb:Destroy() end)
                                else
                                    local v = ValueOf(m)
                                    local vs = ""
                                    if v >= 1000000 then vs = " $" .. string.format("%.2fjt", v / 1000000)
                                    elseif v >= 1000 then vs = " $" .. string.format("%.0frb", v / 1000) end
                                    t.Text = m.Name .. " " .. tostring(d) .. "m" .. vs
                                end
                            end
                        elseif bb.Name == "TA_BLD_ESP" and m and t then
                            local pos = PivotOf(m)
                            if pos then
                                local d = math.floor((pos - myPos).Magnitude)
                                local e
                                for _, x in ipairs(BList()) do if x.Model == m then e = x break end end
                                t.Text = "BATU " .. string.upper(m.Name) .. "\n" .. (e and BHP(e) or "") .. " | " .. tostring(d) .. "m"
                            end
                        elseif bb.Name == "TA_PLY_ESP" and t then
                            local ch = bb.Parent
                            local pl = Players:GetPlayerFromCharacter(ch)
                            if not pl or pl == LP then pcall(function() bb:Destroy() end)
                            else
                                local phrp = ch:FindFirstChild("HumanoidRootPart")
                                local hum = ch:FindFirstChildOfClass("Humanoid")
                                if phrp then
                                    local d = math.floor((phrp.Position - myPos).Magnitude)
                                    local hp = hum and (" " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)) or ""
                                    t.Text = pl.DisplayName .. " (@" .. pl.Name .. ")\n" .. tostring(d) .. "m" .. hp
                                end
                            end
                        end
                    end
                end
            end
        end)
        task.wait(2)
    end
end)
task.spawn(function()
    while true do
        if Cfg.Auto then
            pcall(function()
                local e = BNearest() local hrp = HRP()
                if e and hrp then
                    if (e.Part.Position - hrp.Position).Magnitude > 20 then BGo(e)
                    else BMine(e) end
                end
            end)
        end
        task.wait(0.4)
    end
end)
task.spawn(function()
    while true do
        if Cfg.Swing then pcall(SwingOnce) end
        task.wait(math.max(0.05, Cfg.SwingRate))
    end
end)

-- UI lebar + sub-menu
local gui = Instance.new("ScreenGui") gui.Name = "TAHub2" gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP.PlayerGui end
local main = Instance.new("Frame")
main.Size = UDim2.new(0,600,0,400) main.Position = UDim2.new(0.5,-300,0.5,-200)
main.BackgroundColor3 = Color3.fromRGB(16,18,26) main.BorderSizePixel = 0
main.Active = true main.Draggable = true main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)
local side = Instance.new("Frame")
side.Size = UDim2.new(0,150,1,0) side.BackgroundColor3 = Color3.fromRGB(12,14,20)
side.BorderSizePixel = 0 side.Parent = main
Instance.new("UICorner", side).CornerRadius = UDim.new(0,10)
local sideT = Instance.new("TextLabel")
sideT.Size = UDim2.new(1,0,0,44) sideT.BackgroundTransparency = 1
sideT.Text = "Tambang Hub" sideT.Font = Enum.Font.GothamBold sideT.TextSize = 15
sideT.TextColor3 = Color3.new(1,1,1) sideT.Parent = side
local content = Instance.new("Frame")
content.Size = UDim2.new(1,-158,1,-8) content.Position = UDim2.new(0,154,0,4)
content.BackgroundTransparency = 1 content.Parent = main

local pages, tabBtns = {}, {}
local tabNames = { "ESP", "Boulder", "Swing", "Teleport" }
for i, tn in ipairs(tabNames) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-12,0,34) b.Position = UDim2.new(0,6,0,48 + (i-1)*40)
    b.BackgroundColor3 = Color3.fromRGB(24,27,38) b.Text = "  " .. tn
    b.Font = Enum.Font.GothamBold b.TextSize = 13 b.TextColor3 = Color3.fromRGB(200,200,200)
    b.TextXAlignment = Enum.TextXAlignment.Left b.Parent = side
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    local pg = Instance.new("ScrollingFrame")
    pg.Size = UDim2.new(1,0,1,0) pg.BackgroundTransparency = 1
    pg.ScrollBarThickness = 4 pg.CanvasSize = UDim2.new(0,0,0,620)
    pg.Visible = (i == 1) pg.Parent = content
    local lay = Instance.new("UIListLayout") lay.Padding = UDim.new(0,6) lay.Parent = pg
    pages[tn] = pg
    tabBtns[tn] = b
    b.MouseButton1Click:Connect(function()
        for _, p in pairs(pages) do p.Visible = false end
        for _, x in pairs(tabBtns) do x.BackgroundColor3 = Color3.fromRGB(24,27,38) end
        pg.Visible = true b.BackgroundColor3 = Color3.fromRGB(50,90,150)
    end)
end
tabBtns["ESP"].BackgroundColor3 = Color3.fromRGB(50,90,150)
local function Sec(pg, t)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-4,0,18) l.BackgroundTransparency = 1 l.Text = t
    l.Font = Enum.Font.GothamBold l.TextSize = 12 l.TextColor3 = Color3.fromRGB(255,200,90)
    l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = pg
end
local function Btn(pg, t, cb, c)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-4,0,28) b.BackgroundColor3 = c or Color3.fromRGB(28,31,43)
    b.Font = Enum.Font.Gotham b.TextSize = 12 b.TextColor3 = Color3.fromRGB(230,230,230)
    b.TextXAlignment = Enum.TextXAlignment.Left b.Parent = pg
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    local function ref(extra) b.Text = "  " .. (extra or "") .. t end
    ref()
    b.MouseButton1Click:Connect(function() pcall(cb, b) end)
    return b, ref
end
local function Tog(pg, t, get, set)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-4,0,28) b.BackgroundColor3 = Color3.fromRGB(28,31,43)
    b.Font = Enum.Font.Gotham b.TextSize = 12 b.TextColor3 = Color3.fromRGB(230,230,230)
    b.TextXAlignment = Enum.TextXAlignment.Left b.Parent = pg
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    local function ref() b.Text = "  " .. (get() and "[ON]  " or "[OFF] ") .. t end
    ref()
    b.MouseButton1Click:Connect(function() set(not get()) ref() end)
    return b
end

-- ===== TAB ESP =====
do local pg = pages["ESP"]
    Sec(pg, "ESP (visual saja)")
    Tog(pg, "ESP Gem liar", function() return Cfg.Gem end, function(v) Cfg.Gem = v
        if not v then for _, d in ipairs(workspace:GetDescendants()) do if d.Name == "TA_GEM_ESP" then pcall(function() d:Destroy() end) end end end end)
    Tog(pg, "ESP Boulder", function() return Cfg.Boulder end, function(v) Cfg.Boulder = v
        if not v then for _, d in ipairs(workspace:GetDescendants()) do if d.Name == "TA_BLD_ESP" then pcall(function() d:Destroy() end) end end end end)
    Tog(pg, "ESP Player", function() return Cfg.Player end, function(v) Cfg.Player = v
        if not v then for _, d in ipairs(workspace:GetDescendants()) do if d.Name == "TA_PLY_ESP" then pcall(function() d:Destroy() end) end end end end)
    Btn(pg, "Jarak gem: 400", function(b)
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then Cfg.MaxDist = math.min(2000, Cfg.MaxDist + 100)
        else Cfg.MaxDist = math.max(0, Cfg.MaxDist - 100) if Cfg.MaxDist == 0 then Cfg.MaxDist = 2000 end end
        b.Text = "  Jarak gem: " .. tostring(Cfg.MaxDist)
    end)
    local CYCLE = { 0, 3, 4, 5, 6 }
    Btn(pg, "Tingkat: Semua", function(b)
        local cur = 1
        for i, v in ipairs(CYCLE) do if v == Cfg.MinRank then cur = i break end end
        Cfg.MinRank = CYCLE[cur % #CYCLE + 1]
        b.Text = "  Tingkat: " .. (RANKNAME[Cfg.MinRank] or tostring(Cfg.MinRank))
        ClearESP()
    end)
    Btn(pg, "Harga min: $0", function(b)
        local cur = 1
        for i, v in ipairs(PRICE) do if v == Cfg.MinValue then cur = i break end end
        Cfg.MinValue = PRICE[cur % #PRICE + 1]
        b.Text = "  Harga min: " .. PriceTxt(Cfg.MinValue)
        ClearESP()
    end)
    Btn(pg, "Bersihkan ESP", function() ClearESP() end)
end
-- ===== TAB BOULDER =====
do local pg = pages["Boulder"]
    Sec(pg, "Batu event (Mossite/Voltite/dll)")
    local infoB = Instance.new("TextLabel")
    infoB.Size = UDim2.new(1,-4,0,30) infoB.BackgroundTransparency = 1
    infoB.Font = Enum.Font.Code infoB.TextSize = 11 infoB.TextColor3 = Color3.new(0.85,0.85,0.85)
    infoB.TextXAlignment = Enum.TextXAlignment.Left infoB.Text = "..." infoB.Parent = pg
    Btn(pg, "Target: TERDEKAT", function(b)
        local list = BList() if #list == 0 then return end
        local cur = nil
        for i, e in ipairs(list) do if e.Name == Cfg.Target then cur = i break end end
        local nxt = list[(cur or 0) % #list + 1]
        if Cfg.Target == nxt.Name then Cfg.Target = nil b.Text = "  Target: TERDEKAT"
        else Cfg.Target = nxt.Name b.Text = "  Target: " .. nxt.Name end
    end)
    Btn(pg, "Teleport ke target", function() BGo() end)
    Btn(pg, "Tambang sekali (E)", function() BMine() end)
    Tog(pg, "Auto TP + E", function() return Cfg.Auto end, function(v) Cfg.Auto = v end)
    task.spawn(function()
        while gui.Parent do
            pcall(function()
                local list = BList() local n = BNearest()
                infoB.Text = #list .. " batu | target: " .. (n and n.Name or "-")
            end)
            task.wait(1)
        end
    end)
end
-- ===== TAB SWING (spam vs speed dipisah) =====
do local pg = pages["Swing"]
    Sec(pg, "A. Auto Swing SPAM (klik tool)")
    Tog(pg, "Auto Swing", function() return Cfg.Swing end, function(v) Cfg.Swing = v end)
    Btn(pg, "Rate: 0.2s", function(b)
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then Cfg.SwingRate = math.min(1, Cfg.SwingRate + 0.05)
        else Cfg.SwingRate = math.max(0.05, Cfg.SwingRate - 0.05) end
        b.Text = "  Rate: " .. string.format("%.2fs", Cfg.SwingRate)
    end)
    Sec(pg, "B. Swing SPEED changer (patch)")
    local statL = Instance.new("TextLabel")
    statL.Size = UDim2.new(1,-4,0,30) statL.BackgroundTransparency = 1
    statL.Font = Enum.Font.Code statL.TextSize = 11 statL.TextColor3 = Color3.new(0.85,0.85,0.85)
    statL.TextXAlignment = Enum.TextXAlignment.Left statL.TextWrapped = true
    statL.Text = "Status: " .. SwingStat.found statL.Parent = pg
    Btn(pg, "Speed: 0.2s", function(b)
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then Cfg.SwingSpeed = math.min(0.4, Cfg.SwingSpeed + 0.05)
        else Cfg.SwingSpeed = math.max(0.01, Cfg.SwingSpeed - 0.05) end
        b.Text = "  Speed: " .. string.format("%.2fs", Cfg.SwingSpeed)
    end)
    Btn(pg, "TERAPKAN speed", function()
        local n = PatchSwing(Cfg.SwingSpeed)
        statL.Text = "Status: " .. SwingStat.found
    end)
    local warn = Instance.new("TextLabel")
    warn.Size = UDim2.new(1,-4,0,60) warn.BackgroundTransparency = 1
    warn.Font = Enum.Font.Gotham warn.TextSize = 11 warn.TextColor3 = Color3.fromRGB(255,150,120)
    warn.TextXAlignment = Enum.TextXAlignment.Left warn.TextWrapped = true
    warn.Text = "Catatan: angka ayun ada di script PickaxeClient. Kalau status 'tidak ketemu', berarti patch tidak nempel." warn.Parent = pg
end
-- ===== TAB TELEPORT (manual meter) =====
do local pg = pages["Teleport"]
    Sec(pg, "Ketinggian manual (meter)")
    local altL = Instance.new("TextLabel")
    altL.Size = UDim2.new(1,-4,0,20) altL.BackgroundTransparency = 1
    altL.Font = Enum.Font.Code altL.TextSize = 12 altL.TextColor3 = Color3.new(0.8,0.9,1)
    altL.TextXAlignment = Enum.TextXAlignment.Left altL.Text = "Kamu: ..." altL.Parent = pg
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1,-4,0,30) box.BackgroundColor3 = Color3.fromRGB(28,31,43)
    box.Font = Enum.Font.GothamBold box.TextSize = 13 box.TextColor3 = Color3.new(1,1,1)
    box.PlaceholderText = "Ketik meter, mis. 674" box.Text = "" box.Parent = pg
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)
    Btn(pg, "PERGI ke meter itu", function()
        local m = tonumber(box.Text)
        if not m then box.Text = "" box.PlaceholderText = "Isi angka dulu!" return end
        local hrp = HRP() if not hrp then return end
        local y = 62 + m * 2
        hrp.CFrame = CFrame.new(Vector3.new(hrp.Position.X, y + 3, hrp.Position.Z))
        hrp.Velocity = Vector3.new()
    end)
    Btn(pg, "Naik +50m / +150m (SHIFT)", function(b)
        local hrp = HRP() if not hrp then return end
        local dy = UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 300 or 100
        local p = hrp.Position
        hrp.CFrame = CFrame.new(p + Vector3.new(0, dy, 0))
        hrp.Velocity = Vector3.new()
    end)
    Sec(pg, "Waypoint (klik simpan, SHIFT+klik pergi)")
    local slots = { nil, nil, nil }
    for i = 1, 3 do
        Btn(pg, "Titik " .. i .. ": -", function(b)
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
                if slots[i] then local hrp = HRP() if hrp then hrp.CFrame = CFrame.new(slots[i] + Vector3.new(0,3,0)) hrp.Velocity = Vector3.new() end end
            else
                local hrp = HRP()
                if hrp then slots[i] = hrp.Position b.Text = "  Titik " .. i .. ": " .. Alt(slots[i]) .. "m" end
            end
        end)
    end
    Sec(pg, "Cepat")
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,-4,0,28) row.BackgroundTransparency = 1 row.Parent = pg
    local function small(t, x, f)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1/3,-3,1,0) b.Position = UDim2.new((x-1)/3 + (x-1)*0.005, 0, 0, 0)
        b.BackgroundColor3 = Color3.fromRGB(50,90,150) b.Font = Enum.Font.GothamBold
        b.TextSize = 11 b.TextColor3 = Color3.new(1,1,1) b.Text = t b.Parent = row
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
        b.MouseButton1Click:Connect(function()
            pcall(function()
                local cur = game
                for part in string.gmatch(f, "[^%.]+") do
                    if part ~= "game" then cur = cur:FindFirstChild(part) if not cur then return end end
                end
                if cur:IsA("RemoteEvent") then cur:FireServer() end
            end)
        end)
    end
    small("Plot", 1, "ReplicatedStorage.BackpackRemotes.TeleportPlot")
    small("Jual", 2, "ReplicatedStorage.BackpackRemotes.TeleportSell")
    small("Pulang", 3, "ReplicatedStorage.BaseRemotes.TeleportHome")
    task.spawn(function()
        while gui.Parent do
            pcall(function()
                local hrp = HRP()
                altL.Text = hrp and ("Kamu: " .. Alt(hrp.Position) .. "m") or "Kamu: ..."
            end)
            task.wait(1)
        end
    end)
end

local mini = Instance.new("TextButton")
mini.Size = UDim2.new(0,64,0,28) mini.Position = UDim2.new(0,20,0,10)
mini.BackgroundColor3 = Color3.fromRGB(16,18,26) mini.Font = Enum.Font.GothamBold
mini.TextSize = 12 mini.TextColor3 = Color3.new(1,1,1) mini.Text = "HUB"
mini.Parent = gui
Instance.new("UICorner", mini).CornerRadius = UDim.new(0,8)
mini.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)
UIS.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightShift then main.Visible = not main.Visible end
end)
print("[TA-Hub2] loaded.")
