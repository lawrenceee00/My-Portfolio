<?php
include 'conn.php';

try {
    // Check if column exists
    $sql = "SHOW COLUMNS FROM reports LIKE 'status'";
    $stmt = $conn->query($sql);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$result) {
        // Add status column
        $sql = "ALTER TABLE reports ADD COLUMN status VARCHAR(50) DEFAULT 'pending'";
        $conn->exec($sql);
        echo "Status column added successfully!";
    } else {
        echo "Status column already exists.";
    }
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}
?>

