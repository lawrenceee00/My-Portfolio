<?php
session_start();
include 'conn.php';

$userID = isset($_SESSION['userID']) ? $_SESSION['userID'] : null;

if (!$userID) {
    echo json_encode(["status" => "error", "message" => "User not logged in"]);
    exit;
}

$sql = "SELECT * FROM reports WHERE userID = ? ORDER BY timestamp DESC";
$stmt = $conn->prepare($sql);
$stmt->bindParam(1, $userID);
$stmt->execute();
$reports = $stmt->fetchAll(PDO::FETCH_ASSOC);

if ($reports) {
    echo json_encode(["status" => "success", "reports" => $reports]);
} else {
    echo json_encode(["status" => "success", "reports" => []]);
}
?>

