-- Tambang Antartika - HUB 1 Menu (ESP + Boulder + Swing)
-- Gabungan: ESP Gem liar (SpawnedGems+gunung, filter tingkat+harga+jarak) + ESP Boulder + ESP Player
-- + teleport/auto boulder + auto swing 0.2s. Murni visual + teleport, tanpa ubah stat.
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local Cfg = { Gem = true, Boulder = true, Player = false, MaxDist = 400,
    MinRank = 0, MinValue = 0, Auto = false, Swing = false, Target = nil }

local RANK = {
    ["umum"] = 1, ["common"] = 1,
    ["tidak biasa"] = 2, ["uncommon"] = 2,
    ["langka"] = 3, ["rare"] = 3,
    ["epik"] = 4, ["epic"] = 4,
    ["legendaris"] = 5, ["legendary"] = 5, ["legend"] = 5,
    ["mistik"] = 6, ["mistis"] = 6, ["mythic"] = 6,
    ["eksotis"] = 7, ["exotic"] = 7,
}
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
local function RarityOf(m)
    do -- GemInfo.Weight = '<font>RARITY</font> ... kg' (akurat, tes live)
        local mesh = m:FindFirstChild("Mesh_0")
        local gi = mesh and mesh:FindFirstChild("GemInfo")
        local w = gi and gi:FindFirstChild("Weight")
        if w and w:IsA("TextLabel") then
            local t = string.lower(w.Text or "")
            for name, r in pairs(RANK) do
                if t:find(name, 1, true) then return r, w.Text end
            end
        end
    end
    for _, d in ipairs(m:GetDescendants()) do
        if d:IsA("TextLabel") then
            local t = string.lower(d.Text or "")
            for name, r in pairs(RANK) do
                if t:find(name, 1, true) then return r, d.Text end
            end
        end
    end
    local nm = string.lower(m.Name or "")
    for name, r in pairs(RANK) do
        if nm:find(name, 1, true) then return r, m.Name end
    end
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
local function Boulders() return workspace:FindFirstChild("Boulders") end
local function BList()
    local out = {} local b = Boulders() if not b then return out end
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

-- Loops
task.spawn(function() -- ESP scan
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
            -- update teks
            if myPos then
                for _, bb in ipairs(workspace:GetDescendants()) do
                    if bb:IsA("BillboardGui") and myPos then
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
task.spawn(function() -- auto boulder
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
task.spawn(function() -- auto swing 0.2s (setara gamepass, bukan 0.01)
    while true do
        if Cfg.Swing then pcall(SwingOnce) end
        task.wait(0.2)
    end
end)

-- UI 1 menu
local gui = Instance.new("ScreenGui") gui.Name = "TAHub" gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP.PlayerGui end
local main = Instance.new("Frame")
main.Size = UDim2.new(0,250,0,430) main.Position = UDim2.new(0,20,0.5,-215)
main.BackgroundColor3 = Color3.fromRGB(16,18,26) main.BorderSizePixel = 0
main.Active = true main.Draggable = true main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,30) title.BackgroundTransparency = 1
title.Text = "  Tambang Hub" title.Font = Enum.Font.GothamBold title.TextSize = 14
title.TextColor3 = Color3.new(1,1,1) title.TextXAlignment = Enum.TextXAlignment.Left title.Parent = main
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-16,1,-40) scroll.Position = UDim2.new(0,8,0,34)
scroll.BackgroundTransparency = 1 scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0,0,0,640) scroll.Parent = main
local lay = Instance.new("UIListLayout") lay.Padding = UDim.new(0,6) lay.Parent = scroll
local function Sec(t)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-8,0,18) l.BackgroundTransparency = 1 l.Text = t
    l.Font = Enum.Font.GothamBold l.TextSize = 12 l.TextColor3 = Color3.fromRGB(255,200,90)
    l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = scroll
end
local function Btn(t, cb, c)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-8,0,28) b.BackgroundColor3 = c or Color3.fromRGB(30,33,45)
    b.Font = Enum.Font.GothamBold b.TextSize = 12 b.TextColor3 = Color3.new(1,1,1)
    b.Text = t b.Parent = scroll
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(function() pcall(cb, b) end)
    return b
end
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1,-8,0,30) info.BackgroundTransparency = 1
info.Font = Enum.Font.Code info.TextSize = 11 info.TextColor3 = Color3.new(0.85,0.85,0.85)
info.TextXAlignment = Enum.TextXAlignment.Left info.Text = "..." info.Parent = scroll

Sec("— ESP —")
Btn("[ON] ESP Gem", function(b)
    Cfg.Gem = not Cfg.Gem b.Text = (Cfg.Gem and "[ON] " or "[OFF] ") .. "ESP Gem"
    if not Cfg.Gem then for _, d in ipairs(workspace:GetDescendants()) do if d.Name == "TA_GEM_ESP" then pcall(function() d:Destroy() end) end end end
end)
Btn("[ON] ESP Boulder", function(b)
    Cfg.Boulder = not Cfg.Boulder b.Text = (Cfg.Boulder and "[ON] " or "[OFF] ") .. "ESP Boulder"
    if not Cfg.Boulder then for _, d in ipairs(workspace:GetDescendants()) do if d.Name == "TA_BLD_ESP" then pcall(function() d:Destroy() end) end end end
end)
Btn("[OFF] ESP Player", function(b)
    Cfg.Player = not Cfg.Player b.Text = (Cfg.Player and "[ON] " or "[OFF] ") .. "ESP Player"
    if not Cfg.Player then for _, d in ipairs(workspace:GetDescendants()) do if d.Name == "TA_PLY_ESP" then pcall(function() d:Destroy() end) end end end
end)
Btn("Jarak gem: 400", function(b)
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then Cfg.MaxDist = math.min(2000, Cfg.MaxDist + 100)
    else Cfg.MaxDist = math.max(0, Cfg.MaxDist - 100) if Cfg.MaxDist == 0 then Cfg.MaxDist = 2000 end end
    b.Text = "Jarak gem: " .. tostring(Cfg.MaxDist)
end)
local CYCLE = { 0, 3, 4, 5, 6 }
Btn("Tingkat: Semua", function(b)
    local cur = 1
    for i, v in ipairs(CYCLE) do if v == Cfg.MinRank then cur = i break end end
    Cfg.MinRank = CYCLE[cur % #CYCLE + 1]
    b.Text = "Tingkat: " .. (RANKNAME[Cfg.MinRank] or tostring(Cfg.MinRank))
    ClearESP()
end)
Btn("Harga min: $0", function(b)
    local cur = 1
    for i, v in ipairs(PRICE) do if v == Cfg.MinValue then cur = i break end end
    Cfg.MinValue = PRICE[cur % #PRICE + 1]
    b.Text = "Harga min: " .. PriceTxt(Cfg.MinValue)
    ClearESP()
end)
Btn("Bersihkan ESP", ClearESP)
Sec("— BOULDER —")
Btn("Target: TERDEKAT", function(b)
    local list = BList() if #list == 0 then return end
    local cur = nil
    for i, e in ipairs(list) do if e.Name == Cfg.Target then cur = i break end end
    local nxt = list[(cur or 0) % #list + 1]
    if Cfg.Target == nxt.Name then Cfg.Target = nil b.Text = "Target: TERDEKAT"
    else Cfg.Target = nxt.Name b.Text = "Target: " .. nxt.Name end
end)
Btn("Teleport ke target", function() BGo() end, Color3.fromRGB(40,100,150))
Btn("Tambang sekali (E)", function() BMine() end)
Btn("[OFF] Auto TP + E", function(b)
    Cfg.Auto = not Cfg.Auto b.Text = (Cfg.Auto and "[ON] " or "[OFF] ") .. "Auto TP + E"
end)
Btn("[OFF] Auto Swing 0.2s", function(b)
    Cfg.Swing = not Cfg.Swing b.Text = (Cfg.Swing and "[ON] " or "[OFF] ") .. "Auto Swing 0.2s"
end)
task.spawn(function()
    while gui.Parent do
        pcall(function()
            local list = BList()
            local n = BNearest()
            info.Text = #list .. " batu | target: " .. (n and n.Name or "-")
        end)
        task.wait(1)
    end
end)
local mini = Instance.new("TextButton")
mini.Size = UDim2.new(0,64,0,28) mini.Position = UDim2.new(0,20,0,10)
mini.BackgroundColor3 = Color3.fromRGB(16,18,26) mini.Font = Enum.Font.GothamBold
mini.TextSize = 12 mini.TextColor3 = Color3.new(1,1,1) mini.Text = "HUB"
mini.Parent = gui
Instance.new("UICorner", mini).CornerRadius = UDim.new(0,8)
mini.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)
UIS.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightControl then main.Visible = not main.Visible end
end)
print("[TA-Hub] loaded (ESP + Boulder + Swing, 1 menu).")
