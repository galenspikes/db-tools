--
-- Table structure for table `application_logs`
--

DROP TABLE IF EXISTS `application_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `application_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `parameters` text COLLATE utf8mb4_unicode_ci,
  `datetime_created` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `created_by` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=430 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELIMITER ;;
CREATE DEFINER=`app_dba`@`%` FUNCTION `generate_password`() RETURNS varchar(16) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
    READS SQL DATA
    DETERMINISTIC
BEGIN
DECLARE v_password VARCHAR(16);
    set @special_a=35;
    set @special_b=38;
    set @num_a=48;
    set @num_b=57;
    set @lowercase_a=97;
    set @lowercase_b=122;
    set @uppercase_a=65;
    set @uppercase_b=90;
    select char(
        floor(rand()*(@lowercase_b-@lowercase_a+1))+@lowercase_a,
        floor(rand()*(@special_b-@special_a+1))+@special_a,
        floor(rand()*(@uppercase_b-@uppercase_a+1))+@uppercase_a,
        floor(rand()*(@lowercase_b-@lowercase_a+1))+@lowercase_a,
        floor(rand()*(@num_b-@num_a+1))+@num_a,
        floor(rand()*(@lowercase_b-@lowercase_a+1))+@lowercase_a,
        floor(rand()*(@lowercase_b-@lowercase_a+1))+@lowercase_a,
        floor(rand()*(@num_b-@num_a+1))+@num_a,
        floor(rand()*(@special_b-@special_a+1))+@special_a,
        floor(rand()*(@lowercase_b-@lowercase_a+1))+@lowercase_a,
        floor(rand()*(@uppercase_b-@uppercase_a+1))+@uppercase_a,
        floor(rand()*(@lowercase_b-@lowercase_a+1))+@lowercase_a,
        floor(rand()*(@num_b-@num_a+1))+@num_a,
        floor(rand()*(@special_b-@special_a+1))+@special_a,
        floor(rand()*(@lowercase_b-@lowercase_a+1))+@lowercase_a,
        floor(rand()*(@uppercase_b-@uppercase_a+1))+@uppercase_a
        ) into v_password;

    RETURN v_password;
END ;;
DELIMITER ;
