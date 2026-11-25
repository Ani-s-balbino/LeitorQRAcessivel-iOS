# Leitor QR Acessível (iOS)

Versão para iPhone do Leitor QR Acessível. Ajuda pessoas cegas a encontrar e enquadrar um QR code
pela câmera traseira, com orientação por voz (opcional), bips e vibração.

Versão de testes. Compatível com iOS 16 ou superior.

## Principais funções

- Busca guiada: avisos para mover o celular para a esquerda, direita, cima, baixo, e para aproximar ou afastar.
- Leitura do conteúdo, com ações: abrir link, copiar, compartilhar e ouvir novamente.
- Parar e retomar a busca, lanterna, e escanear outro QR code.
- Dicas para captura de QR code (papel em modo paisagem, tela de computador, distância, luz).
- Configurações: vibração, bips, ou os dois; voz do aplicativo; permissão da câmera; política de privacidade; feedback por e-mail.

## Como gerar o app

Este projeto usa o [XcodeGen](https://github.com/yonaskolb/XcodeGen). O arquivo `project.yml` descreve o projeto.

Em um Mac com Xcode 15 ou superior:

```bash
brew install xcodegen
xcodegen generate
open LeitorQRAcessivel.xcodeproj
```

Para rodar no iPhone, abra o projeto no Xcode, escolha seu aparelho, e configure sua equipe (Signing & Capabilities).
A distribuição para outras pessoas é feita pelo TestFlight, que exige uma conta do Apple Developer Program.

O GitHub Actions também compila o projeto a cada envio, para o simulador, sem assinatura.

## Privacidade

Nenhum dado pessoal é coletado ou enviado. A leitura do QR code é feita no próprio aparelho.
Veja a política completa dentro do aplicativo, em Configurações do aplicativo > Privacidade e termos.

## Licença

Este projeto é distribuído sob a [licença MIT](LICENSE).
