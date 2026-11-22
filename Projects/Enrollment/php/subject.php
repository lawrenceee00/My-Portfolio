<?php
session_start();
include 'conn.php';

$subjectName = $_POST['subjectName'];
$subjectCode = $_POST['subjectCode'];
$studentID = $_SESSION['studentID'] ?? null;

$sql = "INSERT INTO subject(subjectname, subjectcode, studentID) VALUES (?, ?, ?)";
$stmt = $conn->prepare($sql);
$stmt->bindParam(1, $subjectName);
$stmt->bindParam(2, $subjectCode);
$stmt->bindParam(3, $studentID);
if($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "Subject enrolled successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => "Failed to enroll subject"]);
}
