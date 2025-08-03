
CREATE TABLE IF NOT EXISTS `mBanking_transactions` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(60) NOT NULL,
    `type` varchar(50) NOT NULL,
    `amount` int(11) NOT NULL,
    `date` varchar(10) NOT NULL,
    `status` varchar(50) NOT NULL,
    `month` int(2) NOT NULL,
    `year` int(4) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `identifier` (`identifier`),
    KEY `month_year` (`month`, `year`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mBanking_monthly_stats` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(60) NOT NULL,
    `month` int(2) NOT NULL,
    `year` int(4) NOT NULL,
    `monthly_expenses` int(11) NOT NULL DEFAULT 0,
    `monthly_deposits` int(11) NOT NULL DEFAULT 0,
    `last_bonus_claim` int(11) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier_month_year` (`identifier`, `month`, `year`),
    KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4; 

