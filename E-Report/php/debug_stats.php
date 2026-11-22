<?php
include 'conn.php';
echo "=== REPORT STATUS COUNTS ===\n";
$sql = "SELECT status, COUNT(*) as count FROM reports GROUP BY status";
foreach ($conn->query($sql) as $row) {
    echo $row['status'] . ': ' . $row['count'] . "\n";
}

echo "\n=== MONTHLY BREAKDOWN PER STATUS ===\n";
$sql = "SELECT status, MONTHNAME(timestamp) as month, COUNT(*) as cnt FROM reports WHERE timestamp IS NOT NULL GROUP BY status, MONTH(timestamp) ORDER BY status, MONTH(timestamp)";
foreach ($conn->query($sql) as $row) {
    echo $row['status'] . ' - ' . $row['month'] . ': ' . $row['cnt'] . "\n";
}

echo "\n=== SAMPLE REPORTS (latest 10) ===\n";
$sql = "SELECT reportID, status, timestamp FROM reports ORDER BY reportID DESC LIMIT 10";
foreach ($conn->query($sql) as $row) {
    echo 'ID ' . $row['reportID'] . ': ' . $row['status'] . ', ' . $row['timestamp'] . "\n";
}
?>

