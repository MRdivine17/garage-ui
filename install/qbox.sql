-- ============================================================
--  Qbox (qbx_core) schema for garage-ui
--  Run this ONCE against your database.
--  Qbox already ships `player_vehicles`; this only adds the extra
--  columns this resource relies on. `IF NOT EXISTS` makes it safe
--  to re-run (MariaDB / MySQL 8+).
-- ============================================================

ALTER TABLE `player_vehicles`
    ADD COLUMN IF NOT EXISTS `job` VARCHAR(20) NULL DEFAULT NULL;

ALTER TABLE `player_vehicles`
    ADD COLUMN IF NOT EXISTS `type` VARCHAR(20) NOT NULL DEFAULT 'car';

ALTER TABLE `player_vehicles`
    ADD COLUMN IF NOT EXISTS `stored` TINYINT(1) NOT NULL DEFAULT 1;

ALTER TABLE `player_vehicles`
    ADD COLUMN IF NOT EXISTS `vehicle_image` VARCHAR(255) NULL DEFAULT NULL;

ALTER TABLE `player_vehicles`
    ADD COLUMN IF NOT EXISTS `engine_health` INT(11) NOT NULL DEFAULT 1000;

ALTER TABLE `player_vehicles`
    ADD COLUMN IF NOT EXISTS `body_health` INT(11) NOT NULL DEFAULT 1000;

-- Existing vehicles: make sure they are considered parked and have health.
UPDATE `player_vehicles` SET `stored` = 1 WHERE `stored` IS NULL;
UPDATE `player_vehicles` SET `type` = 'car' WHERE `type` IS NULL OR `type` = '';
UPDATE `player_vehicles` SET `engine_health` = 1000 WHERE `engine_health` IS NULL;
UPDATE `player_vehicles` SET `body_health` = 1000 WHERE `body_health` IS NULL;
