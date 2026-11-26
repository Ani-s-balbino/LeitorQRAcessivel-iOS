# Leitor QR Acessível (iOS)

Aplicativo para iPhone que ajuda pessoas cegas a encontrar, enquadrar e ler um QR code sozinhas. A câmera traseira guia a busca por voz (opcional), bips e vibração até o código estar bem enquadrado. Depois de ler, o app mostra o conteúdo com ações seguras.

**Versão atual:** 1.4.0 · **Licença:** GPLv3 · **Plataforma:** iOS 16 ou superior

Esta é a versão para iPhone. A versão para Android está no repositório [LeitorQRAcessivel](https://github.com/Ani-s-balbino/LeitorQRAcessivel).

## Principais funções

- Busca guiada com avisos de direção, distância e inclinação.
- Feedback escolhido pela pessoa: nenhum, bips, vibração, ou vibração e bips.
- Voz do aplicativo opcional, para quem não usa o VoiceOver.
- Leitura do QR code com ações: abrir o link, copiar, compartilhar e ouvir novamente.
- Parar e retomar a busca, e lanterna.
- Dicas para captura de QR code.
- Configurações, política de privacidade e termos, e envio de feedback por e-mail.

## Como gerar o app

O projeto usa o [XcodeGen](https://github.com/yonaskolb/XcodeGen). O arquivo `project.yml` descreve o projeto.

Em um Mac com Xcode 15 ou superior:

```bash
brew install xcodegen
xcodegen generate
open LeitorQRAcessivel.xcodeproj
```

Para rodar no iPhone, abra o projeto no Xcode, escolha seu aparelho e configure sua equipe em Signing & Capabilities. Para distribuir a outras pessoas, use o TestFlight, que exige uma conta do Apple Developer Program.

O GitHub Actions compila o projeto a cada envio, para o simulador, sem assinatura.

## Documentação

- [Versionamento e histórico (Android)](https://github.com/Ani-s-balbino/LeitorQRAcessivel/blob/main/docs/VERSIONAMENTO.md)
- [Relatório de testes 1.4.0 (Android)](https://github.com/Ani-s-balbino/LeitorQRAcessivel/blob/main/docs/RELATORIO_DE_TESTES.md)

## Privacidade

Nenhum dado pessoal é coletado ou enviado. A leitura do QR code é feita no próprio aparelho.

## Licença

Este projeto é distribuído sob a [GNU GPLv3](LICENSE). Você pode usar, estudar, modificar e redistribuir o código. Se distribuir uma versão modificada, ela também precisa ser publicada sob a GPLv3, com o código-fonte disponível.
