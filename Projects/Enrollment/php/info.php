<?php
session_start();
include 'conn.php';

header('Content-Type: application/json');

if (!isset($_SESSION['studentID'])) {
    echo json_encode(["status" => "error", "message" => "Not logged in"]);
    exit;
}

$studentID = $_SESSION['studentID'];

// Handle POST request for updating student info
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'update') {
    $lastname = $_POST['lastname'] ?? '';
    $firstname = $_POST['firstname'] ?? '';
    $middlename = $_POST['middlename'] ?? '';
    $address = $_POST['address'] ?? '';
    $contactnumber = $_POST['contactnumber'] ?? '';
    $birthday = $_POST['birthday'] ?? '';
    $gender = $_POST['gender'] ?? '';
    $semester = $_POST['semester'] ?? '';
    $year = $_POST['year'] ?? '';
    $course = $_POST['course'] ?? '';
    $email = $_POST['email'] ?? '';

    $sql = "UPDATE studentinfo 
            SET lastname = ?, firstname = ?, middlename = ?, address = ?, 
                contactnumber = ?, birthday = ?, gender = ?, semester = ?, 
                year = ?, course = ?, email = ?
            WHERE studentID = ?";
    
    $stmt = $conn->prepare($sql);
    $result = $stmt->execute([
        $lastname, $firstname, $middlename, $address, 
        $contactnumber, $birthday, $gender, $semester, 
        $year, $course, $email, $studentID
    ]);

    if ($result) {
        echo json_encode(["status" => "success", "message" => "Student information updated successfully"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Failed to update student information"]);
    }
    exit;
}

// Handle GET request for fetching student info
$sql = "SELECT studentID, lastname, firstname, middlename, address, contactnumber, birthday, gender, semester, year, course, email
        FROM studentinfo
        WHERE studentID = ?";
$stmt = $conn->prepare($sql);
$stmt->execute([$studentID]);

$row = $stmt->fetch(PDO::FETCH_ASSOC);

if ($row) {
    echo json_encode(["status" => "success", "data" => $row]);
} else {
    echo json_encode(["status" => "error", "message" => "Student not found"]);
}
