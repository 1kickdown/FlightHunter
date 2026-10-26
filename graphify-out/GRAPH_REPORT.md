# Graph Report - FlightHunter  (2026-10-24)

## Corpus Check
- 39 files · ~9,142 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: (none) 3, .xcscheme 2, .entitlements 2)

## Summary
- 278 nodes · 457 edges · 14 communities (13 shown, 1 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 25 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- App Entry
- Destination Model
- Product Spec & Plan
- API Client
- City Model
- Date & Format Helpers
- Price Calendar View
- AddDestinationView
- Destination Detail Screen
- check-prices/index.ts
- Destination Row & Price Cells
- Cities Store
- WidgetDestination

## God Nodes (most connected - your core abstractions)
1. `DestinationDetailView` - 21 edges
2. `WidgetDestination` - 14 edges
3. `PriceCalendarView` - 14 edges
4. `AddDestinationView` - 11 edges
5. `PriceEntry` - 10 edges
6. `Format` - 10 edges
7. `PriceState` - 10 edges
8. `DestinationListView` - 10 edges
9. `Destination` - 9 edges
10. `CityPickerView` - 9 edges

## Surprising Connections (you probably didn't know these)
- `.body` --calls--> `DestinationListView`  [INFERRED]
  FlightHunter/FlightHunterApp.swift → Views/DestinationListView.swift
- `.best` --references--> `WidgetDestination`  [INFERRED]
  FlightHunterWidget/FlightHunterWidget.swift → Models/WidgetSnapshot.swift
- `Landing page feature list` --conceptually_related_to--> `MVP features`  [INFERRED]
  site/index.html → CLAUDE.md
- `PriceState` --references--> `PricesResponse`  [EXTRACTED]
  Services/PricesStore.swift → Models/PricesResponse.swift
- `DestinationDetailView` --references--> `PriceState`  [EXTRACTED]
  Views/DestinationDetailView.swift → Services/PricesStore.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Price tracking and alert flow** — claude_backend, claude_travelpayouts_api, claude_push_notifications, claude_widget [INFERRED 0.85]

## Communities (14 total, 1 thin omitted)

### Community 0 - "App Entry"
Cohesion: 0.11
Nodes (8): FlightHunterApp, .body, Destination, .title, SwiftData, SwiftUI, AddDestinationPlaceholder, .body

### Community 1 - "Destination Model"
Cohesion: 0.17
Nodes (9): PricesStore, PriceState, failed, loaded, loading, DestinationListView, .body, .emptyState (+1 more)

### Community 2 - "Product Spec & Plan"
Cohesion: 0.15
Nodes (19): Anonymous device identification, App Store preparation, Aviasales, Backend (proxy, cache, scheduler), Buy button with affiliate marker, FlightHunter iOS app, iOS architecture (Swift, SwiftUI, WidgetKit, App Group), MVP features (+11 more)

### Community 3 - "API Client"
Cohesion: 0.15
Nodes (7): APIClient, APIError, badURL, .errorDescription, network, server, BuyLinkResponse

### Community 4 - "City Model"
Cohesion: 0.21
Nodes (6): CitiesResponse, City, .id, Day, .id, PricesResponse

### Community 5 - "Date & Format Helpers"
Cohesion: 0.23
Nodes (4): Format, .canGoBack, .canGoForward, .body

### Community 6 - "Price Calendar View"
Cohesion: 0.12
Nodes (10): ContentView, .body, CityPickerView, .body, .popular, .results, PriceCalendarView, .bestDayByDate (+2 more)

### Community 7 - "AddDestinationView"
Cohesion: 0.18
Nodes (7): CitiesStore, AddDestinationView, .body, .canSave, .routeRows, MonthOption, .id

### Community 8 - "Destination Detail Screen"
Cohesion: 0.23
Nodes (5): DestinationDetailView, .body, .content, .legend, .monthSwitcher

### Community 9 - "check-prices/index.ts"
Cohesion: 0.07
Nodes (28): checkRoute(), dayText(), db, MONTHS, priceText(), Subscription, City, db (+20 more)

### Community 10 - "Destination Row & Price Cells"
Cohesion: 0.16
Nodes (9): FlighthunterWidgetEntryView, .body, .emptyView, .mediumView, .smallView, DestinationRow, .body, .priceLine (+1 more)

### Community 11 - "Cities Store"
Cohesion: 0.14
Nodes (9): Foundation, Observation, CitiesState, failed, idle, loaded, loading, InstallID (+1 more)

### Community 13 - "WidgetDestination"
Cohesion: 0.08
Nodes (14): FlightHunterWidget, .body, PriceEntry, .best, Provider, FlightHunterWidgetBundle, .body, SharedStore (+6 more)

## Knowledge Gaps
- **33 isolated node(s):** `.body`, `.emptyView`, `.id`, `.title`, `.id` (+28 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 102 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Foundation` connect `Cities Store` to `App Entry`, `API Client`, `City Model`, `Date & Format Helpers`, `WidgetDestination`?**
  _High betweenness centrality (0.105) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `WidgetDestination` (e.g. with `.best` and `.syncWidget()`) actually correct?**
  _`WidgetDestination` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.body`, `.emptyView`, `.id` to the rest of the system?**
  _33 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `App Entry` be split into smaller, more focused modules?**
  _Cohesion score 0.11462450592885376 - nodes in this community are weakly interconnected._
- **Why does `DestinationDetailView` connect `Destination Detail Screen` to `App Entry`, `Destination Model`, `Date & Format Helpers`, `Price Calendar View`?**
  _High betweenness centrality (0.097) - this node is a cross-community bridge._
- **Should `Product Spec & Plan` be split into smaller, more focused modules?**
  _Cohesion score 0.14619883040935672 - nodes in this community are weakly interconnected._
- **Why does `AddDestinationView` connect `AddDestinationView` to `Destination Model`, `Destination Row & Price Cells`, `Price Calendar View`?**
  _High betweenness centrality (0.066) - this node is a cross-community bridge._