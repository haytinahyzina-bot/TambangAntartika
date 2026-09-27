-- Tambang Antartika - ESP Gabungan v1 (Gem + Boulder, 1 menu)
-- Gem: Workspace.PlotCrystals.Plot<1-8>.<Nama> | Boulder: Workspace.Boulders.<Nama> > Mesh_0 + HpBar
-- Murni visual, tidak mengubah speed/stat.
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Cfg = { Gem = true, Boulder = true, Player = false, MaxDist = 400 }

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
            -- GEM
            if Cfg.Gem then
                local pc = workspace:FindFirstChild("PlotCrystals")
                if pc then
                    for _, m in ipairs(pc:GetDescendants()) do
                        if m:IsA("Model") and not m:FindFirstChild("TA_GEM_ESP") then
                            local pos = PivotOf(m)
                            if pos then
                                local d = (myPos and (pos - myPos).Magnitude) or 0
                                if Cfg.MaxDist <= 0 or d <= Cfg.MaxDist then
                                    local ador = m:FindFirstChildWhichIsA("BasePart")
                                    if ador then MkBB(m, ador, "TA_GEM_ESP", Color3.fromRGB(30,25,10), Color3.new(1,0.85,0.3)) end
                                end
                            end
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
                            elseif bb.Name == "TA_BLD_ESP" then
                                local hp = ""
                                local part = m:FindFirstChild("Mesh_0")
                                local bar = part and part:FindFirstChild("HpBar")
                                local tl = bar and bar:FindFirstChild("TextLabel")
                                hp = (tl and tl.Text) or ""
                                t.Text = "BATU " .. string.upper(m.Name) .. "\n" .. hp .. " | " .. tostring(d) .. "m"
                            else
                                t.Text = m.Name .. " " .. tostring(d) .. "m"
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
main.Size = UDim2.new(0,220,0,212) main.Position = UDim2.new(0,20,0.5,-106)
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
mk("[OFF] ESP Player", 170, function(b)
    Cfg.Player = not Cfg.Player b.Text = (Cfg.Player and "[ON] " or "[OFF] ") .. "ESP Player"
    if not Cfg.Player then for _, d in ipairs(workspace:GetDescendants()) do if d.Name == "TA_PLY_ESP" then pcall(function() d:Destroy() end) end end end
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
