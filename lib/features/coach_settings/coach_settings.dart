/// Coach Settings Feature (ML-5)
///
/// Settings CRUD for coaches — capacity, intake toggle, discoverability.
///
/// Features:
/// - View coach settings (maxClients, acceptingClients, isDiscoverable)
/// - Update coach settings
///
/// Model: `CoachSettings` (1-to-1 with Coach)
/// - `maxClients` — hard cap on active client count (default 40)
/// - `acceptingClients` — manual on/off for new intake
/// - `isDiscoverable` — appear in public search results
library;

// Data layer
export 'data/data.dart';

// Presentation layer
export 'presentation/presentation.dart';
