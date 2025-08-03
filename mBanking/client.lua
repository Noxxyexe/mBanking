ESX = exports["es_extended"]:getSharedObject()

local isUIOpen = false
local playerData = nil
local playerBankData = {}
local lastBonusClaim = 0
local initialTime = GetGameTimer()
local currentMonth = (math.floor(initialTime / (30 * 24 * 60 * 60 * 1000)) % 12) + 1
local currentYear = math.floor(initialTime / (365 * 24 * 60 * 60 * 1000)) + 2020
local shouldUpdate = false
local updateThread = nil
local playerCash = 0

function GetCurrentMonth()
    TriggerServerEvent('mBanking:getCurrentDate')

    local gameTimer = GetGameTimer()
    local tempYear = math.floor(gameTimer / (365 * 24 * 60 * 60 * 1000)) + 2020
    local tempMonth = math.floor((gameTimer % (365 * 24 * 60 * 60 * 1000)) / (30 * 24 * 60 * 60 * 1000)) + 1

    if tempMonth > 12 then tempMonth = 1 end

    return tempMonth, tempYear
end

RegisterNetEvent('mBanking:setCurrentDate')
AddEventHandler('mBanking:setCurrentDate', function(month, year)
    local oldMonth = currentMonth
    local oldYear = currentYear

    currentMonth = month
    currentYear = year

    if isUIOpen then
        UpdateUIData()
    end

    if oldMonth ~= month or oldYear ~= year then
        TriggerServerEvent('mBanking:checkMonthChange', oldMonth, oldYear)
    end
end)

Citizen.CreateThread(function()
    while ESX == nil do
        Citizen.Wait(10)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    playerData = ESX.GetPlayerData()
    GetCurrentMonth()
    TriggerServerEvent('mBanking:getPlayerData')
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    playerData = xPlayer
    xPlayer.UniqueID = xPlayer.identifier
    TriggerServerEvent('mBanking:getPlayerData')
end)

RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account)
    if account.name == 'bank' then
        if playerData then
            playerData.accounts.bank = account.money
            if isUIOpen then
                UpdateUIData()
            end
        end
    end
end)

RegisterNetEvent('mBanking:receivePlayerData')
AddEventHandler('mBanking:receivePlayerData', function(data)
    playerBankData = data
    lastBonusClaim = data.lastBonusClaim or 0

    TriggerServerEvent('mBanking:getCurrentDate')
end)

RegisterNetEvent('mBanking:monthChanged')
AddEventHandler('mBanking:monthChanged', function(newMonth, newYear, resetStats)
    if resetStats then
        TriggerServerEvent('mBanking:resetMonthlyStats')
    end
    currentMonth = newMonth
    currentYear = newYear
end)

function StartUpdateThread()
    if updateThread then return end

    shouldUpdate = true
    updateThread = Citizen.CreateThread(function()
        while shouldUpdate do
            TriggerServerEvent('mBanking:getPlayerData')

            Citizen.Wait(1000)
        end
    end)
end

function StopUpdateThread()
    shouldUpdate = false
    updateThread = nil
end

function OpenmBankingUI()
    if isUIOpen then return end

    if not playerData then
        TriggerEvent('esx:showNotification', 'Impossible d\'accéder à la banque pour le moment.')
        return
    end

    playerData = ESX.GetPlayerData()

    TriggerServerEvent('mBanking:getPlayerData')
    TriggerServerEvent('mBanking:requestPlayerCash')

    Citizen.Wait(100)

    isUIOpen = true

    SetNuiFocus(true, true)

    SendNUIMessage({
        type = 'showUI'
    })

    UpdateUIData()

    StartUpdateThread()
end

function GenerateCardNumber()
    local identifier = playerData.identifier or GetPlayerServerId(PlayerId())
    local cardNum = ""

    for i = 1, 4 do
        local segment = ""
        if i == 3 then
            segment = "****"
        else
            segment = string.sub(tostring(GetHashKey(identifier .. i)), 1, 4)
        end
        cardNum = cardNum .. segment
        if i < 4 then
            cardNum = cardNum .. " "
        end
    end

    return cardNum
end

function GenerateCardDate()
    local expiryYear = (currentYear % 100) + 10
    local expiryMonth = math.random(1, 12)

    return string.format("%02d/%02d", expiryMonth, expiryYear)
end

function UpdateUIData()
    if not playerData then return end

    local bankMoney = 0
    if playerData.getAccount and type(playerData.getAccount) == "function" then
        local bankAccount = playerData.getAccount("bank")
        if bankAccount then
            bankMoney = bankAccount.money
        end
    elseif playerData.accounts then
        for i = 1, #playerData.accounts do
            if playerData.accounts[i].name == 'bank' then
                bankMoney = playerData.accounts[i].money
                break
            end
        end
    end

    local playerName = ""
    if playerData.getName and type(playerData.getName) == "function" then
        playerName = playerData.getName()
    else
        playerName = GetPlayerName(PlayerId())
    end

    if currentMonth < 1 or currentMonth > 12 then
        TriggerServerEvent('mBanking:getCurrentDate')

        currentMonth = tonumber(os.date("%m"))
    end

    SendNUIMessage({
        type = 'updateData',
        money = bankMoney,
        cash = playerCash,
        name = playerName,
        cardNumber = GenerateCardNumber(),
        -- cardDate = GenerateCardDate(),
        monthlyExpenses = playerBankData.monthlyExpenses or 0,
        monthlyDeposits = playerBankData.monthlyDeposits or 0,
        transactions = playerBankData.transactions or {},
        lastBonusClaim = lastBonusClaim,
        currentMonth = currentMonth
    })
end

function RefreshUIAfterTransaction()
    playerData = ESX.GetPlayerData()

    TriggerServerEvent('mBanking:getPlayerData')
    TriggerServerEvent('mBanking:requestPlayerCash')

    TriggerServerEvent('mBanking:getCurrentDate')

    Citizen.Wait(200)

    UpdateUIData()

    SendNUIMessage({
        type = 'refreshData',
        forceUpdate = true,
        currentMonth = currentMonth
    })
end

RegisterNUICallback('closeUI', function(data, cb)
    isUIOpen = false
    SetNuiFocus(false, false)

    StopUpdateThread()

    SendNUIMessage({
        type = 'hideUI'
    })

    cb('ok')
end)

RegisterNUICallback('getInitialData', function(data, cb)
    if not playerData or not playerData.accounts then
        cb({
            money = 0,
            name = GetPlayerName(PlayerId()),
            cardNumber = "1234 5678 **** 3456",
            cardDate = "02/32",
            monthlyExpenses = 0,
            monthlyDeposits = 0,
            transactions = {},
            lastBonusClaim = 0
        })
        return
    end

    cb({
        money = playerData.accounts.bank,
        name = GetPlayerName(PlayerId()),
        cardNumber = GenerateCardNumber(),
        -- cardDate = GenerateCardDate(),
        monthlyExpenses = playerBankData.monthlyExpenses or 0,
        monthlyDeposits = playerBankData.monthlyDeposits or 0,
        transactions = playerBankData.transactions or {},
        lastBonusClaim = lastBonusClaim
    })
end)

RegisterNUICallback('showNotification', function(data, cb)
    local msg = data.message or "Notification"
    TriggerEvent('esx:showNotification', msg)
    cb({})
end)

RegisterNUICallback('deposit', function(data, cb)
    local amount = tonumber(data.amount)

    if amount and amount > 0 then
        local cash = GetPlayerCash()

        if cash >= amount then
            TriggerServerEvent('mBanking:deposit', amount)

            Citizen.Wait(200)
            RefreshUIAfterTransaction()
            TriggerServerEvent('mBanking:requestPlayerCash')

            cb({ success = true })
        else
            TriggerEvent('esx:showNotification', 'Vous n\'avez pas assez d\'argent sur vous.')
            cb({ success = false, reason = "not_enough_money" })
        end
    else
        cb({ success = false, reason = "invalid_amount" })
    end
end)

RegisterNUICallback('withdraw', function(data, cb)
    local amount = tonumber(data.amount)

    if amount and amount > 0 then
        local bankMoney = 0
        if playerData.getAccount and type(playerData.getAccount) == "function" then
            local bankAccount = playerData.getAccount("bank")
            if bankAccount then
                bankMoney = bankAccount.money
            end
        elseif playerData.accounts then
            for i = 1, #playerData.accounts do
                if playerData.accounts[i].name == 'bank' then
                    bankMoney = playerData.accounts[i].money
                    break
                end
            end
        end

        if bankMoney >= amount then
            TriggerServerEvent('mBanking:withdraw', amount)

            Citizen.Wait(200)
            RefreshUIAfterTransaction()
            TriggerServerEvent('mBanking:requestPlayerCash')

            cb({ success = true })
        else
            TriggerEvent('esx:showNotification', 'Vous n\'avez pas assez d\'argent en banque.')
            cb({ success = false, reason = "not_enough_money" })
        end
    else
        cb({ success = false, reason = "invalid_amount" })
    end
end)

-- RegisterNUICallback('transfer', function(data, cb)
--     local amount = tonumber(data.amount)
--     local target = data.target

--     if amount and amount > 0 and target then
--         local bankMoney = 0
--         if playerData.getAccount and type(playerData.getAccount) == "function" then
--             local bankAccount = playerData.getAccount("bank")
--             if bankAccount then
--                 bankMoney = bankAccount.money
--             end
--         elseif playerData.accounts then
--             for i = 1, #playerData.accounts do
--                 if playerData.accounts[i].name == 'bank' then
--                     bankMoney = playerData.accounts[i].money
--                     break
--                 end
--             end
--         end

--         if bankMoney >= amount then
--             TriggerServerEvent('mBanking:transfer', amount, target)
--             cb({ success = true, waiting_server = true })
--         else
--             exports['noxxyNotif']:ShowNotification('Banque', 'Vous n\'avez pas assez d\'argent en banque.',
--                 'bank.png',
--                 5000)
--             cb({ success = false, reason = "not_enough_money" })
--         end
--     else
--         cb({ success = false, reason = "invalid_amount_or_target" })
--     end
-- end)

RegisterNUICallback('transfer', function(data, cb)
    local amount = tonumber(data.amount)
    local target = data.target

    if amount and amount > 0 and target then
        local bankMoney = 0
        if playerData.getAccount and type(playerData.getAccount) == "function" then
            local bankAccount = playerData.getAccount("bank")
            if bankAccount then
                bankMoney = bankAccount.money
            end
        elseif playerData.accounts then
            for i = 1, #playerData.accounts do
                if playerData.accounts[i].name == 'bank' then
                    bankMoney = playerData.accounts[i].money
                    break
                end
            end
        end

        if bankMoney >= amount then
            TriggerServerEvent('mBanking:transfer', amount, target)
            cb({ success = true, waiting_server = true })
        else
            cb({ success = false, reason = "not_enough_money" })
            TriggerEvent('esx:showNotification', 'Vous n\'avez pas assez d\'argent en banque.')
        end
    else
        cb({ success = false, reason = "invalid_amount_or_target" })
    end
end)

RegisterNUICallback('claimBonus', function(data, cb)
    TriggerServerEvent('mBanking:claimWeeklyBonus')

    Citizen.Wait(200)
    RefreshUIAfterTransaction()
    cb({ success = true })
end)

RegisterNetEvent('mBanking:bonusResult')
AddEventHandler('mBanking:bonusResult', function(success, amount, timestamp)
    if isUIOpen then
        SendNUIMessage({
            type = 'bonusResult',
            success = success,
            amount = amount
        })

        if success then
            lastBonusClaim = timestamp
        end
    end
end)

RegisterNetEvent('mBanking:transferResult')
AddEventHandler('mBanking:transferResult', function(success, reason)
    if isUIOpen then
        SendNUIMessage({
            type = 'transferResult',
            success = success,
            reason = reason
        })

        if success then
            Citizen.Wait(200)
            TriggerServerEvent('mBanking:getPlayerData')

            playerData = ESX.GetPlayerData()

            Citizen.Wait(100)
            UpdateUIData()

            TriggerEvent('esx:showNotification', 'Transfert effectué avec succès!')
        else
            TriggerEvent('esx:showNotification', 'Le transfert a échoué: ' .. (reason or 'Erreur inconnue'))
        end
    end
end)

RegisterNetEvent('mBanking:receiveCash')
AddEventHandler('mBanking:receiveCash', function(cash)
    playerCash = cash
    if isUIOpen then
        UpdateUIData()
    end
end)

Citizen.CreateThread(function()
    while playerData == nil do
        Citizen.Wait(500)
    end

    if Config.BankLocations and type(Config.BankLocations) == "table" then
        for k, v in pairs(Config.BankLocations) do
            local blip = AddBlipForCoord(v.x, v.y, v.z)
            SetBlipSprite(blip, Config.Blips.sprite)
            SetBlipDisplay(blip, Config.Blips.display)
            SetBlipScale(blip, Config.Blips.scale)
            SetBlipColour(blip, Config.Blips.color)
            SetBlipAsShortRange(blip, Config.Blips.shortRange)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(Config.Blips.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

Citizen.CreateThread(function()
    while playerData == nil do
        Citizen.Wait(500)
    end

    for _, model in ipairs(Config.ATMProps) do
        exports.ox_target:addModel(model, {
            {
                name = 'atm_access',
                icon = 'fas fa-credit-card',
                label = 'Utiliser l\'ATM',
                distance = 2.0,
                onSelect = function()
                    TriggerEvent('mBanking:openUI')
                end
            }
        })
    end
end)

function GetPlayerCash()
    local playerData = ESX.GetPlayerData()
    local cash = 0

    if playerData.accounts then
        for i = 1, #playerData.accounts do
            if playerData.accounts[i].name == 'money' then
                cash = playerData.accounts[i].money
                break
            end
        end
    end

    return cash
end

RegisterNetEvent('mBanking:openUI')
AddEventHandler('mBanking:openUI', function()
    OpenmBankingUI()
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local isNearBank = false

        if Config.BankLocations then
            for _, bankCoords in pairs(Config.BankLocations) do
                local distance = #(playerCoords - vector3(bankCoords.x, bankCoords.y, bankCoords.z))
                if distance < 3.0 then
                    isNearBank = true
                    break
                end
            end
        end

        if isNearBank and not isUIOpen then
            ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir la banque")
            if IsControlJustPressed(0, 38) then
                TriggerEvent('mBanking:openUI')
            end
        end
    end
end)
