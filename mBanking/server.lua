ESX = exports["es_extended"]:getSharedObject()

local playerBankData = {}
local cooldownTime = Config.WeeklyBonus.cooldownTime
local bonusAmount = Config.WeeklyBonus.amount

function GetPlayerTransactions(identifier, month, year)
    local result = exports.oxmysql:query_async(
        'SELECT * FROM mBanking_transactions WHERE identifier = ? AND month = ? AND year = ? ORDER BY id DESC LIMIT 50',
        {
            identifier, month, year
        })
    return result
end

function RecordTransaction(identifier, type, amount, status, month, year)
    exports.oxmysql:execute(
        'INSERT INTO mBanking_transactions (identifier, type, amount, date, status, month, year) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {
            identifier, type, amount, os.date("%d/%m/%Y"), status, month, year
        })
end

function CleanOldTransactions()
    local currentDate = os.date("*t")
    local twoMonthsAgo = currentDate.month - 2
    local year = currentDate.year

    if twoMonthsAgo <= 0 then
        twoMonthsAgo = twoMonthsAgo + 12
        year = year - 1
    end

    exports.oxmysql:execute('DELETE FROM mBanking_transactions WHERE (year < ?) OR (year = ? AND month < ?)', {
        year, year, twoMonthsAgo
    })
end

function UpdatePlayerBankData(identifier)
    local currentDate = os.date("*t")
    local month = currentDate.month
    local year = currentDate.year

    local transactions = GetPlayerTransactions(identifier, month, year)

    -- Récupérer le dernier bonus réclamé depuis la base de données
    local result = exports.oxmysql:query_async(
        'SELECT last_bonus_claim FROM mBanking_monthly_stats WHERE identifier = ? AND month = ? AND year = ?',
        { identifier, month, year }
    )

    local lastBonusClaim = 0
    if result and result[1] then
        lastBonusClaim = result[1].last_bonus_claim
    end

    playerBankData[identifier] = {
        transactions = transactions or {},
        lastBonusClaim = lastBonusClaim
    }
end

function InitPlayerBankData(identifier)
    if not playerBankData[identifier] then
        UpdatePlayerBankData(identifier)
    end
end

function RefreshClientData(source, identifier)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    UpdatePlayerBankData(identifier)

    local bankMoney = 0
    if xPlayer.getAccount and type(xPlayer.getAccount) == "function" then
        local bankAccount = xPlayer.getAccount('bank')
        if bankAccount then
            bankMoney = bankAccount.money
        end
    elseif xPlayer.accounts then
        for i = 1, #xPlayer.accounts do
            if xPlayer.accounts[i].name == 'bank' then
                bankMoney = xPlayer.accounts[i].money
                break
            end
        end
    end

    TriggerClientEvent('mBanking:receivePlayerData', source, {
        money = bankMoney,
        transactions = playerBankData[identifier].transactions,
        lastBonusClaim = playerBankData[identifier].lastBonusClaim,
        currentMonth = tonumber(os.date("%m")),
        currentYear = tonumber(os.date("%Y"))
    })
end

RegisterNetEvent('mBanking:getPlayerData')
AddEventHandler('mBanking:getPlayerData', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    local identifier = xPlayer.identifier

    InitPlayerBankData(identifier)

    TriggerClientEvent('mBanking:receivePlayerData', source, playerBankData[identifier])
end)

RegisterNetEvent('mBanking:deposit')
AddEventHandler('mBanking:deposit', function(amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        TriggerClientEvent('esx:showNotification', source, "Erreur: Impossible de trouver le joueur")
        return
    end

    local identifier = xPlayer.identifier
    amount = tonumber(amount)

    if not amount or amount <= 0 then
        TriggerClientEvent('esx:showNotification', source, "Montant invalide")
        return
    end

    local hasEnoughMoney = false
    local moneyItem = exports.ox_inventory:GetItem(source, 'money', nil, false)

    if moneyItem and moneyItem.count >= amount then
        hasEnoughMoney = true
    end

    if not hasEnoughMoney then
        TriggerClientEvent('esx:showNotification', source, "Vous n'avez pas assez d'argent sur vous")
        return
    end

    -- Essayer de retirer l'argent de l'inventaire
    if not exports.ox_inventory:RemoveItem(source, 'money', amount) then
        -- Si l'argent n'a pas pu être retiré, on envoie une notification d'erreur
        TriggerClientEvent('esx:showNotification', source, "Erreur lors du retrait d'argent")
        return
    end

    -- Essayer de récupérer le compte bancaire du joueur
    local bankAccount = xPlayer.getAccount('bank')
    if not bankAccount then
        -- Si le compte bancaire n'existe pas, on réajoute l'argent et on envoie une notification d'erreur
        exports.ox_inventory:AddItem(source, 'money', amount)
        TriggerClientEvent('esx:showNotification', source, "Erreur: Compte bancaire non trouvé")
        return
    end

    -- Dépôt dans le compte bancaire
    xPlayer.setAccountMoney('bank', bankAccount.money + amount)

    local currentDate = os.date("*t")
    local month = currentDate.month
    local year = currentDate.year

    -- Enregistrement de la transaction
    RecordTransaction(identifier, "Dépôt", amount, "La transaction a été confirmée", month, year)

    -- Notification de succès
    TriggerClientEvent('esx:showNotification', source, "Vous avez déposé " .. amount .. "$")

    -- Mise à jour des données client
    RefreshClientData(source, identifier)
end)


RegisterNetEvent('mBanking:withdraw')
AddEventHandler('mBanking:withdraw', function(amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    local identifier = xPlayer.identifier
    amount = tonumber(amount)

    if not amount or amount <= 0 then
        TriggerClientEvent('esx:showNotification', source, "Montant invalide")
        return
    end

    local bankAccount = xPlayer.getAccount('bank')
    if not bankAccount or bankAccount.money < amount then
        TriggerClientEvent('esx:showNotification', source, "Vous n'avez pas assez d'argent en banque")
        return
    end

    xPlayer.removeAccountMoney('bank', amount)
    xPlayer.addMoney(amount)

    local currentDate = os.date("*t")
    local month = currentDate.month
    local year = currentDate.year

    RecordTransaction(identifier, "Retrait", -amount, "La transaction a été confirmée", month, year)

    TriggerClientEvent('esx:showNotification', source, "Vous avez retiré " .. amount .. "$")

    RefreshClientData(source, identifier)
end)

RegisterNetEvent('mBanking:transfer')
AddEventHandler('mBanking:transfer', function(amount, target)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local targetPlayer = nil
    local targetSource = tonumber(target)

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('mBanking:transferResult', source, false, "Montant invalide")
        return
    end

    if not xPlayer then
        TriggerClientEvent('mBanking:transferResult', source, false, "Erreur: Impossible de trouver le joueur")
        return
    end

    if targetSource then
        targetPlayer = ESX.GetPlayerFromId(targetSource)
    end

    if not targetPlayer then
        TriggerClientEvent('mBanking:transferResult', source, false, "Destinataire introuvable")
        return
    end

    if xPlayer.source == targetPlayer.source then
        TriggerClientEvent('mBanking:transferResult', source, false,
            "Vous ne pouvez pas vous transférer de l'argent à vous-même")
        return
    end

    local identifier = xPlayer.identifier
    local targetIdentifier = targetPlayer.identifier

    local bankAccount = xPlayer.getAccount('bank')
    if not bankAccount or bankAccount.money < amount then
        TriggerClientEvent('mBanking:transferResult', source, false, "Fonds insuffisants")
        return
    end

    xPlayer.removeAccountMoney('bank', amount)
    targetPlayer.addAccountMoney('bank', amount)

    local currentDate = os.date("*t")
    local month = currentDate.month
    local year = currentDate.year

    RecordTransaction(identifier, "Transfert", -amount, "Transfert à " .. xPlayer.getName(), month, year)
    RecordTransaction(targetIdentifier, "Transfert", amount, "Reçu de " .. xPlayer.getName(), month, year)

    TriggerClientEvent('esx:showNotification', source, "Vous avez envoyé " .. amount .. "$ à " .. targetPlayer.getName())

    TriggerClientEvent('mBanking:transferResult', source, true)

    RefreshClientData(source, identifier)
    RefreshClientData(targetPlayer.source, targetIdentifier)
end)


RegisterNetEvent('mBanking:getCurrentDate')
AddEventHandler('mBanking:getCurrentDate', function()
    local source = source
    local month = tonumber(os.date("%m"))
    local year = tonumber(os.date("%Y"))

    TriggerClientEvent('mBanking:setCurrentDate', source, month, year)
end)

RegisterNetEvent('mBanking:claimWeeklyBonus')
AddEventHandler('mBanking:claimWeeklyBonus', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        TriggerClientEvent('mBanking:bonusResult', source, false, 0, 0)
        return
    end

    local identifier = xPlayer.identifier
    local currentTime = os.time()

    local result = exports.oxmysql:query_async(
        'SELECT last_bonus_claim FROM mBanking_monthly_stats WHERE identifier = ?',
        { identifier }
    )

    local lastClaim = 0
    if result and result[1] and result[1].last_bonus_claim then
        lastClaim = result[1].last_bonus_claim
    end

    local timeSinceLastClaim = currentTime - lastClaim

    if timeSinceLastClaim >= cooldownTime or lastClaim == 0 then
        xPlayer.addInventoryItem('money', bonusAmount)
        RecordTransaction(identifier, "Bonus", bonusAmount, "Bonus Hebdomadaire", os.date("*t").month, os.date("*t").year)

        exports.oxmysql:execute(
            'INSERT INTO mBanking_monthly_stats (identifier, last_bonus_claim) VALUES (?, ?) ON DUPLICATE KEY UPDATE last_bonus_claim = ?',
            { identifier, currentTime, currentTime }
        )

        TriggerClientEvent('mBanking:bonusResult', source, true, bonusAmount, currentTime)
        TriggerClientEvent('esx:showNotification', source, "Vous avez reçu votre bonus hebdomadaire de " .. bonusAmount .. "$")

        RefreshClientData(source, identifier)
    else
        local remainingTime = cooldownTime - timeSinceLastClaim
        local remainingDays = math.ceil(remainingTime / (24 * 60 * 60))

        TriggerClientEvent('mBanking:bonusResult', source, false, 0, currentTime)
        TriggerClientEvent('esx:showNotification', source, "Vous devez attendre encore " .. remainingDays .. " jour(s) pour réclamer votre bonus")
    end
end)

RegisterNetEvent('mBanking:requestPlayerCash')
AddEventHandler('mBanking:requestPlayerCash', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    local cash = 0
    local moneyItem = exports.ox_inventory:GetItem(source, 'money', nil, false)

    if moneyItem then
        cash = moneyItem.count
    end

    TriggerClientEvent('mBanking:receiveCash', source, cash)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(24 * 60 * 60 * 1000)
        CleanOldTransactions()
    end
end)
