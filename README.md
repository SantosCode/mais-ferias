# Mais Férias

Planejador de férias para iOS (SwiftUI, iOS 17+) que encontra as melhores
emendas entre feriados nacionais/estaduais e seus dias livres, respeitando as
regras da CLT. Arquitetura e convenções: veja `CLAUDE.md`.

## Como buildar

1. Clone o repositório e abra `Mais Ferias.xcodeproj` no Xcode.
2. Crie o arquivo `Mais Ferias/App/Secrets.swift` (ignorado pelo git) com a sua
   chave da [Feriados API](https://feriadosapi.com):

   ```swift
   import Foundation

   enum Secrets {
       static var feriadosAPIKey: String {
           if let fromPlist = Bundle.main.object(forInfoDictionaryKey: "FeriadosAPIKey") as? String, !fromPlist.isEmpty {
               return fromPlist
           }
           return "SUA_CHAVE_AQUI"
       }
   }
   ```

   Alternativa para CI: injete `FeriadosAPIKey` no Info.plist via `.xcconfig`.
3. Rode o scheme "Mais Ferias" (⌘R) e os testes (⌘U — Swift Testing).

## Checklist de publicação (App Store)

- [x] Privacy Manifest (`PrivacyInfo.xcprivacy`) — sem rastreamento, sem coleta
- [x] `ITSAppUsesNonExemptEncryption = NO` (dispensa de compliance de exportação)
- [x] Descrição de uso do calendário (write-only) no Info.plist
- [x] Ícone 1024 com variantes dark/tinted
- [x] Somente iPhone (`TARGETED_DEVICE_FAMILY = 1`)
- [x] Política de privacidade (`PRIVACY.md` — publique a URL no App Store Connect)
- [ ] Rotacionar a chave da Feriados API e conferir os termos de uso comercial
- [ ] Conta Apple Developer, certificados e ficha no App Store Connect
      (screenshots, descrição, URL de suporte e de privacidade)
- [ ] Rodada de TestFlight em aparelho real (notificações e permissão de calendário)
