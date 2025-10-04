--// deployment framework:
local deploymentFramework = {}

deploymentFramework.__index = deploymentFramework

--// framework constructors:
function deploymentFramework.new()
    local object_data = setmetatable({}, deploymentFramework)
    
    --// some global variables the framework will need to run:
    object_data.vari = { 

    }

    do
        local varis = object_data.vari

        varis.replicated_storage = game:GetService("ReplicatedStorage")
        varis.players = game:GetService('Players')
        varis.virtual_user = cloneref(game:GetService("VirtualUser"))
        varis.lplr = varis.players.LocalPlayer
        varis.remote_funcs = varis.replicated_storage.RemoteFunctions
        varis.pgui = varis.lplr.PlayerGui
    end

    object_data.vari.lplr.Idled:Connect(function()
        varis.virtual_user:CaptureController()
        varis.virtual_user:ClickButton2(Vector2.new())
    end)

    return object_data
end

function deploymentFramework:register_deployables(wave, deploy_table)
    if not self[wave] then
        self[wave] = {}
    end
    
    --// create copys of the deploy_table each wave. this should allow for different configs for different waves.
    for object_name, object_info in pairs(deploy_table) do
        if not self[wave][object_name] then
            self[wave][object_name] = { positions = {} }
        end

        for _, objectCFrames in ipairs(object_info.positions or object_info) do
            table.insert(self[wave][object_name].positions, objectCFrames)
        end
    end
end

function deploymentFramework:deploy_wave(wave)
    local variables = self.vari

    if not variables.place_deploys then
        variables.place_deploys = variables.remote_funcs.CreateDeployable
        variables.next_wave = variables.remote_funcs.VoteSkip
        variables.deployables = workspace.Deployables
    end

    local waveDeploys = self[wave]

    if not waveDeploys then
        return warn("No deployables registered for wave", wave)
    end

    for object_name, object_info in pairs(waveDeploys) do
        local positions = object_info.positions

        if wave == 1 then
            --// deploy deployables on wave1, to prevent game.Workspace.Deployables[lplr.Name] from returning nil & place x amount of deployables based on the max number of indexes in the positions array.
            --// Example: 3 indexes means 3 deployables will be placed.
            
            for _, targetPosition in ipairs(positions) do
                variables.place_deploys:InvokeServer(object_name, targetPosition, "Close")
            end

            if not variables.deployablesFolder then
                variables.deployablesFolder = variables.deployables[lplr.Name]
            end
        else
            --// "placed_deployables" represents the amount of deployables placed down at any given time:
            local deployables_folder = variables.deployablesFolder
            local place_deploys = variables.place_deploys
            local placed_deployables = 0
            
            for _, targetPosition in ipairs(positions) do
                placed_deployables = 0
            
                --// in-game deployables are counted to keep track of them here, this is important since we need to know how many are placed for later.

                for _, v in pairs(deployables_folder:GetChildren()) do
                    if v.Name == object_name:gsub(" ", "") then
                        placed_deployables += 1
                    end
                end
                
                --// iterate through the positions array and keep track of the number of positions in the array, this is important since we need to know how many positions there are for later.
                --// this is due to a bug that occured when there is multiple positions stored inside the positions array with the same "x, y, z" values.

                local samePositionCount = 0

                for _, pos in ipairs(positions) do
                    if pos == targetPosition then
                        samePositionCount += 1
                    end
                end

                --// if the number of in-game deployables, is below the samePositionCount then deploy.
                --// would do #positions but since we are comparing if the target position matches the pos on line 82 this would cause a bug.
                --// this allows item stacking to be handled properly.

                if placed_deployables < samePositionCount then
                    variables.place_deploys:InvokeServer(object_name, targetPosition, "Close")

                    placed_deployables += 1
                else
                    local matched = false

                    -- this compares the in-game deployable position with the position inside of the positions array, if they match then ignore placement.
                    for _, v in pairs(deployables_folder:GetChildren()) do
                        if v.Name == object_name:gsub(" ", "") and v.WorldPivot == targetPosition then
                            matched = true
                            
                            break
                        end
                    end

                    -- this compares the in-game deployable position with the position inside of the positions array, if they dont match then placement.
                    if not matched and placed_deployables < #positions then
                        variables.place_deploys:InvokeServer(object_name, targetPosition, "Close")
                        
                        placed_deployables += 1
                    end
                end
            end
        end
    end

    return self
end

function deploymentFramework:enableAutoReplace()
    local deployables_folder = self.vari.deployablesFolder
    local place_deploys = self.vari.place_deploys

    deployables_folder.ChildRemoved:Connect(function(v)
        place_deploys:InvokeServer(v.Name:gsub("(%l)(%u)", "%1 %2"), v.WorldPivot, "Close")
    end)

    return self
end

function deploymentFramework:game_loaded()
    local menugui = self:object_loaded_wait(self.vari.pgui, "MenuGui"); 
    local is_load = self:object_loaded_wait(menugui, "LoadingFrame")
    local map = workspace.Map
    local geometry_map = map.Geometry
    local player_spawn = RF.RemoteSpawnPlayer

    self:property_change_wait(is_load, 'Visible', 1)
    
    geometry_map.ChildAdded:Wait()
    menugui:remove()
    player_spawn:InvokeServer()
end

--// helper methods:
function deploymentFramework:object_loaded_wait(path, object, t)
    return path:FindFirstChild(object) or path:WaitForChild(object, t)
end

function deploymentFramework:ready_and_deploy(current_wave)
    local variables = self.vari

    if not variables.screen then
        variables.screen = variables.pgui.ScreenGui
        variables.game_frame = variables.screen.GameFrame
        variables.core = variables.game_frame.Core
        variables.weapon_frame = variables.core.WeaponFrame
        variables.vote_button = variables.weapon_frame.VoteSkip
        variables.next_wave = variables.remote_funcs.VoteSkip
    end
    
    local voteskip_remote_func = variables.next_wave
    local vote_button = variables.vote_button

    while vote_button.Text ~= "Ready Up 0/1" do 
        task.wait() 
    end

    voteskip_remote_func:InvokeServer()

    return self:deploy_wave(current_wave)
end

function deploymentFramework:property_change_wait(obj, property, timeout)
    local conn, bool = nil, false

    s = obj:GetPropertyChangedSignal(property):Connect(function()
        bool = true

        s:Disconnect()
    end)

    local time = 0
    while not bool and (not timeout or time < timeout) do
        task.wait(0.1)

        time += 0.1
    end

    if s.Connected then 
        s:Disconnect() 
    end

    return bool
end

return self
