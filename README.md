# Introdução ao uso do RBXNet

## O que são definições?

As definições (ou definitions) são como um "projeto" (blueprint) para todos os objetos relacionados à rede no seu jogo ou biblioteca.

Elas são uma única fonte de verdade, na qual todo o código do seu jogo pode acessar os remotes (eventos e funções remotas) para lidar com a comunicação entre cliente e servidor do seu jogo ou biblioteca.

Criando um script de definições
Para usar as definições, você precisará criar um script que esteja dentro de ReplicatedStorage (ou dentro da própria biblioteca, caso esteja criando uma). Ele precisa ser acessível tanto por scripts do servidor quanto por scripts do cliente.

> [!TIP]
> A declaração básica de um script de definições é a seguinte:

```lua
-- src/shared/remotes.lua
local Net = require(ReplicatedStorage.Net)

local Remotes = Net.CreateDefinitions({
  -- Definições dos remotes vão aqui
})

return Remotes
```
> [!TIP]
> Depois de criar o script de definições, você pode simplesmente importar esse módulo de qualquer lugar no código e usar a API de definições para obter os remotes.

---

## Criando uma Definição

> [!TIP]
> No RBXNet, existem três categorias principais de objetos remotos:

- **Event** - É equivalente a um RemoteEvent. Usado quando você deseja enviar um evento (como uma ação) para o servidor ou para um jogador.
- **AsyncFunction** - Similar a um RemoteFunction, mas usa internamente um RemoteEvent. A diferença é que a AsyncFunction trata de timeouts e funciona de forma totalmente assíncrona (não bloqueando o código). Se não houver resposta do receptor, a função será rejeitada.
- **Function** - Equivalente a um RemoteFunction, porém, ao contrário do RemoteFunction regular, não permite chamar o cliente, por questões de segurança.

### Definindo Eventos e Funções

Com esse entendimento, podemos aplicar isso ao nosso script de definição de remotes. Existem as seguintes funções dentro de Net.Definitions para criar definições para as três categorias mencionadas. A API para cada tipo de definição é explícita, facilitando a compreensão do que cada remote definido faz.

### Tipos de Definições

- **Event (Evento)**
  - `Net.Definitions.ServerToClientEvent` - Define um evento no qual o servidor envia um evento para um ou mais clientes.
  - `Net.Definitions.ClientToServerEvent` - Define um evento no qual o cliente envia eventos para o servidor.
  - `Net.Definitions.BidirectionalEvent` - Define um evento no qual tanto o servidor pode enviar um evento para um ou mais clientes, quanto os clientes podem enviar eventos para o servidor. Deve ser usado apenas quando necessário.
- **AsyncFunction (Função Assíncrona)**
  - `Net.Definitions.ServerAsyncFunction` - Define uma função assíncrona que existe no servidor e pode ser chamada pelos clientes. O resultado retornado será recebido no cliente como uma promise.
  - `Net.Definitions.ClientAsyncFunction` - Define uma função assíncrona que existe no cliente e pode ser chamada pelo servidor. O resultado retornado será recebido no servidor como uma promise.
- **Function (Função)**
  - `Net.Definitions.ServerFunction` - Define uma função síncrona que existe no servidor e pode ser chamada pelos clientes.
- **Broadcast (Transmissão)**
  - `Net.Definitions.ExperienceBroadcastEvent` - Define um evento que o servidor pode usar para se comunicar com outros servidores na mesma experiência.

### Definindo Remotes
Com o conhecimento acima, podemos criar algumas definições de exemplo. Suponha que queremos os seguintes casos de uso:

```lua
-- src/shared/remotes.lua
local Net = require(ReplicatedStorage.Net)

local Remotes = Net.CreateDefinitions({
  GetPlayerInventory = Net.Definitions.ServerFunction(),
  GetPlayerEquipped = Net.Definitions.ServerFunction(),

  PlayerInventoryUpdated = Net.Definitions.ServerToClientEvent(),
  PlayerEquippedUpdated = Net.Definitions.ServerToClientEvent(),

  PlayerUnequipItem = Net.Definitions.ClientToServerEvent(),
  PlayerEquipItem = Net.Definitions.ClientToServerEvent(),
})

return Remotes
```

> [!NOTE]
> Imediatamente, você pode ver como é fácil entender o que cada remote faz. Cada definição é clara e bem organizada, permitindo que você gerencie a comunicação entre cliente e servidor de maneira eficiente.

### Usando Suas Definições
Suponhamos que temos o arquivo de definições de exemplo já criado:

```lua
-- src/shared/remotes.lua
local Net = require(ReplicatedStorage.Net)

local Remotes = Net.CreateDefinitions({
  GetPlayerInventory = Net.Definitions.ServerFunction(),
  GetPlayerEquipped = Net.Definitions.ServerFunction(),

  PlayerInventoryUpdated = Net.Definitions.ServerToClientEvent(),
  PlayerEquippedUpdated = Net.Definitions.ServerToClientEvent(),

  PlayerUnequipItem = Net.Definitions.ClientToServerEvent(),
  PlayerEquipItem = Net.Definitions.ClientToServerEvent(),
})

return Remotes
```

Agora, a pergunta é: como podemos usar isso para enviar mensagens entre o servidor e o cliente?

- **Uso No servidor**:
  Aqui está como podemos configurar o servidor para ouvir eventos enviados pelo cliente:
    ```lua
    -- src/server/main.server.lua
    local Remotes = require(ReplicatedStorage.Shared.Remotes)

    Remotes.Server:Get("PlayerEquipItem"):Connect(function(player: Player, text: string)
      print("Recebido: "..text.." de "..player.Name)
    end)
    ```
    Nesse exemplo, o servidor está ouvindo o evento `"PlayerEquipItem"` e, quando o cliente envia uma mensagem, ele recebe o jogador e a mensagem como parâmetros.

- **No cliente**:
  Agora, no lado do client, podemos enviar um evento para o servidor da seguinte maneira:

  ```lua
  -- src/client/test.client.lua
  local Remotes = require(ReplicatedStorage.Shared.Remotes)

  Remotes.Client:Get("PlayerEquipItem"):SendToServer("Olá!")
  ```
  Aqui, o client está enviando a mensagem `"Olá!"` para o servidor através do evento `"PlayerEquipItem"`.

> [!NOTE]
> Resumo: No servidor, você usa `:Connect()` para escutar eventos enviados pelo client.
No client, você usa `:SendToServer()` para enviar eventos para o servidor.
Isso permite uma comunicação eficiente entre client e servidor, mantendo os scripts bem organizados.

---

## Escopando com Namespaces
À medida que seu jogo cresce, o mesmo ocorre com o arquivo de definições de remotos. Para ajudar na organização das definições de rede, o RbxNet introduz o conceito de **Namespaces**.

**Namespaces** funcionam como sub-definições e podem ser armazenados em arquivos separados, facilitando a divisão e organização dos remotos por contexto ou funcionalidade.

### Criando um Namespace
Seguindo nosso exemplo anterior, imagine que queremos separar os remotos relacionados ao inventário e ao equipamento em arquivos diferentes:

```lua
-- src/shared/remotes.lua
local Net = require(ReplicatedStorage.Net)

local Remotes = Net.CreateDefinitions({
  -- Esses são todos os remotos relacionados ao inventário
  Inventory = Net.Definitions.Namespace({
    PlayerInventoryUpdated = Net.Definitions.ServerToClientEvent(),
    GetPlayerInventory = Net.Definitions.ServerFunction(),
  }),

  -- Esses são todos os remotos relacionados ao equipamento
  Equipped = Net.Definitions.Namespace({
    GetPlayerEquipped = Net.Definitions.ServerFunction(),
    PlayerEquippedUpdated = Net.Definitions.ServerToClientEvent(),
    PlayerUnequipItem = Net.Definitions.ClientToServerEvent(),
    PlayerEquipItem = Net.Definitions.ClientToServerEvent(),
  }),
})

return Remotes
```

> [!NOTE]
> Com isso, estamos separando as definições em dois namespaces: Inventory (para remotos relacionados ao inventário) e Equipped (para remotos relacionados ao equipamento). Isso deixa o código mais organizado e fácil de manter.

### Uso no Servidor
Agora, para utilizar esses namespaces no servidor, podemos fazer o seguinte:

```lua
-- src/server/main.server.lua
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-- Isso conterá todos os remotos do inventário do servidor
local InventoryRemotes = Remotes.Server:GetNamespace("Inventory")

-- Isso conterá todos os remotos do equipamento do servidor
local EquippedRemotes = Remotes.Server:GetNamespace("Equipped")
```

> [!NOTE]
> Resumo: Namespaces ajudam a organizar remotos em subcategorias, facilitando a manutenção e a expansão do projeto.
Você pode acessar remotos dentro de um namespace específico usando `:GetNamespace("NamespaceName")`.
Isso garante que, conforme seu projeto cresce, você mantenha um nível de organização claro e eficiente para gerenciar os remotos no servidor e no client.

---

# Envolvendo Objetos Personalizados de Jogadores
Uma prática comum ao usar remotos no servidor é a necessidade de transformar o jogador em uma representação de objeto do jogador. Isso geralmente aparece em situações como a seguinte:

```lua
local PlayerService = require(ServerScriptService.Services.PlayerService)
local Remotes = require(ReplicatedStorage.Remotes)

local PlayerEquipItem = Remotes.Server:Get("PlayerEquipItem")
PlayerEquipItem:Connect(function (player, itemId)
  local entity = PlayerService:GetEntity(player)
  if entity then
    entity:EquipItem(itemId)
  end
end)

local PlayerUnequipItem = Remotes.Server:Get("PlayerUnequipItem")
PlayerUnequipItem:Connect(function (player, itemId)
  local entity = PlayerService:GetEntity(player)
  if entity then
    entity:UnequipItem(itemId)
  end
end)

local GetPlayerEquipped = Remotes.Server:Get("GetPlayerEquipped")
GetPlayerEquipped:SetCallback(function(player)
  local entity = PlayerService:GetEntity(player)
  if entity then
    return entity:GetEquippedItems()
  end
end)
```

### Problema com Código Repetitivo
Como você pode perceber, há um código repetido em que estamos constantemente buscando a entidade do jogador em vez do próprio jogador. Para evitar essa repetição, podemos usar um **wrapper** que realiza essa operação para nós, de forma que pareça que estamos conectando diretamente ao remoto com a entidade como argumento, em vez do jogador.

### Usando um Wrapper
Podemos definir uma função `withPlayerEntity` que encapsula essa lógica repetitiva. Isso é a forma recomendada de fazer, pois garante que o código será executado após todos os middlewares, garantindo maior segurança.

### Definição do Wrapper

```lua
-- src/server/Wrappers/withPlayerEntity.lua
local PlayerService = require(ServerScriptService.Services.PlayerService)

local function withPlayerEntity(fn)
  return function (player, ...)
    local entity = PlayerService:GetEntity(player)
    if entity then
      return fn(entity, ...)
    end
  end
end

return withPlayerEntity
```

Aqui, o wrapper `withPlayerEntity` faz o trabalho de pegar a entidade do jogador e passar isso para a função fornecida.

### Aplicando o Wrapper
Agora podemos aplicar o wrapper ao nosso código para reduzir a repetição:

```lua
local PlayerService = require(ServerScriptService.Services.PlayerService)
local Remotes = require(ReplicatedStorage.Remotes)
local withPlayerEntity = require(ServerScriptService.Wrappers.withPlayerEntity)

local PlayerEquipItem = Remotes.Server:Get("PlayerEquipItem")
PlayerEquipItem:Connect(
  withPlayerEntity(function (entity, itemId)
    entity:EquipItem(itemId)
  end)
)

local PlayerUnequipItem = Remotes.Server:Get("PlayerUnequipItem")
PlayerUnequipItem:Connect(
  withPlayerEntity(function (entity, itemId)
    entity:UnequipItem(itemId)
  end)
)

local GetPlayerEquipped = Remotes.Server:Get("GetPlayerEquipped")
GetPlayerEquipped:SetCallback(
  withPlayerEntity(function (entity)
    return entity:GetEquippedItems()
  end)
)
```

> [!TIP]
> Benefícios: Como você pode ver, esse método reduz o código repetido e nos fornece a entidade do jogador diretamente. Isso torna o código mais simples, fácil de manter e menos propenso a erros.

---

## Limitando a Taxa de Invocações de Remotos
Quando você tem funções ou eventos no servidor que são intensivos em termos de processamento ou recursos, permitir que os jogadores invoquem esses remotos sem restrições pode causar sobrecarga e até mesmo travar o jogo. Uma maneira de evitar isso é aplicando o middleware de Rate Limiting com o Net.Middleware.RateLimit.

### Definindo um Limitador de Taxa
O middleware RateLimit impõe um limite na quantidade de requisições que podem ser feitas em um determinado período de tempo. Por exemplo, para limitar um jogador a apenas uma solicitação por minuto, você configuraria o middleware da seguinte forma:

```lua
local Net = require(ReplicatedStorage.Net)

-- Definindo o limite de 1 solicitação por minuto
Net.Middleware.RateLimit({
  MaxRequestsPerMinute = 1 -- Limita a 1 requisição por minuto
})
```

### Aplicando o Rate Limiting a uma Função
Agora, podemos aplicar essa limitação a uma definição específica de remoto, como em uma **AsyncFunction**:

```lua
local Net = require(ReplicatedStorage.Net)

-- Aplicando o limitador a uma AsyncFunction
local Remotes = Net.Definitions.Create({
  Example = Net.Definitions.AsyncFunction({
    Net.Middleware.RateLimit({
      MaxRequestsPerMinute = 1
    })
  })
})
```

Nesse caso, o remoto `Example` será limitado a apenas uma requisição por minuto.

### Tratamento Personalizado de Erros
Por padrão, quando o limite de taxa é excedido, o erro é tratado por uma função que exibe um aviso no servidor:

```lua
export function rateLimitWarningHandler(error: RateLimitError) {
  warn("[rbx-net]", error.Message);
}
```

> [!NOTE]
> Se você quiser implementar um tratamento de erro personalizado, como enviar dados de erros para um serviço de análise, pode criar sua própria função de tratamento de erros e passá-la ao RateLimit:

```lua
local AnalyticsService = require(ServerScriptService.AnalyticsService)

-- Função personalizada de tratamento de erros
local function analyticRateLimitError(error)
  AnalyticsService:Error(error.Message) -- Exemplo de envio de erro para um serviço de analytics
end

-- Aplicando a função personalizada de tratamento de erros
local Remotes = Net.Definitions.Create({
  Example = Net.Definitions.AsyncFunction({
    Net.Middleware.RateLimit({
      MaxRequestsPerMinute = 1,
      ErrorHandler = analyticRateLimitError -- Definindo o handler personalizado
    })
  })
})
```

### Benefícios
- **Protege o servidor**: O uso de Rate Limiting impede que os jogadores sobrecarreguem o servidor ao invocarem remotamente funções ou eventos repetidamente.
- **Personalização**: O tratamento de erros customizado permite que você lide com excessos de requisição de maneira mais eficiente, como registrando-os em serviços de análise.
- **Simples de aplicar**: O middleware pode ser facilmente adicionado a qualquer definição de remoto, garantindo que o controle de taxa seja aplicado onde for necessário.

---

## Verificação de Tipos em Tempo de Execução
Para garantir a integridade do sistema e evitar erros indesejados, é fundamental verificar se os dados recebidos de eventos ou chamadas de função do client possuem os tipos esperados. Isso pode ser feito utilizando o middleware `Net.Middleware.TypeChecking`, que permite validar os tipos em tempo de execução antes que os dados sejam processados.

## Utilizando a Biblioteca t para Verificação de Tipos
A biblioteca **t**, muito utilizada em projetos de Roblox, fornece uma maneira fácil de verificar tipos. Abaixo, segue um exemplo de como utilizar essa biblioteca com o middleware de verificação de tipos.

```lua
local t = require(ReplicatedStorage.Libs.t)

local Remotes = Net.CreateDefinitions({
  Click = Net.Definitions.ClientToServerEvent({
    Net.Middleware.TypeChecking(t.Vector3, t.string) -- Verifica se os parâmetros são um Vector3 e uma string
  })
})
```

Aqui, o evento remoto `Click` espera receber um `Vector3` e uma `string`. O middleware TypeChecking garante que, se os tipos não corresponderem, o evento não será processado.

### Criando Funções de Verificação de Tipos Customizadas
Se você não estiver utilizando a biblioteca **t**, também é possível criar suas próprias funções para verificar os tipos dos argumentos recebidos:

```lua
-- Função que verifica se o valor é uma string
local function typeCheckString(check: any)
  return typeof(check) == "string"
end

-- Função que verifica se o valor é um Vector3
local function typeCheckVector3(check: any)
  return typeof(check) == "Vector3"
end

local Remotes = Net.CreateDefinitions({
  Click = Net.Definitions.ClientToServerEvent({
    Net.Middleware.TypeChecking(typeCheckVector3, typeCheckString) -- Verifica se os parâmetros são um Vector3 e uma string
  })
})
```

Aqui, criamos duas funções simples, `typeCheckString` e `typeCheckVector3`, que validam os tipos esperados. Esses validadores personalizados são então passados ao middleware.

### Vantagens da Verificação de Tipos
- **Prevenção de Erros**: Garante que as funções e eventos só sejam executados se os tipos corretos forem fornecidos, evitando erros em tempo de execução.
- **Flexibilidade**: Você pode usar bibliotecas como t ou criar seus próprios verificadores de tipos.
- **Fácil Integração**: O middleware pode ser aplicado a qualquer evento ou função remota, facilitando a proteção do seu código.

Utilizar type checking é uma prática recomendada para evitar erros de processamento, garantindo que o servidor e o client se comuniquem de maneira segura e eficiente.
