-- Add engine_health and body_health columns to owned_vehicles table (ESX)
ALTER TABLE `owned_vehicles` 
ADD COLUMN `engine_health` INT(11) DEFAULT 1000 AFTER `vehicle_image`,
ADD COLUMN `body_health` INT(11) DEFAULT 1000 AFTER `engine_health`;

-- Add engine_health and body_health columns to player_vehicles table (QBCore)
ALTER TABLE `player_vehicles` 
ADD COLUMN `engine_health` INT(11) DEFAULT 1000 AFTER `vehicle_image`,
ADD COLUMN `body_health` INT(11) DEFAULT 1000 AFTER `engine_health`;

-- Update existing vehicles to have default health values
UPDATE `owned_vehicles` SET `engine_health` = 1000, `body_health` = 1000 WHERE `engine_health` IS NULL;
UPDATE `player_vehicles` SET `engine_health` = 1000, `body_health` = 1000 WHERE `engine_health` IS NULL;
