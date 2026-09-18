# Mais Férias

App iOS (SwiftUI, iOS 17+) que sugere as melhores emendas de feriados no Brasil,
considerando a UF, a jornada e o saldo de férias do usuário.

## Arquitetura (Clean Architecture)

- `Domain/` — regras puras (só Foundation): entidades, `EmendaCalculator`
  (cálculo de emendas + CLT), `LocalHolidayCalculator` (nacionais offline),
  `VacationPlanner` (plano anual com fracionamento da CLT), protocolo
  `HolidayRepository`.
- `Data/` — `FeriadosAPIHolidayRepository` (Feriados API) e modelos SwiftData
  (`UserProfile`, `VacationPeriod`, `CachedHoliday` = cache offline por UF).
- `Presentation/` — `AppState` (store `@Observable` único, repositório injetado
  no init), telas em `Screens/`, estilo liquid glass em `Style/`.
- `Infrastructure/` — `NotificationScheduler`, `CalendarExporter` (EventKit).

Regra de dependência: Domain não conhece Data/Presentation. A UI fala só com o
`AppState`.

## Regras de negócio críticas

- **Os testes são a especificação do cálculo.** `EmendaCalculatorTests` fixa o
  comportamento por dia da semana e a legalidade (CLT art. 134 §3º: férias nunca
  começam na sexta/sábado nem nos 2 dias antes de um feriado). Não altere o
  calculador sem manter esses testes verdes.
- Janela rolante de 12 meses a partir do mês corrente (`AppState.twelveMonthWindow`)
  para busca, cálculo e exibição do calendário.
- Fallback em camadas no `loadEmendas`: API → cache da UF → nacionais locais →
  dados de exemplo.
- `VacationPlanner`: reserva 14 dias para o período principal e cobra no mínimo
  5 dias por emenda (fracionamento CLT art. 134 §1º).

## Comandos / ferramentas

- Build/testes pelo Xcode (scheme "Mais Ferias"); suíte usa Swift Testing.
- Ícone do app: gerado por script CoreGraphics (histórico em `/tmp/make_icon.swift`).
- Chave da Feriados API: lida do Info.plist (`FeriadosAPIKey`) via `Secrets`;
  o valor deve migrar para um `.xcconfig` fora do git.

## Convenções

- Comentários de código em português do Brasil.
- UI segue o estilo do `GlassStyle.swift` (fundo `AppBackground`, `.glassCard()`,
  destaque `accentOrange`).
