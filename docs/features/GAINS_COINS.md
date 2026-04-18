# Gains Coins & Economy

> **Status**: ✅ Complete  
> **Last Updated**: April 19, 2026  
> **Covers**: Coin balance, transaction history, cosmetics shop, inventory, equip system, leaderboard

---

## Overview

The Gains Coins economy rewards users for completing workouts. Coins can be spent in the cosmetics shop to purchase wearable items (headwear, tops, bottoms, accessories) that appear on the user's avatar in Unity.

---

## Architecture

```
lib/features/gains_coins/
├── gains_coins.dart                          # Feature barrel export
├── data/
│   ├── data.dart
│   ├── coins_repository.dart                 # Balance + transaction history (offline-first)
│   ├── coin_estimate_calculator.dart         # Local reward estimate before server confirm
│   ├── cosmetics_repository.dart             # Shop catalog, inventory, equip/unequip
│   ├── leaderboard_repository.dart           # Leaderboard data
│   ├── shop_repository.dart                  # Purchase operations
│   └── models/
│       ├── coin_balance_model.dart           # CoinBalanceModel (current, lifetime earned/spent)
│       ├── coin_estimate_model.dart          # Pre-session reward estimate
│       ├── coin_transaction_model.dart       # CoinTransactionModel + paginated response
│       ├── cosmetic_model.dart               # CosmeticModel (id, name, slot, price, imageUrl)
│       ├── equipped_cosmetic_model.dart      # EquippedCosmeticModel (slot → cosmeticId map)
│       ├── leaderboard_entry_model.dart      # LeaderboardEntryModel (rank, user, balance)
│       └── user_cosmetic_model.dart          # UserCosmeticModel (owned cosmetics)
└── presentation/
    ├── providers/
    │   ├── coin_balance_provider.dart        # Balance state + fetch/refresh
    │   ├── coin_history_provider.dart        # Paginated transaction history
    │   ├── inventory_provider.dart           # Owned + equipped cosmetics notifier
    │   ├── leaderboard_provider.dart         # Leaderboard state
    │   └── shop_provider.dart                # Shop catalog + purchase flow
    ├── screens/
    │   ├── coin_history_screen.dart          # Paginated transaction list
    │   ├── coin_reward_screen.dart           # Post-workout reward animation/summary
    │   ├── cosmetic_detail_screen.dart       # Single cosmetic detail + buy/equip CTA
    │   ├── cosmetic_fullscreen_screen.dart   # Full-screen cosmetic preview
    │   ├── inventory_screen.dart             # User's owned cosmetics + equip slots
    │   ├── leaderboard_screen.dart           # Global coin leaderboard
    │   └── shop_screen.dart                  # Cosmetics shop catalog
    └── widgets/
        ├── coin_balance_widget.dart          # Inline balance display (header/appbar)
        ├── coin_breakdown_card.dart          # Session reward breakdown
        ├── cosmetic_preview.dart             # Cosmetic thumbnail + equipped badge
        └── leaderboard_row.dart              # Single leaderboard entry row
```

---

## Features

| Feature               | Description                                                 | Status      |
|-----------------------|-------------------------------------------------------------|-------------|
| Coin Balance          | View current balance, lifetime earned, lifetime spent       | ✅ Complete |
| Transaction History   | Paginated list of earn/spend transactions                   | ✅ Complete |
| Post-workout Reward   | Animated reward screen after session completion             | ✅ Complete |
| Reward Estimate       | Pre-session coin estimate shown before starting             | ✅ Complete |
| Shop                  | Browse cosmetics by slot (headwear, tops, bottoms, accessories) | ✅ Complete |
| Purchase              | Buy cosmetics with coins; server-side balance deducted      | ✅ Complete |
| Inventory             | View owned cosmetics, equip to slots                        | ✅ Complete |
| Equip / Unequip       | Toggle cosmetics per slot; state cached locally             | ✅ Complete |
| Leaderboard           | Global ranking by coin balance                              | ✅ Complete |

---

## Offline-First Patterns

- **Balance**: Cached in Drift `CoinBalances` table; served from cache when offline
- **Equipped state**: Cached in Drift; equip/unequip optimistically updates local cache then syncs to server
- **Inventory**: Cached in Drift after first successful fetch

---

## Routes

| Route                | Screen                  | Notes                          |
|----------------------|-------------------------|--------------------------------|
| `/coins/reward`      | `CoinRewardScreen`      | Post-workout reward display    |
| `/coins/history`     | `CoinHistoryScreen`     | Paginated transaction list     |
| `/shop`              | `ShopScreen`            | Cosmetics catalog              |
| `/shop/cosmetic`     | `CosmeticDetailScreen`  | Single item detail             |
| `/inventory`         | `InventoryScreen`       | Owned + equipped cosmetics     |
| `/leaderboard`       | `LeaderboardScreen`     | Global rankings                |

---

## Key Providers

| Provider                   | Type            | Returns                                  |
|----------------------------|-----------------|------------------------------------------|
| `coinBalanceProvider`      | AsyncNotifier   | `CoinBalanceModel`                       |
| `coinHistoryProvider`      | AsyncNotifier   | Paginated `CoinTransactionModel` list    |
| `shopProvider`             | AsyncNotifier   | Shop catalog + purchase state            |
| `inventoryProvider`        | AsyncNotifier   | `InventoryResponse` (owned + equipped)   |
| `leaderboardProvider`      | AsyncNotifier   | `List<LeaderboardEntryModel>`            |
