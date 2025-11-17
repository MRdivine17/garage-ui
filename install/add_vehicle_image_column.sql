-- Add vehicle_image column to owned_vehicles table (ESX)
ALTER TABLE `owned_vehicles` ADD COLUMN `vehicle_image` VARCHAR(255) NULL DEFAULT NULL AFTER `stored`;

-- Add vehicle_image column to player_vehicles table (QBCore)
ALTER TABLE `player_vehicles` ADD COLUMN `vehicle_image` VARCHAR(255) NULL DEFAULT NULL AFTER `state`;
