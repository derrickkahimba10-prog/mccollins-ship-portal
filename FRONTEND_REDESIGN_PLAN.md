# McCollins Premium Frontend Redesign Plan

This is a frontend transformation of the completed Phase 1–12 system. It introduces no new development phase and does not redesign the database.

| Page/area | Current problem found | Implemented improvement | Components affected | CSS affected | Priority |
|---|---|---|---|---|---|
| Global shell | Functional but visually flat and weak hierarchy | Layered dark-emerald structure, cream workspace, champagne-gold accents, depth and route-inspired background | Layout, header, content shell | Tokens, gradients, elevation, spacing | High |
| Sidebar | Long ungrouped list; updates easy to miss | Workflow groups, active glow, contextual hover/focus preview and live attention counters | Navigation, badges, profile area | Sidebar, tooltip, responsive drawer | High |
| Dashboards | Repeated identical cards | Stronger lead metric, elevated statistics and clearer action hierarchy | Metrics, quick actions | Dashboard metric mosaic | High |
| Login/register | Basic centered form with little logistics identity | Responsive split experience with original freight illustration and secure workspace panel | Auth layout/forms/branding | Auth story, responsive panels | High |
| Subscriptions | No visible prices or tier identity | Gold, sapphire Premium and platinum tier treatments; temporary TSh prices; trial CTA routes to plans | Plan cards, carrier overview CTA | Tier cards, price typography | High |
| Transport offers | FX formula displayed separately; free-text breakdown | TZS/USD selector, automatic equivalent, comma formatting and four structured cost fields | Offer create/revise/detail | Pricing entry and money display | High |
| Tracking | Coordinate fields lacked browser ranges | Numeric latitude/longitude limits and precision aligned with backend validation | Tracking form | Form controls/status cards | High |
| Notifications | Broadcast-first; open did not mark read; position reset | Individual-email default, explicit audience choice, open-as-read, close action and scroll restoration | Service, inbox, open route | Notification cards/actions | Critical UX |
| Status/time display | Important states blended into surrounding text | Bold semantic status pills and tabular bold timestamps | Tables, tracking, offers, plans | Status system | High |
| Assistant readiness | No future support entry point | Clearly labelled UI-only assistant shell with no fake AI behavior | Shared footer | Floating assistant | Low |
| Mobile | Core responsive behavior existed but richer UI needed validation | Stacked plans/pricing/auth, drawer navigation, touch targets and contained tables | All shared components | 900/600px breakpoints | High |

## Preserved

- Authentication, role permissions and company scoping.
- Approved workflow transitions and business ownership rules.
- Existing tables and core data.
- Operations control of matching, offers, assignment and dispatch.
- Existing document, e-POD, payment, settlement, audit and notification records.

## Database impact

No new table or column is required for these changes. Existing fields are reused for targeted recipients, notification state, dual-currency values, structured price text and subscription presentation.
