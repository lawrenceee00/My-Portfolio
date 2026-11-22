<?php
$host = 'localhost'; 
$dbname = 'ereport';
$username = 'root';
$password = '';

try {
    $conn = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $conn->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
    $conn->exec("SET SESSION query_cache_type=0");
} catch (PDOException $e) {
    die("Connection failed: " . $e->getMessage());
}

