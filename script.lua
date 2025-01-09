local HttpService = game:GetService('HttpService')
local Players = game:GetService("Players")
local currentUser = Players.LocalPlayer.Name
local foundUser = false
local red = tonumber(0xff0000)    -- Vermelho
local orange = tonumber(0xffa500) -- Laranja
local green = tonumber(0x00ff00)  -- Verde

-- Pegando as configurações do webhook a partir da tabela WebhookConfig
local Webhook_URL = getgenv().WebhookDiscordConfig.Url  -- URL do webhook
local Webhook_Enabled = getgenv().WebhookDiscordConfig.Enabled  -- Se o webhook está ativado

-- Verifica a disponibilidade da função 'request' ou alternativas
local httpRequest
if request then
    httpRequest = request
elseif syn and syn.request then
    httpRequest = syn.request
elseif fluxus and fluxus.request then
    httpRequest = fluxus.request
else
    warn("Nenhuma função de requisição HTTP disponível. O envio do Webhook não será realizado.")
    return
end


-- Função para enviar uma mensagem para um webhook do Discord
local function sendWebhookMessage(webhookURL, title, description, color)
    if not Webhook_Enabled then return end

    -- Garante que a função 'request' está disponível no executor
    local httpRequest = request or (syn and syn.request) or (fluxus and fluxus.request)
    if not httpRequest then
        warn("A função de requisição HTTP não está disponível neste executor.")
        return
    end

    local response = httpRequest({
        Url = webhookURL,
        Method = 'POST',
        Headers = {
            ['Content-Type'] = 'application/json'
        },
        Body = HttpService:JSONEncode({
            ['content'] = '@everyone', -- Você pode modificar isso se necessário
            ['embeds'] = {{
                ["title"] = title,          -- Título do embed
                ["description"] = description, -- Descrição do embed
                ["type"] = "rich",         -- Definindo o tipo como embed
                ["color"] = color,         -- Escolhendo a cor do embed
                ["footer"] = {             -- Adicionando o rodapé
                    ["text"] = "© 2024 - by Recieri", -- Mensagem de copyright
                }
            }}
        })
    })

    -- Verifica se a requisição foi bem-sucedida
    if response.StatusCode == 204 then
        print("Mensagem enviada com sucesso!")
    else
        print("Erro ao enviar mensagem: " .. tostring(response.StatusCode))
    end
end

-- Caminho do arquivo
local filePath = currentUser .. ".txt"

-- Função para apagar o arquivo se existir
local function deleteFileIfExists()
    if isfile(filePath) then  -- Verifica se o arquivo existe
        delfile(filePath)  -- Apaga o arquivo
        sendWebhookMessage(Webhook_URL, 'SUCESSO', "**Usuário**\n" .. currentUser .. "\n\n**Descrição:**\n" .. "Arquivo " .. filePath .. " foi apagado.", green)
        print("Arquivo " .. filePath .. " foi apagado.")
    end
end

deleteFileIfExists()


-- Função para fazer a requisição
local function checkUser()
    local trackingResponse = httpRequest({
        Url = "https://data.hermanos-dev.com/blox-fruit/data/af57b92c-d22c-46ef-ba8d-c6eeab739d52", 
        Method = 'GET',
        Headers = {
            ['content-type'] = 'application/json',
            ['Referer'] = 'https://www.hermanos-dev.com/'
        }
    })

    if trackingResponse and trackingResponse.StatusCode == 200 then
        -- Depurando a resposta da API
        print("Resposta da API: " .. trackingResponse.Body)  -- Imprime a resposta completa para verificar seu formato
        local trackingData = HttpService:JSONDecode(trackingResponse.Body)

        if trackingData then
            local foundUser = false
            -- Itera sobre cada item na resposta
            for _, user in ipairs(trackingData) do
                -- Depura o nome do usuário retornado
                print("Verificando usuário: " .. user.data.username)
                -- Verifica se o campo 'username' é igual ao currentUser
                if user.data.username == currentUser then
                    foundUser = true
                    break
                end
            end

            -- Caso o usuário não seja encontrado
            if not foundUser then
                sendWebhookMessage(Webhook_URL, 'FALHA', "**Usuário**\n" .. currentUser .. "\n\n**Descrição:**\n" .. "Usuário não encontrado", red)
                print("Usuário não encontrado.")
            end
        else
            sendWebhookMessage(Webhook_URL, 'FALHA', "**Usuário**\n" .. currentUser .. "\n\n**Descrição:**\n" .. "Nenhum dado de usuário encontrado", red)
            print("Nenhum dado de usuário encontrado.")
        end
    else
        sendWebhookMessage(Webhook_URL, 'FALHA', "**Usuário**\n" .. currentUser .. "\n\n**Descrição:**\n" .. "Erro na requisição: " .. tostring(trackingResponse.StatusCode), red)
        print("Erro na requisição: " .. tostring(trackingResponse.StatusCode))
    end
end

-- Função para salvar o nome do usuário em um arquivo
local function saveUserName()
    -- Usando a função writefile do executor
    writefile(filePath, "Completed-" .. currentUser) -- Escreve o conteúdo
    sendWebhookMessage(Webhook_URL, 'SUCESSO', "**Usuário**\n" .. currentUser .. "\n\n**Descrição:**\n" .. "Nome de usuário salvo em " .. filePath, green)
    print("Nome de usuário salvo em: " .. filePath)
end

-- Loop a cada x segundos
while not foundUser do
    checkUser()
    
    if foundUser then
        saveUserName()
    end
    wait(20) -- Aguarda x segundos
end
