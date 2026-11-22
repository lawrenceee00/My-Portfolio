<?php
include 'conn.php';

echo "Before fix:\n";
foreach ($conn->query("SELECT status, COUNT(*) c FROM reports GROUP BY status") as $row) {
    echo $row['status'] . ': ' . $row['c'] . "\n";
}

$stmt = $conn->prepare("UPDATE reports SET status='in-progress' WHERE status='in-progres'");
$stmt->execute();
$affected = $stmt->rowCount();

echo "\nFixed $affected records (in-progres → in-progress)\n\n";

echo "After fix:\n";
foreach ($conn->query("SELECT status, COUNT(*) c FROM reports GROUP BY status") as $row) {
    echo $row['status'] . ': ' . $row['c'] . "\n";
}
?>

