if _G.CoinHarvesterSession and typeof(_G.CoinHarvesterSession.Unload) == "function" then
    pcall(function()
        _G.CoinHarvesterSession.Unload()
    end)
end

local sessao = {
    Conexoes = {},
    Threads = {},
    Limpar = false
}
_G.CoinHarvesterSession = sessao

local ATIVADO = false
local AUTO_EGG = false
local AUTO_BUBBLE = true
local AUTO_REWARDS = true
local AUTO_CHESTS = true
local FPS_BOOST = false
local SKIP_EGG_ANIM = true

local VELOCIDADE_TWEEN = 160
local NOCLIP_ATIVO = true
local ALTURA_OFFSET = 1.0
local RAIO_MAXIMO_BUSCA = 500
local DISTANCIA_MAX_OVO = 30
local PRIORIZAR_CAIXAS = true
local TEMPO_COOLDOWN_MOEDA = 4.0

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local NetworkRemoteEvent = ReplicatedStorage:FindFirstChild("NetworkRemoteEvent")
local NetworkRemoteFunction = ReplicatedStorage:FindFirstChild("NetworkRemoteFunction")
local LocalPlayer = Players.LocalPlayer

local historicoRecentes = {}
local ultimoAlvoInstancia = nil
local threadPrincipal = nil
local threadEgg = nil
local threadBubble = nil
local threadRewards = nil
local noclipConexao = nil
local fpsBoostConexao = nil
local tweenAtual = nil
local partesPersonagem = {}
local acaoEspecialAtiva = false

local totalColetadas = 0
local totalOvosAbertos = 0

local bausGlobais = {
    "The Floating Island", "The Skylands", "The Void", "XP Island",
    "Gumdrop Island", "Candy Island", "Sweet Island",
    "Block Island", "Teddy Island", "Treasure Isle",
    "Oceanic Island", "Sea Island", "Sea Shell Isle",
    "Treasure Island", "Water Island", "Sandy Island",
    "Blue Island", "Red Island", "Purple Island",
    "Fire Island", "Inferno Island", "Molten Island",
    "Crystal Island", "Spirit Island", "Magic Island",
    "Light Island", "Cloud Island", "Demon Island"
}

local mundosComprar = {
    "Candy Land", "Toy Land", "Beach World", "Atlantis",
    "Rainbow Land", "Underworld", "Mystic Forest", "Heaven"
}

local VexUI = loadstring(game:HttpGet("https://github.com/SSHRKs/VexUI/releases/latest/download/main.lua"))()

local Window = VexUI:CreateWindow({
    Name = "BGS Privado",
    Icon = "shield",
    SideBarWidth = 165,
    Theme = "Dark",
    Transparent = true,
    Author = "Feito por h64",
    User = {
        Enabled = true,
        Anonymous = false
    }
})

Window:EditOpenButton({
    Title = "BGS Privado (h64)",
    Icon = "shield",
    Transparency = 0.15,
    StrokeThickness = 1.5,
    Rotation = 0,
    Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 185, 129)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 165, 233))
    },
    AutoRotation = true,
    Speed = 15,
    CornerRadius = UDim.new(0, 14)
})

local function notificar(titulo, desc, icone)
    pcall(function()
        VexUI:Notification({
            Title = titulo or "BGS Privado",
            Desc = desc or "",
            Icon = icone or "shield",
            Duration = 3
        })
    end)
end

local FarmTab = Window:Tab({ Title = "Farm e Ovos", Icon = "circle-dot", Border = true })
local RewardsTab = Window:Tab({ Title = "Recompensas", Icon = "gift", Border = true })
local WorldsTab = Window:Tab({ Title = "Mundos e Ilhas", Icon = "globe", Border = true })
local SettingsTab = Window:Tab({ Title = "Config e AFK", Icon = "settings", Border = true })

Window:SelectTab(1)

local function atualizarPartesPersonagem()
    table.clear(partesPersonagem)
    local char = LocalPlayer.Character
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("BasePart") then
                table.insert(partesPersonagem, v)
            end
        end
    end
end

local charAddedConexao = LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    atualizarPartesPersonagem()
end)
table.insert(sessao.Conexoes, charAddedConexao)

local function obterPersonagem()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then
        hrp = char:WaitForChild("HumanoidRootPart", 3)
        hum = char:WaitForChild("Humanoid", 3)
        atualizarPartesPersonagem()
    end
    return char, hrp, hum
end

local function gerenciarNoclip(ativar)
    if ativar and NOCLIP_ATIVO then
        if not noclipConexao then
            if #partesPersonagem == 0 then
                atualizarPartesPersonagem()
            end
            noclipConexao = RunService.Stepped:Connect(function()
                for i = 1, #partesPersonagem do
                    local p = partesPersonagem[i]
                    if p and p.Parent and p.CanCollide then
                        p.CanCollide = false
                    end
                end
            end)
            table.insert(sessao.Conexoes, noclipConexao)
        end
    else
        if noclipConexao then
            noclipConexao:Disconnect()
            noclipConexao = nil
        end
    end
end

local function aplicarFPSBoost(ativar)
    if ativar then
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)

        for _, v in ipairs(Workspace:GetDescendants()) do
            pcall(function()
                if v:IsA("BasePart") and not v.Parent:FindFirstChildWhichIsA("Humanoid") then
                    v.Material = Enum.Material.SmoothPlastic
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    v.Transparency = 1
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                    v.Enabled = false
                end
            end)
        end

        if not fpsBoostConexao then
            fpsBoostConexao = Workspace.DescendantAdded:Connect(function(v)
                if FPS_BOOST then
                    pcall(function()
                        if v:IsA("BasePart") and not v.Parent:FindFirstChildWhichIsA("Humanoid") then
                            v.Material = Enum.Material.SmoothPlastic
                        elseif v:IsA("Decal") or v:IsA("Texture") then
                            v.Transparency = 1
                        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                            v.Enabled = false
                        end
                    end)
                end
            end)
            table.insert(sessao.Conexoes, fpsBoostConexao)
        end
    else
        pcall(function()
            Lighting.GlobalShadows = true
        end)
        if fpsBoostConexao then
            fpsBoostConexao:Disconnect()
            fpsBoostConexao = nil
        end
    end
end

local function obterPosicaoEPart(obj)
    if not obj or not obj.Parent then return nil, nil end
    if obj:IsA("BasePart") then
        return obj.Position, obj
    elseif obj:IsA("Model") then
        local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if pp then
            return pp.Position, pp
        end
    end
    return nil, nil
end

local function calcularValorRapido(obj)
    if not PRIORIZAR_CAIXAS then return 1 end
    local nome = obj.Name
    if nome == "Model" then
        local p = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if p and p.Size.Magnitude > 4 then
            return 8
        end
        return 1
    end
    local nomeMin = string.lower(nome)
    if string.find(nomeMin, "box") or string.find(nomeMin, "crate") or string.find(nomeMin, "chest") then
        return 10
    elseif string.find(nomeMin, "stack") or string.find(nomeMin, "pile") then
        return 4
    end
    return 1
end

local function buscarMelhorAlvo(origem)
    local melhorAlvo = nil
    local maiorScore = -1
    local agora = os.clock()

    for item, expira in pairs(historicoRecentes) do
        if agora > expira or not item.Parent then
            historicoRecentes[item] = nil
        end
    end

    local pickupsFolder = Workspace:FindFirstChild("Pickups")
    if not pickupsFolder then return nil end

    local itens = pickupsFolder:GetChildren()
    for i = 1, #itens do
        local item = itens[i]
        if item ~= ultimoAlvoInstancia and not historicoRecentes[item] then
            local pos, part = obterPosicaoEPart(item)
            if pos then
                local dx = pos.X - origem.X
                local dy = pos.Y - origem.Y
                local dz = pos.Z - origem.Z
                local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

                if dist <= RAIO_MAXIMO_BUSCA then
                    local val = calcularValorRapido(item)
                    local score = (val * 15) / (dist + 3)

                    if score > maiorScore then
                        maiorScore = score
                        melhorAlvo = {
                            Instancia = item,
                            Part = part,
                            Posicao = pos,
                            Distancia = dist
                        }
                    end
                end
            end
        end
    end

    if not melhorAlvo and #itens > 0 then
        table.clear(historicoRecentes)
        ultimoAlvoInstancia = nil
        for i = 1, #itens do
            local item = itens[i]
            local pos, part = obterPosicaoEPart(item)
            if pos then
                local dx = pos.X - origem.X
                local dy = pos.Y - origem.Y
                local dz = pos.Z - origem.Z
                local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

                if dist <= RAIO_MAXIMO_BUSCA then
                    local val = calcularValorRapido(item)
                    local score = (val * 15) / (dist + 3)

                    if score > maiorScore then
                        maiorScore = score
                        melhorAlvo = {
                            Instancia = item,
                            Part = part,
                            Posicao = pos,
                            Distancia = dist
                        }
                    end
                end
            end
        end
    end

    return melhorAlvo
end

local function obterOvoMaisProximo(origem)
    local menorDist = math.huge
    local ovoMaisProx = nil
    local nomeOvo = nil

    local function escanearPasta(pasta)
        if not pasta then return end
        for _, obj in ipairs(pasta:GetChildren()) do
            local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
            if pp then
                local dx = pp.Position.X - origem.X
                local dy = pp.Position.Y - origem.Y
                local dz = pp.Position.Z - origem.Z
                local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                if dist < menorDist then
                    menorDist = dist
                    ovoMaisProx = obj
                    nomeOvo = obj.Name
                end
            end
        end
    end

    escanearPasta(Workspace:FindFirstChild("Eggs"))
    
    local eggStatue = Workspace:FindFirstChild("EggStatue")
    if eggStatue then
        escanearPasta(eggStatue:FindFirstChild("Eggs"))
    end

    local floating = Workspace:FindFirstChild("FloatingIslands")
    if floating then
        for _, island in ipairs(floating:GetDescendants()) do
            if island.Name == "Eggs" and island:IsA("Folder") then
                escanearPasta(island)
            end
        end
    end

    return ovoMaisProx, nomeOvo, menorDist
end

local function pularAnimacaoOvo()
    if not SKIP_EGG_ANIM then return end
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if playerGui then
            local screenGuiGame = playerGui:FindFirstChild("ScreenGui")
            if screenGuiGame then
                local eggOpening = screenGuiGame:FindFirstChild("EggOpening")
                if eggOpening and eggOpening.Visible then
                    eggOpening.Visible = false
                end
                local buyEggFrame = screenGuiGame:FindFirstChild("BuyEggFrame")
                if buyEggFrame and buyEggFrame.Visible then
                    buyEggFrame.Visible = false
                end
            end
        end
    end)
end

local function abrirOvoCompleto(nomeOvo, ovoObj)
    if not nomeOvo then return end

    pcall(function()
        local servicesMod = require(ReplicatedStorage.Assets.Modules.Services)
        local hotkeyService = servicesMod:GetService("HotkeyService")
        if hotkeyService and hotkeyService.GetActiveHotkeys then
            local hotkeys = hotkeyService:GetActiveHotkeys()
            for _, hk in pairs(hotkeys) do
                if hk.Function then
                    hk.Function()
                elseif hk.Function2 then
                    hk.Function2()
                elseif hk.Function3 then
                    hk.Function3()
                end
            end
        end
    end)

    if NetworkRemoteEvent then
        pcall(function()
            NetworkRemoteEvent:FireServer("HatchEgg", nomeOvo, 1)
            NetworkRemoteEvent:FireServer("BuyEgg", nomeOvo, 1)
            NetworkRemoteEvent:FireServer("OpenEgg", nomeOvo, 1)
            NetworkRemoteEvent:FireServer("HatchEgg", nomeOvo, 3)
            NetworkRemoteEvent:FireServer("BuyEgg", nomeOvo, 3)
            NetworkRemoteEvent:FireServer("OpenEgg", nomeOvo, 3)
        end)
    end

    if NetworkRemoteFunction then
        pcall(function()
            task.spawn(function()
                NetworkRemoteFunction:InvokeServer("BuyEgg", nomeOvo, 1)
            end)
            task.spawn(function()
                NetworkRemoteFunction:InvokeServer("OpenEgg", nomeOvo, 1)
            end)
        end)
    end

    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.03)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
            task.wait(0.03)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        end)
    end

    if ovoObj then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hkPart = ovoObj:FindFirstChild("Hotkey") or ovoObj:FindFirstChildWhichIsA("BasePart", true)
        if hrp and hkPart and typeof(firetouchinterest) == "function" then
            pcall(function()
                firetouchinterest(hrp, hkPart, 0)
                task.wait()
                firetouchinterest(hrp, hkPart, 1)
            end)
        end
    end

    pularAnimacaoOvo()
end

local function estaBauDisponivel(chestModel, nomeIlha)
    if not chestModel or not chestModel.Parent then return false end

    local chestPart = chestModel:FindFirstChild("Chest")
    if chestPart and chestPart:IsA("BasePart") then
        if chestPart.Transparency > 0.5 then
            return false
        end
    end

    local regenGui = chestModel:FindFirstChild("Regen")
    if regenGui and (regenGui:IsA("SurfaceGui") or regenGui:IsA("BillboardGui")) then
        if regenGui.Enabled == true then
            return false
        end
    end

    local dadosDisponivel = true
    pcall(function()
        local servicesMod = require(ReplicatedStorage.Assets.Modules.Services)
        local network = servicesMod:GetService("Network")
        local library = servicesMod:GetService("Library")
        local idx = library("index")
        if network and idx and idx.CHEST_REGEN_TIMES then
            local regenTimes = network:Call("GetClientData", idx.CHEST_REGEN_TIMES)
            if type(regenTimes) == "table" then
                local serverTime = os.time()
                local chestScript = ReplicatedStorage.Assets.Modules:FindFirstChild("ChestLayerService")
                if chestScript and chestScript:FindFirstChild("ServerTime") then
                    serverTime = chestScript.ServerTime.Value
                end

                for _, entry in ipairs(regenTimes) do
                    if entry[1] == nomeIlha then
                        local expireTime = entry[2]
                        if expireTime and (expireTime - serverTime) > 0 then
                            dadosDisponivel = false
                        end
                        break
                    end
                end
            end
        end
    end)

    return dadosDisponivel
end

local function obterPadEBau(chestModel, nomeIlha)
    local padPart = nil
    local chestPart = chestModel:FindFirstChild("Chest")

    for _, child in ipairs(chestModel:GetChildren()) do
        if child:IsA("Model") and string.find(child.Name, "Chest Collect") then
            padPart = child:FindFirstChild("Root") or child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
            if padPart then break end
        end
    end

    if not padPart then
        local actModel = Workspace:FindFirstChild("Activations") and Workspace.Activations:FindFirstChild("Chest Collect " .. nomeIlha)
        if actModel then
            padPart = actModel:FindFirstChild("Root") or actModel.PrimaryPart or actModel:FindFirstChildWhichIsA("BasePart")
        end
    end

    if not padPart then
        padPart = chestModel:FindFirstChild("Root", true) or chestModel:FindFirstChild("Particles") or chestPart
    end

    return padPart or chestPart, chestPart or padPart
end

local function coletarBausRapidoComSweep()
    if acaoEspecialAtiva then return end
    acaoEspecialAtiva = true

    local char, hrp, hum = obterPersonagem()
    if not char or not hrp or not hum then
        acaoEspecialAtiva = false
        return
    end

    local listaBaus = {}
    local floating = Workspace:FindFirstChild("FloatingIslands")
    if floating then
        for _, obj in ipairs(floating:GetDescendants()) do
            if obj.Name == "Chest" and obj:IsA("Model") then
                local nomeIlha = obj.Parent and obj.Parent.Name or "Ilha"
                if estaBauDisponivel(obj, nomeIlha) then
                    local padPart, chestPart = obterPadEBau(obj, nomeIlha)
                    if padPart and padPart:IsA("BasePart") then
                        table.insert(listaBaus, {
                            Nome = nomeIlha,
                            Pad = padPart,
                            Chest = chestPart,
                            Model = obj
                        })
                    end
                end
            end
        end
    end

    local total = #listaBaus
    if total == 0 then
        notificar("Baus", "Nenhum bau disponivel no momento (todos em cooldown).", "clock")
        acaoEspecialAtiva = false
        return
    end

    if tweenAtual then
        pcall(function() tweenAtual:Cancel() end)
        tweenAtual = nil
    end

    local posInicial = hrp.CFrame
    gerenciarNoclip(true)

    notificar("Varredura de Baus", "Coletando " .. total .. " baus disponiveis...", "package")

    for i = 1, total do
        if sessao.Limpar then break end
        local bInfo = listaBaus[i]
        local padPart = bInfo.Pad
        local chestPart = bInfo.Chest

        local posPadEmCima = padPart.Position + Vector3.new(0, 3.2, 0)
        local posPadCentro = padPart.Position
        local posDentroBau = (chestPart and chestPart.Position) or posPadCentro

        -- Alternância de múltiplos micro-teleportes (em cima da placa, dentro da placa, dentro do baú)
        for step = 1, 6 do
            if step % 3 == 1 then
                hrp.CFrame = CFrame.new(posPadEmCima)
            elseif step % 3 == 2 then
                hrp.CFrame = CFrame.new(posPadCentro)
            else
                hrp.CFrame = CFrame.new(posDentroBau)
            end
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

            if typeof(firetouchinterest) == "function" then
                pcall(function()
                    firetouchinterest(hrp, padPart, 0)
                    task.wait(0.015)
                    firetouchinterest(hrp, padPart, 1)
                    if chestPart and chestPart ~= padPart then
                        firetouchinterest(hrp, chestPart, 0)
                        task.wait(0.015)
                        firetouchinterest(hrp, chestPart, 1)
                    end
                end)
                for _, d in ipairs(bInfo.Model:GetDescendants()) do
                    if d:IsA("BasePart") and (d.Name == "Root" or d.Name == "Chest" or d.Name == "Particles") then
                        pcall(function()
                            firetouchinterest(hrp, d, 0)
                            task.wait()
                            firetouchinterest(hrp, d, 1)
                        end)
                    end
                end
            end

            if NetworkRemoteEvent then
                pcall(function()
                    NetworkRemoteEvent:FireServer("CollectChestReward", bInfo.Nome)
                end)
            end

            pcall(function()
                local servicesMod = require(ReplicatedStorage.Assets.Modules.Services)
                local actService = servicesMod:GetService("ActivationService")
                if actService and actService.Activation then
                    for actObj, actData in pairs(actService.Activation) do
                        if actObj and string.find(tostring(actObj.Name), bInfo.Nome) and typeof(actData[1]) == "function" then
                            pcall(actData[1])
                        end
                    end
                end
            end)

            task.wait(0.06)
        end

        task.wait(0.05)
    end

    hrp.CFrame = posInicial
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    gerenciarNoclip(ATIVADO)

    notificar("Baus Coletados", "Coleta finalizada com sucesso.", "check")
    acaoEspecialAtiva = false
end

local function tentarTocar(hrp, part)
    if not part or not part.Parent then return end
    if typeof(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(hrp, part, 0)
            task.wait()
            firetouchinterest(hrp, part, 1)
        end)
    end
end

local function tweenAteMoeda(alvoInfo)
    local char, hrp, hum = obterPersonagem()
    if not char or not hrp or not hum then return false end

    local destino = alvoInfo.Posicao + Vector3.new(0, ALTURA_OFFSET, 0)
    local item = alvoInfo.Instancia
    local part = alvoInfo.Part

    ultimoAlvoInstancia = item
    historicoRecentes[item] = os.clock() + TEMPO_COOLDOWN_MOEDA

    local dist = (hrp.Position - destino).Magnitude
    local duracao = math.clamp(dist / VELOCIDADE_TWEEN, 0.02, 1.0)

    local tweenInfo = TweenInfo.new(duracao, Enum.EasingStyle.Linear)
    local cframeAlvo = CFrame.new(destino, destino + hrp.CFrame.LookVector)

    if tweenAtual then
        pcall(function() tweenAtual:Cancel() end)
        tweenAtual = nil
    end

    tweenAtual = TweenService:Create(hrp, tweenInfo, {CFrame = cframeAlvo})
    tweenAtual:Play()

    local inicio = os.clock()
    while ATIVADO and not sessao.Limpar and not acaoEspecialAtiva and (os.clock() - inicio < duracao + 0.03) do
        if not item or not item.Parent then
            pcall(function() tweenAtual:Cancel() end)
            tentarTocar(hrp, part)
            totalColetadas = totalColetadas + 1
            return true
        end

        local distAtual = (hrp.Position - destino).Magnitude
        if distAtual <= 3.5 then
            tentarTocar(hrp, part)
            if not item.Parent or distAtual <= 1.2 then
                pcall(function() tweenAtual:Cancel() end)
                totalColetadas = totalColetadas + 1
                return true
            end
        end

        task.wait(0.015)
    end

    tentarTocar(hrp, part)
    return true
end

local function coletarPremiosEGiros()
    if not NetworkRemoteEvent then return end

    pcall(function()
        NetworkRemoteEvent:FireServer("AlienSpinToWin")
        NetworkRemoteEvent:FireServer("SpinToWin")
        NetworkRemoteEvent:FireServer("ClaimDailyReward")
        NetworkRemoteEvent:FireServer("ClaimGroupBenefits")
    end)

    for i = 1, 12 do
        pcall(function()
            NetworkRemoteEvent:FireServer("ClaimGift", i)
            NetworkRemoteEvent:FireServer("ClaimGiftReward", i)
            NetworkRemoteEvent:FireServer("ClaimPlaytimeReward", i)
        end)
    end

    for _, nomeBau in ipairs(bausGlobais) do
        pcall(function()
            NetworkRemoteEvent:FireServer("CollectChestReward", nomeBau)
        end)
    end
end

local function desbloquearTodasIlhasDefinitivo()
    if acaoEspecialAtiva then return end
    acaoEspecialAtiva = true

    local char, hrp, hum = obterPersonagem()
    if not char or not hrp or not hum then
        acaoEspecialAtiva = false
        return
    end

    if tweenAtual then
        pcall(function() tweenAtual:Cancel() end)
        tweenAtual = nil
    end

    local posInicial = hrp.CFrame
    gerenciarNoclip(true)

    notificar("Desbloqueando Ilhas", "Comprando mundos e visitando checkpoints...", "globe")

    for _, mundoNome in ipairs(mundosComprar) do
        if NetworkRemoteFunction then
            pcall(function()
                NetworkRemoteFunction:InvokeServer("BuyWorld", mundoNome)
            end)
        end
        if NetworkRemoteEvent then
            pcall(function()
                NetworkRemoteEvent:FireServer("BuyWorld", mundoNome)
            end)
        end
    end

    local checkpointsParaVisitar = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v.Name == "Checkpoint" and v:IsA("StringValue") and v.Parent and v.Parent:IsA("BasePart") then
            table.insert(checkpointsParaVisitar, {
                Nome = v.Value,
                Part = v.Parent,
                Modelo = v.Parent.Parent
            })
        end
    end

    local floating = Workspace:FindFirstChild("FloatingIslands")
    if floating then
        for _, mundo in ipairs(floating:GetChildren()) do
            for _, ilha in ipairs(mundo:GetChildren()) do
                if ilha:IsA("Model") then
                    local p = ilha:FindFirstChild("Collision") or ilha:FindFirstChild("TeleportToSurface") or ilha:FindFirstChild("TeleportPoint") or ilha:FindFirstChild("FastSpawn") or ilha.PrimaryPart
                    if p and p:IsA("BasePart") then
                        table.insert(checkpointsParaVisitar, {
                            Nome = ilha.Name,
                            Part = p,
                            Modelo = ilha
                        })
                    end
                end
            end
        end
    end

    local total = #checkpointsParaVisitar
    for i = 1, total do
        if sessao.Limpar then break end
        local cp = checkpointsParaVisitar[i]

        local posAlvo = cp.Part.Position + Vector3.new(0, 3, 0)
        hrp.CFrame = CFrame.new(posAlvo)
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

        for step = 1, 3 do
            if typeof(firetouchinterest) == "function" then
                pcall(function()
                    firetouchinterest(hrp, cp.Part, 0)
                    task.wait(0.04)
                    firetouchinterest(hrp, cp.Part, 1)
                end)

                if cp.Modelo then
                    for _, obj in ipairs(cp.Modelo:GetDescendants()) do
                        if obj:IsA("BasePart") and (obj.Name == "Door" or obj.Name == "TeleportPoint" or obj.Name == "FastSpawn" or obj.Name == "Collision" or obj.Name == "TeleportToSurface") then
                            pcall(function()
                                firetouchinterest(hrp, obj, 0)
                                task.wait(0.02)
                                firetouchinterest(hrp, obj, 1)
                            end)
                        end
                    end
                end
            end

            if NetworkRemoteEvent and cp.Nome then
                pcall(function()
                    NetworkRemoteEvent:FireServer("SetCheckpoint", cp.Nome)
                    NetworkRemoteEvent:FireServer("Checkpoint", cp.Nome)
                    NetworkRemoteEvent:FireServer("DiscoverIsland", cp.Nome)
                    NetworkRemoteEvent:FireServer("UnlockIsland", cp.Nome)
                end)
            end
            task.wait(0.08)
        end

        task.wait(0.05)
    end

    local checkpointsFolder = Workspace:FindFirstChild("Checkpoints")
    if checkpointsFolder then
        for _, chkModel in ipairs(checkpointsFolder:GetChildren()) do
            local doorPart = chkModel:FindFirstChild("Door") or chkModel:FindFirstChildWhichIsA("BasePart", true)
            if doorPart and typeof(firetouchinterest) == "function" then
                pcall(function()
                    firetouchinterest(hrp, doorPart, 0)
                    task.wait(0.03)
                    firetouchinterest(hrp, doorPart, 1)
                end)
            end
        end
    end

    hrp.CFrame = posInicial
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    gerenciarNoclip(ATIVADO)

    notificar("Sucesso", "Todas as ilhas e checkpoints foram desbloqueados.", "check")
    acaoEspecialAtiva = false
end

local function obterWorldService()
    local ws = nil
    pcall(function()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg and pg:FindFirstChild("ScreenGui") and pg.ScreenGui:FindFirstChild("ClientScript") and pg.ScreenGui.ClientScript:FindFirstChild("Modules") then
            local mod = pg.ScreenGui.ClientScript.Modules:FindFirstChild("WorldService")
            if mod then
                ws = require(mod)
            end
        end
    end)
    if not ws then
        pcall(function()
            local servicesMod = require(ReplicatedStorage.Assets.Modules.Services)
            ws = servicesMod:GetService("WorldService")
        end)
    end
    return ws
end

local function viajarParaMundo(nomeMundo)
    if not nomeMundo then return end

    if tweenAtual then
        pcall(function() tweenAtual:Cancel() end)
        tweenAtual = nil
    end

    local char, hrp, hum = obterPersonagem()
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
    gerenciarNoclip(true)

    pcall(function()
        if NetworkRemoteFunction then
            NetworkRemoteFunction:InvokeServer("BuyWorld", nomeMundo)
        end
        if NetworkRemoteEvent then
            NetworkRemoteEvent:FireServer("BuyWorld", nomeMundo)
        end
    end)

    local ws = obterWorldService()
    local trocouPeloService = false
    if ws and typeof(ws.SetWorld) == "function" then
        pcall(function()
            ws:SetWorld(nomeMundo)
            trocouPeloService = true
        end)
    end

    if not trocouPeloService or (ws and typeof(ws.GetCurrentWorld) == "function" and ws:GetCurrentWorld() ~= nomeMundo) then
        pcall(function()
            if NetworkRemoteFunction then
                task.spawn(function()
                    NetworkRemoteFunction:InvokeServer("Teleport", nomeMundo .. "Spawn")
                end)
            end
            if NetworkRemoteEvent then
                NetworkRemoteEvent:FireServer("Teleport", nomeMundo .. "Spawn")
            end
        end)
    end

    task.delay(1.5, function()
        local c, h, hm = obterPersonagem()
        if h then
            h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        gerenciarNoclip(ATIVADO and NOCLIP_ATIVO)
    end)

    notificar("Teleporte", "Viajando para: " .. tostring(nomeMundo), "map-pin")
end

-- Aba: Farm e Ovos
FarmTab:Section({ Title = "Coin Harvester" })

FarmTab:Toggle({
    Title = "Auto Farm Moedas (Tween)",
    Desc = "Movimenta ate moedas e caixas pelo mapa",
    Default = ATIVADO,
    Callback = function(v)
        ATIVADO = v
        gerenciarNoclip(ATIVADO)
        if not ATIVADO then
            if tweenAtual then
                pcall(function() tweenAtual:Cancel() end)
                tweenAtual = nil
            end
        else
            if not threadPrincipal or coroutine.status(threadPrincipal) == "dead" then
                threadPrincipal = task.spawn(function()
                    while ATIVADO and not sessao.Limpar do
                        if not acaoEspecialAtiva then
                            local char, hrp, hum = obterPersonagem()
                            if hrp and hum and hum.Health > 0 then
                                local alvo = buscarMelhorAlvo(hrp.Position)
                                if alvo and alvo.Instancia and alvo.Instancia.Parent then
                                    tweenAteMoeda(alvo)
                                else
                                    task.wait(0.2)
                                end
                            else
                                task.wait(1)
                            end
                        else
                            task.wait(0.5)
                        end
                        task.wait(0.01)
                    end
                    gerenciarNoclip(false)
                end)
                table.insert(sessao.Threads, threadPrincipal)
            end
        end
    end
})

FarmTab:Slider({
    Title = "Velocidade do Tween",
    Desc = "Velocidade de deslocamento (studs/s)",
    Value = {
        Min = 60,
        Max = 400,
        Default = VELOCIDADE_TWEEN
    },
    Step = 10,
    Callback = function(v)
        VELOCIDADE_TWEEN = v
    end
})

FarmTab:Toggle({
    Title = "Priorizar Caixas Grandes",
    Desc = "Foca em coletar caixas de maior valor",
    Default = PRIORIZAR_CAIXAS,
    Callback = function(v)
        PRIORIZAR_CAIXAS = v
    end
})

FarmTab:Toggle({
    Title = "Noclip Ativo",
    Desc = "Atravessa objetos durante o movimento",
    Default = NOCLIP_ATIVO,
    Callback = function(v)
        NOCLIP_ATIVO = v
        gerenciarNoclip(ATIVADO and NOCLIP_ATIVO)
    end
})

FarmTab:Section({ Title = "Turbo Bubble e Auto Egg" })

FarmTab:Toggle({
    Title = "Turbo Auto Bubble",
    Desc = "Sopra bolhas continuamente na velocidade maxima",
    Default = AUTO_BUBBLE,
    Callback = function(v)
        AUTO_BUBBLE = v
    end
})

FarmTab:Toggle({
    Title = "Auto Egg por Proximidade",
    Desc = "Choca ovos automaticamente ao se aproximar",
    Default = AUTO_EGG,
    Callback = function(v)
        AUTO_EGG = v
        if AUTO_EGG then
            if not threadEgg or coroutine.status(threadEgg) == "dead" then
                threadEgg = task.spawn(function()
                    while AUTO_EGG and not sessao.Limpar do
                        local char, hrp, hum = obterPersonagem()
                        if hrp and hum and hum.Health > 0 then
                            local ovoObj, nomeOvo, dist = obterOvoMaisProximo(hrp.Position)
                            if nomeOvo and dist <= DISTANCIA_MAX_OVO then
                                abrirOvoCompleto(nomeOvo, ovoObj)
                                totalOvosAbertos = totalOvosAbertos + 1
                                task.wait(0.3)
                            else
                                task.wait(0.35)
                            end
                        else
                            task.wait(1)
                        end
                        task.wait(0.02)
                    end
                end)
                table.insert(sessao.Threads, threadEgg)
            end
        end
    end
})

FarmTab:Toggle({
    Title = "Pular Cutscene do Ovo",
    Desc = "Fecha animacao do ovo instantaneamente",
    Default = SKIP_EGG_ANIM,
    Callback = function(v)
        SKIP_EGG_ANIM = v
    end
})

-- Aba: Recompensas
RewardsTab:Section({ Title = "Giros e Presentes" })

RewardsTab:Toggle({
    Title = "Auto Giros e Playtime Gifts",
    Desc = "Coleta spins diarios, recompensas de grupo e playtime gifts",
    Default = AUTO_REWARDS,
    Callback = function(v)
        AUTO_REWARDS = v
    end
})

RewardsTab:Button({
    Title = "Coletar Giros e Presentes Agora",
    Desc = "Dispara a coleta imediata de todas as recompensas",
    Callback = function()
        coletarPremiosEGiros()
        notificar("Recompensas", "Giros e presentes coletados com sucesso.", "gift")
    end
})

RewardsTab:Section({ Title = "Baus Remotos Globais" })

RewardsTab:Toggle({
    Title = "Auto Coleta Remota de Baus",
    Desc = "Requisita baus a cada 15 segundos",
    Default = AUTO_CHESTS,
    Callback = function(v)
        AUTO_CHESTS = v
    end
})

RewardsTab:Button({
    Title = "Coletar Todos os Baus (Global Sweep)",
    Desc = "Varre e coleta apenas os baus que nao estao em cooldown",
    Callback = function()
        task.spawn(coletarBausRapidoComSweep)
    end
})

-- Aba: Mundos e Ilhas
WorldsTab:Section({ Title = "Desbloqueio de Todas as Ilhas" })

WorldsTab:Button({
    Title = "Desbloquear Todas as Ilhas (Checkpoints)",
    Desc = "Visita fisicamente todos os checkpoints e compra mundos novos",
    Callback = function()
        task.spawn(desbloquearTodasIlhasDefinitivo)
    end
})

WorldsTab:Section({ Title = "Teleporte Rapido de Mundo" })

WorldsTab:Dropdown({
    Title = "Teleportar para Mundo",
    Desc = "Altera instantaneamente para o mundo selecionado",
    Multi = false,
    Option = {
        "Overworld", "Candy Land", "Toy Land", "Beach World",
        "Atlantis", "Rainbow Land", "Underworld", "Mystic Forest", "Heaven"
    },
    Value = "Overworld",
    Callback = function(v)
        local mundo = (typeof(v) == "table" and v[1]) or v
        viajarParaMundo(mundo)
    end
})

-- Aba: Configuracoes e AFK
SettingsTab:Section({ Title = "Performance e AFK" })

SettingsTab:Toggle({
    Title = "Anti-AFK Integrado (24/7)",
    Desc = "Previne desconexao automatica do Roblox por inatividade",
    Default = true,
    Callback = function() end
})

SettingsTab:Toggle({
    Title = "Modo Economia / FPS Booster",
    Desc = "Reduz texturas, sombras e particulas para economia de bateria e performance",
    Default = FPS_BOOST,
    Callback = function(v)
        FPS_BOOST = v
        aplicarFPSBoost(FPS_BOOST)
    end
})

SettingsTab:Section({ Title = "Aparencia do Menu" })

SettingsTab:Dropdown({
    Title = "Tema do Menu",
    Option = { "Dark", "Light", "Forest", "Amethyst" },
    Value = "Dark",
    Callback = function(Value)
        pcall(function()
            Window:SetTheme(Value)
            notificar("Tema", "Tema alterado para: " .. tostring(Value), "palette")
        end)
    end
})

SettingsTab:Section({ Title = "Sessao" })

SettingsTab:Button({
    Title = "Descarregar Script (Unload)",
    Desc = "Fecha e encerra todas as conexoes do script com seguranca",
    Callback = function()
        sessao.Unload()
    end
})

local idledConexao = LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)
table.insert(sessao.Conexoes, idledConexao)

threadBubble = task.spawn(function()
    while not sessao.Limpar do
        if AUTO_BUBBLE and NetworkRemoteEvent then
            pcall(function()
                NetworkRemoteEvent:FireServer("BlowBubble")
            end)
        end
        task.wait(0.03)
    end
end)
table.insert(sessao.Threads, threadBubble)

threadRewards = task.spawn(function()
    while not sessao.Limpar do
        if AUTO_REWARDS or AUTO_CHESTS then
            coletarPremiosEGiros()
        end
        task.wait(15)
    end
end)
table.insert(sessao.Threads, threadRewards)

function sessao.Unload()
    sessao.Limpar = true
    ATIVADO = false
    AUTO_EGG = false
    AUTO_BUBBLE = false
    AUTO_REWARDS = false
    AUTO_CHESTS = false
    FPS_BOOST = false
    acaoEspecialAtiva = false

    aplicarFPSBoost(false)

    if tweenAtual then
        pcall(function() tweenAtual:Cancel() end)
        tweenAtual = nil
    end

    gerenciarNoclip(false)

    for _, c in ipairs(sessao.Conexoes) do
        if typeof(c) == "RBXScriptConnection" and c.Connected then
            pcall(function() c:Disconnect() end)
        end
    end
    table.clear(sessao.Conexoes)

    for _, t in ipairs(sessao.Threads) do
        if typeof(t) == "thread" then
            pcall(function() task.cancel(t) end)
        end
    end
    table.clear(sessao.Threads)

    pcall(function()
        Window:Destroy()
    end)
end

atualizarPartesPersonagem()
notificar("BGS Privado", "Carregado com sucesso. Feito por h64", "shield")
