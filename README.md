# SNS PedManager

Eigenständige RedM-Resource für die distanzbasierte Verwaltung von NPCs. NPCs werden automatisch gespawnt, wenn der Spieler sich nähert, und wieder entfernt, wenn er sich entfernt – für bessere Performance und weniger unnötige Entities. Darüber hinaus könnt ihr Ped Szenarien/Animationen setzen, wodurch eure Peds lebendiger in der Welt wirken statt stumpfe Statisten in der Welt. 
Man kann in jeder Resource wo Peds eigenständig generiert werden den Export nutzen und so Performance sparen. 

Bei Fragen und Hilfestellung besucht den Ludwig_Development Discord: https://discord.gg/c84TPjXHDn

## Abhängigkeiten

- **ox_lib** – (Distanz-Checks)
- **murphy_interact** – für Interaktionen (optional, nur wenn du `interaction` nutzt)

## Installation

1. `sns_pedmanager` in deinen `resources`-Ordner legen
2. In `server.cfg` starten (nach ox_lib und murphy_interact):

```cfg
ensure ox_lib
ensure murphy_interact
ensure sns_pedmanager
```

## Nutzung

### Variante 1: Export (empfohlen)

In deiner Resource (z.B. beim Start):

```lua
exports.sns_pedmanager:registerNpcs(GetCurrentResourceName(), npcList, options)
```

Beim Stoppen der Resource:

```lua
exports.sns_pedmanager:unregisterNpcs(GetCurrentResourceName())
```

### Variante 2: Event

```lua
-- Registrieren
TriggerEvent('sns_pedmanager:registerNpcs', GetCurrentResourceName(), npcList, options)

-- Deregistrieren
TriggerEvent('sns_pedmanager:unregisterNpcs', GetCurrentResourceName())
```

---

## NPC-Liste aufbauen

Jeder Eintrag in `npcList` ist eine Tabelle mit folgenden Feldern:

| Feld | Typ | Pflicht | Beschreibung |
|------|-----|---------|--------------|
| `model` | string | Ja | Ped-Model (z.B. `cs_pinkertongoon`) |
| `x`, `y`, `z` | number | Ja | Position |
| `heading` | number | Nein | Blickrichtung (Standard: 0) |
| `outfit` | number | Nein | Outfit-Preset-ID. Ohne Angabe: zufällige Variation |
| `animDict` | string | Nein | Animations-Dictionary |
| `animName` | string | Nein | Animations-Name |
| `scenario` | string | Nein | Scenario (z.B. `"WORLD_HUMAN_SIT_GROUND"`) |
| `spawnDistance` | number | Nein | Abstand zum Spawnen (Standard: 100) |
| `interaction` | table | Nein | murphy_interact Konfiguration |
| `blip` | table | Nein | Blip-Konfiguration |
| `onSpawn` | function | Nein | Callback `(ped, npcData)` beim Spawn |
| `onDespawn` | function | Nein | Callback `(npcData)` beim Despawn |
| `onNearby` | function | Nein | Callback `(npcData)` während Spieler in Reichweite ist |

---

## Optionen (global für alle NPCs)

| Option | Typ | Beschreibung |
|--------|-----|--------------|
| `spawnDistance` | number | Standard-Spawn-Distanz für alle NPCs |
| `defaultOutfit` | number | Standard-Outfit, wenn pro NPC keins gesetzt ist |

---

## Beispiele

### Einfacher NPC ohne Interaktion

```lua
local npcList = {
    {
        model = "cs_pinkertongoon",
        x = 123.4, y = 456.7, z = 789.0,
        heading = 90.0,
        scenario = "WORLD_HUMAN_SIT_GROUND"
    }
}

exports.sns_pedmanager:registerNpcs(GetCurrentResourceName(), npcList)
```

### NPC mit Interaktion (murphy_interact)

```lua
local npcList = {
    {
        model = "cs_pinkertongoon",
        x = 123.4, y = 456.7, z = 789.0,
        heading = 90.0,
        interaction = {
            distance = 3,
            title = "Händler",
            options = {
                {
                    label = "Handeln",
                    icon = "hand",
                    onSelect = function()
                        -- Deine Logik
                    end
                }
            }
        }
    }
}

exports.sns_pedmanager:registerNpcs(GetCurrentResourceName(), npcList)
```

### NPC mit Blip

```lua
{
    model = "cs_pinkertongoon",
    x = 123.4, y = 456.7, z = 789.0,
    blip = {
        name = "Händler",
        sprite = "blip_shop",
        color = "BLIP_MODIFIER_MP_COLOR_1"  -- optional
    }
}
```

### Mit Callbacks

```lua
{
    model = "cs_pinkertongoon",
    x = 123.4, y = 456.7, z = 789.0,
    onSpawn = function(ped, npcData)
        -- Zusätzliche Anpassungen am Ped
    end,
    onDespawn = function(npcData)
        -- Aufräumen
    end
}
```


## Wichtige Hinweise

- **Resource-Stop**: Wenn deine Resource stoppt, werden ihre NPCs automatisch deregistriert.
- **Reihenfolge**: `sns_pedmanager` sollte vor Resources starten, die es nutzen.
- **Interaktionen**: Ohne `murphy_interact` funktionieren keine `interaction`-Einträge.
- NPCs sind standardmäßig **invincible**, **frozen** und haben **collision** aktiviert.
