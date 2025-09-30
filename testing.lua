local module = loadstring(game:HttpGet('https://raw.githubusercontent.com/ZvQiv/ZvQiv/refs/heads/main/framework.lua'))()
local newFramework = module.new()

coroutine.wrap(function()
    local replicated_storage = game:GetService("ReplicatedStorage")
    local players = game:GetService('Players')
    local teleportService = game:GetService('TeleportService')
    local lplr = players.LocalPlayer
    local RF = replicated_storage.RemoteFunctions
    local RE = replicated_storage.RemoteEvents
    local pGui = lplr.PlayerGui
    local new_coroutine = coroutine.wrap

    local object_loaded = function(path, object, t)
        return path:FindFirstChild(object) or path:WaitForChild(object, t)
    end

    local deploy_items = function(current_wave)
        newFramework:deploy_wave(current_wave) -- deploy items using framework
        RF.VoteSkip:InvokeServer()
    end

    local startFarming = function(map)
        local buy, upgrade = RE.BuyStructure, RE.UpgradeStructurePlayer
        local screenGui = object_loaded(pGui, 'ScreenGui')
        local wave = screenGui.GameFrame.Core.WeaponFrame.Wave
        local current_wave = wave.Text

        for k1, v1 in pairs(getgenv().config) do -- problem is here i need upgrade configs to work here
            if v1.buyable then
                buy:FireServer(k1)
                
                for k2, v2 in pairs(v1) do
                    if k2 ~= "buyable" then
                        for i = 1, v2 do
                            upgrade:FireServer(k1, k2)
                        end
                    end
                end
            end
        end
        
        wave:GetPropertyChangedSignal("Text"):Connect(function()
            current_wave = wave.Text

            screenGui.GameFrame.WaveSurvive:GetPropertyChangedSignal("Visible"):Wait() 
            screenGui.GameFrame.WaveSurvive:GetPropertyChangedSignal("Visible"):Wait()

            if current_wave == tostring(wave_to_restart_at) then
                teleportService:Teleport(133815151)
            else
                deploy_items(current_wave)
            end
        end)

        screenGui.GameFrame.Core.WeaponFrame.VoteSkip.Reminder:GetPropertyChangedSignal("Visible"):Wait()

        deploy_items(current_wave)

        map:Destroy()
    end

    do
        if game.PlaceId == 133815151 then
            RF.CreatePrivate:InvokeServer(5, 'Default')
        else
            do
                local mgui = object_loaded(pGui, 'MenuGui'); 
                local loading = object_loaded(mgui, 'LoadingFrame')
                loading:GetPropertyChangedSignal('Visible'):Wait()
                mgui:remove()
                RF.RemoteSpawnPlayer:InvokeServer()
            end

            local map = workspace.Map:Clone()
            map.Parent = game.Workspace

            local character = lplr.Character or lplr.CharacterAdded:Wait()
            local rootPart = object_loaded(character, 'HumanoidRootPart')

            rootPart.CFrame = CFrame.new(6.38317299, 3.50018048, 79.9122925, -0.997826815, 1.02605767e-07, 0.0658911243, 9.96090179e-08, 1, -4.87654646e-08, -0.0658911243, -4.20961364e-08, -0.997826815)
            
            startFarming(map)
        end
    end
end)()

return newFramework
