# Moera iOS

iOS-клиент для децентрализованной соцсети [Moera](https://moera.org) в стиле Facebook.

## Сборка

```sh
brew install xcodegen
xcodegen generate
open MoeraClient.xcodeproj
```

## Структура

- `App/` — точка входа, вкладки
- `API/` — клиент Moera Node API
- `Models/` — модели данных
- `Features/` — экраны: Auth, Feed, Post, Profile, Notifications
- `Shared/` — общие компоненты UI
