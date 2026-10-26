# Graph Report - FlightHunter  (2026-10-20)

## Corpus Check
- Corpus is ~5,605 words - fits in a single context window. You may not need a graph.

## Summary
- 200 nodes · 329 edges · 13 communities (12 shown, 1 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- App Entry
- Destination Model
- Product Spec & Plan
- API Client
- City Model
- Date & Format Helpers
- Price Calendar View
- Add Destination Screen
- Destination Detail Screen
- Backend Prices & Cities
- Destination Row & Price Cells
- Cities Store

## God Nodes (most connected - your core abstractions)
1. `DestinationDetailView` - 21 edges
2. `Destination` - 17 edges
3. `PriceCalendarView` - 14 edges
4. `AddDestinationView` - 11 edges
5. `Format` - 10 edges
6. `PriceState` - 10 edges
7. `CityPickerView` - 9 edges
8. `DestinationListView` - 9 edges
9. `DestinationRow` - 9 edges
10. `Day` - 8 edges

## Surprising Connections (you probably didn't know these)
- `.body` --calls--> `DestinationListView`  [INFERRED]
  FlightHunter/FlightHunterApp.swift → Views/DestinationListView.swift
- `.priceLine` --references--> `Destination`  [INFERRED]
  Views/DestinationRow.swift → Models/Destination.swift
- `DestinationListView` --calls--> `PricesStore`  [INFERRED]
  Views/DestinationListView.swift → Services/PricesStore.swift
- `Landing page feature list` --conceptually_related_to--> `MVP features`  [INFERRED]
  site/index.html → CLAUDE.md
- `DestinationDetailView` --references--> `Destination`  [EXTRACTED]
  Views/DestinationDetailView.swift → Models/Destination.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Price tracking and alert flow** — claude_backend, claude_travelpayouts_api, claude_push_notifications, claude_widget [INFERRED 0.85]

## Communities (13 total, 1 thin omitted)

### Community 0 - "App Entry"
Cohesion: 0.11
Nodes (9): FlightHunterApp, .body, SwiftData, SwiftUI, AddDestinationPlaceholder, .body, DestinationListView, .body (+1 more)

### Community 1 - "Destination Model"
Cohesion: 0.15
Nodes (9): Destination, .title, Observation, PricesStore, PriceState, failed, loaded, loading (+1 more)

### Community 2 - "Product Spec & Plan"
Cohesion: 0.15
Nodes (19): Anonymous device identification, App Store preparation, Aviasales, Backend (proxy, cache, scheduler), Buy button with affiliate marker, FlightHunter iOS app, iOS architecture (Swift, SwiftUI, WidgetKit, App Group), MVP features (+11 more)

### Community 3 - "API Client"
Cohesion: 0.15
Nodes (7): APIClient, APIError, badURL, .errorDescription, network, server, BuyLinkResponse

### Community 4 - "City Model"
Cohesion: 0.16
Nodes (8): CitiesResponse, City, .id, Day, .id, PricesResponse, MonthOption, .id

### Community 5 - "Date & Format Helpers"
Cohesion: 0.16
Nodes (7): Foundation, Format, InstallID, .value, .canGoBack, .canGoForward, .body

### Community 6 - "Price Calendar View"
Cohesion: 0.18
Nodes (6): ContentView, .body, PriceCalendarView, .bestDayByDate, .lowestPrice, .priceByDate

### Community 7 - "Add Destination Screen"
Cohesion: 0.16
Nodes (8): AddDestinationView, .body, .canSave, .routeRows, CityPickerView, .body, .popular, .results

### Community 8 - "Destination Detail Screen"
Cohesion: 0.27
Nodes (5): DestinationDetailView, .body, .content, .legend, .monthSwitcher

### Community 9 - "Backend Prices & Cities"
Cohesion: 0.20
Nodes (8): City, db, json(), load(), Day, db, json(), tp()

### Community 10 - "Destination Row & Price Cells"
Cohesion: 0.22
Nodes (4): DestinationRow, .body, .priceLine, .subtitle

### Community 11 - "Cities Store"
Cohesion: 0.25
Nodes (6): CitiesState, failed, idle, loaded, loading, CitiesStore

## Knowledge Gaps
- **28 isolated node(s):** `.id`, `.title`, `.id`, `badURL`, `server` (+23 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 64 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `DestinationDetailView` connect `Destination Detail Screen` to `App Entry`, `Destination Model`, `Date & Format Helpers`, `Price Calendar View`?**
  _High betweenness centrality (0.154) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `Destination` (e.g. with `.add()` and `.save()`) actually correct?**
  _`Destination` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.id`, `.title`, `.id` to the rest of the system?**
  _28 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `App Entry` be split into smaller, more focused modules?**
  _Cohesion score 0.11255411255411256 - nodes in this community are weakly interconnected._
- **Why does `Foundation` connect `Date & Format Helpers` to `App Entry`, `Destination Model`, `API Client`, `City Model`, `Cities Store`?**
  _High betweenness centrality (0.125) - this node is a cross-community bridge._
- **Should `Product Spec & Plan` be split into smaller, more focused modules?**
  _Cohesion score 0.14619883040935672 - nodes in this community are weakly interconnected._
- **Why does `Destination` connect `Destination Model` to `App Entry`, `Destination Detail Screen`, `Destination Row & Price Cells`, `Add Destination Screen`?**
  _High betweenness centrality (0.119) - this node is a cross-community bridge._