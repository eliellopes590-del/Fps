-- LocalScript dentro de ScreenGui "GraphicsPanel"
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =========================================================
-- CONFIGURAÇÃO INICIAL
-- =========================================================
-- ScreenGui já existe (o pai deste script)
local screenGui = script.Parent
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Aplica efeito "massinha" (plastic/clay) no jogo
local function applyClayGraphics()
	-- Ajusta a iluminação para um look de massinha
	Lighting.Brightness = 2
	Lighting.ClockTime = 14
	Lighting.Ambient = Color3.fromRGB(180, 180, 180)
	Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
	Lighting.FogEnd = 100000
	Lighting.GlobalShadows = false

	-- Remove efeitos antigos de massinha se existirem
	for _, v in ipairs(Lighting:GetChildren()) do
		if v.Name == "ClayEffect" or v.Name == "ClayBlur" then
			v:Destroy()
		end
	end

	-- Blur leve + saturação pra dar aparência de plastilina
	local blur = Instance.new("BlurEffect")
	blur.Name = "ClayBlur"
	blur.Size = 2
	blur.Parent = Lighting

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "ClayEffect"
	colorCorrection.Saturation = 0.25
	colorCorrection.Contrast = -0.1
	colorCorrection.Brightness = 0.05
	colorCorrection.Parent = Lighting

	-- Aplica material "Plastic" em todas as partes (efeito massinha)
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			pcall(function()
				obj.Material = Enum.Material.SmoothPlastic
				obj.Reflectance = 0
			end)
		end
	end
end

-- Remove o efeito massinha
local function removeClayGraphics()
	for _, v in ipairs(Lighting:GetChildren()) do
		if v.Name == "ClayEffect" or v.Name == "ClayBlur" then
			v:Destroy()
		end
	end
end

-- =========================================================
-- FUNÇÕES DE QUALIDADE GRÁFICA
-- =========================================================
local function setGraphicsQuality(level)
	if level == "Low" then
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 500
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		for _, v in ipairs(Lighting:GetChildren()) do
			if v:IsA("PostEffect") then v.Enabled = false end
		end
	elseif level == "Medium" then
		Lighting.GlobalShadows = true
		Lighting.FogEnd = 5000
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level06
		for _, v in ipairs(Lighting:GetChildren()) do
			if v:IsA("PostEffect") then v.Enabled = true end
		end
	elseif level == "High" then
		Lighting.GlobalShadows = true
		Lighting.FogEnd = 100000
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level10
		for _, v in ipairs(Lighting:GetChildren()) do
			if v:IsA("PostEffect") then v.Enabled = true end
		end
	end
end

-- =========================================================
-- CRIAÇÃO DO PAINEL (estilo neon, horizontal)
-- =========================================================
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 520, 0, 180)
panel.Position = UDim2.new(0.5, -260, 0.5, -90)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true -- arrastável nativamente
panel.Parent = screenGui

-- Borda neon
local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(0, 255, 200)
uiStroke.Thickness = 2
uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
uiStroke.Parent = panel

-- Gradiente neon no fundo
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 5, 40)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 30, 50)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 5, 60)),
})
gradient.Rotation = 45
gradient.Parent = panel

-- Cantos arredondados
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = panel

-- =========================================================
-- TÍTULO
-- =========================================================
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -90, 0, 32)
title.Position = UDim2.new(0, 12, 0, 8)
title.BackgroundTransparency = 1
title.Text = "⚙ PAINEL GRÁFICO — CLAY MODE"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(0, 255, 200)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(0, 255, 200)
titleStroke.Thickness = 1
titleStroke.Transparency = 0.5
titleStroke.Parent = title

-- =========================================================
-- BOTÃO MINIMIZAR
-- =========================================================
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -42, 0, 8)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
minimizeBtn.Text = "—"
minimizeBtn.TextColor3 = Color3.fromRGB(10, 10, 20)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 20
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = panel

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 8)
minCorner.Parent = minimizeBtn

local minStroke = Instance.new("UIStroke")
minStroke.Color = Color3.fromRGB(0, 255, 255)
minStroke.Thickness = 2
minStroke.Parent = minimizeBtn

-- =========================================================
-- BOTÕES DE QUALIDADE (Low / Medium / High)
-- =========================================================
local function createQualityButton(name, position, color)
	local btn = Instance.new("TextButton")
	btn.Name = name .. "Btn"
	btn.Size = UDim2.new(0, 140, 0, 40)
	btn.Position = position
	btn.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	btn.Text = name
	btn.TextColor3 = color
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.BorderSizePixel = 0
	btn.Parent = panel

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = btn

	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = 2
	s.Parent = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
		TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(0,0,0)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20,20,35)}):Play()
		TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = color}):Play()
	end)

	return btn
end

local lowBtn = createQualityButton("LOW", UDim2.new(0, 20, 0, 60), Color3.fromRGB(255, 80, 80))
local medBtn = createQualityButton("MEDIUM", UDim2.new(0, 180, 0, 60), Color3.fromRGB(255, 200, 0))
local highBtn = createQualityButton("HIGH", UDim2.new(0, 340, 0, 60), Color3.fromRGB(0, 255, 120))

lowBtn.MouseButton1Click:Connect(function()
	setGraphicsQuality("Low")
end)
medBtn.MouseButton1Click:Connect(function()
	setGraphicsQuality("Medium")
end)
highBtn.MouseButton1Click:Connect(function()
	setGraphicsQuality("High")
end)

-- =========================================================
-- TOGGLE CLAY MODE + SWIPE (esticar tela)
-- =========================================================
local clayBtn = Instance.new("TextButton")
clayBtn.Name = "ClayBtn"
clayBtn.Size = UDim2.new(0, 240, 0, 40)
clayBtn.Position = UDim2.new(0, 20, 0, 115)
clayBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
clayBtn.Text = "🍡 CLAY MODE: OFF"
clayBtn.TextColor3 = Color3.fromRGB(255, 100, 220)
clayBtn.Font = Enum.Font.GothamBold
clayBtn.TextSize = 16
clayBtn.BorderSizePixel = 0
clayBtn.Parent = panel

local clayCorner = Instance.new("UICorner")
clayCorner.CornerRadius = UDim.new(0, 10)
clayCorner.Parent = clayBtn

local clayStroke = Instance.new("UIStroke")
clayStroke.Color = Color3.fromRGB(255, 100, 220)
clayStroke.Thickness = 2
clayStroke.Parent = clayBtn

local clayActive = false
clayBtn.MouseButton1Click:Connect(function()
	clayActive = not clayActive
	if clayActive then
		applyClayGraphics()
		clayBtn.Text = "🍡 CLAY MODE: ON"
		clayBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 220)
		clayBtn.TextColor3 = Color3.fromRGB(20, 5, 30)
	else
		removeClayGraphics()
		clayBtn.Text = "🍡 CLAY MODE: OFF"
		clayBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
		clayBtn.TextColor3 = Color3.fromRGB(255, 100, 220)
	end
end)

-- =========================================================
-- SWIPE / ESTICAR TELA (Stretch horizontal ou vertical)
-- =========================================================
local stretchBtn = Instance.new("TextButton")
stretchBtn.Name = "StretchBtn"
stretchBtn.Size = UDim2.new(0, 240, 0, 40)
stretchBtn.Position = UDim2.new(0, 270, 0, 115)
stretchBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
stretchBtn.Text = "↔ ESTICAR TELA: OFF"
stretchBtn.TextColor3 = Color3.fromRGB(120, 200, 255)
stretchBtn.Font = Enum.Font.GothamBold
stretchBtn.TextSize = 16
stretchBtn.BorderSizePixel = 0
stretchBtn.Parent = panel

local stCorner = Instance.new("UICorner")
stCorner.CornerRadius = UDim.new(0, 10)
stCorner.Parent = stretchBtn

local stStroke = Instance.new("UIStroke")
stStroke.Color = Color3.fromRGB(120, 200, 255)
stStroke.Thickness = 2
stStroke.Parent = stretchBtn

-- Cria o efeito de "esticar" via camera FOV + aspect ratio
local stretchActive = false
local originalFOV = workspace.CurrentCamera.FieldOfView

stretchBtn.MouseButton1Click:Connect(function()
	stretchActive = not stretchActive
	local cam = workspace.CurrentCamera
	if stretchActive then
		-- Aumenta FOV pra dar efeito "esticado" tipo swipe
		TweenService:Create(cam, TweenInfo.new(0.4), {FieldOfView = 90}):Play()
		stretchBtn.Text = "↔ ESTICAR TELA: ON"
		stretchBtn.BackgroundColor3 = Color3.fromRGB(120, 200, 255)
		stretchBtn.TextColor3 = Color3.fromRGB(10, 20, 40)
	else
		TweenService:Create(cam, TweenInfo.new(0.4), {FieldOfView = originalFOV}):Play()
		stretchBtn.Text = "↔ ESTICAR TELA: OFF"
		stretchBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
		stretchBtn.TextColor3 = Color3.fromRGB(120, 200, 255)
	end
end)

-- =========================================================
-- MODO MINIMIZADO — vira ícone arrastável
-- =========================================================
local minimized = false
local savedSize = panel.Size
local savedPos = panel.Position

local function setChildrenVisible(parent, visible)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "MinimizeBtn" then
			child.Visible = visible
		end
	end
end

minimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		-- Salva estado atual
		savedSize = panel.Size
		savedPos = panel.Position
		-- Vira um ícone pequeno
		setChildrenVisible(panel, false)
		TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Size = UDim2.new(0, 50, 0, 50)
		}):Play()
		minimizeBtn.Text = "+"
		minimizeBtn.Size = UDim2.new(0, 40, 0, 40)
		minimizeBtn.Position = UDim2.new(0, 5, 0, 5)
	else
		-- Restaura
		TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Size = savedSize,
			Position = savedPos
		}):Play()
		task.wait(0.1)
		setChildrenVisible(panel, true)
		minimizeBtn.Text = "—"
		minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
		minimizeBtn.Position = UDim2.new(1, -42, 0, 8)
	end
end)

print("✅ Painel Gráfico carregado!")
