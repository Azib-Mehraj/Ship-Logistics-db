-- Server version	26.7.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- Table structure for table `checkpoint`
--

DROP TABLE IF EXISTS `checkpoint`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `checkpoint` (
  `checkpoint_id` int NOT NULL AUTO_INCREMENT,
  `departure_time` datetime DEFAULT NULL,
  `arrival_time` datetime DEFAULT NULL,
  `status` varchar(50) NOT NULL,
  `port_id` int NOT NULL,
  `shipment_id` int NOT NULL,
  PRIMARY KEY (`checkpoint_id`),
  KEY `checkpoint_ibfk_1` (`port_id`),
  KEY `checkpoint_ibfk_2` (`shipment_id`),
  CONSTRAINT `checkpoint_ibfk_1` FOREIGN KEY (`port_id`) REFERENCES `port` (`port_id`),
  CONSTRAINT `checkpoint_ibfk_2` FOREIGN KEY (`shipment_id`) REFERENCES `shipment` (`shipment_id`),
  CONSTRAINT `chk_checkpoint_status` CHECK ((`status` in (_utf8mb4'Scheduled',_utf8mb4'Arrived',_utf8mb4'Departed',_utf8mb4'Delayed'))),
  CONSTRAINT `chk_checkpoint_times` CHECK (((`arrival_time` is null) or (`departure_time` is null) or (`arrival_time` <= `departure_time`)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `employees`
--

DROP TABLE IF EXISTS `employees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employees` (
  `employee_id` int NOT NULL AUTO_INCREMENT,
  `employee_name` varchar(100) NOT NULL,
  PRIMARY KEY (`employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `port`
--

DROP TABLE IF EXISTS `port`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `port` (
  `port_id` int NOT NULL AUTO_INCREMENT,
  `port_name` varchar(100) NOT NULL,
  PRIMARY KEY (`port_id`),
  UNIQUE KEY `uq_port_name` (`port_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `route`
--

DROP TABLE IF EXISTS `route`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `route` (
  `route_id` int NOT NULL AUTO_INCREMENT,
  `route_name` varchar(100) NOT NULL DEFAULT 'Unknown',
  PRIMARY KEY (`route_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `route_stop`
--

DROP TABLE IF EXISTS `route_stop`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `route_stop` (
  `route_stop_id` int NOT NULL AUTO_INCREMENT,
  `sequence_no` int NOT NULL,
  `route_id` int NOT NULL,
  `port_id` int NOT NULL,
  PRIMARY KEY (`route_stop_id`),
  UNIQUE KEY `uq_route_seq` (`route_id`,`sequence_no`),
  KEY `route_stop_ibfk_2` (`port_id`),
  CONSTRAINT `route_stop_ibfk_1` FOREIGN KEY (`route_id`) REFERENCES `route` (`route_id`),
  CONSTRAINT `route_stop_ibfk_2` FOREIGN KEY (`port_id`) REFERENCES `port` (`port_id`),
  CONSTRAINT `chk_seq_positive` CHECK ((`sequence_no` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ship`
--

DROP TABLE IF EXISTS `ship`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ship` (
  `ship_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `uq_imo` varchar(20) NOT NULL,
  `route_id` int DEFAULT NULL,
  PRIMARY KEY (`ship_id`),
  UNIQUE KEY `uq_imo` (`uq_imo`),
  KEY `ship_ibfk_1` (`route_id`),
  CONSTRAINT `ship_ibfk_1` FOREIGN KEY (`route_id`) REFERENCES `route` (`route_id`),
  CONSTRAINT `chk_imo_format` CHECK (regexp_like(`uq_imo`,_utf8mb4'^[0-9]{7}$'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ship_assignment`
--

DROP TABLE IF EXISTS `ship_assignment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ship_assignment` (
  `assignment_id` int NOT NULL AUTO_INCREMENT,
  `assigned_from` datetime NOT NULL,
  `assigned_to` datetime DEFAULT NULL,
  `role` varchar(50) NOT NULL,
  `employee_id` int NOT NULL,
  `ship_id` int NOT NULL,
  PRIMARY KEY (`assignment_id`),
  KEY `ship_assignment_ibfk_1` (`employee_id`),
  KEY `ship_assignment_ibfk_2` (`ship_id`),
  CONSTRAINT `ship_assignment_ibfk_1` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`),
  CONSTRAINT `ship_assignment_ibfk_2` FOREIGN KEY (`ship_id`) REFERENCES `ship` (`ship_id`),
  CONSTRAINT `chk_assignment_dates` CHECK (((`assigned_to` is null) or (`assigned_to` >= `assigned_from`)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `shipment`
--

DROP TABLE IF EXISTS `shipment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shipment` (
  `shipment_id` int NOT NULL AUTO_INCREMENT,
  `sender_name` varchar(100) NOT NULL,
  `receiver_name` varchar(100) NOT NULL,
  `weight` decimal(10,2) NOT NULL,
  `cargo_type` varchar(100) NOT NULL,
  `booking_date` date NOT NULL,
  `current_status` varchar(50) NOT NULL,
  `ship_id` int DEFAULT NULL,
  PRIMARY KEY (`shipment_id`),
  KEY `shipment_ibfk_1` (`ship_id`),
  CONSTRAINT `shipment_ibfk_1` FOREIGN KEY (`ship_id`) REFERENCES `ship` (`ship_id`),
  CONSTRAINT `chk_shipment_status` CHECK ((`current_status` in (_utf8mb4'Booked',_utf8mb4'In Transit',_utf8mb4'Delivered',_utf8mb4'Cancelled'))),
  CONSTRAINT `chk_weight_positive` CHECK ((`weight` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `shipment_updates`
--

DROP TABLE IF EXISTS `shipment_updates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shipment_updates` (
  `update_id` int NOT NULL AUTO_INCREMENT,
  `update_time` datetime NOT NULL,
  `update_status` varchar(50) NOT NULL,
  `description` varchar(200) DEFAULT NULL,
  `shipment_id` int NOT NULL,
  PRIMARY KEY (`update_id`),
  KEY `shipment_updates_ibfk_1` (`shipment_id`),
  CONSTRAINT `shipment_updates_ibfk_1` FOREIGN KEY (`shipment_id`) REFERENCES `shipment` (`shipment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-28 18:20:27
