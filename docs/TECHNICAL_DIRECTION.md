# Direcao Tecnica

## Engine

O projeto usa Godot 4 por ser gratuita, local, leve, adequada para 2D e viavel para um desenvolvimento longo sem custo de licenca.

## Linguagem

O prototipo usa GDScript. Para a fase atual, isso reduz complexidade e acelera iteracao dentro da propria engine.

## Estrutura atual

```text
assets/              Assets visuais pequenos e placeholders
data/                Dados estruturados do jogo
docs/                Planejamento e documentacao
scenes/              Cenas Godot
scripts/             Scripts GDScript e utilitarios
scripts/launch/      Launcher Windows
```

## Dados

Dados de gameplay ficam fora do script sempre que possivel. O arquivo `data/countries.json` e o primeiro exemplo disso.

Diretriz:

- scripts controlam comportamento;
- JSON/recursos controlam conteudo;
- dados reais precisam de fonte antes de entrar como conteudo publico.

## Compatibilidade Windows

O launcher principal e `launch_red_meridian.cmd`, que chama PowerShell com `ExecutionPolicy Bypass` apenas para o script local do projeto. Isso evita o problema comum de `npm.ps1`/scripts bloqueados por policy no Windows.

## Git

O repositorio deve manter commits pequenos e descritivos. Arquivos gerados pela Godot, builds e logs ficam fora do versionamento via `.gitignore`.

## Proximas decisoes tecnicas

- Definir pipeline de mapa real.
- Definir formato de save.
- Definir validacao automatizada dos JSONs.
- Definir padrao para eventos, focos e relacoes diplomaticas.
- Definir estrategia para assets com licenca segura.

