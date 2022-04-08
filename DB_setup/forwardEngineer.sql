-- MySQL Workbench Forward Engineering;

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema ecometri_caddis
-- -----------------------------------------------------;
DROP SCHEMA IF EXISTS `ecometri_caddis` ;

-- -----------------------------------------------------
-- Schema ecometri_caddis
-- -----------------------------------------------------;
CREATE SCHEMA IF NOT EXISTS `ecometri_caddis` DEFAULT CHARACTER SET utf8 ;
USE `ecometri_caddis`;

-- -----------------------------------------------------
-- Table `ecometri_caddis`.`Makes`
-- -----------------------------------------------------;
DROP TABLE IF EXISTS `ecometri_caddis`.`Makes` ;

CREATE TABLE IF NOT EXISTS `ecometri_caddis`.`Makes` (
  `make_id` INT NOT NULL AUTO_INCREMENT,
  `make_name` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`make_id`),
  UNIQUE INDEX `make_name_UNIQUE` (`make_name` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ecometri_caddis`.`Models`
-- -----------------------------------------------------;
DROP TABLE IF EXISTS `ecometri_caddis`.`Models` ;

CREATE TABLE IF NOT EXISTS `ecometri_caddis`.`Models` (
  `model_id` INT NOT NULL AUTO_INCREMENT,
  `model_name` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`model_id`),
  UNIQUE INDEX `model_name_UNIQUE` (`model_name` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ecometri_caddis`.`Loggers`
-- -----------------------------------------------------;
DROP TABLE IF EXISTS `ecometri_caddis`.`Loggers` ;

CREATE TABLE IF NOT EXISTS `ecometri_caddis`.`Loggers` (
  `logger_id` INT NOT NULL AUTO_INCREMENT,
  `serialNo` INT NOT NULL,
  `make_id` INT NOT NULL,
  `model_id` INT NOT NULL,
  PRIMARY KEY (`logger_id`),
  INDEX `model_id_idx` (`model_id` ASC),
  INDEX `make_id_idx` (`make_id` ASC),
  UNIQUE INDEX `serialNo_UNIQUE` (`serialNo` ASC),
  CONSTRAINT `make_id`
    FOREIGN KEY (`make_id`)
    REFERENCES `ecometri_caddis`.`Makes` (`make_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `model_id`
    FOREIGN KEY (`model_id`)
    REFERENCES `ecometri_caddis`.`Models` (`model_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ecometri_caddis`.`Locations`
-- -----------------------------------------------------;
DROP TABLE IF EXISTS `ecometri_caddis`.`Locations` ;

CREATE TABLE IF NOT EXISTS `ecometri_caddis`.`Locations` (
  `location_id` INT NOT NULL AUTO_INCREMENT,
  `location_name` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`location_id`),
  UNIQUE INDEX `location_name_UNIQUE` (`location_name` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ecometri_caddis`.`Deployments`
-- -----------------------------------------------------;
DROP TABLE IF EXISTS `ecometri_caddis`.`Deployments` ;

CREATE TABLE IF NOT EXISTS `ecometri_caddis`.`Deployments` (
  `deployment_id` INT NOT NULL AUTO_INCREMENT,
  `logger_id` INT NOT NULL,
  `deployment_start` DATETIME NOT NULL,
  `deployment_end` DATETIME NULL,
  `location_id` INT NOT NULL,
  PRIMARY KEY (`deployment_id`),
  INDEX `logger_id_idx` (`logger_id` ASC),
  INDEX `location_id_idx` (`location_id` ASC),
  UNIQUE INDEX `deployment_UNIQUE` (`logger_id` ASC, `deployment_start` ASC, `location_id` ASC),
  CONSTRAINT `logger_id`
    FOREIGN KEY (`logger_id`)
    REFERENCES `ecometri_caddis`.`Loggers` (`logger_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `location_id_dep`
    FOREIGN KEY (`location_id`)
    REFERENCES `ecometri_caddis`.`Locations` (`location_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ecometri_caddis`.`Metrics`
-- -----------------------------------------------------;
DROP TABLE IF EXISTS `ecometri_caddis`.`Metrics` ;

CREATE TABLE IF NOT EXISTS `ecometri_caddis`.`Metrics` (
  `metric_id` INT NOT NULL AUTO_INCREMENT,
  `metric_name` VARCHAR(45) NOT NULL,
  `metric_units` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`metric_id`),
  UNIQUE INDEX `metric_name_UNIQUE` (`metric_name` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ecometri_caddis`.`Readings`
-- -----------------------------------------------------;
DROP TABLE IF EXISTS `ecometri_caddis`.`Readings` ;

CREATE TABLE IF NOT EXISTS `ecometri_caddis`.`Readings` (
  `reading_id` INT NOT NULL AUTO_INCREMENT,
  `deployment_id` INT NOT NULL,
  `reading_datetime` DATETIME NOT NULL,
  `metric_id` INT NOT NULL,
  `value` FLOAT NULL,
  PRIMARY KEY (`reading_id`),
  INDEX `deployment_id_idx` (`deployment_id` ASC),
  INDEX `metric_id_idx` (`metric_id` ASC),
  UNIQUE INDEX `reading_UNIQUE` (`deployment_id` ASC, `reading_datetime` ASC, `metric_id` ASC),
  CONSTRAINT `deployment_id`
    FOREIGN KEY (`deployment_id`)
    REFERENCES `ecometri_caddis`.`Deployments` (`deployment_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `metric_id_read`
    FOREIGN KEY (`metric_id`)
    REFERENCES `ecometri_caddis`.`Metrics` (`metric_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ecometri_caddis`.`Labs`
-- -----------------------------------------------------;
DROP TABLE IF EXISTS `ecometri_caddis`.`Labs` ;

CREATE TABLE IF NOT EXISTS `ecometri_caddis`.`Labs` (
  `lab_id` INT NOT NULL AUTO_INCREMENT,
  `lab_name` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`lab_id`),
  UNIQUE INDEX `lab_name_UNIQUE` (`lab_name` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ecometri_caddis`.`Batches`
-- -----------------------------------------------------;
DROP TABLE IF EXISTS `ecometri_caddis`.`Batches` ;

CREATE TABLE IF NOT EXISTS `ecometri_caddis`.`Batches` (
  `batch_id` INT NOT NULL AUTO_INCREMENT,
  `lab_id` INT NOT NULL,
  `batch_date` DATE NOT NULL,
  `filename` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`batch_id`),
  INDEX `lab_id_idx` (`lab_id` ASC),
  UNIQUE INDEX `filename_UNIQUE` (`filename` ASC),
  CONSTRAINT `lab_id`
    FOREIGN KEY (`lab_id`)
    REFERENCES `ecometri_caddis`.`Labs` (`lab_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ecometri_caddis`.`Samples`
-- -----------------------------------------------------;
DROP TABLE IF EXISTS `ecometri_caddis`.`Samples` ;

CREATE TABLE IF NOT EXISTS `ecometri_caddis`.`Samples` (
  `sample_id` INT NOT NULL AUTO_INCREMENT,
  `sample_name` VARCHAR(45) NOT NULL,
  `location_id` INT NOT NULL,
  `sample_datetime` DATETIME NOT NULL,
  `sample_notes` VARCHAR(1000) NULL,
  PRIMARY KEY (`sample_id`),
  INDEX `location_id_idx` (`location_id` ASC),
  UNIQUE INDEX `sample_name_UNIQUE` (`sample_name` ASC),
  CONSTRAINT `location_id_sam`
    FOREIGN KEY (`location_id`)
    REFERENCES `ecometri_caddis`.`Locations` (`location_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ecometri_caddis`.`Measurements`
-- -----------------------------------------------------;
DROP TABLE IF EXISTS `ecometri_caddis`.`Measurements` ;

CREATE TABLE IF NOT EXISTS `ecometri_caddis`.`Measurements` (
  `measurement_id` INT NOT NULL AUTO_INCREMENT,
  `sample_id` INT NOT NULL,
  `batch_id` INT NOT NULL,
  `measurement_value` FLOAT NOT NULL,
  `metric_id` INT NOT NULL,
  `bd_flag` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`measurement_id`),
  INDEX `sample_id_idx` (`sample_id` ASC),
  INDEX `batch_id_idx` (`batch_id` ASC),
  INDEX `metric_id_idx` (`metric_id` ASC),
  UNIQUE INDEX `measurement_UNIQUE` (`sample_id` ASC, `batch_id` ASC, `metric_id` ASC),
  CONSTRAINT `sample_id`
    FOREIGN KEY (`sample_id`)
    REFERENCES `ecometri_caddis`.`Samples` (`sample_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `batch_id`
    FOREIGN KEY (`batch_id`)
    REFERENCES `ecometri_caddis`.`Batches` (`batch_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `metric_id_meas`
    FOREIGN KEY (`metric_id`)
    REFERENCES `ecometri_caddis`.`Metrics` (`metric_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ecometri_caddis`.`Slugs`
-- -----------------------------------------------------;
DROP TABLE IF EXISTS `ecometri_caddis`.`Slugs` ;

CREATE TABLE IF NOT EXISTS `ecometri_caddis`.`Slugs` (
  `slug_id` INT NOT NULL AUTO_INCREMENT,
  `slug_datetime` DATETIME NOT NULL,
  `location_id` INT NOT NULL,
  PRIMARY KEY (`slug_id`),
  UNIQUE INDEX `slug_datetime_UNIQUE` (`slug_datetime` ASC),
  INDEX `location_id` (`location_id` ASC),
  CONSTRAINT `location_id_slugs`
    FOREIGN KEY (`location_id`)
    REFERENCES `ecometri_caddis`.`Locations` (`location_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ecometri_caddis`.`Treatments`
-- -----------------------------------------------------;
DROP TABLE IF EXISTS `ecometri_caddis`.`Treatments` ;

CREATE TABLE IF NOT EXISTS `ecometri_caddis`.`Treatments` (
  `treatment_id` INT NOT NULL AUTO_INCREMENT,
  `treatment_name` VARCHAR(200) NOT NULL,
  PRIMARY KEY (`treatment_id`),
  UNIQUE INDEX `treament_name_UNIQUE` (`treatment_name` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ecometri_caddis`.`Assignments`
-- -----------------------------------------------------;
DROP TABLE IF EXISTS `ecometri_caddis`.`Assignments` ;

CREATE TABLE IF NOT EXISTS `ecometri_caddis`.`Assignments` (
  `assignment_id` INT NOT NULL AUTO_INCREMENT,
  `location_id` INT NOT NULL,
  `treatment_id` INT NOT NULL,
  `assignment_start` DATE NOT NULL,
  `assignment_end` DATE NOT NULL,
  PRIMARY KEY (`assignment_id`),
  INDEX `location_id_idx` (`location_id` ASC),
  INDEX `treament_id_idx` (`treatment_id` ASC),
  UNIQUE INDEX `assignment_UNIQUE` (`location_id` ASC, `treatment_id` ASC, `assignment_start` ASC),
  CONSTRAINT `location_id_assign`
    FOREIGN KEY (`location_id`)
    REFERENCES `ecometri_caddis`.`Locations` (`location_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `treatment_id`
    FOREIGN KEY (`treatment_id`)
    REFERENCES `ecometri_caddis`.`Treatments` (`treatment_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `ecometri_caddis`.`Observations`
-- -----------------------------------------------------;
DROP TABLE IF EXISTS `ecometri_caddis`.`Observations` ;

CREATE TABLE IF NOT EXISTS `ecometri_caddis`.`Observations` (
  `observation_id` INT NOT NULL AUTO_INCREMENT,
  `metric_id` INT NOT NULL,
  `observation_value` FLOAT NOT NULL,
  `location_id` INT NOT NULL,
  `observation_date` DATE NOT NULL,
  `observation_time` TIME NOT NULL,
  `time_flag` BIT(1) NOT NULL,
  PRIMARY KEY (`observation_id`),
  INDEX `location_id_idx` (`location_id` ASC),
  INDEX `metric_id_idx` (`metric_id` ASC),
  UNIQUE INDEX `observation_UNIQUE` (`observation_date` ASC, `location_id` ASC, `metric_id` ASC, `observation_time` ASC),
  CONSTRAINT `location_id_obs`
    FOREIGN KEY (`location_id`)
    REFERENCES `ecometri_caddis`.`Locations` (`location_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `metric_id_obs`
    FOREIGN KEY (`metric_id`)
    REFERENCES `ecometri_caddis`.`Metrics` (`metric_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
