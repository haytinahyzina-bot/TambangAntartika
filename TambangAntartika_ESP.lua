-- Tambang Antartika - ESP Gabungan v1 (Gem + Boulder, 1 menu)
-- Gem: Workspace.PlotCrystals.Plot<1-8>.<Nama> | Boulder: Workspace.Boulders.<Nama> > Mesh_0 + HpBar
-- Murni visual, tidak mengubah speed/stat.
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Cfg = { Gem = true, Boulder = true, Player = false, MaxDist = 400, MinRank = 0, MinValue = 0 }
-- Tingkatan (ID + EN): 0=semua
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
-- Harga live: Mesh_0.GemInfo.Value = '<font ...>$672,000</font>' (tes live)
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
local function RarityOf(m)
    -- 0) PALING AKURAT: Mesh_0.GemInfo.Weight = '<font ...>RARITY</font> ... kg' (tes live:
    --     Rare=#469BFF, Legendary=#FFAA2D, format sama untuk semua gem)
    do
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
    -- 1) atribut umum
    for _, k in ipairs({"Rarity","RarityName","Tier","TierName","Rank","RarityId"}) do
        local ok, v = pcall(function() return m:GetAttribute(k) end)
        if ok and v ~= nil then
            if type(v) == "number" then return tonumber(v), tostring(v) end
            local r = RANK[string.lower(tostring(v))]
            if r then return r, tostring(v) end
        end
    end
    -- 2) teks di billboard bawaan model
    for _, d in ipairs(m:GetDescendants()) do
        if d:IsA("TextLabel") then
            local t = string.lower(d.Text or "")
            for name, r in pairs(RANK) do
                if t:find(name, 1, true) then return r, d.Text end
            end
        end
    end
    -- 3) kata kunci di nama model
    local nm = string.lower(m.Name or "")
    for name, r in pairs(RANK) do
        if nm:find(name, 1, true) then return r, m.Name end
    end
    return 1, "?"
end

local function HRP() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function PivotOf(m)
    local ok, cf = pcall(function() return m:GetPivot() end)
    if ok then return cf.Position end
    local p = m:FindFirstChildWhichIsA("BasePart")
    return p and p.Position or nil
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

task.spawn(function()
    while true do
        pcall(function()
            local hrp = HRP()
            local myPos = hrp and hrp.Position
            -- GEM (2 scope: PlotCrystals + gunung/folder "Model" generik yang ada GemInfo-nya)
            if Cfg.Gem then
                local function TryGem(m)
                    if not m:IsA("Model") then return end
                    if m:FindFirstChild("TA_GEM_ESP") then return end
                    if m:GetAttribute("TA_Skip") then return end
                    -- wajib ada GemInfo (ciri gem asli, bukan batu/dekorasi)
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
                -- gunung saja (plot tidak ikut): chunk "Model" generik yang ada GemInfo-nya
                for _, top in ipairs(workspace:GetChildren()) do
                    if top:IsA("Model") and (top.Name == "Model" or top.Name:find("Mountain") or top.Name:find("Mine") or top.Name:find("Zone")) then
                        for _, m in ipairs(top:GetDescendants()) do
                            if m:IsA("Model") then TryGem(m) end
                        end
                    end
                end
            end
            -- BOULDER
            if Cfg.Boulder then
                local b = workspace:FindFirstChild("Boulders")
                if b then
                    for _, m in ipairs(b:GetChildren()) do
                        if m:IsA("Model") and not m:FindFirstChild("TA_BLD_ESP") then
                            local part = m:FindFirstChild("Mesh_0") or m:FindFirstChildWhichIsA("BasePart")
                            if part then MkBB(m, part, "TA_BLD_ESP", Color3.fromRGB(10,20,40), Color3.new(0.5,0.8,1), UDim2.new(0,220,0,50)) end
                        end
                    end
                end
            end
            -- PLAYER LAIN
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
                for _, ch in ipairs(workspace:GetChildren()) do
                    local bb = ch:FindFirstChild("TA_PLY_ESP")
                    if bb and bb:IsA("BillboardGui") then
                        local pl = Players:GetPlayerFromCharacter(ch)
                        local t = bb:FindFirstChild("Txt")
                        if not pl or pl == LP then
                            pcall(function() bb:Destroy() end)
                        elseif t and myPos then
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
            -- update teks + cull jarak
            for _, bb in ipairs(workspace:GetDescendants()) do
                if bb:IsA("BillboardGui") and (bb.Name == "TA_GEM_ESP" or bb.Name == "TA_BLD_ESP") and myPos then
                    local m = bb.Parent
                    local t = bb:FindFirstChild("Txt")
                    if m and t then
                        local pos = PivotOf(m)
                        if pos then
                            local d = math.floor((pos - myPos).Magnitude)
                            if bb.Name == "TA_GEM_ESP" and Cfg.MaxDist > 0 and d > Cfg.MaxDist then
                                pcall(function() bb:Destroy() end)
                            elseif bb.Name == "TA_GEM_ESP" and ValueOf(m) < Cfg.MinValue then
                                pcall(function() bb:Destroy() end)
                            elseif bb.Name == "TA_BLD_ESP" then
                                local hp = ""
                                local part = m:FindFirstChild("Mesh_0")
                                local bar = part and part:FindFirstChild("HpBar")
                                local tl = bar and bar:FindFirstChild("TextLabel")
                                hp = (tl and tl.Text) or ""
                                t.Text = "BATU " .. string.upper(m.Name) .. "\n" .. hp .. " | " .. tostring(d) .. "m"
                            else
                                local v = ValueOf(m)
                                local vs = ""
                                if v >= 1000000 then vs = " $" .. string.format("%.2fjt", v / 1000000)
                                elseif v >= 1000 then vs = " $" .. string.format("%.0frb", v / 1000) end
                                t.Text = m.Name .. " " .. tostring(d) .. "m" .. vs
                            end
                        end
                    end
                end
            end
        end)
        task.wait(2)
    end
end)

local function Clear()
    for _, d in ipairs(workspace:GetDescendants()) do
        if d.Name == "TA_GEM_ESP" or d.Name == "TA_BLD_ESP" or d.Name == "TA_PLY_ESP" then pcall(function() d:Destroy() end) end
    end
end

local gui = Instance.new("ScreenGui") gui.Name = "TAESP" gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP.PlayerGui end
local main = Instance.new("Frame")
main.Size = UDim2.new(0,220,0,336) main.Position = UDim2.new(0,20,0.5,-168)
main.BackgroundColor3 = Color3.fromRGB(16,18,26) main.BorderSizePixel = 0
main.Active = true main.Draggable = true main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,28) title.BackgroundTransparency = 1
title.Text = "  ESP Gabungan" title.Font = Enum.Font.GothamBold title.TextSize = 13
title.TextColor3 = Color3.new(1,1,1) title.TextXAlignment = Enum.TextXAlignment.Left title.Parent = main
local function mk(t, y, cb, c)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-16,0,28) b.Position = UDim2.new(0,8,0,y)
    b.BackgroundColor3 = c or Color3.fromRGB(30,33,45) b.Font = Enum.Font.GothamBold
    b.TextSize = 12 b.TextColor3 = Color3.new(1,1,1) b.Text = t b.Parent = main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(function() pcall(cb, b) end)
    return b
end
mk("[ON] ESP Gem", 34, function(b)
    Cfg.Gem = not Cfg.Gem b.Text = (Cfg.Gem and "[ON] " or "[OFF] ") .. "ESP Gem"
    if not Cfg.Gem then for _, d in ipairs(workspace:GetDescendants()) do if d.Name == "TA_GEM_ESP" then pcall(function() d:Destroy() end) end end end
end)
mk("[ON] ESP Boulder", 68, function(b)
    Cfg.Boulder = not Cfg.Boulder b.Text = (Cfg.Boulder and "[ON] " or "[OFF] ") .. "ESP Boulder"
    if not Cfg.Boulder then for _, d in ipairs(workspace:GetDescendants()) do if d.Name == "TA_BLD_ESP" then pcall(function() d:Destroy() end) end end end
end)
mk("Jarak gem: 400", 102, function(b)
    if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then
        Cfg.MaxDist = math.min(2000, Cfg.MaxDist + 100)
    else
        Cfg.MaxDist = math.max(0, Cfg.MaxDist - 100)
        if Cfg.MaxDist == 0 then Cfg.MaxDist = 2000 end
    end
    b.Text = "Jarak gem: " .. tostring(Cfg.MaxDist)
end)
mk("Bersihkan semua", 136, Clear)
local CYCLE = { 0, 3, 4, 5, 6 }
mk("Tingkat: Semua", 170, function(b)
    local cur = 1
    for i, v in ipairs(CYCLE) do if v == Cfg.MinRank then cur = i break end end
    Cfg.MinRank = CYCLE[cur % #CYCLE + 1]
    b.Text = "Tingkat: " .. (RANKNAME[Cfg.MinRank] or tostring(Cfg.MinRank))
    Clear()
end)
local PRICE = { 0, 100000, 500000, 1000000, 5000000 }
local function PriceTxt(v)
    if v >= 1000000 then return "$" .. tostring(v / 1000000):gsub("%.0$", "") .. "jt" end
    if v >= 1000 then return "$" .. tostring(v / 1000):gsub("%.0$", "") .. "rb" end
    return "$" .. tostring(v)
end
mk("Harga min: $0", 204, function(b)
    local cur = 1
    for i, v in ipairs(PRICE) do if v == Cfg.MinValue then cur = i break end end
    Cfg.MinValue = PRICE[cur % #PRICE + 1]
    b.Text = "Harga min: " .. PriceTxt(Cfg.MinValue)
    Clear()
end)
mk("[OFF] ESP Player", 238, function(b)
    Cfg.Player = not Cfg.Player b.Text = (Cfg.Player and "[ON] " or "[OFF] ") .. "ESP Player"
    if not Cfg.Player then for _, d in ipairs(workspace:GetDescendants()) do if d.Name == "TA_PLY_ESP" then pcall(function() d:Destroy() end) end end end
end)
mk("Cek rarity (F9)", 272, function()
    local pc = workspace:FindFirstChild("PlotCrystals")
    local n = 0
    if pc then
        for _, m in ipairs(pc:GetDescendants()) do
            if m:IsA("Model") and n < 8 then
                n += 1
                local r, src = RarityOf(m)
                print("[TA-ESP] " .. m:GetFullName() .. " rank=" .. tostring(r) .. " via=" .. tostring(src))
            end
        end
    end
    print("[TA-ESP] selesai, lihat F9. Paste 3 baris ke saya kalau filter salah.")
end)
local mini = Instance.new("TextButton")
mini.Size = UDim2.new(0,52,0,26) mini.Position = UDim2.new(0,20,0,10)
mini.BackgroundColor3 = Color3.fromRGB(16,18,26) mini.Font = Enum.Font.GothamBold
mini.TextSize = 11 mini.TextColor3 = Color3.new(1,1,1) mini.Text = "ESP"
mini.Parent = gui
Instance.new("UICorner", mini).CornerRadius = UDim.new(0,8)
mini.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)
game:GetService("UserInputService").InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightShift then main.Visible = not main.Visible end
end)
print("[TA-ESP] loaded (gem + boulder, visual saja).")
