# Red Meridian

Red Meridian e um jogo 2D de estrategia geopolitica e militar em desenvolvimento com Godot 4. A visao de longo prazo e combinar simulacao politica, economia, diplomacia, inteligencia, doutrina militar e operacoes estrategicas em uma experiencia inspirada por grand strategy e wargames modernos, sem copiar sistemas, UI ou conteudo proprietario de outros jogos.

O projeto esta em fase inicial e, por enquanto, existe como um prototipo local jogavel para validar arquitetura, fluxo de jogo e sistemas-base.

## Status atual

- Engine: Godot 4.
- Plataforma inicial: Windows.
- Escopo atual: prototipo 2D local.
- Rede/multiplayer: fora do escopo por enquanto.
- Dados reais: placeholders ate haver fontes, criterios e licencas definidos.

## Como abrir

Use o atalho `Red Meridian` na Area de Trabalho ou execute:

```powershell
.\launch_red_meridian.cmd
```

O launcher procura uma instalacao local do Godot 4 e abre esta pasta como projeto. Se o Godot nao estiver no `PATH`, ele tambem checa locais comuns no Windows. Tambem e possivel definir a variavel `GODOT_EXE` apontando para o executavel do Godot.

## O que ja existe

- Tela principal em 2D.
- Mapa estrategico abstrato clicavel.
- Paises reais como entidades simuladas.
- Simulacao simples de data, pausa e velocidade.
- Tensao global, estabilidade, GDP, prontidao militar e diplomacia.
- Acoes iniciais de governo.
- Focos nacionais com duracao e efeitos.
- Estrutura de dados externa em JSON para evoluir o jogo sem prender tudo no codigo.

## Direcao do projeto

Os documentos de planejamento ficam em `docs/`:

- `docs/VISION.md`: visao de produto e pilares de design.
- `docs/ROADMAP.md`: roadmap tecnico e de gameplay.
- `docs/TECHNICAL_DIRECTION.md`: decisoes tecnicas iniciais.

## Observacao sobre dados reais

Nomes de paises sao dados factuais, mas retratos, fotos, biografias, logos, dados politicos detalhados e qualquer material de terceiros precisam de fonte, licenca e criterio editorial antes de uso publico. Para a fase local, o projeto usa placeholders e prepara o sistema para receber dados auditados depois.

## Licenca

Ainda nao ha uma licenca publica definida. Ate uma licenca ser escolhida explicitamente, todos os direitos ficam reservados.
