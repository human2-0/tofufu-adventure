# Polish localization

Select **Settings → Language → Polski** (or **Ustawienia → Język → Polski**).
The change applies immediately and is saved on this device, independently of
adventure saves and other co-op players. The first launch follows the system
language for Polish/English and uses English for other languages. English remains
the source language and fallback.

The editable catalog is [pl.po](../game/settings/localization/pl.po). It covers
menus, loading/saving and connection messages, controls, HUD/combat, inventory,
equipment, shops/deposits, quests/dialogue, maps, weather, farming, factory
instructions and physical world signs. Names are playful but consistent: **Sojomat**,
**Mlekomiot**, **Kiełkokostur**, **Strąkoplecak**, **Chmurokrólestwo**, **Kaszopola**
and **Upadła Kaszogwardia**. Tofufu, Fufu, Dofufu, Godfufu, named characters and
Gigalopolis retain their identities. Factory operator access remains **Tofufu**.
Numbers, weapon requirements, rewards and control assignments retain their values.

Godot automatically translates Control and Label3D text. The
[formatted-message resource](../game/settings/localization/localized_messages.gd)
also recognizes catalogued messages that rules or peers have already formatted,
and composes their translated fragments at presentation time. Known user-name
fields are opaque; chat, speech bubbles, peer nameplates and player map captions
preserve user text. Saved adventure titles remain user text; newly suggested
titles use the selected language. Custom canvas text calls `tr()` explicitly.
The adapter has bounded recursion and a 2,048-entry display cache. App entry
composition registers it and removes it when the scene tree exits.

When adding text, add its exact English source and Polish translation to the PO
catalog. Keep format fields and their order, percent escapes, newlines and input
glyphs intact. Add a complete template for a composed message, and mark player or
adventure-name fields opaque in `LocalizedMessages.OPAQUE`. Do not translate IDs,
resource paths, protocol keys, save keys or player-authored messages. Use `tr_n()`
for grammatical plurals: the catalog supplies Polish singular, few and many forms.

`tests/test_localization.gd` checks the catalog's formatted templates, rule/peer
message presentation, preserved identities, generated factory labels, Polish
plural rules/glyphs, language persistence, fallback and live UI switching.
`tests/preview_polish.gd` renders actual menus at 1280×720 and 640×360, then the HUD,
inventory/tooltips, shop, quests, deposit and factory journal to `/tmp/tofufu-polish-*.png`.
Run the normal architecture checker and full verifier after source changes.

Every new or changed player-facing feature must ship in English and Polish. The character hub includes translated attributes, mastery titles, bonuses, equipment summaries, controls and notifications; `tests/preview_character_details.gd` renders both locales, including compact controller focus.
