-- Tambang Antartika - Boulder Menu (semua batu event: Mossite, Voltite, dll)
-- Pola: Workspace.Boulders.<Nama> > Mesh_0 + BoulderMine prompt + HpBar
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Cfg = { ESP = true, Auto = false, Target = nil } -- Target=nil = terdekat

local function HRP() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function Boulders() return workspace:FindFirstChild("Boulders") end
local function List()
    local out = {} local b = Boulders() if not b then return out end
    for _, m in ipairs(b:GetChildren()) do
        if m:IsA("Model") then
            local part = m:FindFirstChild("Mesh_0") or m:FindFirstChildWhichIsA("BasePart")
            if part then table.insert(out, { Model = m, Part = part, Name = m.Name }) end
        end
    end
    return out
end
local function Nearest()
    local hrp = HRP() local list = List() if #list == 0 then return nil end
    if Cfg.Target then for _, e in ipairs(list) do if e.Name == Cfg.Target then return e end end end
    local best, bd = nil, math.huge
    for _, e in ipairs(list) do
        if hrp then local d = (e.Part.Position - hrp.Position).Magnitude if d < bd then bd = d best = e end
        else best = best or e end
    end
    return best
end
local function HP(e)
    local hp = e.Part:FindFirstChild("HpBar") local tl = hp and hp:FindFirstChild("TextLabel")
    return (tl and tl.Text) or ""
end
local function Go(e)
    e = e or Nearest() local hrp = HRP()
    if e and hrp then hrp.CFrame = CFrame.new(e.Part.Position + Vector3.new(0,5,5), e.Part.Position) return true end
    return false
end
local function MineOnce(e)
    e = e or Nearest() if not e then return end
    local pr = e.Part:FindFirstChild("BoulderMine")
    if pr then pcall(function() fireproximityprompt(pr) end) end
end

task.spawn(function()
    while true do
        if Cfg.ESP then
            pcall(function()
                for _, e in ipairs(List()) do
                    if not e.Model:FindFirstChild("TA_BLD_ESP") then
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "TA_BLD_ESP" bb.Size = UDim2.new(0,220,0,50)
                        bb.StudsOffset = Vector3.new(0,6,0) bb.AlwaysOnTop = true
                        bb.Adornee = e.Part bb.Parent = e.Model
                        local tl = Instance.new("TextLabel")
                        tl.Name = "Txt" tl.Size = UDim2.new(1,0,1,0) tl.BackgroundTransparency = 0.4
                        tl.BackgroundColor3 = Color3.fromRGB(10,20,40)
                        tl.TextColor3 = Color3.new(0.5,0.8,1) tl.TextStrokeTransparency = 0
                        tl.TextSize = 14 tl.Font = Enum.Font.GothamBold tl.Parent = bb
                        Instance.new("UICorner", bb).CornerRadius = UDim.new(0,8)
                    end
                    local hrp = HRP()
                    local dist = hrp and math.floor((e.Part.Position - hrp.Position).Magnitude) or -1
                    local t = e.Model:FindFirstChild("TA_BLD_ESP") and e.Model.TA_BLD_ESP:FindFirstChild("Txt")
                    if t then t.Text = "BATU " .. string.upper(e.Name) .. "\n" .. HP(e) .. " | " .. tostring(dist) .. "m" end
                end
            end)
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        if Cfg.Auto then
            pcall(function()
                local e = Nearest() local hrp = HRP()
                if e and hrp then
                    if (e.Part.Position - hrp.Position).Magnitude > 20 then Go(e)
                    else MineOnce(e) end
                end
            end)
        end
        task.wait(0.4)
    end
end)

local gui = Instance.new("ScreenGui") gui.Name = "TABoulderMenu" gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LP.PlayerGui end
local main = Instance.new("Frame")
main.Size = UDim2.new(0,250,0,300) main.Position = UDim2.new(0,20,0.5,-150)
main.BackgroundColor3 = Color3.fromRGB(14,18,28) main.BorderSizePixel = 0
main.Active = true main.Draggable = true main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,30) title.BackgroundTransparency = 1
title.Text = "  Boulder Menu" title.Font = Enum.Font.GothamBold title.TextSize = 14
title.TextColor3 = Color3.new(0.6,0.85,1) title.TextXAlignment = Enum.TextXAlignment.Left title.Parent = main
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1,-16,0,30) info.Position = UDim2.new(0,8,0,30)
info.BackgroundTransparency = 1 info.Font = Enum.Font.Code info.TextSize = 12
info.TextColor3 = Color3.new(0.9,0.9,0.9) info.TextXAlignment = Enum.TextXAlignment.Left
info.Text = "..." info.Parent = main
local function mk(t, y, cb, c)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-16,0,28) b.Position = UDim2.new(0,8,0,y)
    b.BackgroundColor3 = c or Color3.fromRGB(28,38,55) b.Font = Enum.Font.GothamBold
    b.TextSize = 12 b.TextColor3 = Color3.new(1,1,1) b.Text = t b.Parent = main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(function() pcall(cb, b) end)
    return b
end
mk("[ON] ESP semua batu", 66, function(b) Cfg.ESP = not Cfg.ESP b.Text = (Cfg.ESP and "[ON] " or "[OFF] ") .. "ESP semua batu" end)
mk("[OFF] Auto terdekat + E", 100, function(b) Cfg.Auto = not Cfg.Auto b.Text = (Cfg.Auto and "[ON] " or "[OFF] ") .. "Auto terdekat + E" end)
mk("Target: TERDEKAT (klik ganti)", 134, function(b)
    local list = List() if #list == 0 then return end
    local cur = nil
    for i, e in ipairs(list) do if e.Name == Cfg.Target then cur = i break end end
    local nxt = list[(cur or 0) % #list + 1]
    -- klik 2x = kunci ke 1 batu, klik sampai TERDEKAT lagi = lepas
    if Cfg.Target == nxt.Name then Cfg.Target = nil b.Text = "Target: TERDEKAT (klik ganti)"
    else Cfg.Target = nxt.Name b.Text = "Target: " .. nxt.Name end
end)
mk("Teleport ke target", 168, function() Go() end, Color3.fromRGB(40,100,150))
mk("Tambang sekali (E)", 202, function() MineOnce() end)
task.spawn(function()
    while gui.Parent do
        pcall(function()
            local list = List()
            if #list == 0 then info.Text = "Tidak ada batu"
            else
                local n = Nearest()
                info.Text = #list .. " batu | target: " .. (n and n.Name or "-") .. "\n" .. (n and HP(n) or "")
            end
        end)
        task.wait(1)
    end
end)
-- Hide/show: tombol mini + RightShift
local mini = Instance.new("TextButton")
mini.Size = UDim2.new(0,64,0,28) mini.Position = UDim2.new(0,20,0,10)
mini.BackgroundColor3 = Color3.fromRGB(14,18,28) mini.Font = Enum.Font.GothamBold
mini.TextSize = 12 mini.TextColor3 = Color3.new(0.6,0.85,1) mini.Text = "BOULDER"
mini.Parent = gui
Instance.new("UICorner", mini).CornerRadius = UDim.new(0,8)
mini.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)
game:GetService("UserInputService").InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightShift then main.Visible = not main.Visible end
end)
print("[TA-Boulder] loaded. Berlaku untuk Mossite, Voltite, dan batu event lain.")
