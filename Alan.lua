--========================================================--
--==== ALAN MENÚ - Inf Stamina + ESP + AutoFarm + AutoSell ====--
--========================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

--======================--
-- CONFIG AUTOSELL --
--======================--
local backpack = Player:WaitForChild("Backpack")
local sellAllPrompt = workspace.fishIgloo.SellFish.SellAllFish
local sellOnePrompt = workspace.fishIgloo.SellFish.SellFish

local AutoSell = false
local SellLimit = 40 -- valor por defecto, se puede cambiar en GUI

local SellableItems = {
    "Clownfish","Old Boot","Plastic Bottle","Karp","Sea Bass","Catfish","Trout","Pike",
    "Goldfish","Sardine","Salmon","Mackerel","Barracuda","Spearfish","Amberjack",
    "Bluefin Tuna","Swordfish","Stingray","Sturgeon","Pink Dolphin","Anglerfish",
    "Pufferfish","Manta Ray","Sea Bunny","Boxfish","Butterfly Fish","Sea Turtle",
    "Bonefish","Ghostfish","Barreleye Fish","Giant Squid","Squid","Great White",
    "Humpback Whale","Killer Whale","Mako Shark","Sunfish","Dolphin","Megalodon",
    "Basking Shark","Sawfish","Fangtooth","Viperfish","Cuttlefish","Moray Eel",
    "Blenny","Piranha","Red Snapper","Blue Tang","Moonfish","Lionfish","Halibut",
    "Rainbow Trout","Bumphead","Scorpionfish","Lava Eel","Ancient Fish","Flamecore",
    "Forgotten Tome","Jumbo Shrimp"
}

local SellSet = {}
for _, n in ipairs(SellableItems) do
    SellSet[n] = true
end

--======================--
-- AUTOSELL MEJORADO --
--======================--
spawn(function()
    while task.wait(0.5) do
        if AutoSell then
            local count = 0
            for _, item in ipairs(backpack:GetChildren()) do
                if SellSet[item.Name] then
                    count = count + 1
                end
            end

            if count >= SellLimit then
                local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local originalPos = hrp.CFrame
                    hrp.CFrame = sellAllPrompt.Parent.CFrame + Vector3.new(0,3,0)
                    task.wait(0.05)

                    local successAll = pcall(function()
                        sellAllPrompt:InputHoldBegin(Enum.UserInputType.Keyboard)
                        task.wait(1)
                        sellAllPrompt:InputHoldEnd(Enum.UserInputType.Keyboard)
                    end)

                    if not successAll then
                        pcall(function()
                            sellOnePrompt:InputHoldBegin(Enum.UserInputType.Keyboard)
                            task.wait(1)
                            sellOnePrompt:InputHoldEnd(Enum.UserInputType.Keyboard)
                        end)
                    end

                    task.wait(0.05)
                    hrp.CFrame = originalPos
                end
            end
        end
    end
end)

--======================--
-- INF STAMINA --
--======================--
local infStaminaActive = false
local staminaLoop = nil
local function getSwimStamina()
    local char = Workspace:FindFirstChild(Player.Name)
    if not char then return nil, nil end
    local vars = char:FindFirstChild("Vars")
    if not vars then return nil, nil end
    local swimming = vars:FindFirstChild("Swimming")
    if not swimming then return nil, nil end
    return swimming:FindFirstChild("SwimStamina"), swimming:FindFirstChild("MaxSwimStamina")
end

--======================--
-- ESP SYSTEM --
--======================--
local espActive = false
local espObjects = {}
local espUpdateConn = nil
local function findHead(model)
    if not model then return nil end
    local parts = {"Head","HumanoidRootPart","UpperTorso","Torso"}
    for _, n in ipairs(parts) do
        local p = model:FindFirstChild(n)
        if p and p:IsA("BasePart") then return p end
    end
    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower():find("head") then
            return v
        end
    end
    return nil
end
local function findRoot(model)
    if not model then return nil end
    if model.PrimaryPart then return model.PrimaryPart end
    local r = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("UpperTorso")
    if r then return r end
    for _, v in ipairs(model:GetChildren()) do
        if v:IsA("BasePart") then return v end
    end
end
local function createESP(plr)
    if plr == Player then return end
    if espObjects[plr] then return end
    if not plr.Character then return end
    local head = findHead(plr.Character)
    local root = findRoot(plr.Character)
    if not head or not root then return end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(0,255,0)
    highlight.FillTransparency = 0.45
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = plr.Character
    highlight.Parent = Workspace
    local bill = Instance.new("BillboardGui", head)
    bill.Size = UDim2.new(0,150,0,40)
    bill.AlwaysOnTop = true
    bill.StudsOffset = Vector3.new(0,2.6,0)
    local txt = Instance.new("TextLabel", bill)
    txt.Size = UDim2.new(1,0,1,0)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 14
    txt.TextColor3 = Color3.fromRGB(0,255,0)
    txt.Text = plr.DisplayName or plr.Name
    espObjects[plr] = {highlight=highlight,bill=bill,txt=txt}
end
local function removeESP(plr)
    local obj = espObjects[plr]
    if not obj then return end
    if obj.highlight then obj.highlight:Destroy() end
    if obj.bill then obj.bill:Destroy() end
    espObjects[plr] = nil
end
local function toggleESP(state)
    espActive = state
    if not state then
        for p,_ in pairs(espObjects) do removeESP(p) end
        if espUpdateConn then espUpdateConn:Disconnect() end
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then createESP(p) end
    end
    espUpdateConn = RunService.Heartbeat:Connect(function()
        local myRoot = Player.Character and findRoot(Player.Character)
        if not myRoot then return end
        for plr,obj in pairs(espObjects) do
            local c = plr.Character
            if not c then removeESP(plr) continue end
            local root = findRoot(c)
            local head = findHead(c)
            if not root or not head then removeESP(plr) continue end
            local dist = (myRoot.Position - root.Position).Magnitude
            obj.txt.Text = (plr.DisplayName or plr.Name).." • "..math.floor(dist).."m"
        end
    end)
end

--======================--
-- GUI ELEGANTE ALAN MENÚ --
--======================--
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AlanMenu"
screenGui.ResetOnSpawn = false
screenGui.Parent = Player:WaitForChild("PlayerGui")

local main = Instance.new("Frame", screenGui)
main.Size = UDim2.new(0,320,0,460)
main.Position = UDim2.new(0.5,-160,0.5,-230)
main.BackgroundColor3 = Color3.fromRGB(18,18,18)
Instance.new("UICorner", main).CornerRadius = UDim.new(0,14)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(70,70,70)

-- Título y Subtítulo
local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1,-30,0,60)
title.Position = UDim2.new(0,15,0,10)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 28
title.Text = "Alan Menú"
title.TextColor3 = Color3.fromRGB(230,230,230)
title.TextXAlignment = Enum.TextXAlignment.Left

local subtitle = Instance.new("TextLabel", main)
subtitle.Size = UDim2.new(1,-30,0,18)
subtitle.Position = UDim2.new(0,15,0,65)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamSemibold
subtitle.TextSize = 12
subtitle.Text = "Inf Stamina • ESP • AutoFarm • AutoSell"
subtitle.TextColor3 = Color3.fromRGB(170,170,170)
subtitle.TextXAlignment = Enum.TextXAlignment.Left

-- Stamina
local statusLabel = Instance.new("TextLabel", main)
statusLabel.Size = UDim2.new(1,-30,0,24)
statusLabel.Position = UDim2.new(0,15,0,90)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamSemibold
statusLabel.TextSize = 13
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextColor3 = Color3.fromRGB(200,200,200)
statusLabel.Text = "Stamina: -- / --"

-- Función para crear botones
local function makeButton(parent, y, text)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0,280,0,44)
    btn.Position = UDim2.new(0,20,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.TextColor3 = Color3.fromRGB(220,220,220)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.Text = text
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(60,60,60)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3=Color3.fromRGB(55,55,55) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3=Color3.fromRGB(40,40,40) end)
    return btn
end

-- Botones
local stamBtn = makeButton(main, 130, "Inf Stamina: OFF")
stamBtn.MouseButton1Click:Connect(function()
    infStaminaActive = not infStaminaActive
    stamBtn.Text = "Inf Stamina: "..(infStaminaActive and "ON" or "OFF")
    if infStaminaActive then
        if staminaLoop then staminaLoop:Disconnect() end
        staminaLoop = RunService.Heartbeat:Connect(function()
            local c,m = getSwimStamina()
            if c and m then c.Value = m.Value end
        end)
    else
        if staminaLoop then staminaLoop:Disconnect() staminaLoop=nil end
    end
end)

local espBtn = makeButton(main, 190, "ESP Seals: OFF")
espBtn.MouseButton1Click:Connect(function()
    espActive = not espActive
    espBtn.Text = "ESP Seals: "..(espActive and "ON" or "OFF")
    toggleESP(espActive)
end)

local autoBtn = makeButton(main, 250, "AutoFarm")
autoBtn.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ColaKomaru/Be-A-Silly-Seal/refs/heads/main/Protected_1133748289932122.lua.txt"))()
end)

local autosellBtn = makeButton(main, 310, "AutoSell: OFF")
autosellBtn.MouseButton1Click:Connect(function()
    AutoSell = not AutoSell
    autosellBtn.Text = "AutoSell: "..(AutoSell and "ON" or "OFF")
end)

-- Botón límite inventario
local limitBtn = makeButton(main, 370, "Límite inventario: "..SellLimit)
local options = {40,30,20}
local index = 1
limitBtn.MouseButton1Click:Connect(function()
    index = index + 1
    if index > #options then index = 1 end
    SellLimit = options[index]
    limitBtn.Text = "Límite inventario: "..SellLimit
end)

-- Créditos ajustados
local creditLabel = Instance.new("TextLabel", main)
creditLabel.Size = UDim2.new(1,0,0,20)
creditLabel.Position = UDim2.new(0,0,1,-30) -- un poco más arriba desde el borde
creditLabel.BackgroundTransparency = 1
creditLabel.TextColor3 = Color3.fromRGB(150,150,150)
creditLabel.Font = Enum.Font.GothamSemibold
creditLabel.TextSize = 12
creditLabel.Text = "Créditos a: Alan 616"
creditLabel.TextXAlignment = Enum.TextXAlignment.Center


-- Mover, minimizar, cerrar
local dragging, dragStart, startPos=false,nil,nil
title.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true; dragStart=i.Position; startPos=main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
        local delta=i.Position-dragStart
        main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)

local closeBtn = Instance.new("TextButton", main)
closeBtn.Size=UDim2.new(0,34,0,28)
closeBtn.Position=UDim2.new(1,-44,0,12)
closeBtn.Text="X"
closeBtn.Font=Enum.Font.GothamBold
closeBtn.BackgroundColor3=Color3.fromRGB(40,40,40)
closeBtn.TextColor3=Color3.fromRGB(220,220,220)
Instance.new("UICorner", closeBtn).CornerRadius=UDim.new(0,6)
closeBtn.MouseButton1Click:Connect(function()
    if staminaLoop then staminaLoop:Disconnect() end
    if espUpdateConn then espUpdateConn:Disconnect() end
    screenGui:Destroy()
end)

local minBtn = Instance.new("TextButton", main)
minBtn.Size=UDim2.new(0,34,0,28)
minBtn.Position=UDim2.new(1,-84,0,12)
minBtn.Text="—"
minBtn.Font=Enum.Font.GothamBold
minBtn.BackgroundColor3=Color3.fromRGB(40,40,40)
minBtn.TextColor3=Color3.fromRGB(220,220,220)
Instance.new("UICorner", minBtn).CornerRadius=UDim.new(0,6)

local floatBtn = Instance.new("TextButton", screenGui)
floatBtn.Size=UDim2.new(0,48,0,48)
floatBtn.Position=UDim2.new(0.5,-24,0.5,-24)
floatBtn.BackgroundColor3=Color3.fromRGB(34,34,34)
floatBtn.Text="ALAN"
floatBtn.TextSize=14
floatBtn.Font=Enum.Font.GothamBold
floatBtn.TextColor3=Color3.fromRGB(220,220,220)
Instance.new("UICorner", floatBtn).CornerRadius=UDim.new(0.5,0)
floatBtn.Visible=false

minBtn.MouseButton1Click:Connect(function()
    main.Visible=false
    floatBtn.Position=main.Position+UDim2.new(0,150,0,150)
    floatBtn.Visible=true
end)
floatBtn.MouseButton1Click:Connect(function()
    main.Visible=true
    floatBtn.Visible=false
end)

-- Actualizar Stamina
RunService.Heartbeat:Connect(function()
    local c,m=getSwimStamina()
    if c and m then
        statusLabel.Text=("Stamina: %d / %d (%d%%)"):format(c.Value,m.Value,math.floor(c.Value/m.Value*100))
    else
        statusLabel.Text="Stamina: No detectada"
    end
end)

print("Alan Menú cargado | AutoFarm listo | AutoSell discreto con límite | UI elegante y mejorada")
