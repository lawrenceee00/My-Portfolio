<?php
session_start();
include 'conn.php';

$sql = "SELECT * FROM reports ORDER BY timestamp DESC";
$stmt = $conn->prepare($sql);
$stmt->execute();
$reports = $stmt->fetchAll(PDO::FETCH_ASSOC);

if ($reports) {
    echo json_encode(["status" => "success", "reports" => $reports]);
} else {
    echo json_encode(["status" => "success", "reports" => []]);
}
?>

