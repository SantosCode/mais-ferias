# Prompt de implementação — App "Mais Férias" (iOS, SwiftUI)

Implemente um app iOS nativo em SwiftUI chamado **Mais Férias**, um planejador de férias baseado em feriados nacionais e estaduais brasileiros, focado em "emendas" (folgas que combinam feriado + fim de semana + poucos dias de férias para maximizar dias de descanso).

## Stack e arquitetura
- SwiftUI puro, iOS 17+, sem dependências externas.
- `@StateObject`/`@EnvironmentObject` com uma classe `AppState: ObservableObject` centralizando: estado (UF) do usuário e lista de períodos de férias registrados.
- Estrutura de arquivos (já prototipados, usar como base):
  - `Models.swift` — `Emenda`, `VacationPeriod`, `BrazilState` (enum com as 27 UFs), `AppState`.
  - `GlassStyle.swift` — `AppBackground` (gradiente aurora) e modifier `.glassCard()` (liquid glass: `.ultraThinMaterial` + tint branco translúcido + borda com gradiente de brilho).
  - `ContentView.swift` — `TabView` raiz com 4 abas.
  - `HomeView.swift`, `EmendasView.swift`, `CalendarioView.swift`, `PerfilView.swift` — telas principais.
  - `EstadoPickerView.swift`, `RegistrarFeriasView.swift` — telas secundárias, navegadas a partir do Perfil.

## Identidade visual (liquid glass / iOS 26)
- Fundo: gradiente escuro roxo/azul (`#241a42` → `#16112c` → `#0a081c`) com 4 manchas radiais coloridas (laranja pêssego, rosa coral, azul, teal) simulando aurora — mesmo em todas as telas.
- Cor de destaque única: laranja coral `#FF8A5B`, usado em números de destaque, botões primários e badges "Nacional".
- Cards em vidro líquido: fundo `.ultraThinMaterial` + tint branco ~12-16% opacidade, cantos bem arredondados (18–28px), borda de 0.5-0.8px com gradiente de brilho branco (mais opaco no topo-esquerda).
- Texto: branco puro para conteúdo primário; branco 70-85% opacidade para secundário (nunca abaixo de 70% em texto de corpo, para manter contraste AA).
- Tipografia do sistema (SF Pro / `-apple-system`), pesos 500-800, títulos grandes ~28px bold.

## Telas e comportamento

**1. Início (Home)**
- Cabeçalho: saudação + nome do usuário + avatar circular com iniciais.
- Card "Próxima emenda" em destaque: data grande, nome do feriado, dia da semana, badge Nacional/Estadual, e o cálculo "emende com N dia(s) de férias → ganhe M dias".
- Duas estatísticas lado a lado: dias de férias já usados no ano (computado a partir dos períodos registrados) e nº de emendas disponíveis.
- Lista "Outras emendas": demais oportunidades do ano, cada linha com mês/dia, nome, período, badge e "+N dias".

**2. Emendas**
- Lista completa de emendas do ano com chips de filtro (Todos / Nacional / Estadual).
- Cada card mostra: data, nome, dia da semana, badge de tipo, período da emenda, dias de férias necessários e total de dias ganhos.

**3. Calendário**
- Grade mensal (mês de exemplo: Abril/2026) com destaque visual para: feriado (preenchido laranja), dia de férias sugerido (contorno laranja), fins de semana (fundo sutil) — mais legenda.
- Card de destaque abaixo explicando a emenda do mês em texto.

**4. Perfil**
- Card do usuário: avatar, nome, "Estado · UF" atual.
- Seção "Preferências": linha **Estado** (abre `EstadoPickerView`, salva a UF escolhida em `AppState.selectedUF`, reflete em toda a UI — feriados estaduais e no card do perfil); linha **Minhas férias** (abre `RegistrarFeriasView`, mostra contagem de períodos); Notificações; Modo escuro (placeholders informativos).
- Seção "Sobre": Central de ajuda, versão do app.

**5. Seu estado** (`EstadoPickerView`, navegação a partir do Perfil)
- Busca por nome do estado + lista das 27 UFs com indicador de seleção (check laranja). Selecionar salva no `AppState` e retorna à tela anterior.

**6. Registrar férias** (`RegistrarFeriasView`, navegação a partir do Perfil)
- Dois `DatePicker` (início/fim), prévia de "N dias corridos" quando o intervalo é válido, botão "Adicionar período" (desabilitado até intervalo válido).
- Lista dos períodos já registrados com opção de remover (ícone "x").
- Estatísticas no topo: nº de períodos e total de dias usados no ano — atualizadas em tempo real.

## Dados de exemplo (para popular a UI sem backend)
Usar os 4 feriados/emendas já prototipados em `Models.swift` (Tiradentes, Consciência Negra, Ano Novo, Revolução Constitucionalista-SP) como seed. Estrutura pronta para depois plugar uma fonte real de feriados nacionais + estaduais por UF (ex.: API brasilapi.com.br/api/v1/feriados ou base local anual).

## Próximos passos sugeridos (fora do escopo desta prompt, mencionar mas não implementar)
- Persistência local dos períodos de férias e da UF escolhida (`UserDefaults` ou `SwiftData`).
- Cálculo dinâmico de emendas a partir de uma tabela real de feriados nacionais + estaduais por UF e por ano.
- Notificações locais avisando de emendas próximas.
