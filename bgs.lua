-- ==============================================================================
-- BUBBLE GUM SIMULATOR - AUTO FARM & SYSTEM SUITE (OPTIMIZED / MOBILE & PC)
-- ==============================================================================

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

-- ==================== CONFIGURAÇÕES GERAIS ====================
local ATIVADO = false
local AUTO_EGG = false
local SPAM_EGG = false
local QTD_OVOS = 3
local DELAY_EGG = 0.15

local AUTO_BUBBLE = true
local AUTO_REWARDS = true
local AUTO_CHESTS = true
local AUTO_MEGA_SPIN = true
local FPS_BOOST = false
local SKIP_EGG_ANIM = true
local uiInicializada = false

-- Configurações de Movimento & Tween
local VELOCIDADE_TWEEN = 90
local NOCLIP_ATIVO = true
local ALTURA_OFFSET = 0.8
local RAIO_MAXIMO_BUSCA = 400
local DISTANCIA_MAX_OVO = 40
local PRIORIZAR_CAIXAS = true
local TEMPO_COOLDOWN_MOEDA = 3.5
local FILTRO_MOEDAS = "Tudo"
local MAGNET_RAIO = 32
local TEMPO_PAD_BAU = 0.65

-- ==================== SERVIÇOS ROBLOX ====================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local NetworkRemoteEvent = ReplicatedStorage:FindFirstChild("NetworkRemoteEvent")
local NetworkRemoteFunction = ReplicatedStorage:FindFirstChild("NetworkRemoteFunction")
local LocalPlayer = Players.LocalPlayer

-- ==================== VARIÁVEIS DE ESTADO ====================
local historicoRecentes = {}
local ultimoAlvoInstancia = nil
local threadPrincipal = nil
local threadEgg = nil
local threadBubble = nil
local threadRewards = nil
local threadAntiAfk = nil
local noclipConexao = nil
local fpsBoostConexao = nil
local tweenAtual = nil
local partesPersonagem = {}
local acaoEspecialAtiva = false

-- ==================== LISTAS DE DADOS ====================
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

local codigosPorCategoria = {
    ["Sorte (2x Luck)"] = {
        "CrashFix", "Update82", "MythicFallenAngel", "Update81", "FrostPortal",
        "SuperSpooky", "Glitch", "Easter21", "Luckiest", "StPatrickLuck",
        "Update71", "Update70", "Update68", "JollyChristmas", "Update67",
        "Christmas2020", "Update65", "Update64", "Update63", "AutumnSale",
        "Update61", "Update59", "Update58", "Update57", "MegaLuckBoost",
        "Update55", "Update54", "Update53", "Update52", "Update51",
        "Update50", "Update49", "Season 8", "Eeaster2020", "Mushroom",
        "Mystic", "NewEgg", "Galactic", "Portal", "MegaSale",
        "600M", "Valentines", "Halloween", "BubblePass", "Fancy2",
        "2hourluck", "July4th", "NewWorld", "Kraken", "Ocean",
        "SecretLuckCode", "HappyEaster", "LostCity", "UnderTheSea", "Update21",
        "ThankYou", "StPatricks", "BriteJuice", "SecretCode", "sircfenneriscool",
        "SuperBeach", "Update16", "LuckyDay", "SuperLuck", "ExtraLuck"
    },
    ["Hatch Speed (2x Velocidade)"] = {
        "AlienCashew", "AlienInvasion", "PermMythic", "Update78", "Update77",
        "Update75", "Update74", "Update73", "Update72", "Valentine",
        "Royalty", "2020", "JollyChristmas2", "ChristmasPart2", "Split",
        "Costume", "SpookyHalloween", "AutumnSale2", "Autumn", "Vacation",
        "Carnival2", "Carnival", "MegaSpeedBoost", "SuperSale", "Shadow",
        "Meteor", "Vine", "Spring", "Mythic", "Merchant",
        "Update48", "Update47", "Update46", "Update45", "Season7",
        "Challenges", "LuckyDay2", "FreeSpeed", "600MBoost", "Cupid",
        "TrickOrTreat", "Pass", "ReallyFancy", "Fireworks", "Summer",
        "400m", "Tomcat", "InThePast", "AtlantisHats", "Bunny",
        "Poseidon", "Special", "UltraSpeed", "FREE", "300M",
        "SpeedyBoi", "SpeedBoost", "BeachBoost", "superspeed", "FreeBoost",
        "SylentlyIsCool", "SuperSecret", "SecretBoost"
    },
    ["Shiny Chance (3x Brilhante)"] = {
        "SorryShutdown", "Secrets", "Fancy", "UncleSam", "Colorful",
        "Thanks", "Mythical", "AncientTimes", "ChocolateEgg"
    },
    ["Moedas, Gemas, Doces e Pets"] = {
        "DeeterPlays", "SecretPet", "pinkarmypet", "FreePet", "MoreCandy",
        "Candy", "BlueCrew", "Twiisted", "Santa", "Sylently",
        "Christmas", "CandyCanes", "SuperCoins", "SuperGems", "Spotted",
        "FreeCoins", "LotsOfGems", "FreeEgg", "TwitterRelease", "Sircfenner",
        "Tofuu", "ObscureEntity", "Minime", "TwitchRelease", "Golemite"
    }
}

local codigosComDescricao = {
    ["Sorte (2x Luck)"] = {
        "--- Selecione um código de Sorte ---",
        "CrashFix (12h 2x Luck)", "Update82 (3h 2x Luck)", "MythicFallenAngel (3h 2x Luck)",
        "Update81 (3h 2x Luck)", "FrostPortal (6h 2x Luck)", "SuperSpooky (6h 2x Luck)",
        "Glitch (6h 2x Luck)", "Easter21 (6h 2x Luck)", "Luckiest (6h 2x Luck)",
        "StPatrickLuck (6h 2x Luck)", "Update71 (6h 2x Luck)", "Update70 (4h 2x Luck)",
        "Update68 (4h 2x Luck)", "JollyChristmas (6h 2x Luck)", "Update67 (3h 2x Luck)",
        "Christmas2020 (2h 2x Luck)", "Update65 (2h 2x Luck)", "Update64 (2h 2x Luck)",
        "Update63 (2h 2x Luck)", "AutumnSale (5h 2x Luck)", "Update61 (5h 2x Luck)",
        "Update59 (2h 2x Luck)", "Update58 (2h 2x Luck)", "Update57 (2h 2x Luck)",
        "MegaLuckBoost (12h 2x Luck)", "Update55 (2h 2x Luck)", "Update54 (6h 2x Luck)",
        "Update53 (2h 2x Luck)", "Update52 (2h 2x Luck)", "Update51 (6h 2x Luck)",
        "Update50 (2h 2x Luck)", "Update49 (2h 2x Luck)", "Season 8 (2h 2x Luck)",
        "Eeaster2020 (2h 2x Luck)", "Mushroom (2h 2x Luck)", "Mystic (2h 2x Luck)",
        "NewEgg (2h 2x Luck)", "Galactic (2h 2x Luck)", "Portal (2h 2x Luck)",
        "MegaSale (2h 2x Luck)", "600M (2h 2x Luck)", "Valentines (4h 2x Luck)",
        "Halloween (3h 2x Luck)", "BubblePass (15m 2x Luck)", "Fancy2 (15m 2x Luck)",
        "2hourluck (2h 2x Luck)", "July4th (15m 2x Luck)", "NewWorld (15m 2x Luck)",
        "Kraken (15m 2x Luck)", "Ocean (20m 2x Luck)", "SecretLuckCode (15m 2x Luck)",
        "HappyEaster (15m 2x Luck)", "LostCity (20m 2x Luck)", "UnderTheSea (15m 2x Luck)",
        "Update21 (15m 2x Luck)", "ThankYou (15m 2x Luck)", "StPatricks (15m 2x Luck)",
        "BriteJuice (5m 2x Luck)", "SecretCode (15m 2x Luck)", "sircfenneriscool (15m 2x Luck)",
        "SuperBeach (15m 2x Luck)", "Update16 (15m 2x Luck)", "LuckyDay (30m 2x Luck)",
        "SuperLuck (15m 2x Luck)", "ExtraLuck (10m 2x Luck)"
    },
    ["Hatch Speed (2x Velocidade)"] = {
        "--- Selecione um código de Speed ---",
        "AlienCashew (12h 2x Speed)", "AlienInvasion (3h 2x Speed)", "PermMythic (3h 2x Speed)",
        "Update78 (6h 2x Speed)", "Update77 (6h 2x Speed)", "Update75 (6h 2x Speed)",
        "Update74 (6h 2x Speed)", "Update73 (6h 2x Speed)", "Update72 (6h 2x Speed)",
        "Valentine (6h 2x Speed)", "Royalty (4h 2x Speed)", "2020 (4h 2x Speed)",
        "JollyChristmas2 (6h 2x Speed)", "ChristmasPart2 (3h 2x Speed)", "Split (2h 2x Speed)",
        "Costume (2h 2x Speed)", "SpookyHalloween (5h 2x Speed)", "AutumnSale2 (5h 2x Speed)",
        "Autumn (5h 2x Speed)", "Vacation (2h 2x Speed)", "Carnival2 (2h 2x Speed)",
        "Carnival (2h 2x Speed)", "MegaSpeedBoost (12h 2x Speed)", "SuperSale (2h 2x Speed)",
        "Shadow (6h 2x Speed)", "Meteor (2h 2x Speed)", "Vine (2h 2x Speed)",
        "Spring (6h 2x Speed)", "Mythic (2h 2x Speed)", "Merchant (2h 2x Speed)",
        "Update48 (2h 2x Speed)", "Update47 (2h 2x Speed)", "Update46 (2h 2x Speed)",
        "Update45 (2h 2x Speed)", "Season7 (2h 2x Speed)", "Challenges (2h 2x Speed)",
        "LuckyDay2 (2h 2x Speed)", "FreeSpeed (2h 2x Speed)", "600MBoost (2h 2x Speed)",
        "Cupid (4h 2x Speed)", "TrickOrTreat (3h 2x Speed)", "Pass (15m 2x Speed)",
        "ReallyFancy (15m 2x Speed)", "Fireworks (15m 2x Speed)", "Summer (15m 2x Speed)",
        "400m (15m 2x Speed)", "Tomcat (5m 2x Speed)", "InThePast (15m 2x Speed)",
        "AtlantisHats (15m 2x Speed)", "Bunny (15m 2x Speed)", "Poseidon (15m 2x Speed)",
        "Special (15m 2x Speed)", "UltraSpeed (15m 2x Speed)", "FREE (15m 2x Speed)",
        "300M (15m 2x Speed)", "SpeedyBoi (15m 2x Speed)", "SpeedBoost (15m 2x Speed)",
        "BeachBoost (15m 2x Speed)", "superspeed (15m 2x Speed)", "FreeBoost (30m 2x Speed)",
        "SylentlyIsCool (15m 2x Speed)", "SuperSecret (15m 2x Speed)", "SecretBoost (10m 2x Speed)"
    },
    ["Shiny Chance (3x Brilhante)"] = {
        "--- Selecione um código de Shiny ---",
        "SorryShutdown (2h 2x Shiny)", "Secrets (15m 3x Shiny)", "Fancy (15m 3x Shiny)",
        "UncleSam (15m 3x Shiny)", "Colorful (15m 3x Shiny)", "Thanks (15m 3x Shiny)",
        "Mythical (20m 3x Shiny)", "AncientTimes (15m 3x Shiny)", "ChocolateEgg (15m 3x Shiny)"
    },
    ["Moedas, Gemas, Doces e Pets"] = {
        "--- Selecione um código de Item ---",
        "DeeterPlays (5k Blocos)", "SecretPet (Toy Serpent)", "pinkarmypet (5k Gemas)",
        "FreePet (Twitter Dominus)", "MoreCandy (4k Doces)", "Candy (1k Doces)",
        "BlueCrew (5k Gemas)", "Twiisted (5k Gemas)", "Santa (2k Candy Canes)",
        "Sylently (10k Candy Canes)", "Christmas (5k Candy Canes)", "CandyCanes (100 Candy Canes)",
        "SuperCoins (1k Moedas)", "SuperGems (100 Gemas)", "Spotted (Spotted Egg)",
        "FreeCoins (150 Moedas)", "LotsOfGems (25 Gemas)", "FreeEgg (Spotted Egg)",
        "TwitterRelease (Twitter Doggy)", "Sircfenner (Spotted Egg)", "Tofuu (5k Moedas)",
        "ObscureEntity (500 Moedas)", "Minime (2.5k Moedas)", "TwitchRelease (Twitch Kitty)",
        "Golemite (Twitch Golem)"
    }
}

-- ==================== INTERFACE WINDUI ====================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Bubble Gum Simulator",
    Icon = "circle-dot",
    Author = "by h64 (Mobile & PC)",
    Folder = "BGS_h64",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark"
})

local function notificar(texto, duracao)
    pcall(function()
        WindUI:Notify({
            Title = "BGS",
            Content = texto or "",
            Duration = duracao or 3,
            Icon = "circle-dot"
        })
    end)
end

-- Abas do Menu
local FarmTab = Window:Tab({ Title = "Auto Farm", Icon = "sparkles" })
local EggTab = Window:Tab({ Title = "Ovos", Icon = "boxes" })
local RewardsTab = Window:Tab({ Title = "Recompensas", Icon = "gift" })
local WorldsTab = Window:Tab({ Title = "Mundos", Icon = "map-pin" })
local ConfigTab = Window:Tab({ Title = "Configurações", Icon = "sliders-horizontal" })

-- ==================== GERENCIAMENTO DO PERSONAGEM ====================
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

local charAddedConexao = LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    atualizarPartesPersonagem()
    gerenciarNoclip(ATIVADO and NOCLIP_ATIVO)
end)
table.insert(sessao.Conexoes, charAddedConexao)

-- ==================== FPS BOOST ====================
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

-- ==================== LÓGICA DE COLETAS & MAGNET ====================
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
            return 3.5
        end
        return 1
    end
    local nomeMin = string.lower(nome)
    if string.find(nomeMin, "box") or string.find(nomeMin, "crate") or string.find(nomeMin, "chest") then
        return 4.0
    elseif string.find(nomeMin, "stack") or string.find(nomeMin, "pile") then
        return 2.0
    end
    return 1
end

local function passaFiltroTipo(obj)
    if FILTRO_MOEDAS == "Tudo" then return true end
    local nomeMin = string.lower(obj.Name)
    local ehCaixa = string.find(nomeMin, "box") or string.find(nomeMin, "crate") or string.find(nomeMin, "chest") or (obj.Name == "Model" and obj:IsA("Model"))
    local ehGema = string.find(nomeMin, "gem") or string.find(nomeMin, "diamond") or string.find(nomeMin, "crystal")

    if FILTRO_MOEDAS == "Apenas Caixas Grandes" then
        return ehCaixa
    elseif FILTRO_MOEDAS == "Apenas Gemas" then
        return ehGema
    elseif FILTRO_MOEDAS == "Moedas / Mundo" then
        return not ehGema
    end
    return true
end

local function tentarTocar(hrp, part)
    if not hrp or not part or not part.Parent then return end
    if typeof(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(hrp, part, 0)
            task.wait()
            firetouchinterest(hrp, part, 1)
        end)
    end
end

local function aspirarMoedasProximas(hrp)
    local pickups = Workspace:FindFirstChild("Pickups")
    if not pickups or not hrp then return end
    local posChar = hrp.Position
    for _, item in ipairs(pickups:GetChildren()) do
        local pos, part = nil, nil
        if item:IsA("BasePart") then
            pos, part = item.Position, item
        elseif item:IsA("Model") then
            local pp = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
            if pp then pos, part = pp.Position, pp end
        end
        if pos and (pos - posChar).Magnitude <= MAGNET_RAIO then
            tentarTocar(hrp, part)
        end
    end
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
        if item ~= ultimoAlvoInstancia and not historicoRecentes[item] and passaFiltroTipo(item) then
            local pos, part = obterPosicaoEPart(item)
            if pos then
                local dx = pos.X - origem.X
                local dy = pos.Y - origem.Y
                local dz = pos.Z - origem.Z
                local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

                if dist <= RAIO_MAXIMO_BUSCA then
                    local val = calcularValorRapido(item)
                    local score = (val * 40) / (dist + 8)

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
            if passaFiltroTipo(item) then
                local pos, part = obterPosicaoEPart(item)
                if pos then
                    local dx = pos.X - origem.X
                    local dy = pos.Y - origem.Y
                    local dz = pos.Z - origem.Z
                    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

                    if dist <= RAIO_MAXIMO_BUSCA then
                        local val = calcularValorRapido(item)
                        local score = (val * 40) / (dist + 8)

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
    end

    return melhorAlvo
end

-- ==================== TWEEN SUAVE DE MOEDAS ====================
local function tweenAteMoeda(alvoInfo)
    local char, hrp, hum = obterPersonagem()
    if not char or not hrp or not hum then return false end

    local destino = alvoInfo.Posicao + Vector3.new(0, ALTURA_OFFSET, 0)
    local item = alvoInfo.Instancia
    local part = alvoInfo.Part

    ultimoAlvoInstancia = item
    historicoRecentes[item] = os.clock() + TEMPO_COOLDOWN_MOEDA

    local dist = (hrp.Position - destino).Magnitude
    if dist < 1.5 then
        tentarTocar(hrp, part)
        aspirarMoedasProximas(hrp)
        return true
    end

    local duracao = math.max(dist / math.max(VELOCIDADE_TWEEN, 20), 0.04)
    local tweenInfo = TweenInfo.new(duracao, Enum.EasingStyle.Linear)
    local cframeAlvo = CFrame.new(destino, destino + hrp.CFrame.LookVector)

    if tweenAtual then
        pcall(function() tweenAtual:Cancel() end)
        tweenAtual = nil
    end

    hrp.AssemblyLinearVelocity = Vector3.zero
    tweenAtual = TweenService:Create(hrp, tweenInfo, {CFrame = cframeAlvo})
    tweenAtual:Play()

    local inicio = os.clock()
    local ultimoMagnet = 0

    while ATIVADO and not sessao.Limpar and not acaoEspecialAtiva and (os.clock() - inicio < duracao + 0.05) do
        if not item or not item.Parent then
            tentarTocar(hrp, part)
            aspirarMoedasProximas(hrp)
            if tweenAtual then
                pcall(function() tweenAtual:Cancel() end)
                tweenAtual = nil
            end
            return true
        end

        local agora = os.clock()
        if agora - ultimoMagnet > 0.05 then
            ultimoMagnet = agora
            aspirarMoedasProximas(hrp)
        end

        local distAtual = (hrp.Position - destino).Magnitude
        if distAtual <= 3.2 then
            tentarTocar(hrp, part)
            if not item.Parent or distAtual <= 1.2 then
                if tweenAtual then
                    pcall(function() tweenAtual:Cancel() end)
                    tweenAtual = nil
                end
                aspirarMoedasProximas(hrp)
                return true
            end
        end

        task.wait(0.015)
    end

    tentarTocar(hrp, part)
    aspirarMoedasProximas(hrp)
    return true
end

-- ==================== SERVIÇO DE MUNDOS & ANTI-VOID ====================
local plataformaSegura = nil

local function criarOuMoverPlataformaSegura(posicao)
    if not posicao then return end
    pcall(function()
        if not plataformaSegura or not plataformaSegura.Parent then
            plataformaSegura = Instance.new("Part")
            plataformaSegura.Name = "BGS_SafePlatform"
            plataformaSegura.Size = Vector3.new(35, 2, 35)
            plataformaSegura.Anchored = true
            plataformaSegura.CanCollide = true
            plataformaSegura.Transparency = 1
            plataformaSegura.Material = Enum.Material.SmoothPlastic
            plataformaSegura.Parent = Workspace
        end
        plataformaSegura.CFrame = CFrame.new(posicao - Vector3.new(0, 3.2, 0))
    end)
end

local function removerPlataformaSegura()
    if plataformaSegura and plataformaSegura.Parent then
        pcall(function() plataformaSegura:Destroy() end)
        plataformaSegura = nil
    end
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
        hrp.AssemblyLinearVelocity = Vector3.zero
        criarOuMoverPlataformaSegura(hrp.Position)
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

    task.wait(0.4)
    local c, h, hm = obterPersonagem()
    if h then
        h.AssemblyLinearVelocity = Vector3.zero
        criarOuMoverPlataformaSegura(h.Position)
    end

    task.delay(1.0, function()
        local c2, h2, hm2 = obterPersonagem()
        if h2 then
            h2.AssemblyLinearVelocity = Vector3.zero
        end
        gerenciarNoclip(ATIVADO and NOCLIP_ATIVO)
    end)

    notificar("Viajando para: " .. tostring(nomeMundo), 2)
end

-- ==================== COLETA PRECISA DE BAÚS (VIA TWEEN NO PAD) ====================
local function estaBauDisponivel(chestModel, nomeIlha)
    if not chestModel or not chestModel.Parent then return false end

    local regenGui = chestModel:FindFirstChild("Regen") or chestModel:FindFirstChildWhichIsA("BillboardGui", true)
    if regenGui and (regenGui:IsA("SurfaceGui") or regenGui:IsA("BillboardGui")) then
        if regenGui.Enabled == true then
            return false
        end
    end

    local chestPart = chestModel:FindFirstChild("Chest")
    if chestPart and chestPart:IsA("BasePart") then
        if chestPart.Transparency >= 0.8 then
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

local function estaBauColetadoOuInvisivel(bInfo)
    local chestModel = bInfo.Model
    local chestPart = bInfo.Chest

    if not chestModel or not chestModel.Parent then return true end

    -- Se o Chest principal sumiu ou ficou invisível
    if chestPart and chestPart:IsA("BasePart") and chestPart.Transparency >= 0.8 then
        return true
    end

    -- Se o GUI de Regen foi ativado
    local regenGui = chestModel:FindFirstChild("Regen") or chestModel:FindFirstChildWhichIsA("BillboardGui", true)
    if regenGui and (regenGui:IsA("SurfaceGui") or regenGui:IsA("BillboardGui")) then
        if regenGui.Enabled == true then
            return true
        end
    end

    return false
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

local function coletarBauNoPad(bInfo, char, hrp, hum)
    local padPart = bInfo.Pad
    local chestPart = bInfo.Chest
    local chestModel = bInfo.Model
    local nomeIlha = bInfo.Nome

    if not padPart or not hrp or not hum then return end

    local basePos = padPart.Position
    local posTopoPad = basePos + Vector3.new(0, 2.6, 0)

    -- Cancela tween de moedas caso ativo
    if tweenAtual then
        pcall(function() tweenAtual:Cancel() end)
        tweenAtual = nil
    end

    -- Voa em Tween suave até o pad do baú
    local dist = (hrp.Position - posTopoPad).Magnitude
    local duracaoTween = math.clamp(dist / math.max(VELOCIDADE_TWEEN, 100), 0.15, 6.0)
    local tweenInfo = TweenInfo.new(duracaoTween, Enum.EasingStyle.Linear)

    hrp.AssemblyLinearVelocity = Vector3.zero
    local tweenBau = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(posTopoPad, posTopoPad + hrp.CFrame.LookVector)})
    tweenAtual = tweenBau
    tweenBau:Play()

    local inicioVoo = os.clock()
    while (os.clock() - inicioVoo < duracaoTween) and not sessao.Limpar and acaoEspecialAtiva do
        if (hrp.Position - posTopoPad).Magnitude <= 3.0 then
            break
        end

        -- Toques antecipados ao se aproximar do pad durante o voo
        if (hrp.Position - posTopoPad).Magnitude <= 8.0 then
            if typeof(firetouchinterest) == "function" then
                pcall(function()
                    firetouchinterest(hrp, padPart, 0)
                    task.wait()
                    firetouchinterest(hrp, padPart, 1)
                end)
            end
        end
        task.wait(0.02)
    end

    if tweenAtual == tweenBau then
        pcall(function() tweenBau:Cancel() end)
        tweenAtual = nil
    end

    hrp.CFrame = CFrame.new(posTopoPad)
    hrp.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.04)

    -- Membros para colisão física e touch interest
    local partesChar = { hrp }
    for _, name in ipairs({"LeftFoot", "RightFoot", "Left Leg", "Right Leg", "LowerTorso", "Torso"}) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then
            table.insert(partesChar, p)
        end
    end

    -- Waypoints para o boneco andar em cruz e círculos em cima do pad
    local waypoints = {
        Vector3.new(0, 0, 0),
        Vector3.new(1.8, 0, 0),
        Vector3.new(-1.8, 0, 0),
        Vector3.new(0, 0, 1.8),
        Vector3.new(0, 0, -1.8),
        Vector3.new(1.2, 0, 1.2),
        Vector3.new(-1.2, 0, -1.2)
    }

    local inicioTempo = os.clock()
    local tempoLimite = math.max(TEMPO_PAD_BAU + 1.2, 2.2)
    local wpIndex = 1

    while (os.clock() - inicioTempo < tempoLimite) and not sessao.Limpar and acaoEspecialAtiva do
        -- Verifica se o baú já foi registrado / sumiu
        if estaBauColetadoOuInvisivel(bInfo) then
            break
        end

        local offset = waypoints[wpIndex]
        local pontoPasso = basePos + offset + Vector3.new(0, 2.3, 0)
        wpIndex = (wpIndex % #waypoints) + 1

        -- Move o personagem andando no pad e atualiza velocidade física
        pcall(function()
            hum:MoveTo(pontoPasso)
            hrp.CFrame = CFrame.new(pontoPasso, basePos)
            hrp.AssemblyLinearVelocity = (pontoPasso - hrp.Position).Unit * 8
        end)

        -- Toques contínuos em todos os membros
        if typeof(firetouchinterest) == "function" then
            for _, pChar in ipairs(partesChar) do
                pcall(function()
                    firetouchinterest(pChar, padPart, 0)
                    task.wait()
                    firetouchinterest(pChar, padPart, 1)
                    if chestPart and chestPart ~= padPart then
                        firetouchinterest(pChar, chestPart, 0)
                        task.wait()
                        firetouchinterest(pChar, chestPart, 1)
                    end
                end)
            end

            if chestModel then
                for _, child in ipairs(chestModel:GetDescendants()) do
                    if child:IsA("BasePart") then
                        pcall(function()
                            firetouchinterest(hrp, child, 0)
                            task.wait()
                            firetouchinterest(hrp, child, 1)
                        end)
                    end
                end
            end
        end

        -- Invocação de remotes e serviços de ativação do jogo
        if NetworkRemoteEvent then
            pcall(function()
                NetworkRemoteEvent:FireServer("CollectChestReward", nomeIlha)
            end)
        end

        pcall(function()
            local servicesMod = require(ReplicatedStorage.Assets.Modules.Services)
            local actService = servicesMod:GetService("ActivationService")
            if actService and actService.Activation then
                for actObj, actData in pairs(actService.Activation) do
                    if actObj and string.find(tostring(actObj.Name), nomeIlha) and typeof(actData[1]) == "function" then
                        pcall(actData[1])
                    end
                end
            end
        end)

        task.wait(0.06)
    end

    task.wait(0.03)
end

local function obterListaBausMundoAtual()
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
    return listaBaus
end

local function coletarBausMundoAtualSweep()
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

    local listaBaus = obterListaBausMundoAtual()
    notificar("Iniciando coleta via Tween de " .. #listaBaus .. " baús...", 3)

    local coletados = 0
    for i = 1, #listaBaus do
        if sessao.Limpar then break end
        local bInfo = listaBaus[i]
        coletarBauNoPad(bInfo, char, hrp, hum)
        coletados = coletados + 1
        task.wait(0.05)
    end

    -- Retorno exato à posição inicial antes do clique
    local cFim, hFim = obterPersonagem()
    if hFim then
        hFim.CFrame = posInicial
        hFim.AssemblyLinearVelocity = Vector3.zero
        criarOuMoverPlataformaSegura(hFim.Position)
    end
    gerenciarNoclip(ATIVADO and NOCLIP_ATIVO)

    notificar("Coleta concluída: " .. coletados .. " baús coletados!", 3)
    acaoEspecialAtiva = false
end

local function coletarBausRapidoComSweep()
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

    local ws = obterWorldService()
    local mundoInicial = "Overworld"
    if ws and typeof(ws.GetCurrentWorld) == "function" then
        pcall(function() mundoInicial = ws:GetCurrentWorld() or "Overworld" end)
    end

    local todosMundos = { "Overworld", "Candy Land", "Toy Land", "Beach World", "Atlantis", "Rainbow Land", "Underworld", "Mystic Forest", "Heaven" }
    local totalColetadosGeral = 0

    notificar("Iniciando coleta global de baús com Tween...", 3)

    for _, mundo in ipairs(todosMundos) do
        if sessao.Limpar then break end

        if ws and typeof(ws.GetCurrentWorld) == "function" and ws:GetCurrentWorld() ~= mundo then
            viajarParaMundo(mundo)
            task.wait(0.8)
        end

        local listaBaus = obterListaBausMundoAtual()
        for i = 1, #listaBaus do
            if sessao.Limpar then break end
            local bInfo = listaBaus[i]
            coletarBauNoPad(bInfo, char, hrp, hum)
            totalColetadosGeral = totalColetadosGeral + 1
            task.wait(0.05)
        end
    end

    if ws and typeof(ws.GetCurrentWorld) == "function" and ws:GetCurrentWorld() ~= mundoInicial then
        viajarParaMundo(mundoInicial)
        task.wait(0.8)
    end

    -- Retorno exato à posição inicial antes do clique
    local cFim, hFim = obterPersonagem()
    if hFim then
        hFim.CFrame = posInicial
        hFim.AssemblyLinearVelocity = Vector3.zero
        criarOuMoverPlataformaSegura(hFim.Position)
    end
    gerenciarNoclip(ATIVADO and NOCLIP_ATIVO)

    notificar("Varredura concluída: " .. totalColetadosGeral .. " baús coletados!", 3.5)
    acaoEspecialAtiva = false
end

-- ==================== ABERTURA DE OVOS (AUTO DETECTA O MAIS PRÓXIMO) ====================
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
                if typeof(hk) == "table" then
                    if QTD_OVOS == 3 and hk.Function2 then
                        pcall(hk.Function2)
                    elseif hk.Function then
                        pcall(hk.Function)
                    elseif hk.Function3 then
                        pcall(hk.Function3)
                    end
                end
            end
        end
    end)

    pcall(function()
        local servicesMod = require(ReplicatedStorage.Assets.Modules.Services)
        local eggService = servicesMod:GetService("EggService") or servicesMod:GetService("EggsService")
        if eggService then
            if typeof(eggService.Hatch) == "function" then
                eggService:Hatch(nomeOvo, QTD_OVOS)
            elseif typeof(eggService.Open) == "function" then
                eggService:Open(nomeOvo, QTD_OVOS)
            elseif typeof(eggService.Buy) == "function" then
                eggService:Buy(nomeOvo, QTD_OVOS)
            end
        end
    end)

    if NetworkRemoteEvent then
        pcall(function()
            NetworkRemoteEvent:FireServer("HatchEgg", nomeOvo, QTD_OVOS)
            NetworkRemoteEvent:FireServer("BuyEgg", nomeOvo, QTD_OVOS)
            NetworkRemoteEvent:FireServer("OpenEgg", nomeOvo, QTD_OVOS)
        end)
    end

    if NetworkRemoteFunction then
        pcall(function()
            task.spawn(function()
                NetworkRemoteFunction:InvokeServer("BuyEgg", nomeOvo, QTD_OVOS)
            end)
            task.spawn(function()
                NetworkRemoteFunction:InvokeServer("HatchEgg", nomeOvo, QTD_OVOS)
            end)
            task.spawn(function()
                NetworkRemoteFunction:InvokeServer("OpenEgg", nomeOvo, QTD_OVOS)
            end)
        end)
    end

    if ovoObj then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hkPart = ovoObj:FindFirstChild("Hotkey") or ovoObj:FindFirstChild("Root") or ovoObj.PrimaryPart or ovoObj:FindFirstChildWhichIsA("BasePart", true)
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

-- ==================== RECOMPENSAS LIMPAS ====================
local function coletarMegaRoletas()
    if not NetworkRemoteEvent then return end

    pcall(function()
        NetworkRemoteEvent:FireServer("SpinToWin")
        NetworkRemoteEvent:FireServer("AlienSpinToWin")
        NetworkRemoteEvent:FireServer("VIPSpinToWin")
        NetworkRemoteEvent:FireServer("VIP_SPIN_TO_WIN")
        NetworkRemoteEvent:FireServer("SpinToWinSpooky")
        NetworkRemoteEvent:FireServer("SPIN_TO_WIN_SPOOKY")
    end)

    if NetworkRemoteFunction then
        pcall(function()
            task.spawn(function() NetworkRemoteFunction:InvokeServer("SpinToWin") end)
            task.spawn(function() NetworkRemoteFunction:InvokeServer("AlienSpinToWin") end)
            task.spawn(function() NetworkRemoteFunction:InvokeServer("VIPSpinToWin") end)
            task.spawn(function() NetworkRemoteFunction:InvokeServer("SpinToWinSpooky") end)
        end)
    end
end

local function coletarPremiosEGiros()
    if not NetworkRemoteEvent then return end

    pcall(function()
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

    if AUTO_MEGA_SPIN then
        coletarMegaRoletas()
    end
end

-- ==================== CÓDIGOS ====================
local function resgatarListaCodigos(lista, nomeCategoria)
    if not lista or #lista == 0 then return end
    notificar("Resgatando: " .. (nomeCategoria or "Selecionados"), 2)
    local total = #lista
    for i = 1, total do
        local codigo = lista[i]
        if NetworkRemoteFunction then
            pcall(function()
                task.spawn(function()
                    NetworkRemoteFunction:InvokeServer("PickCode", codigo)
                end)
                task.spawn(function()
                    NetworkRemoteFunction:InvokeServer("RedeemCode", codigo)
                end)
            end)
        end
        if NetworkRemoteEvent then
            pcall(function()
                NetworkRemoteEvent:FireServer("PickCode", codigo)
                NetworkRemoteEvent:FireServer("RedeemCode", codigo)
            end)
        end
        task.wait(0.04)
    end
    notificar("Códigos ativados: " .. (nomeCategoria or "Selecionados"), 2)
end

local function extrairNomeCodigo(item)
    if not item then return "" end
    local str = (typeof(item) == "table" and item[1]) or tostring(item)
    if string.find(str, "Selecione") or string.find(str, "^%-") then
        return ""
    end
    local codigo = string.match(str, "^(.-)%s*%(") or string.match(str, "^(.-)%s*%-") or str
    codigo = string.gsub(codigo, "^%s*(.-)%s*$", "%1")
    return codigo
end

local function resgatarUmCodigo(item)
    if not uiInicializada then return end
    local codigo = extrairNomeCodigo(item)
    if not codigo or codigo == "" or string.find(codigo, "Selecione") or string.find(codigo, "^%-") then
        return
    end
    notificar("Código enviado: " .. codigo, 2)
    if NetworkRemoteFunction then
        pcall(function()
            task.spawn(function() NetworkRemoteFunction:InvokeServer("PickCode", codigo) end)
            task.spawn(function() NetworkRemoteFunction:InvokeServer("RedeemCode", codigo) end)
        end)
    end
    if NetworkRemoteEvent then
        pcall(function()
            NetworkRemoteEvent:FireServer("PickCode", codigo)
            NetworkRemoteEvent:FireServer("RedeemCode", codigo)
        end)
    end
end

-- ==================== DESBLOQUEAR TODAS AS ILHAS ====================
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

    notificar("Desbloqueando ilhas...", 3)

    for _, mundoNome in ipairs(mundosComprar) do
        if NetworkRemoteFunction then
            pcall(function()
                NetworkRemoteFunction:InvokeServer("BuyWorld", mundoNome)
            end)
        end
        if NetworkRemoteEvent then
            NetworkRemoteEvent:FireServer("BuyWorld", mundoNome)
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
        hrp.AssemblyLinearVelocity = Vector3.zero

        for step = 1, 2 do
            if typeof(firetouchinterest) == "function" then
                pcall(function()
                    firetouchinterest(hrp, cp.Part, 0)
                    task.wait(0.03)
                    firetouchinterest(hrp, cp.Part, 1)
                end)

                if cp.Modelo then
                    for _, obj in ipairs(cp.Modelo:GetDescendants()) do
                        if obj:IsA("BasePart") and (obj.Name == "Door" or obj.Name == "TeleportPoint" or obj.Name == "FastSpawn" or obj.Name == "Collision" or obj.Name == "TeleportToSurface") then
                            pcall(function()
                                firetouchinterest(hrp, obj, 0)
                                task.wait(0.015)
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
            task.wait(0.06)
        end
        task.wait(0.04)
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
    hrp.AssemblyLinearVelocity = Vector3.zero
    gerenciarNoclip(ATIVADO and NOCLIP_ATIVO)

    notificar("Ilhas e checkpoints desbloqueados", 3)
    acaoEspecialAtiva = false
end

-- ==================== ELEMENTOS DA INTERFACE ====================

-- 1. ABA: AUTO FARM
FarmTab:Section({ Title = "Coleta Automática de Moedas (Tween Suave)" })

FarmTab:Toggle({
    Title = "Auto Farm Moedas",
    Desc = "Movimento contínuo e fluido coletando moedas no mapa",
    Value = ATIVADO,
    Callback = function(v)
        ATIVADO = v
        gerenciarNoclip(ATIVADO and NOCLIP_ATIVO)
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
                                    task.wait(0.15)
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
    Title = "Velocidade Tween",
    Desc = "Velocidade de movimento suave (studs/s)",
    Step = 5,
    Value = {
        Min = 40,
        Max = 250,
        Default = VELOCIDADE_TWEEN
    },
    Callback = function(v)
        VELOCIDADE_TWEEN = v
    end
})

FarmTab:Dropdown({
    Title = "Filtro de Moedas",
    Desc = "Selecione o tipo prioritário de pickups",
    Values = { "Tudo", "Apenas Caixas Grandes", "Apenas Gemas", "Moedas / Mundo" },
    Value = "Tudo",
    Multi = false,
    Callback = function(v)
        FILTRO_MOEDAS = (typeof(v) == "table" and v[1]) or v or "Tudo"
    end
})

FarmTab:Toggle({
    Title = "Priorizar Baús e Caixas",
    Desc = "Prioriza baús e caixas na rota de coleta",
    Value = PRIORIZAR_CAIXAS,
    Callback = function(v)
        PRIORIZAR_CAIXAS = v
    end
})

FarmTab:Toggle({
    Title = "Noclip",
    Desc = "Atravessa colisões durante o farm",
    Value = NOCLIP_ATIVO,
    Callback = function(v)
        NOCLIP_ATIVO = v
        gerenciarNoclip(ATIVADO and NOCLIP_ATIVO)
    end
})

FarmTab:Section({ Title = "Bolhas Automáticas" })

FarmTab:Toggle({
    Title = "Auto Bubble",
    Desc = "Sopra bolhas automaticamente sem parar",
    Value = AUTO_BUBBLE,
    Callback = function(v)
        AUTO_BUBBLE = v
    end
})

-- 2. ABA: OVOS
EggTab:Section({ Title = "Abertura de Ovos (Sem Teclado / Mobile & PC)" })

EggTab:Dropdown({
    Title = "Quantidade por Abertura",
    Desc = "Número de ovos por ciclo de abertura (Padrão: 3)",
    Values = { "3 Ovos (Gamepass)", "1 Ovo (Padrão)" },
    Value = "3 Ovos (Gamepass)",
    Multi = false,
    Callback = function(v)
        local opt = (typeof(v) == "table" and v[1]) or v or ""
        if string.find(tostring(opt), "1") then
            QTD_OVOS = 1
        else
            QTD_OVOS = 3
        end
    end
})

EggTab:Toggle({
    Title = "Spam Ovos (Ovo Mais Próximo)",
    Desc = "Abre continuamente em alta velocidade o ovo onde você estiver perto",
    Value = SPAM_EGG,
    Callback = function(v)
        SPAM_EGG = v
    end
})

EggTab:Toggle({
    Title = "Auto Egg (Proximidade Moderada)",
    Desc = "Abre o ovo mais próximo com intervalo normal",
    Value = AUTO_EGG,
    Callback = function(v)
        AUTO_EGG = v
    end
})

EggTab:Slider({
    Title = "Delay Spam Ovos (s)",
    Desc = "Intervalo entre aberturas no modo spam",
    Step = 0.02,
    Value = {
        Min = 0.05,
        Max = 0.50,
        Default = DELAY_EGG
    },
    Callback = function(v)
        DELAY_EGG = v
    end
})

EggTab:Toggle({
    Title = "Pular Animação de Ovos",
    Desc = "Oculta a tela e animação de abertura de ovos",
    Value = SKIP_EGG_ANIM,
    Callback = function(v)
        SKIP_EGG_ANIM = v
    end
})

-- 3. ABA: RECOMPENSAS
RewardsTab:Section({ Title = "Presentes & Roletas" })

RewardsTab:Toggle({
    Title = "Auto Presentes & Giros Diários",
    Desc = "Resgata playtime gifts e giros diários automaticamente",
    Value = AUTO_REWARDS,
    Callback = function(v)
        AUTO_REWARDS = v
    end
})

RewardsTab:Toggle({
    Title = "Auto Roletas",
    Desc = "Gira roletas Normal, Alien, VIP e Spooky",
    Value = AUTO_MEGA_SPIN,
    Callback = function(v)
        AUTO_MEGA_SPIN = v
    end
})

RewardsTab:Button({
    Title = "Coletar Recompensas Agora",
    Desc = "Dispara coleta imediata de giros e presentes diários",
    Callback = function()
        coletarPremiosEGiros()
        coletarMegaRoletas()
        notificar("Recompensas diárias coletadas", 3)
    end
})

RewardsTab:Section({ Title = "Baús com Validação de Pad" })

RewardsTab:Slider({
    Title = "Tempo no Pad (s)",
    Desc = "Tempo de permanência em cada pad para registrar o baú",
    Step = 0.05,
    Value = {
        Min = 0.35,
        Max = 1.50,
        Default = TEMPO_PAD_BAU
    },
    Callback = function(v)
        TEMPO_PAD_BAU = v
    end
})

RewardsTab:Button({
    Title = "Coletar Baús do Mundo Atual (Tween)",
    Desc = "Voa em Tween e coleta todos os baús disponíveis no mundo atual",
    Callback = function()
        task.spawn(coletarBausMundoAtualSweep)
    end
})

RewardsTab:Button({
    Title = "Varredura Global de Baús (Todos Mundos)",
    Desc = "Visita todos os 9 mundos voando em Tween para os baús",
    Callback = function()
        task.spawn(coletarBausRapidoComSweep)
    end
})

RewardsTab:Section({ Title = "Códigos de Sorte (2x Luck)" })

RewardsTab:Dropdown({
    Title = "Selecionar Boost de Sorte",
    Desc = "Ativa o boost individual selecionado",
    Values = codigosComDescricao["Sorte (2x Luck)"],
    Value = codigosComDescricao["Sorte (2x Luck)"][1],
    Multi = false,
    Callback = function(v)
        resgatarUmCodigo(v)
    end
})

RewardsTab:Button({
    Title = "Resgatar Todos (Sorte)",
    Desc = "Ativa todos os 65 códigos de 2x Luck",
    Callback = function()
        task.spawn(function()
            resgatarListaCodigos(codigosPorCategoria["Sorte (2x Luck)"], "Sorte")
        end)
    end
})

RewardsTab:Section({ Title = "Códigos de Velocidade (2x Hatch Speed)" })

RewardsTab:Dropdown({
    Title = "Selecionar Boost de Velocidade",
    Desc = "Ativa o boost individual selecionado",
    Values = codigosComDescricao["Hatch Speed (2x Velocidade)"],
    Value = codigosComDescricao["Hatch Speed (2x Velocidade)"][1],
    Multi = false,
    Callback = function(v)
        resgatarUmCodigo(v)
    end
})

RewardsTab:Button({
    Title = "Resgatar Todos (Velocidade)",
    Desc = "Ativa todos os 60 códigos de 2x Hatch Speed",
    Callback = function()
        task.spawn(function()
            resgatarListaCodigos(codigosPorCategoria["Hatch Speed (2x Velocidade)"], "Velocidade")
        end)
    end
})

RewardsTab:Section({ Title = "Códigos de Shiny Chance (3x)" })

RewardsTab:Dropdown({
    Title = "Selecionar Boost de Shiny",
    Desc = "Ativa o boost individual selecionado",
    Values = codigosComDescricao["Shiny Chance (3x Brilhante)"],
    Value = codigosComDescricao["Shiny Chance (3x Brilhante)"][1],
    Multi = false,
    Callback = function(v)
        resgatarUmCodigo(v)
    end
})

RewardsTab:Button({
    Title = "Resgatar Todos (Shiny)",
    Desc = "Ativa todos os códigos de 3x Shiny Chance",
    Callback = function()
        task.spawn(function()
            resgatarListaCodigos(codigosPorCategoria["Shiny Chance (3x Brilhante)"], "Shiny")
        end)
    end
})

RewardsTab:Section({ Title = "Códigos de Moedas e Itens" })

RewardsTab:Dropdown({
    Title = "Selecionar Código de Item",
    Desc = "Resgata o item ou moeda selecionado",
    Values = codigosComDescricao["Moedas, Gemas, Doces e Pets"],
    Value = codigosComDescricao["Moedas, Gemas, Doces e Pets"][1],
    Multi = false,
    Callback = function(v)
        resgatarUmCodigo(v)
    end
})

RewardsTab:Button({
    Title = "Resgatar Todos (Itens e Moedas)",
    Desc = "Resgata todos os códigos de gemas, doces e pets",
    Callback = function()
        task.spawn(function()
            resgatarListaCodigos(codigosPorCategoria["Moedas, Gemas, Doces e Pets"], "Itens e Moedas")
        end)
    end
})

-- 4. ABA: MUNDOS
WorldsTab:Section({ Title = "Checkpoints & Ilhas" })

WorldsTab:Button({
    Title = "Desbloquear Todas as Ilhas",
    Desc = "Compra mundos e ativa todos os checkpoints",
    Callback = function()
        task.spawn(desbloquearTodasIlhasDefinitivo)
    end
})

WorldsTab:Section({ Title = "Teleportes" })

WorldsTab:Dropdown({
    Title = "Teleportar para Mundo",
    Desc = "Teleporta para a área inicial do mundo escolhido",
    Values = {
        "Overworld", "Candy Land", "Toy Land", "Beach World",
        "Atlantis", "Rainbow Land", "Underworld", "Mystic Forest", "Heaven"
    },
    Value = "Overworld",
    Multi = false,
    Callback = function(v)
        local mundo = (typeof(v) == "table" and v[1]) or v or "Overworld"
        viajarParaMundo(mundo)
    end
})

-- 5. ABA: CONFIGURAÇÕES
ConfigTab:Section({ Title = "Sistema" })

ConfigTab:Toggle({
    Title = "Anti-AFK (Mobile & PC)",
    Desc = "Previne desconexão sem depender de teclas",
    Value = true,
    Callback = function() end
})

ConfigTab:Toggle({
    Title = "Modo Economia (FPS)",
    Desc = "Reduz qualidade visual para economia de recursos e bateria",
    Value = FPS_BOOST,
    Callback = function(v)
        FPS_BOOST = v
        aplicarFPSBoost(FPS_BOOST)
    end
})

-- ==================== LIMPEZA DE PICKUPS REMOVIDOS ====================
local pickupsFolder = Workspace:FindFirstChild("Pickups")
if pickupsFolder then
    local remConexao = pickupsFolder.ChildRemoved:Connect(function(child)
        historicoRecentes[child] = nil
        if ultimoAlvoInstancia == child then
            ultimoAlvoInstancia = nil
        end
    end)
    table.insert(sessao.Conexoes, remConexao)
end

-- ==================== ANTI-AFK UNIVERSAL (MOBILE & PC) ====================
local idledConexao = LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)
table.insert(sessao.Conexoes, idledConexao)

threadAntiAfk = task.spawn(function()
    while not sessao.Limpar do
        task.wait(120)
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(50, 50))
        end)
    end
end)
table.insert(sessao.Threads, threadAntiAfk)

-- ==================== THREADS PRINCIPAIS ====================
threadEgg = task.spawn(function()
    while not sessao.Limpar do
        if SPAM_EGG or AUTO_EGG then
            local char, hrp, hum = obterPersonagem()
            if hrp and hum and hum.Health > 0 then
                local ovoObj, nomeOvo, dist = obterOvoMaisProximo(hrp.Position)
                if nomeOvo and dist <= DISTANCIA_MAX_OVO then
                    abrirOvoCompleto(nomeOvo, ovoObj)
                    if SPAM_EGG then
                        task.wait(DELAY_EGG)
                    else
                        task.wait(0.3)
                    end
                else
                    task.wait(0.35)
                end
            else
                task.wait(1)
            end
        else
            task.wait(0.5)
        end
        task.wait(0.01)
    end
end)
table.insert(sessao.Threads, threadEgg)

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
        if AUTO_REWARDS or AUTO_MEGA_SPIN then
            coletarPremiosEGiros()
        end
        task.wait(15)
    end
end)
table.insert(sessao.Threads, threadRewards)

local threadAntiVoid = task.spawn(function()
    while not sessao.Limpar do
        pcall(function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                -- Se o personagem cair abaixo do limite do mapa (void)
                if hrp.Position.Y < -35 then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    local ws = obterWorldService()
                    local mundo = (ws and typeof(ws.GetCurrentWorld) == "function" and ws:GetCurrentWorld()) or "Overworld"
                    viajarParaMundo(mundo)
                end
            end
        end)
        task.wait(1.5)
    end
end)
table.insert(sessao.Threads, threadAntiVoid)

-- ==================== DESCARREGAMENTO DE SESSÃO ====================
function sessao.Unload()
    sessao.Limpar = true
    ATIVADO = false
    AUTO_EGG = false
    SPAM_EGG = false
    AUTO_BUBBLE = false
    AUTO_REWARDS = false
    AUTO_CHESTS = false
    AUTO_MEGA_SPIN = false
    FPS_BOOST = false
    acaoEspecialAtiva = false

    aplicarFPSBoost(false)
    removerPlataformaSegura()

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
        for _, v in ipairs(CoreGui:GetChildren()) do
            if v:IsA("ScreenGui") and (string.find(v.Name, "WindUI") or v.Name == "sydeUILoader" or v:FindFirstChild("SYDEUIDetector")) then
                v:Destroy()
            end
        end
    end)
end

atualizarPartesPersonagem()
uiInicializada = true
notificar("Script atualizado com sucesso!", 2.5)
