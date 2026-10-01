# Phase 10 — Documents & e-POD

Complete Phase 10 adds protected transport-document storage and electronic proof of delivery to the verified Phase 9 lifecycle.

## Install

Preserve `.env`, then import:

1. `database/migrations/043_phase10_documents_epod_alignment.sql`
2. `database/seeds/044_phase10_permissions.sql`

Log Operations, Driver, Carrier and Shipper accounts out and back in.

The web-server user must be able to write to `storage/uploads/documents`. Files are stored outside `public` and are served only through an authorization-checked download route.

## Workflow

1. Operations or the assigned Driver uploads transport/delivery documents.
2. Carrier and Shipper can view only documents for their scoped trip and allowed visibility.
3. After Phase 8 delivery, the assigned Driver submits the e-POD.
4. Operations confirms or rejects it.
5. Rejected e-PODs can be corrected as a new immutable version.
6. Confirmed e-POD changes shipment and load from `delivered_pending_epod` to `delivered` and records an `epod_confirmed` milestone.

Supported files: PDF, JPG, PNG and WebP, maximum 10 MB.