-- Align schema with Sui tracker: add decimals + backing config columns.
PRAGMA foreign_keys = OFF;

ALTER TABLE lst_mints
  ADD COLUMN decimals INTEGER NOT NULL DEFAULT 9;

ALTER TABLE lst_mints
  ADD COLUMN backing_method TEXT NOT NULL DEFAULT 'object_field';

ALTER TABLE lst_mints
  ADD COLUMN backing_locator TEXT NOT NULL DEFAULT '{}';

PRAGMA foreign_keys = ON;
