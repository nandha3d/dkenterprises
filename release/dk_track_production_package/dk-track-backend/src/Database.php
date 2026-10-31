<?php
declare(strict_types=1);

namespace DKTrack;

use PDO;
use PDOException;

/**
 * Singleton Database Manager for DK Enterprises ERP
 * Supports MySQL 8.0 InnoDB with strict transaction isolation and UTF8MB4
 */
class Database
{
    private static ?PDO $instance = null;

    public static function getConnection(): ?PDO
    {
        if (self::$instance === null) {
            $config = require __DIR__ . '/../config/database.php';
            $dsn = sprintf(
                'mysql:host=%s;port=%d;dbname=%s;charset=%s',
                $config['host'],
                $config['port'],
                $config['database'],
                $config['charset']
            );

            try {
                self::$instance = new PDO(
                    $dsn,
                    $config['username'],
                    $config['password'],
                    $config['options']
                );
            } catch (PDOException $e) {
                // Return null if connection fails during offline dev/test mode
                error_log("Database connection failed: " . $e->getMessage());
                return null;
            }
        }

        return self::$instance;
    }
}
